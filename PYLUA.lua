-- helpers for scripts generated using pylua Python->Lua translator
local PYLUA = {}

function PYLUA.class(parent)
  return function(methods)
    if parent then
      parent = getmetatable(parent)
      setmetatable(methods, {__index=parent.__index})
    end
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

function PYLUA.is_a(typ, class)
  local methods = getmetatable(class).__index
  while type(typ)=='table' do
    local meta = getmetatable(typ)
    if not meta then
      return false
    elseif meta.__index==methods then
      return true
    end
    typ = meta.__index
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
  
  read = function(self, n)
    if n and n>=0 then
      return self.f:read(n) or ''
    else
      return self.f:read('*a') or ''
    end
  end,

  seek = function(self, offset)
    -- TODO: also support 'whence' argument
    local prev, err = self.f:seek('set', offset)
    if not prev then
      error(PYLUA.IOError(err))
    end
  end,

  close = function(self)
    self.f:close()
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
  if not s then error(debug.traceback('nil argument to PYLUA.strip')) end
  s = string.gsub(s, '%s*$', '')
  s = string.gsub(s, '^%s*', '')
  return s
end

function PYLUA.startswith(s, prefix)
  return #s>=#prefix and string.sub(s,1,#prefix)==prefix
end

function PYLUA.endswith(s, suffix)
  return #s>=#suffix and (#suffix==0 or string.sub(s,-#suffix)==suffix)
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

-- below is based on http://stackoverflow.com/a/20778724/98528
local special_chars = '%^$().[]*+-?'
local quote_pattern = '([' .. string.gsub(special_chars, '(.)', '%%%1') .. '])'
function PYLUA.quote(s)
  return string.gsub(s, quote_pattern, '%%%1')
end

function PYLUA.replace(s, from, to, n)
  to = string.gsub(to, '%%', '%%%%')
  return string.gsub(s, PYLUA.quote(from), to, n)
end

function PYLUA.op_in(x, list)
  if type(list)=='table' then
    for _, v in ipairs(list) do
      if x==v then
        return true
      end
    end
    return false
  elseif type(list)=='string' then
    return string.find(list, x, 1, true) ~= nil
  else
    error(debug.traceback('unexpected type in op_in: '..type(list)))
  end
end

function PYLUA.op_not_in(x, list)
  return not PYLUA.op_in(x, list)
end

function PYLUA.collect(tab, filter)
  local out = {}
  for _, v in ipairs(tab) do
    local result = filter(v)
    if result then
      out[#out+1] = result
    end
  end
  return out
end

function PYLUA.filter(func, t)
  local res = {}
  for _, v in ipairs(t) do
    if func(v) then
      res[#res+1] = v
    end
  end
  return res
end

function PYLUA.map(func, t)
  local res = {}
  for _, v in ipairs(t) do
    res[#res+1] = func(v)
  end
  return res
end

function PYLUA.update(target, overwrites)
  for k,v in pairs(overwrites) do
    target[k] = v
  end
  return target
end

function PYLUA.copy(t)
  local copy = {}
  for k,v in pairs(t) do
    copy[k] = v
  end
  return copy
end

function PYLUA.setdefault(target, k, default)
  if not target[k] then
    target[k] = default
  end
  return target[k]
end


function PYLUA.lower(s) return string.lower(s) end

function PYLUA.traceback(msg)
  if type(msg) == 'string' then
    return debug.traceback(msg, 2)
  else
    return msg
  end
end

local function string_iter(s, i)
  if i<#s then
    local c = string.sub(s, i+1, i+1)
    return i+1, c
  end
end

function PYLUA.ipairs(t)
  if type(t)=='string' then
    return string_iter, t, 0
  else
    return ipairs(t)
  end
end

function PYLUA.ipairs_unicode(t)
  if type(t)=='string' then
    local finder = string.gmatch(t, '[%z\1-\127\194-\244][\128-\191]*')
    local iter = function(finder, i)
      local c = finder()
      if c then
        return i+1, c
      end
    end
    return iter, finder, 0
  elseif type(t)=='nil' then
    error(debug.traceback('nil in ipairs_unicode'))
  else
    return ipairs(t)
  end
end

function PYLUA.ord(s)
  if not s then error(debug.traceback('nil s in ord')) end
  -- TODO: handle unicode correctly
  return string.byte(s)
end

local function unichr_6lsb(n)
  -- return 6 least significant bits + marker bit 0x80, and remaining most significant bits
  return 0x80 + n % 0x3f, math.floor(n/0x40)
end

function PYLUA.unichr(n)
  if n<=0x007f then
    return n
  elseif n<=0x07ff then
    local b0, n = unichr_6lsb(n)
    local b1 = 0xc0 + n
    return string.char(b1, b0)
  elseif n<=0xffff then
    local b0, n = unichr_6lsb(n)
    local b1, n = unichr_6lsb(n)
    local b2 = 0xe0 + n
    return string.char(b2, b1, b0)
  else
    error("unichr not yet implemented for n>0xffff: "..tostring(n))
  end
end

PYLUA.keywords = PYLUA.class() {
  __init__ = function(self, kw)
    PYLUA.update(self, kw)
  end,
}

function PYLUA.slice(seq, i, j)
  i = i or 0
  j = j or #seq
  if i < 0 then i = i + #seq end
  if j < 0 then j = j + #seq end
  -- TODO: what if i or j still < 0 after above adjustment?
  i = i + 1
  if j > #seq then j = #seq end
  if type(seq)=='table' then
    local ret = {}
    for n = i,j do
      ret[#ret+1] = seq[n]
    end
    return ret
  elseif type(seq)=='string' then
    return string.sub(seq, i, j)
  else
    error('unsupported type for PYLUA.slice: '..type(seq))
  end
end

function PYLUA.sum(t)
  local res = 0
  for _, v in ipairs(t) do
    res = res + v
  end
  return res
end

function PYLUA.keys(t)
  local res = {}
  for k in pairs(t) do
    res[#res+1] = k
  end
  return res
end

function PYLUA.max(t)
  local max
  for _,v in pairs(t) do
    if not max or v>max then
      max=v
    end
  end
  return max
end

return PYLUA
