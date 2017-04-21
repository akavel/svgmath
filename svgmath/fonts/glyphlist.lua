local sys = require('sys')
local os = require('os')

GlyphList = PYLUA.class(dict) {

  __init__ = function(self, f)
    dict:__init__(self)
    while true do
      local line = f:readline()
      if #line==0 then
        break
      end
      line = PYLUA.strip(line)
      if #line==0 or PYLUA.startswith(line, '#') then
        goto continue
      end
      local pair = PYLUA.split(line, ';')
      if #pair~=2 then
        goto continue
      end
      local glyph = PYLUA.strip(pair[1])
      local codelist = PYLUA.split(pair[2])
      if #codelist~=1 then
        goto continue
      end
      local codepoint = int(codelist[1], 16)
      if PYLUA.op_in(glyph, PYLUA.keys(self)) then
        table.insert(self[glyph], codepoint)
      else
        self[glyph] = {codepoint}
      end
      ::continue::
    end
  end
  ;

  lookup = function(self, glyphname)
    if PYLUA.op_in(glyphname, PYLUA.keys(self)) then
      return self[glyphname]
    else
      return defaultGlyphList[glyphname]
    end
  end
  ;
}

local glyphListName = PYLUA.join(os.path, os.path:dirname(__file__), 'default.glyphs')
local defaultGlyphList = GlyphList(PYLUA.open(glyphListName, 'r'))

main = function()
  if #sys.argv>1 then
    local glyphList = parseGlyphList(PYLUA.open(sys.argv[2], 'r'))
  else
    glyphList = defaultGlyphList
  end
  for entry, value in pairs(glyphList) do
    PYLUA.print(entry, ' => ', value, '\n')
  end
end
if __name__=='__main__' then
  main()
end
