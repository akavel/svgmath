-- Functions to determine size and position of MathML elements
defaultSlope = 1.383

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
  selectionattr = node.attributes.get('selection', '1')
  selection = node.parseInt(selectionattr)
  node.base = nil
  if selection<=0 then
    node.error(PYLUA.mod('Invalid value \'%s\' for \'selection\' attribute - not a positive integer', selectionattr))
  elseif len(node.children)==0 then
    node.error(PYLUA.mod('No valid subexpression inside maction element - element ignored', selectionattr))
  else
    if selection>len(node.children) then
      node.error(PYLUA.mod('Invalid value \'%d\' for \'selection\' attribute - there are only %d expression descendants in the element', selection, len(node.children)))
      selection = 1
    end
    setNodeBase(node, node.children[selection-1])
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
    if attr.endswith(' height') then
      basevalue = node.base.height
      attr = PYLUA.slice(attr, nil, -7)
    elseif attr.endswith(' depth') then
      basevalue = node.base.depth
      attr = PYLUA.slice(attr, nil, -6)
    elseif attr.endswith(' width') then
      basevalue = node.base.width
      attr = PYLUA.slice(attr, nil, -6)
    else
      basevalue = startvalue
    end
    if attr.endswith('%') then
      attr = PYLUA.slice(attr, nil, -1)
      basevalue = basevalue/100.0
    end
    if canUseSpaces then
      return node.parseSpace(attr, basevalue)
    else
      return node.parseLength(attr, basevalue)
    end
  end

  getDimension = function(attname, startvalue, canUseSpaces)
    attr = node.attributes.get(attname)
    if PYLUA.op_is(attr, nil) then
      return startvalue
    end
    attr = PYLUA.str_maybe(' ').join(attr.split())
    if attr.startswith('+') then
      return startvalue+parseDimension(PYLUA.slice(attr, 1, nil), startvalue, canUseSpaces)
    elseif attr.startswith('+') then
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
  old_children = node.children
  node.children = {}
  openingFence = node.getProperty('open')
  openingFence = PYLUA.str_maybe(' ').join(openingFence.split())
  if len(openingFence)>0 then
    opening = mathnode.MathNode('mo', { fence='true', form='prefix', }, nil, node.config, node)
    opening.text = openingFence
    opening.measure()
  end
  separators = PYLUA.str_maybe('').join(node.getProperty('separators').split())
  sepindex = 0
  lastsep = len(separators)-1
  for ch in ipairs(old_children) do
    if len(node.children)>1 and lastsep>=0 then
      sep = mathnode.MathNode('mo', { separator='true', form='infix', }, nil, node.config, node)
      sep.text = separators[sepindex]
      sep.measure()
      sepindex = min(sepindex+1, lastsep)
    end
    node.children.append(ch)
  end
  closingFence = node.getProperty('close')
  closingFence = PYLUA.str_maybe(' ').join(closingFence.split())
  if len(closingFence)>0 then
    closing = mathnode.MathNode('mo', { fence='true', form='postfix', }, nil, node.config, node)
    closing.text = closingFence
    closing.measure()
  end
  measure_mrow(node)
end

measure_mo = function(node)
  if node.hasGlyph(8722) then
    node.text = node.text.replace('-', '\xe2\x88\x92')
  end
  if node.hasGlyph(8242) then
    node.text = node.text.replace('\'', '\xe2\x80\xb2')
  end
  if PYLUA.op_in(node.text, {'\xe2\x81\xa1', '\xe2\x81\xa2', '\xe2\x81\xa3'}) then
    node.isSpace = true
  else
    node.measureText()
  end
  node.alignToAxis = true
  node.textShift = -node.axis()
  node.height = node.height+node.textShift
  node.ascender = node.ascender+node.textShift
  node.depth = node.depth-node.textShift
  node.descender = node.descender-node.textShift
end

measure_mn = function(node)
  node.measureText()
end

measure_mi = function(node)
  node.measureText()
end

measure_mtext = function(node)
  node.measureText()
  spacing = node.parseSpace('thinmathspace')
  node.leftspace = spacing
  node.rightspace = spacing
end

measure_merror = function(node)
  createImplicitRow(node)
  node.borderWidth = node.nominalLineWidth()
  node.width = node.base.width+2*node.borderWidth
  node.height = node.base.height+node.borderWidth
  node.depth = node.base.depth+node.borderWidth
  node.ascender = node.base.ascender
  node.descender = node.base.descender
