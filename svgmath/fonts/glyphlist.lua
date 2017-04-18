local sys = require('sys')
local os = require('os')

GlyphList = PYLUA.class(dict) {

  __init__ = function(self, f)
    dict.__init__(self)
    while true do
      local line = f.readline()
      if len(line)==0 then
        break
      end
      line = line.strip()
      if len(line)==0 or line.startswith('#') then
        goto continue
      end
      local pair = line.split(';')
      if len(pair)~=2 then
        goto continue
      end
      local glyph = pair[1].strip()
      local codelist = pair[2].split()
      if len(codelist)~=1 then
        goto continue
      end
      local codepoint = int(codelist[1], 16)
      if PYLUA.op_in(glyph, PYLUA.keys(self)) then
        table.insert(self[glyph], codepoint)
      else
        self[glyph] = {codepoint}
      end
    end
  end
  ;

  lookup = function(self, glyphname)
    if PYLUA.op_in(glyphname, PYLUA.keys(self)) then
      return self.get(glyphname)
    else
      return defaultGlyphList.get(glyphname)
    end
  end
  ;
}

local glyphListName = PYLUA.str_maybe(os.path).join(os.path.dirname(__file__), 'default.glyphs')
local defaultGlyphList = GlyphList(open(glyphListName, 'r'))

main = function()
  if len(sys.argv)>1 then
    local glyphList = parseGlyphList(open(sys.argv[2], 'r'))
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
