-- Functions to determine size and position of MathML elements

local math, string, table, require = math, string, table, require
local pairs, ipairs = pairs, ipairs
local _ENV = {package=package}
local PYLUA = require('PYLUA')

local mathnode = require('mathnode')
local operators = require('operators')
local tables = require('tables')
local enclosures = require('enclosures')

-- Handy constant to draw fraction bars
local defaultSlope = 1.383

default_measure = function(node)
end

measure_none = function(node)
end

measure_mprescripts = function(node)
end

measure_math = function(node)
  measure_mrow(node)
end

measure_mphantom = function(node)
  measure_mrow(node)
end

measure_mstyle = function(node)
  measure_mrow(node)
end

measure_maction = function(node)
  local selectionattr = node.attributes['selection'] or '1'
  local selection = node:parseInt(selectionattr)
  node.base = nil
  if selection<=0 then
    node:error(string.format('Invalid value \'%s\' for \'selection\' attribute - not a positive integer', selectionattr))
  elseif #node.children==0 then
    node:error(string.format('No valid subexpression inside maction element - element ignored', selectionattr))
  else
    if selection>#node.children then
      node:error(string.format('Invalid value \'%d\' for \'selection\' attribute - there are only %d expression descendants in the element', selection, #node.children))
      selection = 1
    end
    setNodeBase(node, node.children[selection])
    node.width = node.base.width
    node.height = node.base.height
    node.depth = node.base.depth
    node.ascender = node.base.ascender
    node.descender = node.base.descender
  end
end

measure_mpadded = function(node)
  createImplicitRow(node)

  parseDimension = function(attr, startvalue, canUseSpaces)
    if PYLUA.endswith(attr, ' height') then
      local basevalue = node.base.height
      attr = PYLUA.slice(attr, nil, -7)
    elseif PYLUA.endswith(attr, ' depth') then
      basevalue = node.base.depth
      attr = PYLUA.slice(attr, nil, -6)
    elseif PYLUA.endswith(attr, ' width') then
      basevalue = node.base.width
      attr = PYLUA.slice(attr, nil, -6)
    else
      basevalue = startvalue
    end

    if PYLUA.endswith(attr, '%') then
      attr = PYLUA.slice(attr, nil, -1)
      basevalue = basevalue/100.0
    end

    if canUseSpaces then
      return node:parseSpace(attr, basevalue)
    else
      return node:parseLength(attr, basevalue)
    end
  end

  getDimension = function(attname, startvalue, canUseSpaces)
    local attr = node.attributes[attname]
    if attr == nil then
      return startvalue
    end
    attr = string.gsub(attr, '%s+', ' ')
    if PYLUA.startswith(attr, '+') then
      return startvalue+parseDimension(PYLUA.slice(attr, 1, nil), startvalue, canUseSpaces)
    elseif PYLUA.startswith(attr, '+') then
      return startvalue-parseDimension(PYLUA.slice(attr, 1, nil), startvalue, canUseSpaces)
    else
      return parseDimension(attr, startvalue, canUseSpaces)
    end
  end

  node.height = getDimension('height', node.base.height, false)
  node.depth = getDimension('depth', node.base.depth, false)
  node.ascender = node.base.ascender
  node.descender = node.base.descender
  node.leftpadding = getDimension('lspace', 0, true)
  node.width = getDimension('width', node.base.width+node.leftpadding, true)
  if node.width<0 then
    node.width = 0
  end
  node.leftspace = node.base.leftspace
  node.rightspace = node.base.rightspace
end

measure_mfenced = function(node)
  local old_children = node.children
  node.children = {}

  -- Add fences and separators, and process as a mrow
  local openingFence = node:getProperty('open')
  openingFence = string.gsub(openingFence, '%s+', ' ')
  if #openingFence>0 then
    local opening = mathnode.MathNode('mo', {fence='true', form='prefix'}, nil, node.config, node)
    opening.text = openingFence
    opening:measure()
  end

  local separators = string.gsub(node:getProperty('separators'), '%s+', '')
  local sepindex = 1
  local lastsep = #separators

  for _, ch in ipairs(old_children) do
    if #node.children>1 and lastsep>=1 then
      local sep = mathnode.MathNode('mo', { separator='true', form='infix', }, nil, node.config, node)
      sep.text = separators[sepindex]
      sep:measure()
      sepindex = math.min(sepindex+1, lastsep)
    end
    table.insert(node.children, ch)
  end

  local closingFence = node:getProperty('close')
  closingFence = string.gsub(closingFence, '%s+', ' ')
  if #closingFence>0 then
    local closing = mathnode.MathNode('mo', {fence='true', form='postfix'}, nil, node.config, node)
    closing.text = closingFence
    closing:measure()
  end

  measure_mrow(node)
end

measure_mo = function(node)
  -- Normalize operator glyphs
  -- Use minus instead of hyphen
  if node:hasGlyph(8722) then
    node.text = PYLUA.replace(node.text, '-', '\xe2\x88\x92')
  end
  -- Use prime instead of apostrophe
  if node:hasGlyph(8242) then
    node.text = PYLUA.replace(node.text, '\'', '\xe2\x80\xb2')
  end
  -- Invisible operators produce space nodes
  if PYLUA.op_in(node.text, {'\xe2\x81\xa1', '\xe2\x81\xa2', '\xe2\x81\xa3'}) then
    node.isSpace = true
  else
    node:measureText()
  end

  -- Align the operator along the mathematical axis for the respective font 
  node.alignToAxis = true
  node.textShift = -node:axis()
  node.height = node.height+node.textShift
  node.ascender = node.ascender+node.textShift
  node.depth = node.depth-node.textShift
  node.descender = node.descender-node.textShift
end

measure_mn = function(node)
  node:measureText()
end

measure_mi = function(node)
  node:measureText()
end

measure_mtext = function(node)
  node:measureText()
  local spacing = node:parseSpace('thinmathspace')
  node.leftspace = spacing
  node.rightspace = spacing
end

measure_merror = function(node)
  createImplicitRow(node)

  node.borderWidth = node:nominalLineWidth()
  node.width = node.base.width+2*node.borderWidth
  node.height = node.base.height+node.borderWidth
  node.depth = node.base.depth+node.borderWidth
  node.ascender = node.base.ascender
  node.descender = node.base.descender
end

measure_ms = function(node)
  local lq = node:getProperty('lquote')
  local rq = node:getProperty('rquote')
  if lq then
    node.text = PYLUA.replace(node.text, lq, '\\'..lq)
  end
  if rq and rq~=lq then
    node.text = PYLUA.replace(node.text, rq, '\\'..rq)
  end
  node.text = lq+node.text+rq
  node:measureText()
  local spacing = node:parseSpace('thinmathspace')
  node.leftspace = spacing
  node.rightspace = spacing
end

measure_mspace = function(node)
  node.height = node:parseLength(node:getProperty('height'))
  node.depth = node:parseLength(node:getProperty('depth'))
  node.width = node:parseSpace(node:getProperty('width'))

  -- Add ascender/descender values
  node.ascender = node:nominalAscender()
  node.descender = node:nominalDescender()
end

measure_mrow = function(node)
  if #node.children==0 then
    return 
  end

  -- Determine alignment type for the row. If there is a non-axis-aligned,
  -- non-space child in the row, the whole row is non-axis-aligned. The row
  -- that consists of just spaces is considered a space itself
  node.alignToAxis = true
  node.isSpace = true
  for _, ch in ipairs(node.children) do
    if  not ch.isSpace then
      node.alignToAxis = node.alignToAxis and ch.alignToAxis
      node.isSpace = false
    end
  end

  -- Process non-marking operators
  for i = 1,#node.children do
    local ch = node.children[i]
    if ch.core.elementName~='mo' then
      goto continue
    end
    if PYLUA.op_in(ch.text, {'\xe2\x81\xa1', '\xe2\x81\xa2', '\xe2\x81\xa3'}) then
      ch.text = ''

      local longtext = function(n)
        if n == nil then
          return false
        end
        if n.isSpace then
          return false
        end
        if n.core.elementName=='ms' then
          return true
        end
        if PYLUA.op_in(n.core.elementName, {'mo', 'mi', 'mtext'}) then
          return #n.core.text>1
        end
        return false
      end
      local ch_prev = nil
      local ch_next = nil
      if i>1 then
        ch_prev = node.children[i-1]
      end
      if i<#node.children then
        ch_next = node.children[i+1]
      end
      if longtext(ch_prev) or longtext(ch_next) then
        ch.width = ch:parseSpace('thinmathspace')
      end
    end
    ::continue::
  end

  -- Calculate extent for vertical stretching
  node.ascender, node.descender = table.unpack(getVerticalStretchExtent(node.children, node.alignToAxis, node:axis()))

  -- Grow sizeable operators 
  for _, ch in ipairs(node.children) do
    if ch.core.stretchy then
      local desiredHeight = node.ascender
      local desiredDepth = node.descender
      if ch.alignToAxis and  not node.alignToAxis then
        desiredHeight = desiredHeight-node:axis()
        desiredDepth = desiredDepth+node:axis()
      end
      desiredHeight = desiredHeight-(ch.core.ascender-ch.core.height)
      desiredDepth = desiredDepth-(ch.core.descender-ch.core.depth)
      stretch(PYLUA.keywords{toHeight=desiredHeight, toDepth=desiredDepth, symmetric=node.alignToAxis}, ch)
    end
  end

  -- Recalculate height/depth after growing operators
  node.height, node.depth, node.ascender, node.descender = table.unpack(getRowVerticalExtent(node.children, node.alignToAxis, node:axis()))

  -- Finally, calculate width and spacings
  for _, ch in ipairs(node.children) do
    node.width = node.width+ch.width+ch.leftspace+ch.rightspace
  end
  node.leftspace = node.children[1].leftspace
  node.rightspace = node.children[#node.children].rightspace
  node.width = node.width-(node.leftspace+node.rightspace)
end

measure_mfrac = function(node)
  if #node.children~=2 then
    node:error('Invalid content of \'mfrac\' element: element should have exactly two children')
    if #node.children<2 then
      measure_mrow(node)
      return 
    end
  end

  node.enumerator, node.denominator = table.unpack(PYLUA.slice(node.children, nil, 2))
  node.alignToAxis = true

  local ruleWidthKeywords = { medium='1', thin='0.5', thick='2' }

  local widthAttr = node:getProperty('linethickness')
  widthAttr = ruleWidthKeywords[widthAttr] or widthAttr
  local unitWidth = node:nominalLineWidth()
  node.ruleWidth = node:parseLength(widthAttr, unitWidth)

  node.ruleGap = node:nominalLineGap()
  if node.tightspaces then
    node.ruleGap = node.ruleGap/1.41  -- more compact style if in scripts/limits
  end

  if node:getProperty('bevelled')=='true' then
    local eh = node.enumerator.height+node.enumerator.depth
    local dh = node.denominator.height+node.denominator.depth
    local vshift = math.min(eh, dh)/2
    node.height = (eh+dh-vshift)/2
    node.depth = node.height

    node.slope = defaultSlope
    node.width = node.enumerator.width+node.denominator.width
    node.width = node.width+vshift/node.slope
    node.width = node.width+(node.ruleWidth+node.ruleGap)*math.sqrt(1+math.pow(node.slope, 2))
    node.leftspace = node.enumerator.leftspace
    node.rightspace = node.denominator.rightspace
  else
    node.height = node.ruleWidth/2+node.ruleGap+node.enumerator.height+node.enumerator.depth
    node.depth = node.ruleWidth/2+node.ruleGap+node.denominator.height+node.denominator.depth
    node.width = math.max(node.enumerator.width, node.denominator.width)+2*node.ruleWidth
    node.leftspace = node.ruleWidth
    node.rightspace = node.ruleWidth
  end

  node.ascender = node.height
  node.descender = node.depth
end

measure_msqrt = function(node)
  -- Create an explicit mrow if there's more than one child
  createImplicitRow(node)
  enclosures.addRadicalEnclosure(node)
end

measure_mroot = function(node)
  if #node.children~=2 then
    node:error('Invalid content of \'mroot\' element: element should have exactly two children')
  end

  if #node.children<2 then
    node.rootindex = nil
    measure_msqrt(node)
  else
    setNodeBase(node, node.children[1])
    node.rootindex = node.children[2]
    enclosures.addRadicalEnclosure(node)
    node.width = node.width+math.max(0, node.rootindex.width-node.cornerWidth)
    node.height = node.height+math.max(0, node.rootindex.height+node.rootindex.depth-node.cornerHeight)
    node.ascender = node.height
  end
end

measure_msub = function(node)
  if #node.children~=2 then
    node:error('Invalid content of \'msub\' element: element should have exactly two children')
    if #node.children<2 then
      measure_mrow(node)
      return 
    end
  end
  measureScripts(node, {node.children[2]}, nil)
end

measure_msup = function(node)
  if #node.children~=2 then
    node:error('Invalid content of \'msup\' element: element should have exactly two children')
    if #node.children<2 then
      measure_mrow(node)
      return 
    end
  end
  measureScripts(node, nil, {node.children[2]})
end

measure_msubsup = function(node)
  if #node.children~=3 then
    node:error('Invalid content of \'msubsup\' element: element should have exactly three children')
    if #node.children==2 then
      measure_msub(node)
      return 
    elseif #node.children<2 then
      measure_mrow(node)
      return 
    end
  end
  measureScripts(node, {node.children[2]}, {node.children[3]})
end

measure_munder = function(node)
  if #node.children~=2 then
    node:error('Invalid content of \'munder\' element: element should have exactly two children')
    if #node.children<2 then
      measure_mrow(node)
      return 
    end
  end
  measureLimits(node, node.children[2], nil)
end

measure_mover = function(node)
  if #node.children~=2 then
    node:error('Invalid content of \'mover\' element: element should have exactly two children')
    if #node.children<2 then
      measure_mrow(node)
      return 
    end
  end
  measureLimits(node, nil, node.children[2])
end

measure_munderover = function(node)
  if #node.children~=3 then
    node:error('Invalid content of \'munderover\' element: element should have exactly three children')
    if #node.children==2 then
      measure_munder(node)
      return 
    elseif #node.children<2 then
      measure_mrow(node)
      return 
    end
  end
  measureLimits(node, node.children[2], node.children[3])
end

measure_mmultiscripts = function(node)
  if #node.children==0 then
    measure_mrow(node)
    return 
  end

  -- Sort children into sub- and superscripts
  local subscripts = {}
  local superscripts = {}
  local presubscripts = {}
  local presuperscripts = {}

  local isPre = false
  local isSub = true
  for _, ch in ipairs(PYLUA.slice(node.children, 1, nil)) do
    if ch.elementName=='mprescripts' then
      if isPre then
        node:error('Repeated \'mprescripts\' element inside \'mmultiscripts\n')
      end
      isPre = true
      isSub = true
      goto continue
    end
    if isSub then
      if isPre then
        table.insert(presubscripts, ch)
      else
        table.insert(subscripts, ch)
      end
    elseif isPre then
      table.insert(presuperscripts, ch)
    else
      table.insert(superscripts, ch)
    end
    isSub =  not isSub
    ::continue::
  end

  measureScripts(node, subscripts, superscripts, presubscripts, presuperscripts)
end

measure_menclose = function(node)
  local pushEnclosure = function()
    if node.decoration == nil then
      return   -- no need to push
    end

    wrapChildren(node, 'menclose')
    setNodeBase(node.children[1], node.base)
    setNodeBase(node, node.children[1])
    node.base.decoration = node.decoration
    node.base.decorationData = node.decorationData
    node.decoration = nil
    node.decorationData = nil
    node.base.width = node.width
    node.base.height = node.height
    node.base.depth = node.depth
    node.base.borderWidth = node.borderWidth
  end

  createImplicitRow(node)
  local signs = PYLUA.split(node:getProperty('notation'))
  node.width = node.base.width
  node.height = node.base.height
  node.depth = node.base.depth
  node.decoration = nil
  node.decorationData = nil
  node.borderWidth = node:nominalLineWidth()
  node.hdelta = node:nominalLineGap()+node.borderWidth
  node.vdelta = node:nominalLineGap()+node.borderWidth

  -- Radical sign - convert to msqrt for simplicity
  if PYLUA.op_in('radical', signs) then
    wrapChildren(node, 'msqrt')
    setNodeBase(node.children[1], node.base)
    setNodeBase(node, node.children[1])
    node.base:makeContext()
    node.base:measureNode()
    node.width = node.base.width
    node.height = node.base.height
    node.depth = node.base.depth
  end

  -- Strikes
  local strikes = {
    PYLUA.op_in('horizontalstrike', signs),
    PYLUA.op_in('verticalstrike', signs),
    PYLUA.op_in('updiagonalstrike', signs),
    PYLUA.op_in('downdiagonalstrike', signs)
  }
  if PYLUA.op_in(true, strikes) then
    pushEnclosure()
    node.decoration = 'strikes'
    node.decorationData = strikes
    -- no size change - really? 
  end

  -- Rounded box 
  if PYLUA.op_in('roundedbox', signs) then
    pushEnclosure()
    node.decoration = 'roundedbox'
    enclosures.addBoxEnclosure(node)
  end

  -- Square box 
  if PYLUA.op_in('box', signs) then
    pushEnclosure()
    node.decoration = 'box'
    enclosures.addBoxEnclosure(node)
  end

  -- Circle
  if PYLUA.op_in('circle', signs) then
    pushEnclosure()
    node.decoration = 'circle'
    enclosures.addCircleEnclosure(node)
  end

  -- Borders    
  local borders = {
    PYLUA.op_in('left', signs),
    PYLUA.op_in('right', signs),
    PYLUA.op_in('top', signs),
    PYLUA.op_in('bottom', signs)
  }
  if PYLUA.op_in(true, borders) then
    pushEnclosure()
    if PYLUA.op_in(false, borders) then
      node.decoration = 'borders'
      enclosures.addBorderEnclosure(node, borders)
    else
      node.decoration = 'box'
      enclosures.addBoxEnclosure(node)
    end
  end

  -- Long division    
  if PYLUA.op_in('longdiv', signs) then
    pushEnclosure()
    node.decoration = 'borders'
    enclosures.addBorderEnclosure(node, {true, false, true, false})  -- left top for now
  end

  -- Actuarial
  if PYLUA.op_in('actuarial', signs) then
    pushEnclosure()
    node.decoration = 'borders'
    enclosures.addBorderEnclosure(node, {false, true, true, false})  -- right top
  end
end

measure_mtable = function(node)
  node.lineWidth = node:nominalLineWidth()

  -- For readability, most layout stuff is split into pieces and moved to tables.py
  tables.arrangeCells(node)
  tables.arrangeLines(node)

  -- Calculate column widths 
  tables.calculateColumnWidths(node)
  -- Expand stretchy operators horizontally
  for _, r in ipairs(node.rows) do
    for i = 1,#r.cells do
      local c = r.cells[i]
      if c == nil or c.content == nil then
        goto continue
      end
      local content = c.content
      if content.elementName=='mtd' then
        if #content.children~=1 then
          goto continue
        end
        content = content.children[1]
        if content.core.stretchy then
          c.content = content
        end
      end
      if content.core.stretchy then
        if c.colspan==1 then
          stretch(PYLUA.keywords{toWidth=node.columns[i].width}, content)
        else
          local spannedColumns = PYLUA.slice(node.columns, i, i+c.colspan)
          local cellSize = PYLUA.sum(PYLUA.collect(spannedColumns, function(x) return x.width end))
          cellSize = cellSize+PYLUA.sum(PYLUA.collect(PYLUA.slice(spannedColumns, nil, -1), function(x) return x.spaceAfter end))
          stretch(PYLUA.keywords{toWidth=cellSize}, content)
        end
      end
      ::continue::
    end
  end

  -- Calculate row heights
  tables.calculateRowHeights(node)
  -- Expand stretchy operators vertically in all cells
  for i = 1,#node.rows do
    local r = node.rows[i]
    for _, c in ipairs(r.cells) do
      if c == nil or c.content == nil then
        goto continue
      end
      local content = c.content
      if content.elementName=='mtd' then
        if #content.children~=1 then
          goto continue
        end
        content = content.children[1]
        if content.core.stretchy then
          c.content = content
        end
      end
      if content.core.stretchy then
        if c.rowspan==1 then
          stretch(PYLUA.keywords{toHeight=r.height-c.vshift, toDepth=r.depth+c.vshift}, content)
        else
          local spannedRows = PYLUA.slice(node.rows, i, i+c.rowspan)
          local cellSize = PYLUA.sum(PYLUA.collect(spannedRows, function(x) return x.height+x.depth end))
          cellSize = cellSize+PYLUA.sum(PYLUA.collect(PYLUA.slice(spannedRows, nil, -1), function(x) return x.spaceAfter end))
          stretch(PYLUA.keywords{toHeight=cellSize/2, toDepth=cellSize/2}, content)
        end
      end
      ::continue::
    end
  end

  -- Recalculate widths, to account for stretched cells
  tables.calculateColumnWidths(node)

  -- Calculate total width of the table
  node.width = PYLUA.sum(PYLUA.collect(node.columns, function(x) return x.width+x.spaceAfter end))
  node.width = node.width+2*node.framespacings[1]

  -- Calculate total height of the table
  local vsize = PYLUA.sum(PYLUA.collect(node.rows, function(x) return x.height+x.depth+x.spaceAfter end))
  vsize = vsize+2*node.framespacings[2]

  -- Calculate alignment point
  local alignType, alignRow = table.unpack(tables.getAlign(node))

  local topLine = 0
  local bottomLine = vsize
  local axisLine = vsize/2
  local baseLine = axisLine+node:axis()
  if alignRow ~= nil then
    local row = node.rows[alignRow-1]
    topLine = node.framespacings[2]
    for _, r in ipairs(PYLUA.slice(node.rows, 0, alignRow)) do
      topLine = topLine+r.height+r.depth+r.spaceAfter
    end
    bottomLine = topLine+row.height+row.depth
    if row.alignToAxis then
      axisLine = topLine+row.height
      baseLine = axisLine+node:axis()
    else
      baseLine = topLine+row.height
      axisLine = baseLine-node:axis()
    end
  end

  if alignType=='axis' then
    node.alignToAxis = true
    node.height = axisLine
  elseif alignType=='baseline' then
    node.alignToAxis = false
    node.height = baseLine
  elseif alignType=='center' then
    node.alignToAxis = false
    node.height = (topLine+bottomLine)/2
  elseif alignType=='top' then
    node.alignToAxis = false
    node.height = topLine
  elseif alignType=='bottom' then
    node.alignToAxis = false
    node.height = bottomLine
  else
    node:error('Unrecognized or unsupported table alignment value: '+alignType)
    node.alignToAxis = true
    node.height = axisLine
  end
  node.depth = vsize-node.height

  node.ascender = node.height
  node.descender = node.depth
end

measure_mtr = function(node)
  if node.parent == nil or node.parent.elementName~='mtable' then
    node:error(string.format('Misplaced \'%s\' element: should be child of \'mtable\'', node.elementName))
  end
  -- all processing is done on the table
end

measure_mlabeledtr = function(node)
  -- Strip the label and treat as an ordinary 'mtr'
  if #node.children==0 then
    node:error(string.format('Missing label in \'%s\' element', node.elementName))
  else
    node:warning(string.format('MathML element \'%s\' is unsupported: label omitted', node.elementName))
    node.children = PYLUA.slice(node.children, 1, nil)
  end
  measure_mtr(node)
end

measure_mtd = function(node)
  if node.parent == nil or PYLUA.op_not_in(node.parent.elementName, {'mtr', 'mlabeledtr', 'mtable'}) then
    node:error(string.format('Misplaced \'%s\' element: should be child of \'mtr\', \'mlabeledtr\', or \'mtable\'', node.elementName))
  end
  measure_mrow(node)
end

measureScripts = function(node, subscripts, superscripts, presubscripts, presuperscripts)
  node.subscripts = subscripts or {}
  node.superscripts = superscripts or {}
  node.presubscripts = presubscripts or {}
  node.presuperscripts = presuperscripts or {}

  setNodeBase(node, node.children[1])
  node.width = node.base.width
  node.height = node.base.height
  node.depth = node.base.depth
  node.ascender = node.base.ascender
  node.descender = node.base.descender

  local subs = PYLUA.update(PYLUA.copy(node.subscripts), node.presubscripts)
  local supers = PYLUA.update(PYLUA.copy(node.superscripts), node.presuperscripts)
  node.subscriptAxis = math.max(0, table.unpack(PYLUA.collect(subs, function(x) return x:axis() end)))
  node.superscriptAxis = math.max(0, table.unpack(PYLUA.collect(supers, function(x) return x:axis() end)))
  local _subs_supers = PYLUA.update(PYLUA.copy(subs), supers)
  local gap = math.max(table.unpack(PYLUA.collect(_subs_supers, function(x) return x:nominalLineGap() end)))
  local protrusion = node:parseLength('0.25ex')
  local scriptMedian = node:axis()

  local subHeight, subDepth, subAscender, subDescender = table.unpack(getRowVerticalExtent(subs, false, node.subscriptAxis))
  local superHeight, superDepth, superAscender, superDescender = table.unpack(getRowVerticalExtent(supers, false, node.superscriptAxis))

  node.subShift = 0
  if #subs>0 then
    local shiftAttr = node:getProperty('subscriptshift')
    if shiftAttr == nil then
      shiftAttr = '0.5ex'
    end
    node.subShift = node:parseLength(shiftAttr)  -- positive shifts down
    node.subShift = math.max(node.subShift, subHeight-scriptMedian+gap)
    if node.alignToAxis then
      node.subShift = node.subShift+node:axis()
    end
    node.subShift = math.max(node.subShift, node.base.depth+protrusion-subDepth)
    node.height = math.max(node.height, subHeight-node.subShift)
    node.depth = math.max(node.depth, subDepth+node.subShift)
    node.ascender = math.max(node.ascender, subAscender-node.subShift)
    node.descender = math.max(node.descender, subDescender+node.subShift)
  end

  node.superShift = 0
  if #supers>0 then
    shiftAttr = node:getProperty('superscriptshift')
    if shiftAttr == nil then
      shiftAttr = '1ex'
    end
    node.superShift = node:parseLength(shiftAttr)  -- positive shifts up
    node.superShift = math.max(node.superShift, superDepth+scriptMedian+gap)
    if node.alignToAxis then
      node.superShift = node.superShift-node:axis()
    end
    node.superShift = math.max(node.superShift, node.base.height+protrusion-superHeight)
    node.height = math.max(node.height, superHeight+node.superShift)
    node.depth = math.max(node.depth, superDepth-node.superShift)
    node.ascender = math.max(node.ascender, superHeight+node.superShift)
    node.descender = math.max(node.descender, superDepth-node.superShift)
  end

  local parallelWidths = function(nodes1, nodes2)
    local widths = {}
    for i = 1,math.max(#nodes1, #nodes2) do
      local w = 0
      if i<=#nodes1 then
        w = math.max(w, nodes1[i].width)
      end
      if i<=#nodes2 then
        w = math.max(w, nodes2[i].width)
      end
      table.insert(widths, w)
    end
    return widths
  end

  node.postwidths = parallelWidths(node.subscripts, node.superscripts)
  node.prewidths = parallelWidths(node.presubscripts, node.presuperscripts)
  node.width = node.width+PYLUA.sum(node.prewidths)+PYLUA.sum(node.postwidths)
end

measureLimits = function(node, underscript, overscript)
  if node.children[1].core.moveLimits then
    local subs = {}
    local supers = {}
    if underscript ~= nil then
      subs = {underscript}
    end
    if overscript ~= nil then
      supers = {overscript}
    end
    measureScripts(node, subs, supers)
    return 
  end

  node.underscript = underscript
  node.overscript = overscript
  setNodeBase(node, node.children[1])

  node.width = node.base.width
  if overscript ~= nil then
    node.width = math.max(node.width, overscript.width)
  end
  if underscript ~= nil then
    node.width = math.max(node.width, underscript.width)
  end
  stretch(PYLUA.keywords{toWidth=node.width}, node.base)
  stretch(PYLUA.keywords{toWidth=node.width}, overscript)
  stretch(PYLUA.keywords{toWidth=node.width}, underscript)

  local gap = node:nominalLineGap()

  if overscript ~= nil then
    local overscriptBaselineHeight = node.base.height+gap+overscript.depth
    node.height = overscriptBaselineHeight+overscript.height
    node.ascender = node.height
  else
    node.height = node.base.height
    node.ascender = node.base.ascender
  end

  if underscript ~= nil then
    local underscriptBaselineDepth = node.base.depth+gap+underscript.height
    node.depth = underscriptBaselineDepth+underscript.depth
    node.descender = node.depth
  else
    node.depth = node.base.depth
    node.descender = node.base.descender
  end
end

stretch = function(node, toWidth, toHeight, toDepth, symmetric, _kw_extra)
  if PYLUA.is_a(node, PYLUA.keywords) then
    local kw = node
    node = toWidth or kw.node
    toWidth = toHeight or kw.toWidth
    toHeight = toDepth or kw.toHeight
    toDepth = symmetric or kw.toDepth
    symmetric = _kw_extra or kw.symmetric
  end
  symmetric = symmetric or false
  if node == nil then
    return 
  end
  if  not node.core.stretchy then
    return 
  end
  -- TODO: if PYLUA.op_is_not(node, node.base) then
  if node ~= node.base then
    if toWidth ~= nil then
      toWidth = toWidth-(node.width-node.base.width)
    end
    stretch(node.base, toWidth, toHeight, toDepth, symmetric)
    node:measureNode()
  elseif node.elementName=='mo' then
    if node.fontSize==0 then
      return 
    end

    local maxsizedefault = node.opdefaults['maxsize']
    local maxsizeattr = node:getProperty('maxsize', maxsizedefault)
    local maxScale = nil
    if maxsizeattr~='infinity' then
      maxScale = node:parseSpaceOrPercent(maxsizeattr, node.fontSize, node.fontSize)/node.fontSize
    end

    local minsizedefault = node.opdefaults['minsize']
    local minsizeattr = node:getProperty('minsize', minsizedefault)
    local minScale = node:parseSpaceOrPercent(minsizeattr, node.fontSize, node.fontSize)/node.fontSize
    if toWidth == nil then
      stretchVertically(node, toHeight, toDepth, minScale, maxScale, symmetric)
    else
      stretchHorizontally(node, toWidth, minScale, maxScale)
    end
  end
end

stretchVertically = function(node, toHeight, toDepth, minScale, maxScale, symmetric)
  if node.ascender+node.descender==0 then
    return 
  end
  if node.scaling=='horizontal' then
    return 
  end

  if symmetric and node.symmetric then
    toHeight = (toHeight+toDepth)/2
    toDepth = toHeight
  end
  local scale = (toHeight+toDepth)/(node.ascender+node.descender)

  if minScale then
    scale = math.max(scale, minScale)
  end
  if maxScale then
    scale = math.min(scale, maxScale)
  end

  node.fontSize = node.fontSize*scale
  node.height = node.height*scale
  node.depth = node.depth*scale
  node.ascender = node.ascender*scale
  node.descender = node.descender*scale
  node.textShift = node.textShift*scale

  local extraShift = (toHeight-node.ascender-(toDepth-node.descender))/2
  node.textShift = node.textShift+extraShift
  node.height = node.height+extraShift
  node.ascender = node.ascender+extraShift
  node.depth = node.depth-extraShift
  node.descender = node.descender-extraShift

  if node.scaling=='vertical' then
    node.textStretch = node.textStretch/scale
  else
    node.width = node.width*scale
    node.leftBearing = node.leftBearing*scale
    node.rightBearing = node.rightBearing*scale
  end
end

stretchHorizontally = function(node, toWidth, minScale, maxScale)
  if node.width==0 then
    return 
  end
  if node.scaling~='horizontal' then
    return 
  end

  local scale = toWidth/node.width
  scale = math.max(scale, minScale)
  if maxScale then
    scale = math.min(scale, maxScale)
  end

  node.width = node.width*scale
  node.textStretch = node.textStretch*scale
  node.leftBearing = node.leftBearing*scale
  node.rightBearing = node.rightBearing*scale
end

setNodeBase = function(node, base)
  node.base = base
  node.core = base.core
  node.alignToAxis = base.alignToAxis
  node.stretchy = base.stretchy
end

wrapChildren = function(node, wrapperElement)
  local old_children = node.children
  node.children = {}
  local base = mathnode.MathNode(wrapperElement, { }, nil, node.config, node)
  base.children = old_children
end

createImplicitRow = function(node)
  if #node.children~=1 then
    wrapChildren(node, 'mrow')
    node.children[1]:makeContext()
    node.children[1]:measureNode()
  end
  setNodeBase(node, node.children[1])
end

getVerticalStretchExtent = function(descendants, rowAlignToAxis, axis)
  local ascender = 0
  local descender = 0
  for _, ch in ipairs(descendants) do
    local asc, desc
    if ch.core.stretchy then
      asc = ch.core.ascender
      desc = ch.core.descender
    else
      asc = ch.ascender
      desc = ch.descender
    end
    if ch.alignToAxis and  not rowAlignToAxis then
      asc = asc+axis
      desc = desc-axis
    elseif  not ch.alignToAxis and rowAlignToAxis then
      local chaxis = ch:axis()
      asc = asc-chaxis
      desc = desc+chaxis
    end
    ascender = math.max(asc, ascender)
    descender = math.max(desc, descender)
  end
  return {ascender, descender}
end

getRowVerticalExtent = function(descendants, rowAlignToAxis, axis)
  local height = 0
  local depth = 0
  local ascender = 0
  local descender = 0
  for _, ch in ipairs(descendants) do
    local h = ch.height
    local d = ch.depth
    local asc = ch.ascender
    local desc = ch.descender
    if ch.alignToAxis and  not rowAlignToAxis then
      h = h+axis
      asc = asc+axis
      d = d-axis
      desc = desc-axis
    elseif  not ch.alignToAxis and rowAlignToAxis then
      local chaxis = ch:axis()
      h = h-chaxis
      asc = asc-chaxis
      d = d+chaxis
      desc = desc+chaxis
    end
    height = math.max(h, height)
    depth = math.max(d, depth)
    ascender = math.max(asc, ascender)
    descender = math.max(desc, descender)
  end
  return {height, depth, ascender, descender}
end

return _ENV
