-- Drawing methods for MathML elements
local sys = require('sys')
local math = require('math')
local mathnode = require('mathnode')
local sax = require('xml').sax
local xmlreader = require('xml.sax').xmlreader
SVGNS = 'http://www.w3.org/2000/svg'
SVGMathNS = 'http://www.grigoriev.ru/svgmath'
useNamespaces = true
readable = false
alignKeywords = { left=0, center=0.5, right=1, }

startElement = function(output, localname, namespace, prefix, attrs)
  -- Wrapper to emit a start tag
  if readable then
    output.characters('\n')
  end
  if useNamespaces then
    nsAttrs = { }
    for att, value in ipairs(attrs.items()) do
      nsAttrs[nil, att] = value
    end
    qnames = attrs.keys()
    output.startElementNS(namespace, localname, prefix+localname, xmlreader.AttributesNSImpl(nsAttrs, qnames))
  else
    output.startElement(prefix+localname, xmlreader.AttributesImpl(attrs))
  end
end

endElement = function(output, localname, namespace, prefix)
  -- Wrapper to emit an end tag
  if useNamespaces then
    output.endElementNS(namespace, localname, prefix+localname)
  else
    output.endElement(prefix+localname)
  end
  if readable then
    output.characters('\n')
  end
end

startSVGElement = function(output, localname, attrs)
  startElement(output, localname, SVGNS, 'svg:', attrs)
end

endSVGElement = function(output, localname)
  endElement(output, localname, SVGNS, 'svg:')
end

drawImage = function(node, output)
  -- Top-level draw function: prepare the canvas, then call the draw method of the root node
  baseline = 0
  if node.alignToAxis then
    baseline = node.axis()
  end
  height = max(node.height, node.ascender)
  depth = max(node.depth, node.descender)
  vsize = height+depth
  attrs = { width=PYLUA.mod('%fpt', node.width), height=PYLUA.mod('%fpt', vsize), viewBox=PYLUA.mod('0 %f %f %f', -height+baseline, node.width, vsize), }
  if useNamespaces then
    output.startPrefixMapping('svg', SVGNS)
    output.startPrefixMapping('svgmath', SVGMathNS)
  else
    attrs['xmlns:svg'] = SVGNS
    attrs['xmlns:svgmath'] = SVGMathNS
  end
  startSVGElement(output, 'svg', attrs)
  startSVGElement(output, 'metadata', { })
  startElement(output, 'metrics', SVGMathNS, 'svgmath:', { baseline=depth-baseline, axis=depth-baseline+node.axis(), top=depth+node.height, bottom=depth-node.depth, })
  endElement(output, 'metrics', SVGMathNS, 'svgmath:')
  endSVGElement(output, 'metadata')
  drawTranslatedNode(node, output, 0, -baseline)
  endSVGElement(output, 'svg')
  if useNamespaces then
    output.endPrefixMapping('svg')
    output.endPrefixMapping('svgmath')
  end
end

default_draw = function(node, output)
end

draw_math = function(node, output)
  draw_mrow(node, output)
end

draw_mrow = function(node, output)
  drawBox(node, output)
  if len(node.children)==0 then
    return 
  end
  offset = -node.children[1].leftspace
  for ch in ipairs(node.children) do
    offset = offset+ch.leftspace
    baseline = 0
    if ch.alignToAxis and  not node.alignToAxis then
      baseline = -node.axis()
    end
    drawTranslatedNode(ch, output, offset, baseline)
    offset = offset+ch.width+ch.rightspace
  end
end

draw_mphantom = function(node, output)
end

draw_none = function(node, output)
end

draw_maction = function(node, output)
  if PYLUA.op_is_not(node.base, nil) then
    node.base.draw(output)
  end
end

draw_mprescripts = function(node, output)
end

draw_mstyle = function(node, output)
  draw_mrow(node, output)
end

draw_mfenced = function(node, output)
  draw_mrow(node, output)
end

draw_merror = function(node, output)
  drawBox(node, output, node.borderWidth, 'red')
  drawTranslatedNode(node.base, output, node.borderWidth, 0)
end

