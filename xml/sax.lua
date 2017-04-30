local PYLUA = require 'PYLUA'

local sax = { handler = {} }

sax.handler.ContentHandler = PYLUA.class() {
  __init__ = function(self)
  end,
}

return sax
