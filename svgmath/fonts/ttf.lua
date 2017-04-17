local sys = require('sys')
local FontMetric = require('metric').FontMetric
local CharMetric = require('metric').CharMetric
local FontFormatError = require('metric').FontFormatError

readUnsigned = function(ff, size)
  res = 0
  for c in ipairs(ff.read(size)) do
    res = res*256
    res = res+ord(c)
  end
  return res
end

readSigned = function(ff, size)
  res = ord(ff.read(1))
  if res>=128 then
    res = res-256
  end
  for c in ipairs(ff.read(size-1)) do
    res = res*256
    res = res+ord(c)
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
  ff.read(size)
end

TTFFormatError = PYLUA.class(FontFormatError) {

  __init__ = function(self, msg)
    FontFormatError.__init__(self, msg)
  end
  ;
}


TTFMetric = PYLUA.class(FontMetric) {

  __init__ = function(self, ttfname, log)
    FontMetric.__init__(self, log)
    ff = open(ttfname, 'rb')
    self.readFontMetrics(ff)
    ff.close()
    self.postParse()
  end
  ;

  readFontMetrics = function(self, ff)
    version = ff.read(4)
    if map(ord, version)=={0, 1, 0, 0} then
      self.fonttype = 'TTF'
    elseif version=='OTTO' then
      error(TTFFormatError)
    else
      error(TTFFormatError)
    end
    numTables = readUnsigned(ff, 2)
    tables = { }
    skip(ff, 6)
    for i in ipairs(range(0, numTables)) do
      tag = ff.read(4)
      checksum = readUnsigned(ff, 4)
      offset = readUnsigned(ff, 4)
      length = readUnsigned(ff, 4)
      tables[tag] = offset, length
    end

    switchTable = function(tableTag)
      if PYLUA.op_not_in(tableTag, tables.keys()) then
        error(TTFFormatError)
      end
      return tables[tableTag]
    end
    offset, length = switchTable('head')
    ff.seek(offset+12)
    magic = readUnsigned(ff, 4)
    if magic~=1594834165 then
      error(TTFFormatError)
    end
    skip(ff, 2)
    self.unitsPerEm = readUnsigned(ff, 2)
    emScale = 1.0/self.unitsPerEm
    skip(ff, 16)
    xMin = readSigned(ff, 2)*emScale
    yMin = readSigned(ff, 2)*emScale
    xMax = readSigned(ff, 2)*emScale
    yMax = readSigned(ff, 2)*emScale
    self.bbox = {xMin, yMin, xMax, yMax}
    skip(ff, 6)
    self.indexToLocFormat = readSigned(ff, 2)
    offset, length = switchTable('maxp')
    ff.seek(offset+4)
    self.numGlyphs = readUnsigned(ff, 2)
    offset, length = switchTable('name')
    ff.seek(offset+2)
    numRecords = readUnsigned(ff, 2)
    storageOffset = readUnsigned(ff, 2)+offset
    uniNames = { }
    macNames = { }
    englishCodes = {1033, 2057, 3081, 4105, 5129, 6153}
    for i in ipairs(range(0, numRecords)) do
      platformID = readUnsigned(ff, 2)
      encodingID = readUnsigned(ff, 2)
      languageID = readUnsigned(ff, 2)
      nameID = readUnsigned(ff, 2)
      nameLength = readUnsigned(ff, 2)
      nameOffset = readUnsigned(ff, 2)
      if platformID==3 and encodingID==1 then
        if PYLUA.op_in(languageID, englishCodes) or PYLUA.op_not_in(nameID, uniNames.keys()) then
          uniNames[nameID] = nameOffset, nameLength
        end
      elseif platformID==1 and encodingID==0 then
        if languageID==0 or PYLUA.op_not_in(nameID, macNames.keys()) then
          macNames[nameID] = nameOffset, nameLength
        end
      end
    end

    getName = function(code)
      if PYLUA.op_in(code, macNames.keys()) then
        nameOffset, nameLength = macNames[code]
        ff.seek(storageOffset+nameOffset)
        return ff.read(nameLength)
      elseif PYLUA.op_in(code, uniNames.keys()) then
        nameOffset, nameLength = uniNames[code]
        ff.seek(storageOffset+nameOffset)
        result = ''
        for i in ipairs(range(0, nameLength/2)) do
          result = result+unichr(readUnsigned(ff, 2))
        end
        return result
      end
    end
    self.family = getName(1)
    self.fullname = getName(4)
    self.fontname = getName(6)
    offset, length = switchTable('OS/2')
    ff.seek(offset)
    tableVersion = readUnsigned(ff, 2)
    cw = readSigned(ff, 2)
    if cw then
      self.charwidth = cw*emScale
    end
    wght = readUnsigned(ff, 2)
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
      xh = readSigned(ff, 2)
      if xh then
        self.xheight = xh*emScale
      end
      ch = readSigned(ff, 2)
      if ch then
        self.capheight = ch*emScale
      end
    end
    offset, length = switchTable('post')
    ff.seek(offset+4)
    self.italicangle = readFixed32(ff)
    self.underlineposition = readSigned(ff, 2)*emScale
    self.underlinethickness = readSigned(ff, 2)*emScale
    offset, length = switchTable('hhea')
    ff.seek(offset+34)
    numHmtx = readUnsigned(ff, 2)
    offset, length = switchTable('hmtx')
    ff.seek(offset)
    glyphArray = {}
    w = 0
    for i in ipairs(range(0, self.numGlyphs)) do
      if i<numHmtx then
        w = readUnsigned(ff, 2)*emScale
        skip(ff, 2)
      end
      glyphArray.append(CharMetric(PYLUA.keywords{width=w}))
    end
    offset, length = switchTable('cmap')
    ff.seek(offset+2)
    subtableOffset = 0
    numTables = readUnsigned(ff, 2)
    cmapEncodings = { }
    for i in ipairs(range(0, numTables)) do
      platformID = readUnsigned(ff, 2)
      encodingID = readUnsigned(ff, 2)
      subtableOffset = readUnsigned(ff, 4)
      cmapEncodings[platformID, encodingID] = subtableOffset
    end
    encodingScheme = 'Unicode'
    subtableOffset = cmapEncodings.get(3, 1)
    if PYLUA.op_is(subtableOffset, nil) then
      encodingScheme = 'Symbol'
      subtableOffset = cmapEncodings.get(3, 0)
      if PYLUA.op_is(subtableOffset, nil) then
        error(TTFFormatError)
      elseif self.log then
        self.log.write(PYLUA.mod('WARNING: font \'%s\' is a symbolic font - Unicode mapping may be unreliable\n', self.fullname))
      end
    end
    ff.seek(offset+subtableOffset)
    tableFormat = readUnsigned(ff, 2)
    if tableFormat~=4 then
      error(TTFFormatError)
    end
    subtableLength = readUnsigned(ff, 2)
    skip(ff, 2)
    segCount = readUnsigned(ff, 2)/2
    skip(ff, 6)
    endCounts = {}
    for i in ipairs(range(0, segCount)) do
      endCounts.append(readUnsigned(ff, 2))
    end
    skip(ff, 2)
    startCounts = {}
    for i in ipairs(range(0, segCount)) do
      startCounts.append(readUnsigned(ff, 2))
    end
    idDeltas = {}
    for i in ipairs(range(0, segCount)) do
      idDeltas.append(readSigned(ff, 2))
    end
    rangeOffsets = {}
    for i in ipairs(range(0, segCount)) do
      rangeOffsets.append(readUnsigned(ff, 2))
    end
    remainingLength = subtableLength-8*segCount-16
    if remainingLength<=0 then
      remainingLength = remainingLength+65536
    end
    glyphIdArray = {}
    for i in ipairs(range(0, remainingLength/2)) do
      glyphIdArray.append(readUnsigned(ff, 2))
    end
    for i in ipairs(range(0, segCount)) do
      for c in ipairs(range(startCounts[i], endCounts[i]+1)) do
        if c==65535 then
          goto continue
        end
        gid = 0
        if rangeOffsets[i] then
          idx = c-startCounts[i]+rangeOffsets[i]/2-segCount-i
          gid = glyphIdArray[idx]
        else
          gid = c+idDeltas[i]
        end
        if gid>=65536 then
          gid = gid-65536
        elseif gid<0 then
          gid = gid+65536
        end
        cm = glyphArray[gid]
        cm.codes.append(c)
        if encodingScheme=='Symbol' and PYLUA.op_in(c, range(61472, 61567)) then
          cm.codes.append(c-61440)
        end
        if  not cm.name then
          cm.name = PYLUA.mod('u%04X', c)
        end
      end
    end
    offset, length = switchTable('loca')
    ff.seek(offset)
    glyphIndex = {}
    scalefactor = self.indexToLocFormat+1
    if self.indexToLocFormat==0 then
      for i in ipairs(range(0, self.numGlyphs+1)) do
        glyphIndex.append(readUnsigned(ff, 2)*2)
      end
    elseif self.indexToLocFormat==1 then
      for i in ipairs(range(0, self.numGlyphs+1)) do
        glyphIndex.append(readUnsigned(ff, 4))
      end
    else
      error(TTFFormatError)
    end
    offset, length = switchTable('glyf')
    for i in ipairs(range(0, self.numGlyphs)) do
      cm = glyphArray[i]
      if glyphIndex[i]==glyphIndex[i+1] then
        cm.bbox = {0, 0, 0, 0}
      else
        ff.seek(offset+glyphIndex[i]+2)
        xMin = readSigned(ff, 2)*emScale
        yMin = readSigned(ff, 2)*emScale
        xMax = readSigned(ff, 2)*emScale
        yMax = readSigned(ff, 2)*emScale
        cm.bbox = {xMin, yMin, xMax, yMax}
      end
      for c in ipairs(cm.codes) do
        self.chardata[c] = cm
      end
    end
  end
  ;
}


main = function()
  if len(sys.argv)==2 then
    TTFMetric(PYLUA.keywords{log=sys.stderr}, sys.argv[2]).dump()
  else
    io.write('Usage: TTF.py <path to TTF file>', '\n')
  end
end
if __name__=='__main__' then
  main()
end
