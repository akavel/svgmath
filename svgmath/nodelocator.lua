-- Node locator for MathML parser.

local math, string, table, require = math, string, table, require
local pairs, ipairs = pairs, ipairs
local _ENV = {}
local PYLUA = require('PYLUA')

local sys = require('sys')

NodeLocator = PYLUA.class() {
  -- Node locator for MathML parser.
  --     
  --     Stores data from a SAX locator object; 
  --     provides a method to format error messages from the parser.

  __init__ = function(self, locator)
    if locator then
      self.line = locator:getLineNumber()
      self.column = locator:getColumnNumber()
      self.filename = locator:getSystemId()
    else
      self.line = nil
      self.column = nil
      self.filename = nil
    end
  end
  ;

  message = function(self, msg, label)
    local coordinate = ''
    local separator = ''
    if self.filename ~= nil then
      coordinate = coordinate+string.format('file %s', self.filename)
      separator = ', '
    end
    if self.line ~= nil then
      coordinate = coordinate+separator+string.format('line %d', self.line)
      separator = ', '
    end
    if self.column ~= nil then
      coordinate = coordinate+separator+string.format('column %d', self.column)
    end
    if label then
      sys.stderr:write(string.format('[%s] ', label))
    end
    if coordinate then
      sys.stderr:write(coordinate+': ')
    end
    if msg then
      sys.stderr:write(msg)
    end
    sys.stderr:write('\n')
  end
  ;
}

return _ENV