draw_mpadded = function(node, output)
  drawBox(node, output)
  drawTranslatedNode(node.base, output, node.leftpadding, 0)
end

draw_menclose = function(node, output)
  if PYLUA.op_is(node.decoration, nil) then
    node.base.draw(output)
  elseif node.decoration=='strikes' then
    drawStrikesEnclosure(node, output)
  elseif node.decoration=='borders' then
    drawBordersEnclosure(node, output)
  elseif node.decoration=='box' then
    drawBoxEnclosure(node, output)
  elseif node.decoration=='roundedbox' then
    r = (node.width-node.base.width+node.height-node.base.height+node.depth-node.base.depth)/4
    drawBoxEnclosure(node, output, r)
  elseif node.decoration=='circle' then
    drawCircleEnclosure(node, output)
  else
    node.error('Internal error: unhandled decoration %s', str(node.decoration))
    node.base.draw(output)
  end
end

draw_mfrac = function(node, output)
  drawBox(node, output)
  if node.getProperty('bevelled')=='true' then
    drawTranslatedNode(node.enumerator, output, 0, node.enumerator.height-node.height)
    drawTranslatedNode(node.denominator, output, node.width-node.denominator.width, node.depth-node.denominator.depth)
  else
    enumalign = getAlign(node, 'enumalign')
    denomalign = getAlign(node, 'denomalign')
    drawTranslatedNode(node.enumerator, output, node.ruleWidth+(node.width-2*node.ruleWidth-node.enumerator.width)*enumalign, node.enumerator.height-node.height)
    drawTranslatedNode(node.denominator, output, node.ruleWidth+(node.width-2*node.ruleWidth-node.denominator.width)*denomalign, node.depth-node.denominator.depth)
  end
  if node.ruleWidth then
    if node.getProperty('bevelled')=='true' then
      eh = node.enumerator.height+node.enumerator.depth
      dh = node.denominator.height+node.denominator.depth
      ruleX = (node.width+node.enumerator.width-node.denominator.width)/2.0
      if eh<dh then
        ruleY = 0.75*eh-node.height
      else
        ruleY = node.depth-0.75*dh
      end
      x1 = max(0, ruleX-(node.depth-ruleY)/node.slope)
      x2 = min(node.width, ruleX+(ruleY+node.height)/node.slope)
      y1 = min(node.depth, ruleY+ruleX*node.slope)
      y2 = max(-node.height, ruleY-(node.width-ruleX)*node.slope)
    else
      x1 = 0
      y1 = 0
      x2 = node.width
      y2 = 0
    end
    drawLine(output, node.color, node.ruleWidth, x1, y1, x2, y2, { ['stroke-linecap']='butt', })
  end
end

draw_mo = function(node, output)
  drawSVGText(node, output)
end

draw_mi = function(node, output)
  drawSVGText(node, output)
end

draw_mn = function(node, output)
  drawSVGText(node, output)
end

draw_mtext = function(node, output)
  drawSVGText(node, output)
end

draw_ms = function(node, output)
  drawSVGText(node, output)
end

draw_mspace = function(node, output)
  drawBox(node, output)
end

