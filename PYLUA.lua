-- helpers for scripts generated using pylua Python->Lua translator
local PYLUA = {}

function PYLUA.class(_)
  -- TODO: LATER: add support for base classes (inheritance)
  return function(methods)
    return function(...)
      local obj = setmetatable({}, {__index=methods})
      obj:__init__(...)
      return obj
    end
  end
end

function PYLUA.open()
  -- FIXME
end

return PYLUA