end

measure_ms = function(node)
  lq = node.getProperty('lquote')
  rq = node.getProperty('rquote')
  if lq then
    node.text = node.text.replace(lq, '\\'+lq)
  end
  if rq and rq~=lq then
    node.text = node.text.replace(rq, '\\'+rq)
  end
  node.text = lq+node.text+rq
  node.measureText()
  spacing = node.parseSpace('thinmathspace')
  node.leftspace = spacing
  node.rightspace = spacing
end

measure_mspace = function(node)
  node.height = node.parseLength(node.getProperty('height'))
  node.depth = node.parseLength(node.getProperty('depth'))
  node.width = node.parseSpace(node.getProperty('width'))
  node.ascender = node.nominalAscender()
  node.descender = node.nominalDescender()
end

measure_mrow = function(node)
  if len(node.children)==0 then
    return 
  end
  node.alignToAxis = true
  node.isSpace = true
  for ch in ipairs(node.children) do
    if  not ch.isSpace then
      node.alignToAxis = node.alignToAxis and ch.alignToAxis
      node.isSpace = false
    end
  end
  for i in ipairs(range(len(node.children))) do
    ch = node.children[i]
    if ch.core.elementName~='mo' then
      goto continue
    end
    if PYLUA.op_in(ch.text, {'\xe2\x81\xa1', '\xe2\x81\xa2', '\xe2\x81\xa3'}) then
      ch.text = ''

      longtext = function(n)
        if PYLUA.op_is(n, nil) then
          return false
        end
        if n.isSpace then
          return false
        end
        if n.core.elementName=='ms' then
          return true
        end
        if PYLUA.op_in(n.core.elementName, {'mo', 'mi', 'mtext'}) then
          return len(n.core.text)>1
        end
        return false
      end
      ch_prev = nil
      ch_next = nil
      if i>0 then
        ch_prev = node.children[i-1]
      end
      if i+1<len(node.children) then
        ch_next = node.children[i+1]
      end
      if longtext(ch_prev) or longtext(ch_next) then
        ch.width = ch.parseSpace('thinmathspace')
      end
    end
  end
  node.ascender, node.descender = getVerticalStretchExtent(node.children, node.alignToAxis, node.axis())
  for ch in ipairs(node.children) do
    if ch.core.stretchy then
      desiredHeight = node.ascender
      desiredDepth = node.descender
      if ch.alignToAxis and  not node.alignToAxis then
        desiredHeight = desiredHeight-node.axis()
        desiredDepth = desiredDepth+node.axis()
      end
      desiredHeight = desiredHeight-ch.core.ascender-ch.core.height
      desiredDepth = desiredDepth-ch.core.descender-ch.core.depth
      stretch(PYLUA.keywords{toHeight=desiredHeight, toDepth=desiredDepth, symmetric=node.alignToAxis}, ch)
    end
  end
  node.height, node.depth, node.ascender, node.descender = getRowVerticalExtent(node.children, node.alignToAxis, node.axis())
  for ch in ipairs(node.children) do
    node.width = node.width+ch.width+ch.leftspace+ch.rightspace
  end
  node.leftspace = node.children[1].leftspace
  node.rightspace = node.children[0].rightspace
  node.width = node.width-node.leftspace+node.rightspace
end

measure_mfrac = function(node)
  if len(node.children)~=2 then
    node.error('Invalid content of \'mfrac\' element: element should have exactly two children')
    if len(node.children)<2 then
      measure_mrow(node)
      return 
    end
  end
  node.enumerator, node.denominator = PYLUA.slice(node.children, nil, 2)
  node.alignToAxis = true
  ruleWidthKeywords = { medium='1', thin='0.5', thick='2', }
  widthAttr = node.getProperty('linethickness')
  widthAttr = ruleWidthKeywords.get(widthAttr, widthAttr)
  unitWidth = node.nominalLineWidth()
  node.ruleWidth = node.parseLength(widthAttr, unitWidth)
  node.ruleGap = node.nominalLineGap()
  if node.tightspaces then
    node.ruleGap = node.ruleGap/1.41
  end
  if node.getProperty('bevelled')=='true' then
    eh = node.enumerator.height+node.enumerator.depth
    dh = node.denominator.height+node.denominator.depth
    vshift = min(eh, dh)/2
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
    node.width = max(node.enumerator.width, node.denominator.width)+2*node.ruleWidth
    node.leftspace = node.ruleWidth
    node.rightspace = node.ruleWidth
  end
  node.ascender = node.height
  node.descender = node.depth
