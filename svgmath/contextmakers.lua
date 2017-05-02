-- Methods to set up the context for a MathML tree node.
-- 
-- The module contains two kinds of methods to set up context:
--    - context creators process the context of the current node;
--    - child context setters alter the context of a child.

local math, string, table, require = math, string, table, require
local pairs, ipairs = pairs, ipairs
local _ENV = {package=package}
local PYLUA = require('PYLUA')

--[[
local sys = require('sys')
--]]
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
    node.parent:makeChildContext(node)
  else
    node.mathsize = node:parseLength(node.defaults['mathsize'])
    node.fontSize = node.mathsize
    node.metriclist = nil
    node.scriptlevel = node:parseInt(node.defaults['scriptlevel'])
    node.tightspaces = false
    node.displaystyle = node.defaults['displaystyle']=='true'
    node.color = node.defaults['mathcolor']
    local defaultVariant = node.config.variants[node.defaults['mathvariant']]
    if defaultVariant == nil then
      error(sax.SAXException('Default mathvariant not defined in configuration file: configuration is unusable'))
    end
    node.fontweight, node.fontstyle, node.fontfamilies = table.unpack(defaultVariant)
  end
  processFontAttributes(node)
  -- Set the rest of properties that need immediate initialization
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
  -- Reset metrics list to None (so far, we used metrics from the parent)
  node.metriclist = nil
  node.nominalMetric = nil
end

context_math = function(node)
  default_context(node)
  -- Display style: set differently on 'math'
  local attr = node.attributes['display']
  if attr ~= nil then
    node.displaystyle = attr=='block'
  else
    attr = node.attributes['mode']
    node.displaystyle = attr=='display'
  end
end

context_mstyle = function(node)
  default_context(node)
  -- Avoid redefinition of mathsize - it is inherited anyway.
  -- This serves to preserve values of 'big', 'small', and 'normal'
  -- throughout the MathML instance.
  if node.attributes and PYLUA.op_in('mathsize', PYLUA.keys(node.attributes)) then
    node.attributes['mathsize'] = nil
  end
  if node.attributes then
    node.defaults = PYLUA.copy(node.defaults)
    PYLUA.update(node.defaults, node.attributes)
  end
end

context_mtable = function(node)
  default_context(node)
  -- Display style: no inheritance, default is 'false' unless redefined in 'mstyle'
  node.displaystyle = node:getProperty('displaystyle')=='true'
end

context_mi = function(node)
  -- If the identifier is a single character, make it italic by default.
  -- (Also includes a single UTF-8 encoded character.)
  -- TODO: Don't forget surrogate pairs here!
  if #node.text==1 or
      string.match(node.text, '^[%z\1-\127\194-\244][\128-\191]*$') then
    PYLUA.setdefault(node.attributes, 'fontstyle', 'italic')
  end
  default_context(node)
end

context_mo = function(node)
  -- Apply special formatting to operators
  local extra_style = node.config.opstyles[node.text]
  if extra_style then
    for prop, value in pairs(extra_style) do
      PYLUA.setdefault(node.attributes, prop, value)
    end
  end

  -- Consult the operator dictionary, and set the appropriate defaults
  local form = 'infix'
  if node.parent and PYLUA.op_in(node.parent.elementName, {
      'mrow', 'mstyle', 'msqrt', 'merror', 'mpadded',
      'mphantom', 'menclose', 'mtd', 'math'}) then

    local isNonSpaceNode = function(x)
      return x.elementName~='mspace'
    end

    local prevSiblings = PYLUA.slice(node.parent.children, nil, node.nodeIndex)
    prevSiblings = PYLUA.filter(isNonSpaceNode, prevSiblings)

    local nextSiblings = PYLUA.slice(node.parent.children, node.nodeIndex+1, nil)
    nextSiblings = PYLUA.filter(isNonSpaceNode, nextSiblings)

    if #prevSiblings==0 and #nextSiblings>0 then
      form = 'prefix'
    end
    if #nextSiblings==0 and #prevSiblings>0 then
      form = 'postfix'
    end
  end

  form = node.attributes['form'] or form

  node.opdefaults = operators.lookup(node.text, form)
  default_context(node)
  local stretchyattr = node:getProperty('stretchy', node.opdefaults['stretchy'])
  node.stretchy = stretchyattr=='true'
  local symmetricattr = node:getProperty('symmetric', node.opdefaults['symmetric'])
  node.symmetric = symmetricattr=='true'
  node.scaling = node.opdefaults['scaling']
  if not node.tightspaces then
    local lspaceattr = node:getProperty('lspace', node.opdefaults['lspace'])
    node.leftspace = node:parseSpace(lspaceattr)
    local rspaceattr = node:getProperty('rspace', node.opdefaults['rspace'])
    node.rightspace = node:parseSpace(rspaceattr)
  end

  if node.displaystyle then
    local value = node.opdefaults['largeop']
    if node:getProperty('largeop', value)=='true' then
      node.fontSize = node.fontSize*1.41
    end
  else
    value = node.opdefaults['movablelimits']
    node.moveLimits = node:getProperty('movablelimits', value)=='true'
  end
