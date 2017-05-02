
local math, string, table, arg = math, string, table, arg
local pairs, ipairs, require, error = pairs, ipairs, require, error
local _ENV = {package=package}
local PYLUA = require('PYLUA')

local FontMetric = require('metric').FontMetric
local CharMetric = require('metric').CharMetric
local FontFormatError = require('metric').FontFormatError

readUnsigned = function(ff, size)
  local res = 0
  for _, c in PYLUA.ipairs(ff:read(size)) do
    res = res*256
    res = res+PYLUA.ord(c)
  end
  return res
end

readSigned = function(ff, size)
  local res = PYLUA.ord(ff:read(1))
  if res>=128 then
    res = res-256
  end
  for _, c in PYLUA.ipairs(ff:read(size-1)) do
    res = res*256
    res = res+PYLUA.ord(c)
  end
  return res
end

readFixed32 = function(ff)
  return readSigned(ff, 4)/65536.0
end

readF2_14 = function(ff)
  return readSigned(ff, 2)/16384.0
end

skip = function(ff, size)
  ff:read(size)
end

TTFFormatError = PYLUA.class(FontFormatError) {

  __init__ = function(self, msg)
    FontFormatError.__init__(self, msg)
  end
  ;
}


TTFMetric = PYLUA.class(FontMetric) {

  __init__ = function(self, ttfname, log, _kw_extra)
    if PYLUA.is_a(ttfname, PYLUA.keywords) then
      local kw = ttfname
      ttfname = log or kw.ttfname
      log = _kw_extra or kw.log
    end
    FontMetric.__init__(self, log)
    local ff = PYLUA.open(ttfname, 'rb')
    self:readFontMetrics(ff)
    ff:close()
    self:postParse()
  end
  ;

  readFontMetrics = function(self, ff)
    local version = ff:read(4)
    if version == '\x00\x01\x00\x00' then
      self.fonttype = 'TTF'
    elseif version=='OTTO' then
      -- self.fonttype="OTF"
      -- At the moment, I cannot parse bbox data out from CFF
      error(TTFFormatError('OpenType/CFF fonts are unsupported'))
    else
      error(TTFFormatError('Not a TrueType file'))
    end

    local numTables = readUnsigned(ff, 2)
    local tables = { }
    skip(ff, 6)
    for i = 1,numTables do
      local tag = ff:read(4)
      local checksum = readUnsigned(ff, 4)
      local offset = readUnsigned(ff, 4)
      local length = readUnsigned(ff, 4)
      tables[tag] = {offset, length}
    end

    local switchTable = function(tableTag)
      return tables[tableTag] or 
        error(TTFFormatError('Required table '..tableTag..' missing in TrueType file'))
    end

    local offset, length = table.unpack(switchTable('head'))
    ff:seek(offset+12)
    local magic = readUnsigned(ff, 4)
    if magic~=0x5F0F3CF5 then
      error(TTFFormatError('Magic number in \'head\' table does not match the spec'))
    end
    skip(ff, 2)
    self.unitsPerEm = readUnsigned(ff, 2)
    local emScale = 1.0/self.unitsPerEm

    skip(ff, 16)
    local xMin = readSigned(ff, 2)*emScale
    local yMin = readSigned(ff, 2)*emScale
    local xMax = readSigned(ff, 2)*emScale
    local yMax = readSigned(ff, 2)*emScale
    self.bbox = {xMin, yMin, xMax, yMax}

    skip(ff, 6)
    self.indexToLocFormat = readSigned(ff, 2)

    offset, length = table.unpack(switchTable('maxp'))
    ff:seek(offset+4)
    self.numGlyphs = readUnsigned(ff, 2)

    offset, length = table.unpack(switchTable('name'))
    ff:seek(offset+2)

    local numRecords = readUnsigned(ff, 2)
    local storageOffset = readUnsigned(ff, 2)+offset

    local uniNames = { }
    local macNames = { }
    local englishCodes = {1033, 2057, 3081, 4105, 5129, 6153}

    for i = 1,numRecords do
      local platformID = readUnsigned(ff, 2)
      local encodingID = readUnsigned(ff, 2)
      local languageID = readUnsigned(ff, 2)
      local nameID = readUnsigned(ff, 2)
      local nameLength = readUnsigned(ff, 2)
      local nameOffset = readUnsigned(ff, 2)

      if platformID==3 and encodingID==1 then
        if PYLUA.op_in(languageID, englishCodes) or not uniNames[nameID] then
          uniNames[nameID] = {nameOffset, nameLength}
        end
      elseif platformID==1 and encodingID==0 then
        if languageID==0 or not macNames[nameID] then
          macNames[nameID] = {nameOffset, nameLength}
        end
      end
    end

    local getName = function(code)
      if macNames[code] then
        local nameOffset, nameLength = table.unpack(macNames[code])
        ff:seek(storageOffset+nameOffset)
        return ff:read(nameLength)
        -- FIXME(grigoriev): repair Mac encoding here
      elseif uniNames[code] then
        nameOffset, nameLength = table.unpack(uniNames[code])
        ff:seek(storageOffset+nameOffset)
        local result = ''
        for i = 1,nameLength/2 do
          result = result..PYLUA.unichr(readUnsigned(ff, 2))
        end
        return result
      end
    end

    self.family = getName(1)
    self.fullname = getName(4)
    self.fontname = getName(6)

    offset, length = table.unpack(switchTable('OS/2'))
    ff:seek(offset)
    local tableVersion = readUnsigned(ff, 2)
    local cw = readSigned(ff, 2)
    if cw then
      self.charwidth = cw*emScale
    end

    local wght = readUnsigned(ff, 2)
    if wght<150 then
      self.weight = 'Thin'
    elseif wght<250 then
      self.weight = 'Extra-Light'
    elseif wght<350 then
      self.weight = 'Light'
    elseif wght<450 then
      self.weight = 'Regular'
    elseif wght<550 then
      self.weight = 'Medium'
    elseif wght<650 then
      self.weight = 'Demi-Bold'
    elseif wght<750 then
      self.weight = 'Bold'
    elseif wght<850 then
      self.weight = 'Extra-Bold'
    else
      self.weight = 'Black'
    end

    skip(ff, 62)
    self.ascender = readSigned(ff, 2)*emScale
    self.descender = readSigned(ff, 2)*emScale

    if tableVersion==2 then
      skip(ff, 14)
      local xh = readSigned(ff, 2)
      if xh then
        self.xheight = xh*emScale
      end
      local ch = readSigned(ff, 2)
      if ch then
        self.capheight = ch*emScale
      end
    end

    offset, length = table.unpack(switchTable('post'))
    ff:seek(offset+4)
    self.italicangle = readFixed32(ff)
    self.underlineposition = readSigned(ff, 2)*emScale
    self.underlinethickness = readSigned(ff, 2)*emScale

    offset, length = table.unpack(switchTable('hhea'))
    ff:seek(offset+34)
    local numHmtx = readUnsigned(ff, 2)

    offset, length = table.unpack(switchTable('hmtx'))
    ff:seek(offset)
    local glyphArray = {}
    local w = 0
    for i = 1,self.numGlyphs do
      if i<numHmtx then
        w = readUnsigned(ff, 2)*emScale
        skip(ff, 2)
      end
      table.insert(glyphArray, CharMetric(PYLUA.keywords{width=w}))
    end

    offset, length = table.unpack(switchTable('cmap'))
    ff:seek(offset+2)
    local subtableOffset = 0
    numTables = readUnsigned(ff, 2)

    local cmapEncodings = { }
    for i = 1,numTables do
      local platformID = readUnsigned(ff, 2)
      local encodingID = readUnsigned(ff, 2)
      subtableOffset = readUnsigned(ff, 4)
      cmapEncodings[string.format('%d %d', platformID, encodingID)] = subtableOffset
    end

    local encodingScheme = 'Unicode'
    subtableOffset = cmapEncodings['3 1']
    if subtableOffset == nil then
      encodingScheme = 'Symbol'
      subtableOffset = cmapEncodings['3 0']
      if subtableOffset == nil then
        error(TTFFormatError(string.format('Cannot use font \'%s\': no known subtable in \'cmap\' table', self.fullname)))
      elseif self.log then
        self.log:write(string.format('WARNING: font \'%s\' is a symbolic font - Unicode mapping may be unreliable\n', self.fullname))
      end
    end

    ff:seek(offset+subtableOffset)

    local tableFormat = readUnsigned(ff, 2)
    if tableFormat~=4 then
      error(TTFFormatError(string.format('Unsupported format in \'cmap\' table: %d', tableFormat)))
    end

    local subtableLength = readUnsigned(ff, 2)
    skip(ff, 2)
    local segCount = readUnsigned(ff, 2)/2
    skip(ff, 6)

    local endCounts = {}
    for i = 1,segCount do
      table.insert(endCounts, readUnsigned(ff, 2))
    end

    skip(ff, 2)
    local startCounts = {}
    for i = 1,segCount do
      table.insert(startCounts, readUnsigned(ff, 2))
    end

    local idDeltas = {}
    for i = 1,segCount do
      table.insert(idDeltas, readSigned(ff, 2))
    end

    local rangeOffsets = {}
    for i = 1,segCount do
      table.insert(rangeOffsets, readUnsigned(ff, 2))
    end

    local remainingLength = subtableLength-8*segCount-16
    if remainingLength<=0 then
      remainingLength = remainingLength+65536  -- protection against Adobe's bug
    end

    local glyphIdArray = {}
    for i = 1,remainingLength/2 do
      table.insert(glyphIdArray, readUnsigned(ff, 2))
    end

    for i = 1,segCount do
      for c = startCounts[i], endCounts[i]+1 do
        if c==0xFFFF then
          goto continue
        end
        local gid = 0
        if (rangeOffsets[i] or 0) ~= 0 then
          local idx = c-startCounts[i]+rangeOffsets[i]/2-(segCount-i)
          gid = glyphIdArray[idx]
        else
          gid = c+idDeltas[i]
        end
        if gid>=65536 then
          gid = gid-65536
        elseif gid<0 then
          gid = gid+65536
        end

        local cm = glyphArray[gid+1]
        table.insert(cm.codes, c)
        -- Dirty hack: map the lower half of the private-use area to ASCII
        if encodingScheme=='Symbol' and PYLUA.op_in(c, range(61472, 61567)) then
          table.insert(cm.codes, c-61440)
        end
        if  not cm.name then
          cm.name = string.format('u%04X', c)
        end
        ::continue::
      end
    end

    offset, length = table.unpack(switchTable('loca'))
    ff:seek(offset)
    local glyphIndex = {}
    local scalefactor = self.indexToLocFormat+1

    if self.indexToLocFormat==0 then
      for i = 1,self.numGlyphs+1 do
        table.insert(glyphIndex, readUnsigned(ff, 2)*2)
      end
    elseif self.indexToLocFormat==1 then
      for i = 1,self.numGlyphs+1 do
        table.insert(glyphIndex, readUnsigned(ff, 4))
      end
    else
      error(TTFFormatError(string.format('Invalid indexToLocFormat value (%d) in \'head\' table', tostring(self.indexToLocFormat))))
    end

    offset, length = table.unpack(switchTable('glyf'))
    for i = 1,self.numGlyphs do
      local cm = glyphArray[i]
      if glyphIndex[i]==glyphIndex[i+1] then
        cm.bbox = {0, 0, 0, 0}  -- empty glyph
      else
        ff:seek(offset+glyphIndex[i]+2)
        local xMin = readSigned(ff, 2)*emScale
        local yMin = readSigned(ff, 2)*emScale
        local xMax = readSigned(ff, 2)*emScale
        local yMax = readSigned(ff, 2)*emScale
        cm.bbox = {xMin, yMin, xMax, yMax}
      end
      for _, c in ipairs(cm.codes) do
        self.chardata[c] = cm
      end
    end
  end
  ;
}


main = function()
  if #arg==1 then
    TTFMetric(PYLUA.keywords{log=io.stderr}, arg[1]):dump()
  else
    PYLUA.print('Usage: TTF.py <path to TTF file>', '\n')
  end
end

if arg and arg[1]==... then
  main()
end

return _ENV
