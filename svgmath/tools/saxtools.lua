-- Miscellaneous SAX-related utilities used in SVGMath
local handler = require('xml.sax').handler
local getwriter = require('codecs').getwriter

escape = function(data)
  -- Escape &, <, and > in a string of data.
  --     
  --     Unicode version of the same-named function in xml.sax.saxutils,
  --     with entity replacement stripped off (not needed for generation).
  data = unicode(data)
  data = PYLUA.replace(data, '&', '&amp;')
  data = PYLUA.replace(data, '>', '&gt;')
  data = PYLUA.replace(data, '<', '&lt;')
  return data
end

quoteattr = function(data)
  -- Escape and quote an attribute value.
  -- 
  --     Unicode version of the same-named function in xml.sax.saxutils,
  --     with entity replacement stripped off (not needed for generation).
  --     Escape &, <, and > in a string of data, then quote it for use as
  --     an attribute value.  The '"' character will be escaped as well, if
  --     necessary.
  --     
  data = escape(data)
  if PYLUA.op_in('"', data) then
    if PYLUA.op_in('\'', data) then
      data = string.format('"%s"', PYLUA.replace(data, '"', '&quot;'))
    else
      data = string.format('\'%s\'', data)
    end
  else
    data = string.format('"%s"', data)
  end
  return data
end

XMLGenerator = PYLUA.class(handler.ContentHandler) {
  -- Clone of xml.sax.saxutils.XMLGenerator, with bugs fixed.
  --        
  --     This is an exact copy of the XMLGenerator class. Unfortunately,
  --     the original class has critical bugs in namespace processing
  --     and output encoding support (as of 2.4.3). This serializer fixes 
  --     them, and additionally provides contraction of empty elements 
  --     (<a/> instead of <a></a>)
  --     

  __init__ = function(self, out, encoding)
    encoding = encoding or 'iso-8859-1'
    handler.ContentHandler.__init__(self)
    self._encoding = encoding
    self._out = getwriter(encoding)(out, 'xmlcharrefreplace')
    self._ns_contexts = {{ }}
    self._current_context = self._ns_contexts[0]
    self._undeclared_ns_maps = {}
    self._starttag_pending = false
  end
  ;

  _write = function(self, text)
    self._out.write(unicode(text))
  end
  ;

  _qname = function(self, name)
    if name[1] then
      local prefix = self._current_context[name[1]]
      if prefix then
        return unicode(prefix)+':'+unicode(name[2])
      end
    end
    return unicode(name[2])
  end
  ;

  _flush_starttag = function(self)
    if self._starttag_pending then
      self._write('>')
      self._starttag_pending = false
    end
  end
  ;

  startDocument = function(self)
    self._out.reset()
    self._write(string.format('<?xml version="1.0" encoding="%s"?>\n', unicode(self._encoding)))
  end
  ;

  endDocument = function(self)
    self._out.reset()
  end
  ;

  startPrefixMapping = function(self, prefix, uri)
    table.insert(self._ns_contexts, PYLUA.copy(self._current_context))
    self._current_context[uri] = prefix
    table.insert(self._undeclared_ns_maps, {prefix, uri})
  end
  ;

  endPrefixMapping = function(self, prefix)
    self._current_context = self._ns_contexts[0]
self._ns_contexts[0]  end
  ;

  startElement = function(self, name, attrs)
    self._flush_starttag()
    self._write(string.format('<%s', unicode(name)))
    for name, value in pairs(attrs) do
      self._write(string.format(' %s=%s', unicode(name), quoteattr(value)))
    end
    self._starttag_pending = true
  end
  ;

  endElement = function(self, name)
    if self._starttag_pending then
      self._write('/>')
      self._starttag_pending = false
    else
      self._write(string.format('</%s>', unicode(name)))
    end
  end
  ;

  startElementNS = function(self, name, qname, attrs)
    local qattrs = { }
    for attname, attvalue in pairs(attrs) do
      qattrs[self._qname(attname)] = attvalue
    end
    for _, {prefix, uri} in ipairs(self._undeclared_ns_maps) do
      if prefix then
        qattrs[string.format('xmlns:%s', unicode(prefix))] = uri
      else
        qattrs['xmlns'] = uri
      end
    end
    self._undeclared_ns_maps = {}
    self.startElement(self._qname(name), qattrs)
  end
  ;

  endElementNS = function(self, name, qname)
    self.endElement(self._qname(name))
  end
  ;

  characters = function(self, content)
    self._flush_starttag()
    self._write(escape(content))
  end
  ;

  ignorableWhitespace = function(self, content)
    self.characters(content)
  end
  ;

  processingInstruction = function(self, target, data)
    self._flush_starttag()
    self._write(string.format('<?%s %s?>', unicode(target), unicode(data)))
  end
  ;
}


ContentFilter = PYLUA.class(handler.ContentHandler) {
  -- Implementation of ContentHandler that passes callbacks to another ContentHandler.
  --     
  --     Used to implement filtering functionality on the ContentHandler side.

  __init__ = function(self, out)
    handler.ContentHandler.__init__(self)
    self.output = out
  end
  ;

  startDocument = function(self)
    self.output.startDocument()
  end
  ;

  endDocument = function(self)
    self.output.endDocument()
  end
  ;

  startPrefixMapping = function(self, prefix, uri)
    self.output.startPrefixMapping(prefix, uri)
  end
  ;

  endPrefixMapping = function(self, prefix)
    self.output.endPrefixMapping(prefix)
  end
  ;

  startElement = function(self, elementName, attrs)
    self.output.startElement(elementName, attrs)
  end
  ;

  endElement = function(self, elementName)
    self.output.endElement(elementName)
  end
  ;

  startElementNS = function(self, elementName, qName, attrs)
    self.output.startElementNS(elementName, qName, attrs)
  end
  ;

  endElementNS = function(self, elementName, qName)
    self.output.endElementNS(elementName, qName)
  end
  ;

  characters = function(self, content)
    self.output.characters(content)
  end
  ;

  ignorableWhitespace = function(self, content)
    self.output.ignorableWhitespace(content)
  end
  ;

  processingInstruction = function(self, target, data)
    self.output.processingInstruction(target, data)
  end
  ;
}

