-- Methods to set up the context for a MathML tree node.
-- 
-- The module contains two kinds of methods to set up context:
--    - context creators process the context of the current node;
--    - child context setters alter the context of a child.
local sys = require('sys')
local mathnode = require('mathnode')
local operators = require('operators')

default_context = function(node)
  -- Default context creator for a MathML tree node.
  if node.parent ~= nil then
    node.mathsize = node.parent.mathsize
    node.fontSize = node.parent.fontSize
    node.metriclist = node.parent.metriclist
    node.scriptlevel = node.parent.scriptlevel
    node.tightspaces = node.parent.tightspaces
    node.displaystyle = node.parent.displaystyle
    node.color = node.parent.color
    node.fontfamilies = node.parent.fontfamilies
    node.fontweight = node.parent.fontweight
    node.fontstyle = node.parent.fontstyle
    node.defaults = node.parent.defaults
    node.parent.makeChildContext(node)
  else
    node.mathsize = node.parseLength(node.defaults['mathsize'])
    node.fontSize = node.mathsize
    node.metriclist = nil
    node.scriptlevel = node.parseInt(node.defaults['scriptlevel'])
    node.tightspaces = false
    node.displaystyle = node.defaults['displaystyle']=='true'
    node.color = node.defaults['mathcolor']
    local defaultVariant = node.config.variants.get(node.defaults['mathvariant'])
    if defaultVariant == nil then
      error(sax.SAXException('Default mathvariant not defined in configuration file: configuration is unusable'))
    end
    node.fontweight, node.fontstyle, node.fontfamilies = table.unpack(defaultVariant)
  end
  processFontAttributes(node)
  node.width = 0
  node.height = 0
  node.depth = 0
  node.ascender = 0
  node.descender = 0
  node.leftspace = 0
  node.rightspace = 0
  node.alignToAxis = false
  node.base = node
  node.core = node
  node.stretchy = false
  node.accent = false
  node.moveLimits = false
  node.textShift = 0
  node.textStretch = 1
  node.leftBearing = 0
  node.rightBearing = 0
  node.isSpace = false
  node.metriclist = nil
  node.nominalMetric = nil
end

context_math = function(node)
  default_context(node)
  local attr = node.attributes.get('display')
  if attr ~= nil then
    node.displaystyle = attr=='block'
  else
    attr = node.attributes.get('mode')
    node.displaystyle = attr=='display'
  end
end

context_mstyle = function(node)
  default_context(node)
  if node.attributes and PYLUA.op_in('mathsize', PYLUA.keys(node.attributes)) then
node.attributes['mathsize']  end
  if node.attributes then
    node.defaults = node.defaults.copy()
    node.defaults.update(node.attributes)
  end
end

context_mtable = function(node)
  default_context(node)
  node.displaystyle = node.getProperty('displaystyle')=='true'
end

context_mi = function(node)
  if len(node.text)==1 or len(node.text)==2 and mathnode.isHighSurrogate(node.text[1]) and mathnode.isLowSurrogate(node.text[2]) then
    node.attributes.setdefault('fontstyle', 'italic')
  end
  default_context(node)
end

context_mo = function(node)
  local extra_style = node.config.opstyles.get(node.text)
  if extra_style then
    for prop, value in pairs(extra_style) do
      node.attributes.setdefault(prop, value)
    end
  end
  local form = 'infix'
  if node.parent == nil then
  elseif PYLUA.op_in(node.parent.elementName, {'mrow', 'mstyle', 'msqrt', 'merror', 'mpadded', 'mphantom', 'menclose', 'mtd', 'math'}) then

    isNonSpaceNode = function(x)
      return x.elementName~='mspace'
    end
    local prevSiblings = PYLUA.slice(node.parent.children, nil, node.nodeIndex)
    prevSiblings = filter(isNonSpaceNode, prevSiblings)
    local nextSiblings = PYLUA.slice(node.parent.children, node.nodeIndex+1, nil)
    nextSiblings = filter(isNonSpaceNode, nextSiblings)
    if len(prevSiblings)==0 and len(nextSiblings)>0 then
      form = 'prefix'
    end
    if len(nextSiblings)==0 and len(prevSiblings)>0 then
      form = 'postfix'
    end
  end
  form = node.attributes.get('form', form)
  node.opdefaults = operators.lookup(node.text, form)
  default_context(node)
  local stretchyattr = node.getProperty('stretchy', node.opdefaults.get('stretchy'))
  node.stretchy = stretchyattr=='true'
  local symmetricattr = node.getProperty('symmetric', node.opdefaults.get('symmetric'))
  node.symmetric = symmetricattr=='true'
  node.scaling = node.opdefaults.get('scaling')
  if  not node.tightspaces then
    local lspaceattr = node.getProperty('lspace', node.opdefaults.get('lspace'))
    node.leftspace = node.parseSpace(lspaceattr)
    local rspaceattr = node.getProperty('rspace', node.opdefaults.get('rspace'))
    node.rightspace = node.parseSpace(rspaceattr)
  end
  if node.displaystyle then
    local value = node.opdefaults.get('largeop')
    if node.getProperty('largeop', value)=='true' then
      node.fontSize = node.fontSize*1.41
    end
  else
    value = node.opdefaults.get('movablelimits')
    node.moveLimits = node.getProperty('movablelimits', value)=='true'
  end
end

