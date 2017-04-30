-- helpers for scripts generated using pylua Python->Lua translator
local PYLUA = {}

function PYLUA.class(_)
  -- TODO: LATER: add support for base classes (inheritance)
  return function(methods)
    local meta = {
      __index=methods,
      __tostring=methods.__str__,
    }
    return setmetatable({}, {
      __index=methods,
      __call = function(self, ...)
        local obj = setmetatable({}, meta)
        obj:__init__(...)
        return obj
      end,
    })
  end
end

function PYLUA.dirname(s)
  return (string.gsub(s, '[^\\/]+$', ''))
end

PYLUA.IOError = PYLUA.class() {
  __init__ = function(self, msg)
    self.msg = debug.traceback(msg, 3)
  end,
  __str__ = function(self)
    return self.msg
  end,
}

local wrappedFile = PYLUA.class() {
  __init__ = function(self, f)
    self.f = f
  end,

  readline = function(self)
    return self.f:read '*L' or ''
  end,
}

function PYLUA.open(filename, mode)
  local f, err = io.open(filename, mode)
  if not f then
    error(PYLUA.IOError(err))
  end
  return wrappedFile(f)
end

function PYLUA.strip(s)
  s = string.gsub(s, '%s*$', '')
  s = string.gsub(s, '^%s*', '')
  return s
end

function PYLUA.startswith(s, prefix)
  return #s>=#prefix and string.sub(s,1,#prefix)==prefix
end

function PYLUA.split(s, sep, maxsplit)
  if maxsplit == -1 then
    maxsplit = nil
  elseif maxsplit then
    maxsplit = maxsplit+1
  end
  if not sep then
    -- special case described in Python manual
    local ret, n = {}, 0
    string.gsub(s, '()([^%s]+)', function(i, match)
      n = n+1
      if not maxsplit or n<=maxsplit then
        ret[#ret+1] = match
      elseif n==maxsplit+1 then
        ret[#ret+1] = string.sub(s, i)
      end
    end, maxsplit)
    return ret
  else
    local ret, prev = {}, 1
    while not maxsplit or maxsplit>1 do
      local first, last = string.find(s, sep, prev, true)
      if not first then
        break
      end
      ret[#ret+1] = string.sub(s, prev, first-1)
      prev = last+1
      if maxsplit then
        maxsplit = maxsplit-1
      end
    end
    ret[#ret+1] = string.sub(s, prev)
    return ret
  end
end

function PYLUA.print(...)
  -- TODO: improve this to better match Python behavior
  for _, s in ipairs{...} do
    io.write(' '..tostring(s))
  end
end


return PYLUA