end

measure_msqrt = function(node)
  createImplicitRow(node)
  enclosures.addRadicalEnclosure(node)
end

measure_mroot = function(node)
  if len(node.children)~=2 then
    node.error('Invalid content of \'mroot\' element: element should have exactly two children')
  end
  if len(node.children)<2 then
    node.rootindex = nil
    measure_msqrt(node)
  else
    setNodeBase(node, node.children[1])
    node.rootindex = node.children[2]
    enclosures.addRadicalEnclosure(node)
    node.width = node.width+max(0, node.rootindex.width-node.cornerWidth)
    node.height = node.height+max(0, node.rootindex.height+node.rootindex.depth-node.cornerHeight)
    node.ascender = node.height
  end
end

measure_msub = function(node)
  if len(node.children)~=2 then
    node.error('Invalid content of \'msub\' element: element should have exactly two children')
    if len(node.children)<2 then
      measure_mrow(node)
      return 
    end
  end
  measureScripts(node, {node.children[2]}, nil)
end

measure_msup = function(node)
  if len(node.children)~=2 then
    node.error('Invalid content of \'msup\' element: element should have exactly two children')
    if len(node.children)<2 then
      measure_mrow(node)
      return 
    end
  end
  measureScripts(node, nil, {node.children[2]})
end

measure_msubsup = function(node)
  if len(node.children)~=3 then
    node.error('Invalid content of \'msubsup\' element: element should have exactly three children')
    if len(node.children)==2 then
      measure_msub(node)
      return 
    elseif len(node.children)<2 then
      measure_mrow(node)
      return 
    end
  end
  measureScripts(node, {node.children[2]}, {node.children[3]})
end

measure_munder = function(node)
  if len(node.children)~=2 then
    node.error('Invalid content of \'munder\' element: element should have exactly two children')
    if len(node.children)<2 then
      measure_mrow(node)
      return 
    end
  end
  measureLimits(node, node.children[2], nil)
end

measure_mover = function(node)
  if len(node.children)~=2 then
    node.error('Invalid content of \'mover\' element: element should have exactly two children')
    if len(node.children)<2 then
      measure_mrow(node)
      return 
    end
  end
  measureLimits(node, nil, node.children[2])
end

measure_munderover = function(node)
  if len(node.children)~=3 then
    node.error('Invalid content of \'munderover\' element: element should have exactly three children')
    if len(node.children)==2 then
      measure_munder(node)
      return 
    elseif len(node.children)<2 then
      measure_mrow(node)
      return 
    end
  end
  measureLimits(node, node.children[2], node.children[3])
end

measure_mmultiscripts = function(node)
  if len(node.children)==0 then
    measure_mrow(node)
    return 
  end
  subscripts = {}
  superscripts = {}
  presubscripts = {}
  presuperscripts = {}
  isPre = false
  isSub = true
  for ch in ipairs(PYLUA.slice(node.children, 1, nil)) do
    if ch.elementName=='mprescripts' then
      if isPre then
        node.error('Repeated \'mprescripts\' element inside \'mmultiscripts\n')
      end
      isPre = true
      isSub = true
      goto continue
    end
    if isSub then
      if isPre then
        presubscripts.append(ch)
      else
        subscripts.append(ch)
      end
    elseif isPre then
      presuperscripts.append(ch)
    else
      superscripts.append(ch)
    end
    isSub =  not isSub
  end
  measureScripts(node, subscripts, superscripts, presubscripts, presuperscripts)
end

