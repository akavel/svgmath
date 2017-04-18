-- SAX filter for MathML-to-SVG conversion.
local MathNode = require('mathnode').MathNode
local MathConfig = require('mathconfig').MathConfig
local NodeLocator = require('nodelocator').NodeLocator

MathNS = 'http://www.w3.org/1998/Math/MathML'

MathHandler = PYLUA.class(sax.ContentHandler) {
  -- SAX ContentHandler for converting MathML formulae to SVG.
  --     
  --     Instances of this class read MathML through SAX callbacks, and write
  --     SVG to the destination (specified as another SAX ContentHandler).
  --     Uses namespace-aware SAX calls for both input and output.

  __init__ = function(self, saxoutput, config)
    self.config = MathConfig(config)
    self.output = saxoutput
    self.skip = 0
    self.currentNode = nil
    self.locator = nil
  end;

  setDocumentLocator = function(self, locator)
    self.locator = locator
  end;

  startDocument = function(self)
    self.output.startDocument()
  end;

  endDocument = function(self)
    self.output.endDocument()
  end;

  startElementNS = function(self, elementName, qName, attributes)
    if self.skip>0 then
      self.skip = self.skip+1
      return 
    end
    locator = NodeLocator(self.locator)
    namespace, localName = table.unpack(elementName)
    if namespace and namespace~=MathNS then
      if self.config.verbose then
        self.locator:message(PYLUA.mod('Skipped element \'%s\' from an unknown namespace \'%s\'', {localName, namespace}), 'INFO')
      end
      self.skip = 1
      return 
    end
    properties = { }
    for attName, value in pairs(attributes) do
      attNamespace, attLocalName = table.unpack(attName)
      if attNamespace and attNamespace~=MathNS then
        if self.config.verbose then
          locator.message(PYLUA.mod('Ignored attribute \'%s\' from an unknown namespace \'%s\'', {attLocalName, attNamespace}), 'INFO')
        end
        goto continue
      end
      properties[attLocalName] = value
    end
    self.currentNode = MathNode(localName, attributes, locator, self.config, self.currentNode)
  end;

  endElementNS = function(self, elementName, qName)
    if self.skip>0 then
      self.skip = self.skip-1
      if self.skip>0 then
        return 
      end
    end
    namespace, localname = table.unpack(elementName)
    if namespace and namespace~=MathNS then
      error(sax.SAXParseException('SAX parser error: namespace on opening and closing elements don\'t match', nil, self.locator))
    end
    if PYLUA.op_is(self.currentNode, nil) then
      error(sax.SAXParseException('SAX parser error: unmatched closing tag', nil, self.locator))
    end
    self.currentNode.text = string.gsub(self.currentNode.text, '%s+', ' ')
    if not self.currentNode.parent then
      self.currentNode:makeImage(self.output)
    end
    self.currentNode = self.currentNode.parent
  end;

  characters = function(self, content)
    if self.skip>0 then
      return 
    end
    if self.currentNode then
      self.currentNode.text = self.currentNode.text+content
    end
  end;
}

