local PYLUA = require 'PYLUA'

local sax = { handler = {} }

sax.handler.ContentHandler = PYLUA.class()

return sax