draw_msqrt = function(node, output)
  drawBox(node, output)
  drawTranslatedNode(node.base, output, node.width-node.base.width-node.gap, 0)
  x1 = node.width-node.base.width-node.rootWidth-2*node.gap
  y1 = (node.rootDepth-node.rootHeight)/2
  x2 = x1+node.rootWidth*0.2
  y2 = y1
  x3 = x1+node.rootWidth*0.6
  y3 = node.rootDepth
  x4 = x1+node.rootWidth
  y4 = -node.rootHeight+node.lineWidth/2
  x5 = node.width
  y5 = y4
  slopeA = (x2-x3)/(y2-y3)
  slopeB = (x3-x4)/(y3-y4)
  x2a = x2+node.thickLineWidth-node.lineWidth
  y2a = y2
  x2c = x2+node.lineWidth*slopeA/2
  y2c = y2+node.lineWidth*0.9
  x2b = x2c+(node.thickLineWidth-node.lineWidth)/2
  y2b = y2c
  ytmp = y3-node.lineWidth/2
  xtmp = x3-node.lineWidth*(slopeA+slopeB)/4
  y3a = (y2a*slopeA-ytmp*slopeB+xtmp-x2a)/(slopeA-slopeB)
  x3a = xtmp+(y3a-ytmp)*slopeB
  y3b = (y2b*slopeA-ytmp*slopeB+xtmp-x2b)/(slopeA-slopeB)
  x3b = xtmp+(y3b-ytmp)*slopeB
  y1 = y1+(x2-x1)*slopeA
  attrs = { stroke=node.color, fill='none', ['stroke-width']=PYLUA.mod('%f', node.lineWidth), ['stroke-linecap']='butt', ['stroke-linejoin']='miter', ['stroke-miterlimit']='10', d=PYLUA.mod('M %f %f L %f %f L %f %f L %f %f L %f %f L %f %f L %f %f L %f %f L %f %f', x1, y1, x2a, y2a, x3a, y3a, x3b, y3b, x2b, y2b, x2c, y2c, x3, y3, x4, y4, x5, y5), }
  startSVGElement(output, 'path', attrs)
  endSVGElement(output, 'path')
end

draw_mroot = function(node, output)
  draw_msqrt(node, output)
  if PYLUA.op_is_not(node.rootindex, nil) then
    w = max(0, node.cornerWidth-node.rootindex.width)/2
    h = -node.rootindex.depth-node.rootHeight+node.cornerHeight
    drawTranslatedNode(node.rootindex, output, w, h)
  end
end

draw_msub = function(node, output)
  drawScripts(node, output)
end

draw_msup = function(node, output)
  drawScripts(node, output)
end

draw_msubsup = function(node, output)
  drawScripts(node, output)
end

draw_mmultiscripts = function(node, output)
  drawScripts(node, output)
end

drawScripts = function(node, output)
  if len(node.children)<2 then
    draw_mrow(node)
    return 
  end
  subY = node.subShift
  superY = -node.superShift

  adjustment = function(script)
    if script.alignToAxis then
      return script.axis()
    else
      return 0
    end
  end
  drawBox(node, output)
  offset = 0
  for i in ipairs(range(len(node.prewidths))) do
    offset = offset+node.prewidths[i]
    if i<len(node.presubscripts) then
      presubscript = node.presubscripts[i]
      drawTranslatedNode(presubscript, output, offset-presubscript.width, subY-adjustment(presubscript))
    end
    if i<len(node.presuperscripts) then
      presuperscript = node.presuperscripts[i]
      drawTranslatedNode(presuperscript, output, offset-presuperscript.width, superY-adjustment(presuperscript))
    end
  end
  drawTranslatedNode(node.base, output, offset, 0)
  offset = offset+node.base.width
  for i in ipairs(range(len(node.postwidths))) do
    if i<len(node.subscripts) then
      subscript = node.subscripts[i]
      drawTranslatedNode(subscript, output, offset, subY-adjustment(subscript))
    end
    if i<len(node.superscripts) then
      superscript = node.superscripts[i]
      drawTranslatedNode(superscript, output, offset, superY-adjustment(superscript))
    end
    offset = offset+node.postwidths[i]
  end
end

draw_munder = function(node, output)
  drawLimits(node, output)
end

draw_mover = function(node, output)
  drawLimits(node, output)
end

draw_munderover = function(node, output)
  drawLimits(node, output)
end

drawLimits = function(node, output)
  if len(node.children)<2 then
    draw_mrow(node)
    return 
  end
  if node.core.moveLimits then
    drawScripts(node, output)
    return 
  end
  drawBox(node, output)
  drawTranslatedNode(node.base, output, (node.width-node.base.width)/2, 0)
  if PYLUA.op_is_not(node.underscript, nil) then
    drawTranslatedNode(node.underscript, output, (node.width-node.underscript.width)/2, node.depth-node.underscript.depth)
  end
  if PYLUA.op_is_not(node.overscript, nil) then
    drawTranslatedNode(node.overscript, output, (node.width-node.overscript.width)/2, node.overscript.height-node.height)
  end