measure_menclose = function(node)

  pushEnclosure = function()
    if PYLUA.op_is(node.decoration, nil) then
      return 
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
  signs = node.getProperty('notation').split()
  node.width = node.base.width
  node.height = node.base.height
  node.depth = node.base.depth
  node.decoration = nil
  node.decorationData = nil
  node.borderWidth = node.nominalLineWidth()
  node.hdelta = node.nominalLineGap()+node.borderWidth
  node.vdelta = node.nominalLineGap()+node.borderWidth
  if PYLUA.op_in('radical', signs) then
    wrapChildren(node, 'msqrt')
    setNodeBase(node.children[1], node.base)
    setNodeBase(node, node.children[1])
    node.base.makeContext()
    node.base.measureNode()
    node.width = node.base.width
    node.height = node.base.height
    node.depth = node.base.depth
  end
  strikes = {PYLUA.op_in('horizontalstrike', signs), PYLUA.op_in('verticalstrike', signs), PYLUA.op_in('updiagonalstrike', signs), PYLUA.op_in('downdiagonalstrike', signs)}
  if PYLUA.op_in(true, strikes) then
    pushEnclosure()
    node.decoration = 'strikes'
    node.decorationData = strikes
  end
  if PYLUA.op_in('roundedbox', signs) then
    pushEnclosure()
    node.decoration = 'roundedbox'
    enclosures.addBoxEnclosure(node)
  end
  if PYLUA.op_in('box', signs) then
    pushEnclosure()
    node.decoration = 'box'
    enclosures.addBoxEnclosure(node)
  end
  if PYLUA.op_in('circle', signs) then
    pushEnclosure()
    node.decoration = 'circle'
    enclosures.addCircleEnclosure(node)
  end
  borders = {PYLUA.op_in('left', signs), PYLUA.op_in('right', signs), PYLUA.op_in('top', signs), PYLUA.op_in('bottom', signs)}
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
  if PYLUA.op_in('longdiv', signs) then
    pushEnclosure()
    node.decoration = 'borders'
    enclosures.addBorderEnclosure(node, {true, false, true, false})
  end
  if PYLUA.op_in('actuarial', signs) then
    pushEnclosure()
    node.decoration = 'borders'
    enclosures.addBorderEnclosure(node, {false, true, true, false})
  end
end

measure_mtable = function(node)
  node.lineWidth = node.nominalLineWidth()
  tables.arrangeCells(node)
  tables.arrangeLines(node)
  tables.calculateColumnWidths(node)
  for r in ipairs(node.rows) do
    for i in ipairs(range(len(r.cells))) do
      c = r.cells[i]
      if PYLUA.op_is(c, nil) or PYLUA.op_is(c.content, nil) then
        goto continue
      end
      content = c.content
      if content.elementName=='mtd' then
        if len(content.children)~=1 then
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
          spannedColumns = PYLUA.slice(node.columns, i, i+c.colspan)
          cellSize = sum(PYLUA.COMPREHENSION())
          cellSize = cellSize+sum(PYLUA.COMPREHENSION())
          stretch(PYLUA.keywords{toWidth=cellSize}, content)
        end
      end
    end
  end
  tables.calculateRowHeights(node)
  for i in ipairs(range(len(node.rows))) do
    r = node.rows[i]
    for c in ipairs(r.cells) do
      if PYLUA.op_is(c, nil) or PYLUA.op_is(c.content, nil) then
        goto continue
      end
      content = c.content
      if content.elementName=='mtd' then
        if len(content.children)~=1 then
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
          spannedRows = PYLUA.slice(node.rows, i, i+c.rowspan)
          cellSize = sum(PYLUA.COMPREHENSION())
          cellSize = cellSize+sum(PYLUA.COMPREHENSION())
          stretch(PYLUA.keywords{toHeight=cellSize/2, toDepth=cellSize/2}, content)
        end
      end
    end
  end
  tables.calculateColumnWidths(node)
  node.width = sum(PYLUA.COMPREHENSION())
  node.width = node.width+2*node.framespacings[1]
  vsize = sum(PYLUA.COMPREHENSION())
  vsize = vsize+2*node.framespacings[2]
  alignType, alignRow = tables.getAlign(node)
  if PYLUA.op_is(alignRow, nil) then
    topLine = 0
    bottomLine = vsize
    axisLine = vsize/2
    baseLine = axisLine+node.axis()
  else
    row = node.rows[alignRow-1]
    topLine = node.framespacings[2]
    for r in ipairs(PYLUA.slice(node.rows, 0, alignRow)) do
      topLine = topLine+r.height+r.depth+r.spaceAfter
    end
    bottomLine = topLine+row.height+row.depth
    if row.alignToAxis then
      axisLine = topLine+row.height
      baseLine = axisLine+node.axis()
    else
      baseLine = topLine+row.height
      axisLine = baseLine-node.axis()
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
    node.error('Unrecognized or unsupported table alignment value: '+alignType)
    node.alignToAxis = true
    node.height = axisLine
  end
  node.depth = vsize-node.height
  node.ascender = node.height
  node.descender = node.depth
end

