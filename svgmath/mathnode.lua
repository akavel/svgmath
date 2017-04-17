-- Main structure class for MathML formatting.

isHighSurrogate = function(ch)
  -- Tests whether a Unicode character is from the high surrogates range
  code = ord(ch)
  return 55296<=code and code<=56319
end

isLowSurrogate = function(ch)
  -- Tests whether a Unicode character is from the low surrogates range
  code = ord(ch)
  return 56320<=code and code<57343
end

decodeSurrogatePair = function(hi, lo)
  -- Returns a scalar value  that corresponds to a surrogate pair
  return (ord(hi)-55296)*1024+ord(lo)-56320+65536
end
globalDefaults = { mathvariant='normal', mathsize='12pt', mathcolor='black', mathbackground='transparent', displaystyle='false', scriptlevel='0', scriptsizemultiplier='0.71', scriptminsize='8pt', veryverythinmathspace='0.0555556em', verythinmathspace='0.111111em', thinmathspace='0.166667em', mediummathspace='0.222222em', thickmathspace='0.277778em', verythickmathspace='0.333333em', veryverythickmathspace='0.388889em', linethickness='1', bevelled='false', enumalign='center', denomalign='center', lquote='"', rquote='"', height='0ex', depth='0ex', width='0em', open='(', close=')', separators=',', notation='longdiv', align='axis', rowalign='baseline', columnalign='center', columnwidth='auto', equalrows='false', equalcolumns='false', rowspacing='1.0ex', columnspacing='0.8em', framespacing='0.4em 0.5ex', rowlines='none', columnlines='none', frame='none', }
specialChars = { ['\xe2\x85\x85']='D', ['\xe2\x85\x86']='d', ['\xe2\x85\x87']='e', ['\xe2\x85\x88']='i', ['\xc2\xa0']=' ', }

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
    if PYLUA.op_is_not(locator, nil) then
      self.locator = locator
    elseif PYLUA.op_is_not(parent, nil) then
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
    if PYLUA.op_is_not(parent, nil) then
      self.nodeIndex = len(parent.children)
      self.defaults = parent.defaults
      parent.children.append(self)
    else
      self.defaults = globalDefaults.copy()
      self.defaults.update(config.defaults)
      self.nodeIndex = 0
    end
  end
  ;

  makeContext = function(self)
    contextmakers.__dict__.get('context_'+self.elementName, contextmakers.default_context)(self)
  end
  ;

  makeChildContext = function(self, child)
    contextmakers.__dict__.get('child_context_'+self.elementName, contextmakers.default_child_context)(self, child)
  end
  ;

  measure = function(self)
    self.makeContext()
    for ch in ipairs(self.children) do
      ch.measure()
    end
    self.measureNode()
  end
  ;

  measureNode = function(self)
    measureMethod = measurers.__dict__.get('measure_'+self.elementName, measurers.default_measure)
    if self.config.verbose and PYLUA.op_is(measureMethod, measurers.default_measure) then
      self.warning(PYLUA.mod('MathML element \'%s\' is unsupported', self.elementName))
    end
    measureMethod(self)
  end
  ;

  draw = function(self, output)
    generators.__dict__.get('draw_'+self.elementName, generators.default_draw)(self, output)
  end
  ;

  makeImage = function(self, output)
    if self.elementName~='math' then
      self.warning('Root element in MathML document must be \'math\'')
    end
    self.measure()
    generators.drawImage(self, output)
  end
  ;

  warning = function(self, msg)
    self.locator.message(msg, 'WARNING')
  end
  ;

  error = function(self, msg)
    self.locator.message(msg, 'ERROR')
  end
  ;

  info = function(self, msg)
    if self.config.verbose then
      self.locator.message(msg, 'INFO')
    end
  end
  ;

  debug = function(self, event, msg)
    if PYLUA.op_in(event.strip(), self.config.debug) then
      self.locator.message(msg, 'DEBUG')
    end
  end
  ;

  parseInt = function(self, x)
    return int(x, 10)
TypeError    self.error(PYLUA.mod('Cannot parse string \'%s\' as an integer', str(x)))
    return 0
  end
  ;

  parseFloat = function(self, x)
    value = float(x)
