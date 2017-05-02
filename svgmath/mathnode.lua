-- Main structure class for MathML formatting.

local math, string, table, require = math, string, table, require
local pairs, ipairs, tonumber, tostring, error = pairs, ipairs, tonumber, tostring, error
local _ENV = {package=package}
local PYLUA = require('PYLUA')

-- avoid circular require with contextmakers, see https://stackoverflow.com/a/13981857/98528
package.loaded[...] = _ENV

local contextmakers = require('contextmakers')
local measurers = require('measurers')
local generators = require('generators')
local sax = require('xml').sax
local NodeLocator = require('nodelocator').NodeLocator

isHighSurrogate = function(ch)
  -- Tests whether a Unicode character is from the high surrogates range
  local code = PYLUA.ord(ch)
  return (0xD800 <= code and code <= 0xDBFF)
end

isLowSurrogate = function(ch)
  -- Tests whether a Unicode character is from the low surrogates range
  local code = PYLUA.ord(ch)
  return (0xDC00 <= code and code < 0xDFFF)
end

decodeSurrogatePair = function(hi, lo)
  -- Returns a scalar value  that corresponds to a surrogate pair
  return ((PYLUA.ord(hi) - 0xD800) * 0x400) + (PYLUA.ord(lo) - 0xDC00) + 0x10000
end

globalDefaults = {
  -- Font and color properties
  mathvariant='normal',
  mathsize='12pt',
  mathcolor='black',
  mathbackground='transparent',
  displaystyle='false',
  scriptlevel='0',
  -- Script size factor and minimum value
  scriptsizemultiplier='0.71',
  scriptminsize='8pt',
  -- Spaces
  veryverythinmathspace='0.0555556em',
  verythinmathspace='0.111111em',
  thinmathspace='0.166667em',
  mediummathspace='0.222222em',
  thickmathspace='0.277778em',
  verythickmathspace='0.333333em',
  veryverythickmathspace='0.388889em',
  -- Line thickness and slope for mfrac    
  linethickness='1',
  bevelled='false',
  enumalign='center',
  denomalign='center',
  -- String quotes for ms
  lquote='"',
  rquote='"',
  -- Properties for mspace
  height='0ex',
  depth='0ex',
  width='0em',
  -- Properties for mfenced
  open='(',
  close=')',
  separators=',',
  -- Property for menclose
  notation='longdiv',
  -- Properties for mtable
  align='axis',
  rowalign='baseline',
  columnalign='center',
  columnwidth='auto',
  equalrows='false',
  equalcolumns='false',
  rowspacing='1.0ex',
  columnspacing='0.8em',
  framespacing='0.4em 0.5ex',
  rowlines='none',
  columnlines='none',
  frame='none',
}

specialChars = {
  ['\xe2\x85\x85']='D',
  ['\xe2\x85\x86']='d',
  ['\xe2\x85\x87']='e',
  ['\xe2\x85\x88']='i',
  ['\xc2\xa0']=' ',
}

FontMetricRecord = PYLUA.class() {
  -- Structure to track usage of a single font family

  __init__ = function(self, family, metric)
    self.family = family
    self.metric = metric
    self.used = false
  end
  ;
}