end

draw_mtd = function(node, output)
  draw_mrow(node, output)
end

draw_mtr = function(node, output)
end

draw_mlabeledtr = function(node, output)
end

draw_mtable = function(node, output)
  drawBox(node, output)
  vshift = -node.height+node.framespacings[2]
  for r in ipairs(range(len(node.rows))) do
    row = node.rows[r]
    vshift = vshift+row.height
    hshift = node.framespacings[1]
    for c in ipairs(range(len(row.cells))) do
      column = node.columns[c]
      cell = row.cells[c]
      if PYLUA.op_is_not(cell, nil) and PYLUA.op_is_not(cell.content, nil) then
        if cell.colspan>1 then
          cellWidth = sum(PYLUA.COMPREHENSION())
          cellWidth = cellWidth+sum(PYLUA.COMPREHENSION())
        else
          cellWidth = column.width
        end
        hadjust = (cellWidth-cell.content.width)*alignKeywords.get(cell.halign, 0.5)
        if cell.rowspan>1 then
          cellHeight = sum(PYLUA.COMPREHENSION())
          cellHeight = cellHeight+sum(PYLUA.COMPREHENSION())
        else
          cellHeight = row.height+row.depth
        end
        if cell.valign=='top' then
          vadjust = cell.content.height-row.height
        elseif cell.valign=='bottom' then
          vadjust = cellHeight-row.height-cell.content.depth
        elseif PYLUA.op_in(cell.valign, {'axis', 'baseline'}) and cell.rowspan==1 then
          vadjust = -cell.vshift
        else
          vadjust = (cell.content.height-cell.content.depth+cellHeight)/2-row.height
        end
        drawTranslatedNode(cell.content, output, hshift+hadjust, vshift+vadjust)
      end
      hshift = hshift+column.width+column.spaceAfter
    end
    vshift = vshift+row.depth+row.spaceAfter
  end

  drawBorder = function(x1, y1, x2, y2, linestyle)
    if PYLUA.op_is(linestyle, nil) then
      return 
    end
    if x1==x2 and y1==y2 then
      return 
    end
    if linestyle=='dashed' then
      linelength = math.sqrt(math.pow(x1-x2, 2)+math.pow(y1-y2, 2))
      dashoffset = 5-PYLUA.mod(linelength/node.lineWidth+3, 10)/2
      extrastyle = { ['stroke-dasharray']=PYLUA.mod('%f,%f', node.lineWidth*7, node.lineWidth*3), ['stroke-dashoffset']=PYLUA.mod('%f', node.lineWidth*dashoffset), }
    else
      extrastyle = nil
    end
    drawLine(output, node.color, node.lineWidth, x1, y1, x2, y2, extrastyle)
  end
  x1 = node.lineWidth/2
  y1 = node.lineWidth/2-node.height
  x2 = node.width-node.lineWidth/2
  y2 = node.depth-node.lineWidth/2
  drawBorder(x1, y1, x1, y2, node.framelines[1])
  drawBorder(x2, y1, x2, y2, node.framelines[1])
  drawBorder(x1, y1, x2, y1, node.framelines[2])
  drawBorder(x1, y2, x2, y2, node.framelines[2])
  hshift = node.framespacings[1]
  hoffsets = {}
  for c in ipairs(range(len(node.columns))) do
    spacing = node.columns[c].spaceAfter
    hshift = hshift+node.columns[c].width
    hoffsets.append(hshift+spacing/2)
    hshift = hshift+spacing
  end
  hoffsets[0] = x2
  vshift = -node.height+node.framespacings[2]
  voffsets = {}
  for r in ipairs(range(len(node.rows))) do
    spacing = node.rows[r].spaceAfter
    vshift = vshift+node.rows[r].height+node.rows[r].depth
    voffsets.append(vshift+spacing/2)
    vshift = vshift+spacing
  end
  voffsets[0] = y2
  vspans = {0}*len(node.columns)
  for r in ipairs(range(len(node.rows)-1)) do
    row = node.rows[r]
    if PYLUA.op_is(row.lineAfter, nil) then
      goto continue
    end
    for c in ipairs(range(len(row.cells))) do
      cell = row.cells[c]
      if PYLUA.op_is(cell, nil) or PYLUA.op_is(cell.content, nil) then
        goto continue
      end
      for j in ipairs(range(c, c+cell.colspan)) do
        vspans[j] = cell.rowspan
      end
    end
    vspans = PYLUA.COMPREHENSION()
    lineY = voffsets[r]
    startX = x1
    endX = x1
    for c in ipairs(range(len(node.columns))) do
      if vspans[c]>0 then
        drawBorder(startX, lineY, endX, lineY, row.lineAfter)
        startX = hoffsets[c]
      end
      endX = hoffsets[c]
    end
    drawBorder(startX, lineY, endX, lineY, row.lineAfter)
  end
  hspans = {0}*len(node.rows)
  for c in ipairs(range(len(node.columns)-1)) do
    column = node.columns[c]
    if PYLUA.op_is(column.lineAfter, nil) then
      goto continue
    end
    for r in ipairs(range(len(node.rows))) do
      row = node.rows[r]
      if len(row.cells)<=c then
        goto continue
      end
      cell = row.cells[c]
      if PYLUA.op_is(cell, nil) or PYLUA.op_is(cell.content, nil) then
        goto continue
      end
      for j in ipairs(range(r, r+cell.rowspan)) do
        hspans[j] = cell.colspan
      end
    end
    hspans = PYLUA.COMPREHENSION()
    lineX = hoffsets[c]
    startY = y1
    endY = y1
    for r in ipairs(range(len(node.rows))) do
      if hspans[r]>0 then
        drawBorder(lineX, startY, lineX, endY, column.lineAfter)
        startY = voffsets[r]
      end
      endY = voffsets[r]
    end
    drawBorder(lineX, startY, lineX, endY, column.lineAfter)
  end
