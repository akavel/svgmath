local PYLUA = require 'PYLUA'
local lxp = require 'lxp'

local sax = {}
sax.handler = {}
sax.xmlreader = {}

sax.handler.ContentHandler = PYLUA.class() {
  __init__ = function(self)
  end,
}

sax.xmlreader.AttributesImpl = PYLUA.class() {
  __init__ = function(self, attrs)
    PYLUA.update(self, attrs)
  end,
}

sax.xmlreader.AttributesNSImpl = PYLUA.class() {
  __init__ = function(self, attrs, qnames)
    PYLUA.update(self, attrs)
  end,
}

sax.SAXException = PYLUA.class() {
  __init__ = function(self, msg)
    self.msg = debug.traceback(msg, 3)
  end,
  __str__ = function(self)
    return self.msg
  end,
  getMessage = function(self)
    return self.msg
  end,
}

sax.SAXParseException = PYLUA.class() {
  __init__ = function(self, msg, _, locator)
    self.msg = debug.traceback(msg, 3)
  end,
  __str__ = function(self)
    return self.msg
  end,
  getMessage = function(self)
    return self.msg
  end,
}

local function split_ns(full_name, default_ns)
  local split_start, _, name = string.find(full_name, ' ?([^%s]+)$')
  if split_start > 1 then
    local ns = string.sub(full_name, 1, split_start-1)
    return ns, name
  else
    return default_ns, name
  end
end

-- Expat to SAX adapter
local function adaptToLxp(saxHandler)
  return {
    CharacterData = function(parser, string)
      if saxHandler.characters then
        saxHandler:characters(string)
      end
    end,
    StartElement = function(parser, elementName, attributes)
      local el_ns, el_name = split_ns(elementName)
      local ns_attrs = {}
      for attr,val in pairs(attributes) do
        -- lxp adds weird integer attributes, so we must keep only strings
        if type(attr)=='string' then
          local a_ns, a_name = split_ns(attr, el_ns)
          ns_attrs[{a_ns, a_name}] = val
        else
          attributes[attr] = nil
        end
      end
      if saxHandler.startElementNS then
        saxHandler:startElementNS({el_ns, el_name}, nil, ns_attrs)
      elseif saxHandler.startElement then
        saxHandler:startElement(el_name, attributes)
      end
    end,
    EndElement = function(parser, elementName)
      local el_ns, el_name = split_ns(elementName)
      if saxHandler.endElementNS then
        saxHandler:endElementNS({el_ns, el_name}, nil)
      elseif saxHandler.endElement then
        saxHandler:endElement(el_name)
      end
    end,
  }
end

function sax.make_parser()
  return {
    setContentHandler = function(self, handler)
      self.handler = adaptToLxp(handler)
    end,
    setFeature = function() end,
    parse = function(self, file)
      local all = file:read '*a'
      if not all then
        error(sax.SAXException("cannot read file contents: "..filename))
      end
      local parser = lxp.new(self.handler, ' ')
      local ok, msg, line, col, pos = parser:parse(all)
      if ok == nil then
        error(sax.SAXException(string.format("%d:%d: %s", line, col, msg)))
      end
    end,
  }
end

return sax
