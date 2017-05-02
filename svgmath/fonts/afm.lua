
local math, string, table, require = math, string, table, require
local pairs, ipairs = pairs, ipairs
local _ENV = {package=package}
local PYLUA = require('PYLUA')

local glyphlist = require('glyphlist')
local FontMetric = require('metric').FontMetric
local CharMetric = require('metric').CharMetric
local FontFormatError = require('metric').FontFormatError

parseLength = function(s)
  return 0.001*float(s)
end

AFMFormatError = PYLUA.class(FontFormatError) {

  __init__ = function(self, msg)
    FontFormatError.__init__(self, msg)
  end
  ;
}


AFMMetric = PYLUA.class(FontMetric) {

  __init__ = function(self, afmname, glyphlistname, log, _kw_extra)
    if PYLUA.is_a(afmname, PYLUA.keywords) then
      local kw = afmname
      afmname = glyphlistname or kw.afmname
      glyphlistname = log or kw.glyphlistname
      log = _kw_extra or kw.log
    end
    FontMetric.__init__(self, log)
    local afmfile = PYLUA.open(afmname, 'r')
    if glyphlistname == nil then
      self.glyphList = glyphlist.defaultGlyphList
    else
      self.glyphList = glyphlist.GlyphList(PYLUA.open(afmname, 'r'))
    end
    self:readFontMetrics(afmfile)
    afmfile:close()
    self:postParse()
  end
  ;

  readFontMetrics = function(self, afmfile)
    local line = afmfile:readline()
    if  not PYLUA.startswith(line, 'StartFontMetrics') then
      error(AFMFormatError('File is not an AFM file'))
    end
    -- TODO(grigoriev): AFM version control    

    while true do
      line = afmfile:readline()
      if #line==0 then
        break  -- EOF
      end
      if PYLUA.startswith(line, 'EndFontMetrics') then
        break
      end

      if PYLUA.startswith(line, 'StartCharMetrics') then
        self:readCharMetrics(afmfile)
      elseif PYLUA.startswith(line, 'StartKernData') then
        self:readKernData(afmfile)
      elseif PYLUA.startswith(line, 'StartComposites') then
        self:readComposites(afmfile)
      else
        local tokens = PYLUA.split(line, nil, 1)
        if #tokens<2 then
          goto continue
        end
        if tokens[1]=='FontName' then
          self.fontname = PYLUA.strip(tokens[2])
        elseif tokens[1]=='FullName' then
          self.fullname = PYLUA.strip(tokens[2])
        elseif tokens[1]=='FamilyName' then
          self.family = PYLUA.strip(tokens[2])
        elseif tokens[1]=='Weight' then
          self.weight = PYLUA.strip(tokens[2])
        elseif tokens[1]=='FontBBox' then
          self.bbox = PYLUA.map(parseLength, PYLUA.split(tokens[2]))
        elseif tokens[1]=='CapHeight' then
          self.capheight = parseLength(tokens[2])
        elseif tokens[1]=='XHeight' then
          self.xheight = parseLength(tokens[2])
        elseif tokens[1]=='Ascender' then
          self.ascender = parseLength(tokens[2])
        elseif tokens[1]=='Descender' then
          self.descender = parseLength(tokens[2])
        elseif tokens[1]=='StdHW' then
          self.stdhw = parseLength(tokens[2])
        elseif tokens[1]=='StdVW' then
          self.stdvw = parseLength(tokens[2])
        elseif tokens[1]=='UnderlinePosition' then
          self.underlineposition = parseLength(tokens[2])
        elseif tokens[1]=='UnderlineThickness' then
          self.underlinethickness = parseLength(tokens[2])
        elseif tokens[1]=='ItalicAngle' then
          self.italicangle = float(tokens[2])
        elseif tokens[1]=='CharWidth' then
          self.charwidth = parseLength(PYLUA.split(tokens[2])[1])
        end
      end
      ::continue::
    end
  end
  ;

  readCharMetrics = function(self, afmfile)
    while true do
      local line = afmfile:readline()
      if #line==0 then
        break
      end
      if PYLUA.startswith(line, 'EndCharMetrics') then
        break
      end
      self:parseCharMetric(line)
    end
  end
  ;

  parseCharMetric = function(self, line)
    local glyphname = nil
    local width = nil
    local bbox = nil
    for _, token in ipairs(PYLUA.split(line, ';')) do
      local d = PYLUA.split(token)
      if #d<2 then
        goto continue
      end
      if d[1]=='W' or d[1]=='WX' or d[1]=='W0X' then
        width = parseLength(d[2])
      elseif d[1]=='B' and #d==5 then
        bbox = PYLUA.map(parseLength, PYLUA.slice(d, 1, nil))
      elseif d[1]=='N' then
        glyphname = d[2]
      end
      ::continue::
    end

    if glyphname == nil then
      return 
    end
    if bbox == nil then
      if self.bbox ~= nil then
        bbox = self.bbox
      else
        bbox = {0, 0, 0, 0}
      end
    end
    if width == nil then
      if self.charwidth ~= nil then
        width = self.charwidth
      else
        width = bbox[3]-bbox[1]
      end
    end

    local codes = self.glyphList:lookup(glyphname)
    if codes ~= nil then
      local cm = CharMetric(glyphname, codes, width, bbox)
      for _, c in ipairs(codes) do
        self.chardata[c] = cm
      end
    elseif PYLUA.startswith(glyphname, 'uni') then
      if #glyphname~=7 then
        -- no support for composites yet
      end
      local c = tonumber(PYLUA.slice(glyphname, 3, nil), 16)
      if c and c>=0 and c<65536 then
        self.chardata[c] = CharMetric(glyphname, {c}, width, bbox)
      end
    elseif PYLUA.startswith(glyphname, 'u') then
      if PYLUA.op_not_in(#glyphname, {5, 6, 7}) then
      end
      c = tonumber(PYLUA.slice(glyphname, 1, nil), 16)
      if c and c>=0 and c<65536 then
        self.chardata[c] = CharMetric(glyphname, {c}, width, bbox)
      end
    end
  end
  ;

  readKernData = function(self, afmfile)
    while true do
      local line = afmfile:readline()
      if #line==0 then
        break  -- EOF
      end
      if PYLUA.startswith(line, 'EndKernData') then
        break
      end
      -- TODO(grigoriev): parse kerning pairs    
    end
  end
  ;

  readComposites = function(self, afmfile)
    while true do
      local line = afmfile:readline()
      if #line==0 then
        break  -- EOF
      end
      if PYLUA.startswith(line, 'EndComposites') then
        break
      end
      -- TODO(grigoriev): parse composites
    end
  end
  ;
}


main = function()
  if #arg==1 then
    AFMMetric(PYLUA.keywords{log=io.stderr}, arg[1]):dump()
  else
    PYLUA.print('Usage: AFM.py <path to AFM file>', '\n')
  end
end
if arg and arg[1]==... then
  main()
end

return _ENV