end

drawBox = function(node, output, borderWidth, borderColor, borderRadius)
  background = getBackground(node)
  if background=='none' then
    if PYLUA.op_is(borderWidth, nil) or borderWidth==0 then
      return 
    end
  end
  if PYLUA.op_is(borderColor, nil) then
    borderColor = node.color
  end
  attrs = { fill=background, stroke='none', x=PYLUA.mod('%f', borderWidth/2), y=PYLUA.mod('%f', borderWidth/2-node.height), width=PYLUA.mod('%f', node.width-borderWidth), height=PYLUA.mod('%f', node.height+node.depth-borderWidth), }
  if borderWidth~=0 and PYLUA.op_is_not(borderColor, nil) then
    attrs['stroke'] = borderColor
    attrs['stroke-width'] = PYLUA.mod('%f', borderWidth)
    if borderRadius~=0 then
      attrs['rx'] = PYLUA.mod('%f', borderRadius)
      attrs['ry'] = PYLUA.mod('%f', borderRadius)
    end
  end
  startSVGElement(output, 'rect', attrs)
  endSVGElement(output, 'rect')
end

drawLine = function(output, color, width, x1, y1, x2, y2, strokeattrs)
  attrs = { fill='none', stroke=color, ['stroke-width']=PYLUA.mod('%f', width), ['stroke-linecap']='square', ['stroke-dasharray']='none', x1=PYLUA.mod('%f', x1), y1=PYLUA.mod('%f', y1), x2=PYLUA.mod('%f', x2), y2=PYLUA.mod('%f', y2), }
  if PYLUA.op_is_not(strokeattrs, nil) then
    attrs.update(strokeattrs)
  end
  startSVGElement(output, 'line', attrs)
  endSVGElement(output, 'line')
end

drawTranslatedNode = function(node, output, dx, dy)
  if dx~=0 or dy~=0 then
    startSVGElement(output, 'g', { transform=PYLUA.mod('translate(%f, %f)', dx, dy), })
  end
  node.draw(output)
  if dx~=0 or dy~=0 then
    endSVGElement(output, 'g')
  end
end

