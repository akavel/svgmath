-- Node locator for MathML parser.

local math, string, table, io = math, string, table, io
local pairs, ipairs, require = pairs, ipairs, require
local _ENV = {package=package}
local PYLUA = require('PYLUA')

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
      io.stderr:write(string.format('[%s] ', label))
    end
    if coordinate then
      io.stderr:write(coordinate..': ')
    end
    if msg then
      io.stderr:write(msg)
    end
    io.stderr:write('\n')
  end
  ;
}

return _ENV
