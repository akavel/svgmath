
local math, string, table, arg = math, string, table, arg
local pairs, ipairs, require, tonumber, error = pairs, ipairs, require, tonumber, error
local _ENV = {package=package}
local PYLUA = require('PYLUA')

local os = require('os')

GlyphList = PYLUA.class(dict) {

  __init__ = function(self, f)
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
        goto continue  -- no support for compounds
      end
      local codepoint = tonumber(codelist[1], 16) or error('cannot convert '..codelist[1]..' to codepoint')

      if self[glyph] then
        table.insert(self[glyph], codepoint)
      else
        self[glyph] = {codepoint}
      end
      ::continue::
    end
  end
  ;

  lookup = function(self, glyphname)
    return self[glyphname] or defaultGlyphList[glyphname]
  end
  ;
}

local glyphListName = PYLUA.dirname(arg[0]) .. 'svgmath/fonts/default.glyphs'
defaultGlyphList = GlyphList(PYLUA.open(glyphListName, 'r'))

main = function()
  if #arg>0 then
    local glyphList = parseGlyphList(PYLUA.open(arg[1], 'r'))
  else
    glyphList = defaultGlyphList
  end

  for entry, value in pairs(glyphList) do
    PYLUA.print(entry, ' => ', value, '\n')
  end
end

if arg and arg[1]==... then
  main()
end

return _ENV