drawSVGText = function(node, output)
  drawBox(node, output)
  fontfamilies = PYLUA.COMPREHENSION()
  if len(fontfamilies)==0 then
    fontfamilies = node.fontfamilies
  end
  attrs = { fill=node.color, ['font-family']=PYLUA.str_maybe(', ').join(fontfamilies), ['font-size']=PYLUA.mod('%f', node.fontSize), ['text-anchor']='middle', x=PYLUA.mod('%f', (node.width+node.leftBearing-node.rightBearing)/2/node.textStretch), y=PYLUA.mod('%f', -node.textShift), }
  if node.fontweight~='normal' then
    attrs['font-weight'] = node.fontweight
  end
  if node.fontstyle~='normal' then
    attrs['font-style'] = node.fontstyle
  end
  if node.textStretch~=1 then
    attrs['transform'] = PYLUA.mod('scale(%f, 1)', node.textStretch)
  end
  for oldchar, newchar in ipairs(mathnode.specialChars.items()) do
    node.text = node.text.replace(oldchar, newchar)
  end
  startSVGElement(output, 'text', attrs)
  output.characters(node.text)
  endSVGElement(output, 'text')
end

getAlign = function(node, attrName)
  attrValue = node.getProperty(attrName, 'center')
  if PYLUA.op_not_in(attrValue, alignKeywords.keys()) then
    node.error('Bad value %s for %s', attrValue, attrName)
  end
  return alignKeywords.get(attrValue, 0.5)
end

drawBoxEnclosure = function(node, output, roundRadius)
  drawBox(node, output, node.borderWidth, nil, roundRadius)
  drawTranslatedNode(node.base, output, (node.width-node.base.width)/2, 0)
end

drawCircleEnclosure = function(node, output)
  background = getBackground(node)
  r = (node.width-node.borderWidth)/2
  cx = node.width/2
  cy = (node.depth-node.height)/2
  attrs = { fill=background, stroke=node.color, ['stroke-width']=PYLUA.mod('%f', node.borderWidth), cx=PYLUA.mod('%f', cx), cy=PYLUA.mod('%f', cy), r=PYLUA.mod('%f', r), }
  startSVGElement(output, 'circle', attrs)
  endSVGElement(output, 'circle')
  drawTranslatedNode(node.base, output, (node.width-node.base.width)/2, 0)
end

drawBordersEnclosure = function(node, output)

  drawBorder = function(x1, y1, x2, y2)
    drawLine(output, node.color, node.borderWidth, x1, y1, x2, y2)
  end
  drawBox(node, output)
  x1 = node.borderWidth/2
  y1 = node.borderWidth/2-node.height
  x2 = node.width-node.borderWidth/2
  y2 = node.depth-node.borderWidth/2
  left, right, top, bottom = node.decorationData
  if left then
    drawBorder(x1, y1, x1, y2)
  end
  if right then
    drawBorder(x2, y1, x2, y2)
  end
  if top then
    drawBorder(x1, y1, x2, y1)
  end
  if bottom then
    drawBorder(x1, y2, x2, y2)
  end
  if left then
    offset = node.width-node.base.width
    if right then
      offset = offset/2
    end
  else
    offset = 0
  end
  drawTranslatedNode(node.base, output, offset, 0)
end

drawStrikesEnclosure = function(node, output)

  drawStrike = function(x1, y1, x2, y2)
    drawLine(output, node.color, node.borderWidth, x1, y1, x2, y2)
  end
  drawBox(node, output)
  node.base.draw(output)
  mid_x = node.width/2
  mid_y = (node.depth-node.height)/2
  horiz, vert, updiag, downdiag = node.decorationData
  if horiz then
    drawStrike(0, mid_y, node.width, mid_y)
  end
  if vert then
    drawStrike(mid_x, -node.height, mid_x, node.depth)
  end
  if updiag then
    drawStrike(0, node.depth, node.width, -node.height)
  end
  if downdiag then
    drawStrike(0, -node.height, node.width, node.depth)
  end
end

getBackground = function(node)
  for attr in ipairs({'mathbackground', 'background-color', 'background'}) do
    value = node.attributes.get(attr)
    if PYLUA.op_is_not(value, nil) then
      if value=='transparent' then
        return 'none'
      else
        return value
      end
    end
  end
end
