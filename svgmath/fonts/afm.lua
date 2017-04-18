local sys = require('sys')
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

  __init__ = function(self, afmname, glyphlistname, log)
    FontMetric.__init__(self, log)
    local afmfile = open(afmname, 'r')
    if PYLUA.op_is(glyphlistname, nil) then
      self.glyphList = glyphlist.defaultGlyphList
    else
      self.glyphList = glyphlist.GlyphList(open(afmname, 'r'))
    end
    self.readFontMetrics(afmfile)
    afmfile.close()
    self.postParse()
  end
  ;

  readFontMetrics = function(self, afmfile)
    local line = afmfile.readline()
    if  not line.startswith('StartFontMetrics') then
      error(AFMFormatError)
    end
    while true do
      line = afmfile.readline()
      if len(line)==0 then
        break
      end
      if line.startswith('EndFontMetrics') then
        break
      end
      if line.startswith('StartCharMetrics') then
        self.readCharMetrics(afmfile)
      elseif line.startswith('StartKernData') then
        self.readKernData(afmfile)
      elseif line.startswith('StartComposites') then
        self.readComposites(afmfile)
      else
        local tokens = line.split(nil, 1)
        if len(tokens)<2 then
          goto continue
        end
        if tokens[1]=='FontName' then
          self.fontname = tokens[2].strip()
        elseif tokens[1]=='FullName' then
          self.fullname = tokens[2].strip()
        elseif tokens[1]=='FamilyName' then
          self.family = tokens[2].strip()
        elseif tokens[1]=='Weight' then
          self.weight = tokens[2].strip()
        elseif tokens[1]=='FontBBox' then
          self.bbox = map(parseLength, tokens[2].split())
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
          self.charwidth = parseLength(tokens[2].split()[1])
        end
      end
    end
  end
  ;

  readCharMetrics = function(self, afmfile)
    while true do
      local line = afmfile.readline()
      if len(line)==0 then
        break
      end
      if line.startswith('EndCharMetrics') then
        break
      end
      self.parseCharMetric(line)
    end
  end
  ;

  parseCharMetric = function(self, line)
    local glyphname = nil
    local width = nil
    local bbox = nil
    for _, token in ipairs(line.split(';')) do
      local d = token.split()
      if len(d)<2 then
        goto continue
      end
      if d[1]=='W' or d[1]=='WX' or d[1]=='W0X' then
        width = parseLength(d[2])
      elseif d[1]=='B' and len(d)==5 then
        bbox = map(parseLength, PYLUA.slice(d, 1, nil))
      elseif d[1]=='N' then
        glyphname = d[2]
      end
    end
    if PYLUA.op_is(glyphname, nil) then
      return 
    end
    if PYLUA.op_is(bbox, nil) then
      if PYLUA.op_is_not(self.bbox, nil) then
        bbox = self.bbox
      else
        bbox = {0, 0, 0, 0}
      end
    end
    if PYLUA.op_is(width, nil) then
      if PYLUA.op_is_not(self.charwidth, nil) then
        width = self.charwidth
      else
        width = bbox[3]-bbox[1]
      end
    end
    local codes = self.glyphList.lookup(glyphname)
    if PYLUA.op_is_not(codes, nil) then
      local cm = CharMetric(glyphname, codes, width, bbox)
      for _, c in ipairs(codes) do
        self.chardata[c] = cm
      end
    elseif glyphname.startswith('uni') then
      if len(glyphname)~=7 then
      end
      -- PYLUA.FIXME: TRY:
        local c = int(PYLUA.slice(glyphname, 3, nil), 16)
        if c>=0 and c<65536 then
          self.chardata[c] = CharMetric(glyphname, {c}, width, bbox)
        end
      -- PYLUA.FIXME: EXCEPT TypeError:
    elseif glyphname.startswith('u') then
      if PYLUA.op_not_in(len(glyphname), {5, 6, 7}) then
      end
      -- PYLUA.FIXME: TRY:
        c = int(PYLUA.slice(glyphname, 1, nil), 16)
        if c>=0 and c<65536 then
          self.chardata[c] = CharMetric(glyphname, {c}, width, bbox)
        end
      -- PYLUA.FIXME: EXCEPT TypeError:
    end
  end
  ;

  readKernData = function(self, afmfile)
    while true do
      local line = afmfile.readline()
      if len(line)==0 then
        break
      end
      if line.startswith('EndKernData') then
        break
      end
    end
  end
  ;

  readComposites = function(self, afmfile)
    while true do
      local line = afmfile.readline()
      if len(line)==0 then
        break
      end
      if line.startswith('EndComposites') then
        break
      end
    end
  end
  ;
}


main = function()
  if len(sys.argv)==2 then
    AFMMetric(PYLUA.keywords{log=sys.stderr}, sys.argv[2]).dump()
  else
    io.write('Usage: AFM.py <path to AFM file>', '\n')
  end
end
if __name__=='__main__' then
  main()
end