measure_mtr = function(node)
  if PYLUA.op_is(node.parent, nil) or node.parent.elementName~='mtable' then
    node.error(PYLUA.mod('Misplaced \'%s\' element: should be child of \'mtable\'', node.elementName))
  end
end

measure_mlabeledtr = function(node)
  if len(node.children)==0 then
    node.error(PYLUA.mod('Missing label in \'%s\' element', node.elementName))
  else
    node.warning(PYLUA.mod('MathML element \'%s\' is unsupported: label omitted', node.elementName))
    node.children = PYLUA.slice(node.children, 1, nil)
  end
  measure_mtr(node)
end

measure_mtd = function(node)
  if PYLUA.op_is(node.parent, nil) or PYLUA.op_not_in(node.parent.elementName, {'mtr', 'mlabeledtr', 'mtable'}) then
    node.error(PYLUA.mod('Misplaced \'%s\' element: should be child of \'mtr\', \'mlabeledtr\', or \'mtable\'', node.elementName))
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
  subs = node.subscripts+node.presubscripts
  supers = node.superscripts+node.presuperscripts
  node.subscriptAxis = max({0}+PYLUA.COMPREHENSION())
  node.superscriptAxis = max({0}+PYLUA.COMPREHENSION())
  gap = max(PYLUA.COMPREHENSION())
  protrusion = node.parseLength('0.25ex')
  scriptMedian = node.axis()
  subHeight, subDepth, subAscender, subDescender = getRowVerticalExtent(subs, false, node.subscriptAxis)
  superHeight, superDepth, superAscender, superDescender = getRowVerticalExtent(supers, false, node.superscriptAxis)
  node.subShift = 0
  if len(subs)>0 then
    shiftAttr = node.getProperty('subscriptshift')
    if PYLUA.op_is(shiftAttr, nil) then
      shiftAttr = '0.5ex'
    end
    node.subShift = node.parseLength(shiftAttr)
    node.subShift = max(node.subShift, subHeight-scriptMedian+gap)
    if node.alignToAxis then
      node.subShift = node.subShift+node.axis()
    end
    node.subShift = max(node.subShift, node.base.depth+protrusion-subDepth)
    node.height = max(node.height, subHeight-node.subShift)
    node.depth = max(node.depth, subDepth+node.subShift)
    node.ascender = max(node.ascender, subAscender-node.subShift)
    node.descender = max(node.descender, subDescender+node.subShift)
  end
  node.superShift = 0
  if len(supers)>0 then
    shiftAttr = node.getProperty('superscriptshift')
    if PYLUA.op_is(shiftAttr, nil) then
      shiftAttr = '1ex'
    end
    node.superShift = node.parseLength(shiftAttr)
    node.superShift = max(node.superShift, superDepth+scriptMedian+gap)
    if node.alignToAxis then
      node.superShift = node.superShift-node.axis()
    end
    node.superShift = max(node.superShift, node.base.height+protrusion-superHeight)
    node.height = max(node.height, superHeight+node.superShift)
    node.depth = max(node.depth, superDepth-node.superShift)
    node.ascender = max(node.ascender, superHeight+node.superShift)
    node.descender = max(node.descender, superDepth-node.superShift)
  end

  parallelWidths = function(nodes1, nodes2)
    widths = {}
    for i in ipairs(range(max(len(nodes1), len(nodes2)))) do
      w = 0
      if i<len(nodes1) then
        w = max(w, nodes1[i].width)
      end
      if i<len(nodes2) then
        w = max(w, nodes2[i].width)
      end
      widths.append(w)
    end
    return widths
  end
  node.postwidths = parallelWidths(node.subscripts, node.superscripts)
  node.prewidths = parallelWidths(node.presubscripts, node.presuperscripts)
  node.width = node.width+sum(node.prewidths+node.postwidths)
end