end

processFontAttributes = function(node)
  local attr = node.attributes['displaystyle']
  if attr ~= nil then
    node.displaystyle = attr=='true'
  end
  local scriptlevelattr = node.attributes['scriptlevel']
  if scriptlevelattr ~= nil then
    scriptlevelattr = PYLUA.strip(scriptlevelattr)
    if PYLUA.startswith(scriptlevelattr, '+') then
      node.scriptlevel = node.scriptlevel+node:parseInt(PYLUA.slice(scriptlevelattr, 1, nil))
    elseif PYLUA.startswith(scriptlevelattr, '-') then
      node.scriptlevel = node.scriptlevel-node:parseInt(PYLUA.slice(scriptlevelattr, 1, nil))
    else
      node.scriptlevel = node:parseInt(scriptlevelattr)
    end
    node.scriptlevel = math.max(node.scriptlevel, 0)
  end

  node.color = node.attributes['mathcolor'] or node.attributes['color'] or node.color

  -- Calculate font attributes
  local mathvariantattr = node.attributes['mathvariant']
  if mathvariantattr ~= nil then
    local mathvariant = node.config.variants[mathvariantattr]
    if mathvariant == nil then
      node:error('Ignored mathvariant attribute: value \''+tostring(mathvariantattr)+'\' not defined in the font configuration file')
    else
      node.fontweight, node.fontstyle, node.fontfamilies = table.unpack(mathvariant)
    end
  else
    node.fontweight = node.attributes['fontweight'] or node.fontweight
    node.fontstyle = node.attributes['fontstyle'] or node.fontstyle
    local familyattr = node.attributes['fontfamily']
    if familyattr ~= nil then
      node.fontfamilies = PYLUA.collect(PYLUA.split(familyattr, ','), function(x) return string.gsub(x, '%s+', ' ') end)
    end
  end

  -- Calculate font size
  local mathsizeattr = node.attributes['mathsize']
  if mathsizeattr ~= nil then
    if mathsizeattr=='normal' then
      node.mathsize = node:parseLength(node.defaults['mathsize'])
    elseif mathsizeattr=='big' then
      node.mathsize = node:parseLength(node.defaults['mathsize'])*1.41
    elseif mathsizeattr=='small' then
      node.mathsize = node:parseLength(node.defaults['mathsize'])/1.41
    else
      local mathsize = node:parseLengthOrPercent(mathsizeattr, node.mathsize)
      if mathsize>0 then
        node.mathsize = mathsize
      else
        node:error('Value of attribute \'mathsize\' ignored - not a positive length: '..tostring(mathsizeattr))
      end
    end
  end

  node.fontSize = node.mathsize
  if node.scriptlevel>0 then
    local scriptsizemultiplier = node:parseFloat(node.defaults['scriptsizemultiplier'])
    if scriptsizemultiplier<=0 then
      node:error('Bad inherited value of \'scriptsizemultiplier\' attribute: '..tostring(mathsizeattr)..'; using default value')
    end
    scriptsizemultiplier = node:parseFloat(mathnode.globalDefaults['scriptsizemultiplier'])
    node.fontSize = node.fontSize*math.pow(scriptsizemultiplier, node.scriptlevel)
  end
  local fontsizeattr = node.attributes['fontsize']
  if fontsizeattr ~= nil and mathsizeattr == nil then
    local fontSizeOverride = node:parseLengthOrPercent(fontsizeattr, node.fontSize)
    if fontSizeOverride>0 then
      node.mathsize = node.mathsize*fontSizeOverride/node.fontSize
      node.fontSize = fontSizeOverride
    else
      node:error('Value of attribute \'fontsize\' ignored - not a positive length: '..tostring(fontsizeattr))
    end
  end
  local scriptminsize = node:parseLength(node.defaults['scriptminsize'])
  node.fontSize = math.max(node.fontSize, scriptminsize)
  node.originalFontSize = node.fontSize  -- save a copy - font size may change in scaling
end

---------------------------------------------------------------------
---- CHILD CONTEXT SETTERS 

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

child_context_msub = function(node, child) makeScriptContext(child) end 
child_context_msup = function(node, child) makeScriptContext(child) end 
child_context_msubsup = function(node, child) makeScriptContext(child) end 
child_context_mmultiscripts = function(node, child) makeScriptContext(child) end

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

  local accentValue = node:getProperty(accentProperty)
  if accentValue == nil then
    local embellishments = {'msub', 'msup', 'msubsup',
      'munder', 'mover', 'munderover', 'mmultiscripts'}

    local function getAccentValue(ch)
      if ch.elementName=='mo' then
        return ch.opdefaults['accent']
      elseif PYLUA.op_in(ch.elementName, embellishments) and #ch.children>0 then
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

return _ENV