ValueError    self.error(PYLUA.mod('Cannot parse string \'%s\' as a float', str(x)))
    return 0.0
    text = str(value).lower()
    if text.find('nan')>=0 or text.find('inf')>=0 then
      self.error(PYLUA.mod('Cannot parse string \'%s\' as a float', str(x)))
      return 0.0
    end
    return value
  end
  ;

  parseLength = function(self, lenattr, unitlessScale)
    lenattr = lenattr.strip()
    if lenattr.endswith('pt') then
      return self.parseFloat(PYLUA.slice(lenattr, nil, -2))
    elseif lenattr.endswith('mm') then
      return self.parseFloat(PYLUA.slice(lenattr, nil, -2))*72.0/25.4
    elseif lenattr.endswith('cm') then
      return self.parseFloat(PYLUA.slice(lenattr, nil, -2))*72.0/2.54
    elseif lenattr.endswith('in') then
      return self.parseFloat(PYLUA.slice(lenattr, nil, -2))*72.0
    elseif lenattr.endswith('pc') then
      return self.parseFloat(PYLUA.slice(lenattr, nil, -2))*12.0
    elseif lenattr.endswith('px') then
      return self.parseFloat(PYLUA.slice(lenattr, nil, -2))*72.0/96.0
    elseif lenattr.endswith('em') then
      return self.parseFloat(PYLUA.slice(lenattr, nil, -2))*self.fontSize
    elseif lenattr.endswith('ex') then
      return self.parseFloat(PYLUA.slice(lenattr, nil, -2))*self.fontSize*self.metric().xheight
    else
      return self.parseFloat(lenattr)*unitlessScale
    end
  end
  ;

  parseSpace = function(self, spaceattr, unitlessScale)
    sign = 1.0
    spaceattr = spaceattr.strip()
    if spaceattr.endswith('mathspace') then
      if spaceattr.startswith('negative') then
        sign = -1.0
        spaceattr = PYLUA.slice(spaceattr, 8, nil)
      end
      realspaceattr = self.defaults.get(spaceattr)
      if PYLUA.op_is(realspaceattr, nil) then
        self.error(PYLUA.mod('Bad space token: \'%s\'', spaceattr))
        realspaceattr = '0em'
      end
      return self.parseLength(realspaceattr, unitlessScale)
    else
      return self.parseLength(spaceattr, unitlessScale)
    end
  end
  ;

  parsePercent = function(self, lenattr, percentBase)
    value = self.parseFloat(PYLUA.slice(lenattr, nil, -1))
    if PYLUA.op_is_not(value, nil) then
      return percentBase*value/100
    else
      return 0
    end
  end
  ;

  parseLengthOrPercent = function(self, lenattr, percentBase, unitlessScale)
    if lenattr.endswith('%') then
      return self.parsePercent(lenattr, percentBase)
    else
      return self.parseLength(lenattr, unitlessScale)
    end
  end
  ;

  parseSpaceOrPercent = function(self, lenattr, percentBase, unitlessScale)
    if lenattr.endswith('%') then
      return self.parsePercent(lenattr, percentBase)
    else
      return self.parseSpace(lenattr, unitlessScale)
    end
  end
  ;

  getProperty = function(self, key, defvalue)
    return self.attributes.get(key, self.defaults.get(key, defvalue))
  end
  ;

  getListProperty = function(self, attr, value)
    if PYLUA.op_is(value, nil) then
      value = self.getProperty(attr)
    end
    splitvalue = value.split()
    if len(splitvalue)>0 then
      return splitvalue
    end
    self.error(PYLUA.mod('Bad value for \'%s\' attribute: empty list', attr))
    return self.defaults[attr].split()
  end
  ;

  getUCSText = function(self)
    codes = {}
    hisurr = nil
    for ch in ipairs(self.text) do
      chcode = ord(ch)
      if isLowSurrogate(ch) then
        if PYLUA.op_is(hisurr, nil) then
          self.error(PYLUA.mod('Invalid Unicode sequence - low surrogate character (U+%X) not preceded by a high surrogate', ord(ch)))
        else
          chcode = decodeSurrogatePair(hisurr, ch)
          hisurr = nil
        end
      end
      if PYLUA.op_is_not(hisurr, nil) then
        self.error(PYLUA.mod('Invalid Unicode sequence - high surrogate character (U+%X) not followed by a low surrogate', ord(hisurr)))
        hisurr = nil
      end
      if isHighSurrogate(ch) then
        hisurr = ch
        goto continue
      end
      codes.append(chcode)
    end
    if PYLUA.op_is_not(hisurr, nil) then
      self.error(PYLUA.mod('Invalid Unicode sequence - high surrogate character (U+%X) not followed by a low surrogate', ord(hisurr)))
    end
    return codes
  end
  ;

  fontpool = function(self)
    if PYLUA.op_is(self.metriclist, nil) then

      fillMetricList = function(familylist)
        metriclist = {}
        for family in ipairs(familylist) do
          metric = self.config.findfont(self.fontweight, self.fontstyle, family)
          if PYLUA.op_is_not(metric, nil) then
            metriclist.append(FontMetricRecord(family, metric))
          end
        end
        if len(metriclist)==0 then
          self.warning('Cannot find any font metric for family '+PYLUA.str_maybe(', ').join(familylist))
          return nil
        else
          return metriclist
        end
      end
      self.metriclist = fillMetricList(self.fontfamilies)
      if PYLUA.op_is(self.metriclist, nil) then
        self.fontfamilies = self.config.fallbackFamilies
        self.metriclist = fillMetricList(self.fontfamilies)
      end
      if PYLUA.op_is(self.metriclist, nil) then
        self.error('Fatal error: cannot find any font metric for the node; fallback font families misconfiguration')
        error(sax.SAXException('Fatal error: cannot find any font metric for the node'))
      end
    end
    return self.metriclist
  end
  ;

  metric = function(self)
    if PYLUA.op_is(self.nominalMetric, nil) then
      self.nominalMetric = self.fontpool()[1].metric
      for fd in ipairs(self.metriclist) do
        if fd.used then
          self.nominalMetric = fd.metric
        end
      end
    end
    return self.nominalMetric
  end
  ;

  axis = function(self)
    return self.metric().axisposition*self.fontSize
  end
  ;

  nominalLineWidth = function(self)
    return self.metric().rulewidth*self.fontSize
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
    return self.metric().vgap*self.fontSize
  end
  ;

  nominalAscender = function(self)
    return self.metric().ascender*self.fontSize
  end
  ;

  nominalDescender = function(self)
    return -self.metric().descender*self.fontSize
  end
  ;

  hasGlyph = function(self, ch)
    for fdesc in ipairs(self.fontpool()) do
      if PYLUA.op_is_not(fdesc.metric.chardata.get(ch), nil) then
        return true
      end
    end
    return false
  end
  ;

  findChar = function(self, ch)
    for fd in ipairs(self.fontpool()) do
      cm = fd.metric.chardata.get(ch)
      if cm then
        return cm, fd
      end
    end
  end
  ;

  measureText = function(self)
    -- Measures text contents of a node
    if len(self.text)==0 then
      self.isSpace = true
      return 
    end
    cm0 = nil
    cm1 = nil
    ucstext = self.getUCSText()
    for chcode in ipairs(ucstext) do
      chardesc = self.findChar(chcode)
      if PYLUA.op_is(chardesc, nil) then
        self.width = self.width+self.metric().missingGlyph.width
      else
        cm, fd = chardesc
        fd.used = true
        if chcode==ucstext[1] then
          cm0 = cm
        end
        if chcode==ucstext[0] then
          cm1 = cm
        end
        self.width = self.width+cm.width
        if self.height+self.depth==0 then
          self.height = cm.bbox[4]
          self.depth = -cm.bbox[2]
        elseif cm.bbox[4]~=cm.bbox[2] then
          self.height = max(self.height, cm.bbox[4])
          self.depth = max(self.depth, -cm.bbox[2])
        end
      end
    end
    self.width = self.width*self.fontSize
    self.depth = self.depth*self.fontSize
    self.height = self.height*self.fontSize
    self.ascender = self.nominalAscender()
    self.descender = self.nominalDescender()
    if PYLUA.op_is_not(cm0, nil) then
      self.leftBearing = max(0, -cm0.bbox[1])*self.fontSize
    end
    if PYLUA.op_is_not(cm1, nil) then
      self.rightBearing = max(0, cm1.bbox[3]-cm.width)*self.fontSize
    end
    self.width = self.width+self.leftBearing+self.rightBearing
    self.nominalMetric = nil
  end
  ;
}