measureLimits = function(node, underscript, overscript)
  if node.children[1].core.moveLimits then
    subs = {}
    supers = {}
    if PYLUA.op_is_not(underscript, nil) then
      subs = {underscript}
    end
    if PYLUA.op_is_not(overscript, nil) then
      supers = {overscript}
    end
    measureScripts(node, subs, supers)
    return 
  end
  node.underscript = underscript
  node.overscript = overscript
  setNodeBase(node, node.children[1])
  node.width = node.base.width
  if PYLUA.op_is_not(overscript, nil) then
    node.width = max(node.width, overscript.width)
  end
  if PYLUA.op_is_not(underscript, nil) then
    node.width = max(node.width, underscript.width)
  end
  stretch(PYLUA.keywords{toWidth=node.width}, node.base)
  stretch(PYLUA.keywords{toWidth=node.width}, overscript)
  stretch(PYLUA.keywords{toWidth=node.width}, underscript)
  gap = node.nominalLineGap()
  if PYLUA.op_is_not(overscript, nil) then
    overscriptBaselineHeight = node.base.height+gap+overscript.depth
    node.height = overscriptBaselineHeight+overscript.height
    node.ascender = node.height
  else
    node.height = node.base.height
    node.ascender = node.base.ascender
  end
  if PYLUA.op_is_not(underscript, nil) then
    underscriptBaselineDepth = node.base.depth+gap+underscript.height
    node.depth = underscriptBaselineDepth+underscript.depth
    node.descender = node.depth
  else
    node.depth = node.base.depth
    node.descender = node.base.descender
  end
end

stretch = function(node, toWidth, toHeight, toDepth, symmetric)
  if PYLUA.op_is(node, nil) then
    return 
  end
  if  not node.core.stretchy then
    return 
  end
  if PYLUA.op_is_not(node, node.base) then
    if PYLUA.op_is_not(toWidth, nil) then
      toWidth = toWidth-node.width-node.base.width
    end
    stretch(node.base, toWidth, toHeight, toDepth, symmetric)
    node.measureNode()
  elseif node.elementName=='mo' then
    if node.fontSize==0 then
      return 
    end
    maxsizedefault = node.opdefaults.get('maxsize')
    maxsizeattr = node.getProperty('maxsize', maxsizedefault)
    if maxsizeattr=='infinity' then
      maxScale = nil
    else
      maxScale = node.parseSpaceOrPercent(maxsizeattr, node.fontSize, node.fontSize)/node.fontSize
    end
    minsizedefault = node.opdefaults.get('minsize')
    minsizeattr = node.getProperty('minsize', minsizedefault)
    minScale = node.parseSpaceOrPercent(minsizeattr, node.fontSize, node.fontSize)/node.fontSize
    if PYLUA.op_is(toWidth, nil) then
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
  scale = (toHeight+toDepth)/(node.ascender+node.descender)
  if minScale then
    scale = max(scale, minScale)
  end
  if maxScale then
    scale = min(scale, maxScale)
  end
  node.fontSize = node.fontSize*scale
  node.height = node.height*scale
  node.depth = node.depth*scale
  node.ascender = node.ascender*scale
  node.descender = node.descender*scale
  node.textShift = node.textShift*scale
  extraShift = (toHeight-node.ascender-toDepth-node.descender)/2
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
  scale = toWidth/node.width
  scale = max(scale, minScale)
  if maxScale then
    scale = min(scale, maxScale)
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
  old_children = node.children
  node.children = {}
  base = mathnode.MathNode(wrapperElement, { }, nil, node.config, node)
  base.children = old_children
end

createImplicitRow = function(node)
  if len(node.children)~=1 then
    wrapChildren(node, 'mrow')
    node.children[1].makeContext()
    node.children[1].measureNode()
  end
  setNodeBase(node, node.children[1])
end

getVerticalStretchExtent = function(descendants, rowAlignToAxis, axis)
  ascender = 0
  descender = 0
  for ch in ipairs(descendants) do
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
      chaxis = ch.axis()
      asc = asc-chaxis
      desc = desc+chaxis
    end
    ascender = max(asc, ascender)
    descender = max(desc, descender)
  end
  return ascender, descender
end

getRowVerticalExtent = function(descendants, rowAlignToAxis, axis)
  height = 0
  depth = 0
  ascender = 0
  descender = 0
  for ch in ipairs(descendants) do
    h = ch.height
    d = ch.depth
    asc = ch.ascender
    desc = ch.descender
    if ch.alignToAxis and  not rowAlignToAxis then
      h = h+axis
      asc = asc+axis
      d = d-axis
      desc = desc-axis
    elseif  not ch.alignToAxis and rowAlignToAxis then
      chaxis = ch.axis()
      h = h-chaxis
      asc = asc-chaxis
      d = d+chaxis
      desc = desc+chaxis
    end
    height = max(h, height)
    depth = max(d, depth)
    ascender = max(asc, ascender)
    descender = max(desc, descender)
  end
  return height, depth, ascender, descender
end
