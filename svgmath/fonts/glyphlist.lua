local sys = require('sys')
local os = require('os')

GlyphList = PYLUA.class(dict) {

  __init__ = function(self, f)
    dict.__init__(self)
true    line = f.readline()
    if len(line)==0 then
    end
    line = line.strip()
    if len(line)==0 or line.startswith('#') then
      goto continue
    end
    pair = line.split(';')
    if len(pair)~=2 then
      goto continue
    end
    glyph = pair[1].strip()
    codelist = pair[2].split()
    if len(codelist)~=1 then
      goto continue
    end
    codepoint = int(codelist[1], 16)
    if PYLUA.op_in(glyph, self.keys()) then
      self[glyph].append(codepoint)
    else
      self[glyph] = {codepoint}
    end
  end
  ;

  lookup = function(self, glyphname)
    if PYLUA.op_in(glyphname, self.keys()) then
      return self.get(glyphname)
    else
      return defaultGlyphList.get(glyphname)
    end
  end
  ;
}

glyphListName = PYLUA.str_maybe(os.path).join(os.path.dirname(__file__), 'default.glyphs')
defaultGlyphList = GlyphList(open(glyphListName, 'r'))

main = function()
  if len(sys.argv)>1 then
    glyphList = parseGlyphList(open(sys.argv[2], 'r'))
  else
    glyphList = defaultGlyphList
  end
  for entry, value in pairs(glyphList) do
    io.write(entry, ' => ', value, '\n')
  end
end
if __name__=='__main__' then
  main()
end