processFontAttributes = function(node)
  local attr = node.attributes.get('displaystyle')
  if attr ~= nil then
    node.displaystyle = attr=='true'
  end
  local scriptlevelattr = node.attributes.get('scriptlevel')
  if scriptlevelattr ~= nil then
    scriptlevelattr = scriptlevelattr.strip()
    if scriptlevelattr.startswith('+') then
      node.scriptlevel = node.scriptlevel+node.parseInt(PYLUA.slice(scriptlevelattr, 1, nil))
    elseif scriptlevelattr.startswith('-') then
      node.scriptlevel = node.scriptlevel-node.parseInt(PYLUA.slice(scriptlevelattr, 1, nil))
    else
      node.scriptlevel = node.parseInt(scriptlevelattr)
    end
    node.scriptlevel = max(node.scriptlevel, 0)
  end
  node.color = node.attributes.get('mathcolor', node.attributes.get('color', node.color))
  local mathvariantattr = node.attributes.get('mathvariant')
  if mathvariantattr ~= nil then
    local mathvariant = node.config.variants.get(mathvariantattr)
    if mathvariant == nil then
      node.error('Ignored mathvariant attribute: value \''+str(mathvariantattr)+'\' not defined in the font configuration file')
    else
      node.fontweight, node.fontstyle, node.fontfamilies = table.unpack(mathvariant)
    end
  else
    node.fontweight = node.attributes.get('fontweight', node.fontweight)
    node.fontstyle = node.attributes.get('fontstyle', node.fontstyle)
    local familyattr = node.attributes.get('fontfamily')
    if familyattr ~= nil then
      node.fontfamilies = PYLUA.COMPREHENSION()
    end
  end
  local mathsizeattr = node.attributes.get('mathsize')
  if mathsizeattr ~= nil then
    if mathsizeattr=='normal' then
      node.mathsize = node.parseLength(node.defaults['mathsize'])
    elseif mathsizeattr=='big' then
      node.mathsize = node.parseLength(node.defaults['mathsize'])*1.41
    elseif mathsizeattr=='small' then
      node.mathsize = node.parseLength(node.defaults['mathsize'])/1.41
    else
      local mathsize = node.parseLengthOrPercent(mathsizeattr, node.mathsize)
      if mathsize>0 then
        node.mathsize = mathsize
      else
        node.error('Value of attribute \'mathsize\' ignored - not a positive length: '+str(mathsizeattr))
      end
    end
  end
  node.fontSize = node.mathsize
  if node.scriptlevel>0 then
    local scriptsizemultiplier = node.parseFloat(node.defaults.get('scriptsizemultiplier'))
    if scriptsizemultiplier<=0 then
      node.error('Bad inherited value of \'scriptsizemultiplier\' attribute: '+str(mathsizeattr)+'; using default value')
    end
    scriptsizemultiplier = node.parseFloat(mathnode.globalDefaults.get('scriptsizemultiplier'))
    node.fontSize = node.fontSize*math.pow(scriptsizemultiplier, node.scriptlevel)
  end
  local fontsizeattr = node.attributes.get('fontsize')
  if fontsizeattr ~= nil and mathsizeattr == nil then
    local fontSizeOverride = node.parseLengthOrPercent(fontsizeattr, node.fontSize)
    if fontSizeOverride>0 then
      node.mathsize = node.mathsize*fontSizeOverride/node.fontSize
      node.fontSize = fontSizeOverride
    else
      node.error('Value of attribute \'fontsize\' ignored - not a positive length: '+str(fontsizeattr))
    end
  end
  local scriptminsize = node.parseLength(node.defaults.get('scriptminsize'))
  node.fontSize = max(node.fontSize, scriptminsize)
  node.originalFontSize = node.fontSize
end

default_child_context = function(node, child)
  -- Default child context processing for a MathML tree node.
end

child_context_mfrac = function(node, child)
  if node.displaystyle then
    child.displaystyle = false
  else
    child.scriptlevel = child.scriptlevel+1
  end
end

child_context_mroot = function(node, child)
  if child.nodeIndex==1 then
    child.displaystyle = false
    child.scriptlevel = child.scriptlevel+2
    child.tightspaces = true
  end
end

child_context_msub = function(node, child)
  makeScriptContext(child)
end

child_context_msup = function(node, child)
  makeScriptContext(child)
end

child_context_msubsup = function(node, child)
  makeScriptContext(child)
end

child_context_mmultiscripts = function(node, child)
  makeScriptContext(child)
end

child_context_munder = function(node, child)
  if child.nodeIndex==1 then
    makeLimitContext(node, child, 'accentunder')
  end
end

child_context_mover = function(node, child)
  if child.nodeIndex==1 then
    makeLimitContext(node, child, 'accent')
  end
end

child_context_munderover = function(node, child)
  if child.nodeIndex==1 then
    makeLimitContext(node, child, 'accentunder')
  end
  if child.nodeIndex==2 then
    makeLimitContext(node, child, 'accent')
  end
end

makeScriptContext = function(child)
  if child.nodeIndex>0 then
    child.displaystyle = false
    child.tightspaces = true
    child.scriptlevel = child.scriptlevel+1
  end
end

makeLimitContext = function(node, child, accentProperty)
  child.displaystyle = false
  child.tightspaces = true
  local accentValue = node.getProperty(accentProperty)
  if accentValue == nil then
    local embellishments = {'msub', 'msup', 'msubsup', 'munder', 'mover', 'munderover', 'mmultiscripts'}

    getAccentValue = function(ch)
      if ch.elementName=='mo' then
        return ch.opdefaults.get('accent')
      elseif PYLUA.op_in(ch.elementName, embellishments) and len(ch.children)>0 then
        return getAccentValue(ch.children[1])
      else
        return 'false'
      end
    end
    accentValue = getAccentValue(child)
  end
  child.accent = accentValue=='true'
  if  not child.accent then
    child.scriptlevel = child.scriptlevel+1
  end
end