MathNode = PYLUA.class() {
  -- MathML node descriptor.
  --     
  --     This class defines properties and methods that permit to building blocks
  --     to combine with each other, creating a complex mathematical expression.
  --     It uses dynamic binding to find methods to process specific MathML 
  --     elements: these methods are contained in three other modules - 
  --     contextmakers, measurers, and generators.
  --     

  __init__ = function(self, elementName, attributes, locator, config, parent)
    self.elementName = elementName
    self.config = config

    if locator ~= nil then
      self.locator = locator
    elseif parent ~= nil then
      -- handy when we add nodes in preprocessing
      self.locator = parent.locator
    else
      self.locator = NodeLocator(nil)
    end

    self.text = ''
    self.children = {}
    self.attributes = attributes
    self.parent = parent
    self.metriclist = nil
    self.nominalMetric = nil
    if parent ~= nil then
      self.nodeIndex = #parent.children
      self.defaults = parent.defaults
      table.insert(parent.children, self)
    else
      self.defaults = PYLUA.copy(globalDefaults)
      PYLUA.update(self.defaults, config.defaults)
      self.nodeIndex = 0
    end
  end
  ;

  makeContext = function(self)
    (contextmakers['context_'..self.elementName] or contextmakers.default_context)(self)
  end
  ;

  makeChildContext = function(self, child)
    (contextmakers['child_context_'..self.elementName] or contextmakers.default_child_context)(self, child)
  end
  ;

  measure = function(self)
    self:makeContext()
    for _, ch in ipairs(self.children) do
      ch:measure()
    end
    self:measureNode()
  end
  ;

  measureNode = function(self)
    local measureMethod = (measurers['measure_'..self.elementName] or measurers.default_measure)
    if self.config.verbose and measureMethod == measurers.default_measure then
      self:warning(string.format('MathML element \'%s\' is unsupported', self.elementName))
    end
    measureMethod(self)
  end
  ;

  draw = function(self, output)
    (generators['draw_'..self.elementName] or generators.default_draw)(self, output)
  end
  ;

  makeImage = function(self, output)
    if self.elementName~='math' then
      self:warning('Root element in MathML document must be \'math\'')
    end
    self:measure()
    generators.drawImage(self, output)
  end
  ;

  warning = function(self, msg)
    self.locator:message(msg, 'WARNING')
  end
  ;

  error = function(self, msg)
    self.locator:message(msg, 'ERROR')
  end
  ;

  info = function(self, msg)
    if self.config.verbose then
      self.locator:message(msg, 'INFO')
    end
  end
  ;

  --[[
  debug = function(self, event, msg)
    if PYLUA.op_in(PYLUA.strip(event), self.config.debug) then
      self.locator:message(msg, 'DEBUG')
    end
  end
  ;
  --]]

  parseInt = function(self, x)
    local n = tonumber(x, 10)
    if not n then
      self:error(string.format('Cannot parse string \'%s\' as an integer', x))
      return 0
    end
    return n
  end
  ;

  parseFloat = function(self, x)
    local value = tonumber(x)
    if not value then
      self.error(string.format('Cannot parse string \'%s\' as a float', x))
      return 0.0
    end
    local text = PYLUA.lower(tostring(value))
    if text=='nan' or text=='inf' then -- FIXME(akavel): is this possible in Lua?
      self:error(string.format('Cannot parse string \'%s\' as a float', x))
      return 0.0
    end
    return value
  end
  ;

  parseLength = function(self, lenattr, unitlessScale)
    unitlessScale = unitlessScale or 0.75
    lenattr = PYLUA.strip(lenattr)
    if PYLUA.endswith(lenattr, 'pt') then
      return self:parseFloat(PYLUA.slice(lenattr, nil, -2))
    elseif PYLUA.endswith(lenattr, 'mm') then
      return self:parseFloat(PYLUA.slice(lenattr, nil, -2))*72.0/25.4
    elseif PYLUA.endswith(lenattr, 'cm') then
      return self:parseFloat(PYLUA.slice(lenattr, nil, -2))*72.0/2.54
    elseif PYLUA.endswith(lenattr, 'in') then
      return self:parseFloat(PYLUA.slice(lenattr, nil, -2))*72.0
    elseif PYLUA.endswith(lenattr, 'pc') then
      return self:parseFloat(PYLUA.slice(lenattr, nil, -2))*12.0
    elseif PYLUA.endswith(lenattr, 'px') then
      -- pixels are calculated for 96 dpi
      return self:parseFloat(PYLUA.slice(lenattr, nil, -2))*72.0/96.0
    elseif PYLUA.endswith(lenattr, 'em') then
      return self:parseFloat(PYLUA.slice(lenattr, nil, -2))*self.fontSize
    elseif PYLUA.endswith(lenattr, 'ex') then
      return self:parseFloat(PYLUA.slice(lenattr, nil, -2))*self.fontSize*self:metric().xheight
    else
      -- unitless lengths are treated as if  expressed in pixels
      return self:parseFloat(lenattr)*unitlessScale
    end
  end
  ;

  parseSpace = function(self, spaceattr, unitlessScale)
    unitlessScale = unitlessScale or 0.75
    local sign = 1.0
    spaceattr = PYLUA.strip(spaceattr)
    if PYLUA.endswith(spaceattr, 'mathspace') then
      if PYLUA.startswith(spaceattr, 'negative') then
        sign = -1.0
        spaceattr = PYLUA.slice(spaceattr, 8, nil)
      end
      local realspaceattr = self.defaults[spaceattr]
      if realspaceattr == nil then
        self:error(string.format('Bad space token: \'%s\'', spaceattr))
        realspaceattr = '0em'
      end
      return self:parseLength(realspaceattr, unitlessScale)
    else
      return self:parseLength(spaceattr, unitlessScale)
    end
  end
  ;

  parsePercent = function(self, lenattr, percentBase)
    local value = self:parseFloat(PYLUA.slice(lenattr, nil, -1))
    if value ~= nil then
      return percentBase*value/100
    else
      return 0
    end
  end
  ;

  parseLengthOrPercent = function(self, lenattr, percentBase, unitlessScale)
    unitlessScale = unitlessScale or 0.75
    if PYLUA.endswith(lenattr, '%') then
      return self:parsePercent(lenattr, percentBase)
    else
      return self:parseLength(lenattr, unitlessScale)
    end
  end
  ;

  parseSpaceOrPercent = function(self, lenattr, percentBase, unitlessScale)
    unitlessScale = unitlessScale or 0.75
    if PYLUA.endswith(lenattr, '%') then
      return self:parsePercent(lenattr, percentBase)
    else
      return self:parseSpace(lenattr, unitlessScale)
    end
  end
  ;

  getProperty = function(self, key, defvalue)
    return self.attributes[key] or self.defaults[key] or defvalue
  end
  ;

  getListProperty = function(self, attr, value)
    if value == nil then
      value = self:getProperty(attr)
    end
    local splitvalue = PYLUA.split(value)
    if #splitvalue>0 then
      return splitvalue
    end
    self:error(string.format('Bad value for \'%s\' attribute: empty list', attr))
    return PYLUA.split(self.defaults[attr])
  end
  ;

  getUCSText = function(self)
    local codes = {}
    local hisurr = nil
    for _, ch in PYLUA.ipairs_unicode(self.text) do
      local chcode = PYLUA.ord(ch)

      -- Processing surrogate pairs
      if isLowSurrogate(ch) then
        if hisurr == nil then
          self:error(string.format('Invalid Unicode sequence - low surrogate character (U+%X) not preceded by a high surrogate', PYLUA.ord(ch)))
        else
          chcode = decodeSurrogatePair(hisurr, ch)
          hisurr = nil
        end
      end
      if hisurr ~= nil then
        self:error(string.format('Invalid Unicode sequence - high surrogate character (U+%X) not followed by a low surrogate', PYLUA.ord(hisurr)))
        hisurr = nil
      end
      if isHighSurrogate(ch) then
        hisurr = ch
      else
        table.insert(codes, chcode)
      end
    end
    if hisurr ~= nil then
      self:error(string.format('Invalid Unicode sequence - high surrogate character (U+%X) not followed by a low surrogate', PYLUA.ord(hisurr)))
    end
    return codes
  end
  ;

  fontpool = function(self)
    if self.metriclist == nil then

      local fillMetricList = function(familylist)
        local metriclist = {}
        for _, family in ipairs(familylist) do
          local metric = self.config:findfont(self.fontweight, self.fontstyle, family)
          if metric ~= nil then
            table.insert(metriclist, FontMetricRecord(family, metric))
          end
        end
        if #metriclist==0 then
          self:warning('Cannot find any font metric for family '..table.concat(familylist, ', '))
          return nil
        else
          return metriclist
        end
      end
      self.metriclist = fillMetricList(self.fontfamilies)
      if self.metriclist == nil then
        self.fontfamilies = self.config.fallbackFamilies
        self.metriclist = fillMetricList(self.fontfamilies)
      end
      if self.metriclist == nil then
        self:error('Fatal error: cannot find any font metric for the node; fallback font families misconfiguration')
        error(sax.SAXException('Fatal error: cannot find any font metric for the node'))
      end
    end
    return self.metriclist
  end
  ;

  metric = function(self)
    if self.nominalMetric == nil then
      self.nominalMetric = self:fontpool()[1].metric
      for _, fd in ipairs(self.metriclist) do
        if fd.used then
          self.nominalMetric = fd.metric
          break
        end
      end
    end
    return self.nominalMetric
  end
  ;

  axis = function(self)
    return self:metric().axisposition*self.fontSize
  end
  ;

  nominalLineWidth = function(self)
    return self:metric().rulewidth*self.fontSize
  end
  ;

  nominalThinStrokeWidth = function(self)
    return 0.04*self.originalFontSize
  end
  ;

  nominalMediumStrokeWidth = function(self)
    return 0.06*self.originalFontSize
  end
  ;

  nominalThickStrokeWidth = function(self)
    return 0.08*self.originalFontSize
  end
  ;

  nominalLineGap = function(self)
    return self:metric().vgap*self.fontSize
  end
  ;

  nominalAscender = function(self)
    return self:metric().ascender*self.fontSize
  end
  ;

  nominalDescender = function(self)
    return -self:metric().descender*self.fontSize
  end
  ;

  hasGlyph = function(self, ch)
    for _, fdesc in ipairs(self:fontpool()) do
      if fdesc.metric.chardata[ch] ~= nil then
        return true
      end
    end
    return false
  end
  ;

  findChar = function(self, ch)
    for _, fd in ipairs(self:fontpool()) do
      local cm = fd.metric.chardata[ch]
      if cm then
        return {cm, fd}
      end
    end
    if 0<ch and ch<0xFFFF and specialChars[PYLUA.unichr(ch)] then
      return self:findChar(PYLUA.ord(specialChars[PYLUA.unichr(ch)]))
    end
    self:warning(string.format('Glyph U+%X not found', ch))
    return nil
  end
  ;

  measureText = function(self)
    -- Measures text contents of a node
    if #self.text==0 then
      self.isSpace = true
      return 
    end
    local cm0 = nil
    local cm1 = nil
    local cm, fd
    local ucstext = self:getUCSText()
    for _, chcode in ipairs(ucstext) do
      local chardesc = self:findChar(chcode)
      if chardesc == nil then
        self.width = self.width+self:metric().missingGlyph.width
      else
        cm, fd = table.unpack(chardesc)
        fd.used = true
        if chcode==ucstext[1] then
          cm0 = cm
        end
        if chcode==ucstext[#ucstext] then
          cm1 = cm
        end
        self.width = self.width+cm.width
        if self.height+self.depth==0 then
          self.height = cm.bbox[4]
          self.depth = -cm.bbox[2]
        elseif cm.bbox[4]~=cm.bbox[2] then -- exclude space  
          self.height = math.max(self.height, cm.bbox[4])
          self.depth = math.max(self.depth, -cm.bbox[2])
        end
      end
    end

    -- Normalize to the font size
    self.width = self.width*self.fontSize
    self.depth = self.depth*self.fontSize
    self.height = self.height*self.fontSize

    -- Add ascender/descender values
    self.ascender = self:nominalAscender()
    self.descender = self:nominalDescender()

    -- Shape correction  
    if cm0 ~= nil then
      self.leftBearing = math.max(0, -cm0.bbox[1])*self.fontSize
    end
    if cm1 ~= nil then
      self.rightBearing = math.max(0, cm1.bbox[3]-cm.width)*self.fontSize
    end
    self.width = self.width+self.leftBearing+self.rightBearing

    -- Reset nominal metric
    self.nominalMetric = nil
  end
  ;
}

return _ENV
