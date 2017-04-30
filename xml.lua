local xml = { sax = {} }

-- Expat to SAX adapter
local sax = xml.sax

local function split_ns(full_name, default_ns)
  local split_start, _, name = string.find(full_name, ' ?([^%s+])$')
  if split_start > 1 then
    local ns = string.sub(elementName, 1, split_start-1)
    return ns, name
  else
    return default_ns, name
  end
end

function sax.AdaptToLxp(saxHandler)
  return {
    CharacterData = function(parser, string)
      saxHandler:characters(string)
    end,
    StartElement = function(parser, elementName, attributes)
      local el_ns, el_name = split_ns(elementName)
      local sax_attrs = {}
      for attr,val in pairs(attributes) do
        -- lxp adds weird integer attributes, so we must keep only strings
        if type(attr)=='string' then
          local a_ns, a_name = split_ns(attr, el_ns)
          sax_attrs[{a_ns, a_name}] = val
        end
      end
      saxHandler:startElementNS({el_ns, el_name}, nil, sax_attrs)
    end,
    EndElement = function(parser, elementName)
      saxHandler:endElementNS({split_ns(elementName)}, nil)
    end,
  }
end

return xml

