-- Drawing methods for MathML elements

local math, string, table, require = math, string, table, require
local pairs, ipairs = pairs, ipairs
local _ENV = {package=package}
local PYLUA = require('PYLUA')

--[[
local sys = require('sys')
--]]
local mathnode = require('mathnode')
local sax = require('xml').sax
local xmlreader = require('xml.sax').xmlreader

-- SVG namespace
local SVGNS = 'http://www.w3.org/2000/svg'
-- SVGMath proprietary namespace - used in metadata
local SVGMathNS = 'http://www.grigoriev.ru/svgmath'

-- Use namespace-aware (SAX2) or plain (SAX1) callbacks 
local useNamespaces = true
-- Output extra linefeeds to improve readability
local readable = false

-- Handy mapping of horizontal alignment keywords
local alignKeywords = { left=0, center=0.5, right=1, }

startElement = function(output, localname, namespace, prefix, attrs)
  -- Wrapper to emit a start tag
  if readable then
    output:characters('\n')  -- for readability
  end

  if useNamespaces then
    local nsAttrs = { }
    for att, value in pairs(attrs) do
      nsAttrs[{nil, att}] = value
    end
    local qnames = PYLUA.keys(attrs)
    output:startElementNS({namespace, localname},
      prefix..localname, xmlreader.AttributesNSImpl(nsAttrs, qnames))
  else
    output:startElement(prefix..localname, xmlreader.AttributesImpl(attrs))
  end
end

endElement = function(output, localname, namespace, prefix)
  -- Wrapper to emit an end tag
  if useNamespaces then
    output:endElementNS({namespace, localname}, prefix..localname)
  else
    output:endElement(prefix..localname)
  end

  if readable then
    output:characters('\n')  -- for readability
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
 
  -- The zero level of the viewbox is always aligned on the alphabetic baseline
  local baseline = 0
  if node.alignToAxis then
    baseline = node:axis()
  end

  local height = math.max(node.height, node.ascender)
  local depth = math.max(node.depth, node.descender)
  local vsize = height+depth

  local attrs = {
    width=string.format('%fpt', node.width),
    height=string.format('%fpt', vsize),
    viewBox=string.format('0 %f %f %f', -(height+baseline), node.width, vsize),
  }
  if useNamespaces then
    output:startPrefixMapping('svg', SVGNS)
    output:startPrefixMapping('svgmath', SVGMathNS)
  else
    attrs['xmlns:svg'] = SVGNS
    attrs['xmlns:svgmath'] = SVGMathNS
  end

  startSVGElement(output, 'svg', attrs)

  -- Prints baseline table as metadata    
  startSVGElement(output, 'metadata', { })
  startElement(output,
    'metrics', SVGMathNS, 'svgmath:', {
      baseline=depth-baseline,
      axis=depth-baseline+node:axis(),
      top=depth+node.height,
      bottom=depth-node.depth,
    })
  endElement(output, 'metrics', SVGMathNS, 'svgmath:')

  endSVGElement(output, 'metadata')

  drawTranslatedNode(node, output, 0, -baseline)
  endSVGElement(output, 'svg')

  if useNamespaces then
    output:endPrefixMapping('svg')
    output:endPrefixMapping('svgmath')
  end
end

default_draw = function(node, output)
end

draw_math = function(node, output)
  draw_mrow(node, output)
end

draw_mrow = function(node, output)
  drawBox(node, output)
  if #node.children==0 then
    return 
  end

  local offset = -node.children[1].leftspace
  for _, ch in ipairs(node.children) do
    offset = offset+ch.leftspace
    local baseline = 0
    if ch.alignToAxis and not node.alignToAxis then
      baseline = -node:axis()
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
  if node.base ~= nil then
    node.base:draw(output)
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
  if node.decoration == nil then
    node.base:draw(output)
  elseif node.decoration=='strikes' then
    drawStrikesEnclosure(node, output)
  elseif node.decoration=='borders' then
    drawBordersEnclosure(node, output)
  elseif node.decoration=='box' then
    drawBoxEnclosure(node, output)
  elseif node.decoration=='roundedbox' then
    local r = (node.width-node.base.width+
              node.height-node.base.height+
              node.depth-node.base.depth) / 4
    drawBoxEnclosure(node, output, r)
  elseif node.decoration=='circle' then
    drawCircleEnclosure(node, output)
  else
    node:error('Internal error: unhandled decoration %s', tostring(node.decoration))
    node.base:draw(output)
  end
end

draw_mfrac = function(node, output)
  drawBox(node, output)

  if node:getProperty('bevelled')=='true' then
    drawTranslatedNode(node.enumerator, output,
      0,
      node.enumerator.height - node.height)
    drawTranslatedNode(node.denominator, output,
      node.width - node.denominator.width,
      node.depth - node.denominator.depth)
  else
    local enumalign = getAlign(node, 'enumalign')
    local denomalign = getAlign(node, 'denomalign')
    drawTranslatedNode(node.enumerator, output,
      node.ruleWidth + (node.width - 2*node.ruleWidth - node.enumerator.width) * enumalign,
      node.enumerator.height - node.height)
    drawTranslatedNode(node.denominator, output,
      node.ruleWidth + (node.width - 2*node.ruleWidth - node.denominator.width) * denomalign,
      node.depth - node.denominator.depth)
  end
  if node.ruleWidth then
    local x1, y1, x2, y2
    if node:getProperty('bevelled')=='true' then
      local eh = node.enumerator.height+node.enumerator.depth
      local dh = node.denominator.height+node.denominator.depth
      local ruleX = (node.width+node.enumerator.width-node.denominator.width)/2.0
      local ruleY
      if eh<dh then
        ruleY = 0.75*eh-node.height
      else
        ruleY = node.depth-0.75*dh
      end
      x1 = math.max(0, ruleX - (node.depth-ruleY)/node.slope)
      x2 = math.min(node.width, ruleX + (ruleY+node.height)/node.slope)
      y1 = math.min(node.depth, ruleY + ruleX*node.slope)
      y2 = math.max(-node.height, ruleY - (node.width-ruleX)*node.slope)
    else
      x1 = 0
      y1 = 0
      x2 = node.width
      y2 = 0
    end
    drawLine(output, node.color, node.ruleWidth,
      x1, y1, x2, y2, { ['stroke-linecap']='butt', })
  end
end

draw_mo = function(node, output) drawSVGText(node, output) end 
draw_mi = function(node, output) drawSVGText(node, output) end 
draw_mn = function(node, output) drawSVGText(node, output) end 
draw_mtext = function(node, output) drawSVGText(node, output) end 
draw_ms = function(node, output) drawSVGText(node, output) end

draw_mspace = function(node, output)
  drawBox(node, output)
end

draw_msqrt = function(node, output)
  drawBox(node, output)
  drawTranslatedNode(node.base, output,
    node.width-node.base.width-node.gap, 0)

  -- Basic contour            
  local x1 = node.width-node.base.width-node.rootWidth-2*node.gap
  local y1 = (node.rootDepth-node.rootHeight)/2

  local x2 = x1+node.rootWidth*0.2
  local y2 = y1

  local x3 = x1+node.rootWidth*0.6
  local y3 = node.rootDepth

  local x4 = x1+node.rootWidth
  local y4 = -node.rootHeight+node.lineWidth/2

  local x5 = node.width
  local y5 = y4

  -- Thickening
  local slopeA = (x2-x3)/(y2-y3)
  local slopeB = (x3-x4)/(y3-y4)

  local x2a = x2+node.thickLineWidth-node.lineWidth
  local y2a = y2

  local x2c = x2+node.lineWidth*slopeA/2
  local y2c = y2+node.lineWidth*0.9

  local x2b = x2c+(node.thickLineWidth-node.lineWidth)/2
  local y2b = y2c

  local ytmp = y3-node.lineWidth/2
  local xtmp = x3-node.lineWidth*(slopeA+slopeB)/4

  local y3a = (y2a*slopeA-ytmp*slopeB+xtmp-x2a)/(slopeA-slopeB)
  local x3a = xtmp+(y3a-ytmp)*slopeB

  local y3b = (y2b*slopeA-ytmp*slopeB+xtmp-x2b)/(slopeA-slopeB)
  local x3b = xtmp+(y3b-ytmp)*slopeB

  -- Lean the left protrusion down
  y1 = y1+(x2-x1)*slopeA

  local attrs = {
    stroke=node.color,
    fill='none',
    ['stroke-width']=string.format('%f', node.lineWidth),
    ['stroke-linecap']='butt',
    ['stroke-linejoin']='miter',
    ['stroke-miterlimit']='10',
    d=string.format('M %f %f L %f %f L %f %f L %f %f L %f %f L %f %f L %f %f L %f %f L %f %f',
      x1, y1, x2a, y2a, x3a, y3a, x3b, y3b, x2b, y2b, x2c, y2c, x3, y3, x4, y4, x5, y5),
  }
  startSVGElement(output, 'path', attrs)
  endSVGElement(output, 'path')
end

draw_mroot = function(node, output)
  draw_msqrt(node, output)
  if node.rootindex ~= nil then
    local w = math.max(0, node.cornerWidth-node.rootindex.width)/2
    local h = -node.rootindex.depth-node.rootHeight+node.cornerHeight
    drawTranslatedNode(node.rootindex, output, w, h)
  end
end

draw_msub = function(node, output) drawScripts(node, output) end 
draw_msup = function(node, output) drawScripts(node, output) end 
draw_msubsup = function(node, output) drawScripts(node, output) end 
draw_mmultiscripts = function(node, output) drawScripts(node, output) end

drawScripts = function(node, output)
  if #node.children<2 then
    draw_mrow(node)
    return 
  end

  local subY = node.subShift
  local superY = -node.superShift

  local adjustment = function(script)
    if script.alignToAxis then
      return script:axis()
    else
      return 0
    end
  end

  drawBox(node, output)
  local offset = 0
  for i = 1,#node.prewidths do
    offset = offset+node.prewidths[i]
    if i<=#node.presubscripts then
      local presubscript = node.presubscripts[i]
      drawTranslatedNode(presubscript, output,
        offset-presubscript.width, subY-adjustment(presubscript))
    end
    if i<=#node.presuperscripts then
      local presuperscript = node.presuperscripts[i]
      drawTranslatedNode(presuperscript, output,
        offset-presuperscript.width, superY-adjustment(presuperscript))
    end
  end

  drawTranslatedNode(node.base, output, offset, 0)
  offset = offset+node.base.width

  for i = 1,#node.postwidths do
    if i<=#node.subscripts then
      local subscript = node.subscripts[i]
      drawTranslatedNode(subscript, output,
        offset, subY-adjustment(subscript))
    end
    if i<=#node.superscripts then
      local superscript = node.superscripts[i]
      drawTranslatedNode(superscript, output,
        offset, superY-adjustment(superscript))
    end
    offset = offset+node.postwidths[i]
  end
end

draw_munder = function(node, output) drawLimits(node, output) end 
draw_mover = function(node, output) drawLimits(node, output) end 
draw_munderover = function(node, output) drawLimits(node, output) end

drawLimits = function(node, output)
  if #node.children<2 then
    draw_mrow(node)
    return 
  end
  if node.core.moveLimits then
    drawScripts(node, output)
    return 
  end

  drawBox(node, output)
  drawTranslatedNode(node.base, output,
    (node.width-node.base.width)/2, 0)
  if node.underscript ~= nil then
    drawTranslatedNode(node.underscript, output,
      (node.width-node.underscript.width)/2,
      node.depth-node.underscript.depth)
  end
  if node.overscript ~= nil then
    drawTranslatedNode(node.overscript, output,
      (node.width-node.overscript.width)/2,
      node.overscript.height-node.height)
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

  -- Draw cells
  local vshift = -node.height+node.framespacings[2]
  for r = 1,#node.rows do
    local row = node.rows[r]
    vshift = vshift+row.height
    local hshift = node.framespacings[1]
    for c = 1,#row.cells do
      local column = node.columns[c]
      local cell = row.cells[c]
      if cell ~= nil and cell.content ~= nil then
        -- Calculate horizontal alignment
        local cellWidth
        if cell.colspan>1 then
          cellWidth = PYLUA.sum(PYLUA.collect(PYLUA.slice(node.columns, c, c+cell.colspan), function(x) return x.width end))
          cellWidth = cellWidth+PYLUA.sum(PYLUA.collect(PYLUA.slice(node.columns, c, c+cell.colspan-1), function(x) return x.spaceAfter end))
        else
          cellWidth = column.width
        end
        local hadjust = (cellWidth-cell.content.width)*alignKeywords[cell.halign] or 0.5

        -- Calculate vertical alignment.
        local cellHeight
        if cell.rowspan>1 then
          cellHeight = PYLUA.sum(PYLUA.collect(PYLUA.slice(node.rows, r, r+cell.rowspan), function(x) return x.height+x.depth end))
          cellHeight = cellHeight+PYLUA.sum(PYLUA.collect(PYLUA.slice(node.rows, r, r+cell.rowspan-1), function(x) return x.spaceAfter end))
        else
          cellHeight = row.height+row.depth
        end
        local vadjust
        if cell.valign=='top' then
          vadjust = cell.content.height-row.height
        elseif cell.valign=='bottom' then
          vadjust = cellHeight-row.height-cell.content.depth
        elseif PYLUA.op_in(cell.valign, {'axis', 'baseline'}) and cell.rowspan==1 then
          vadjust = -cell.vshift  -- calculated in the measurer
        else  -- the rest of cases is centered
          vadjust = (cell.content.height-cell.content.depth+cellHeight)/2-row.height
        end
        drawTranslatedNode(cell.content, output, hshift+hadjust, vshift+vadjust)
      end
      hshift = hshift+column.width+column.spaceAfter
    end
    vshift = vshift+row.depth+row.spaceAfter
  end

  -- Draw frame
  local drawBorder = function(x1, y1, x2, y2, linestyle)
    if linestyle == nil then
      return 
    end
    if x1==x2 and y1==y2 then
      return 
    end
    local extrastyle = nil
    if linestyle=='dashed' then
      local linelength = math.sqrt(math.pow(x1-x2, 2)+math.pow(y1-y2, 2))
      local dashoffset = 5-PYLUA.mod(linelength/node.lineWidth+3, 10)/2
      extrastyle = {
        ['stroke-dasharray']=string.format('%f,%f', {node.lineWidth*7, node.lineWidth*3}),
        ['stroke-dashoffset']=string.format('%f', node.lineWidth*dashoffset),
      }
    end
    drawLine(output, node.color, node.lineWidth, x1, y1, x2, y2, extrastyle)
  end

  local x1 = node.lineWidth/2
  local y1 = node.lineWidth/2-node.height
  local x2 = node.width-node.lineWidth/2
  local y2 = node.depth-node.lineWidth/2

  drawBorder(x1, y1, x1, y2, node.framelines[1])
  drawBorder(x2, y1, x2, y2, node.framelines[1])
  drawBorder(x1, y1, x2, y1, node.framelines[2])
  drawBorder(x1, y2, x2, y2, node.framelines[2])

  -- Draw intermediate lines
  -- First, let's make a grid
  local hshift = node.framespacings[1]
  local hoffsets = {}
  for c = 1,#node.columns do
    local spacing = node.columns[c].spaceAfter
    hshift = hshift+node.columns[c].width
    table.insert(hoffsets, hshift+spacing/2)
    hshift = hshift+spacing
  end
  hoffsets[#hoffsets] = x2

  local vshift = -node.height+node.framespacings[2]
  local voffsets = {}
  for r = 1,#node.rows do
    local spacing = node.rows[r].spaceAfter
    vshift = vshift+node.rows[r].height+node.rows[r].depth
    table.insert(voffsets, vshift+spacing/2)
    vshift = vshift+spacing
  end
  voffsets[#voffsets] = y2

  local vspans = {}
  for r = 1,#node.rows-1 do
    local row = node.rows[r]
    if row.lineAfter == nil then
      goto continue
    end

    for c = 1,#row.cells do
      local cell = row.cells[c]
      if cell ~= nil and cell.content ~= nil then
        for j = c, c+cell.colspan do
          vspans[j] = cell.rowspan
        end
      end
    end
    for i = 1,node.columns do
      vspans[i] = math.max(0, (vspans[i] or 0)-1)
    end

    local lineY = voffsets[r]
    local startX = x1
    local endX = x1
    for c = 1,#node.columns do
      if (vspans[c] or 0)>0 then
        drawBorder(startX, lineY, endX, lineY, row.lineAfter)
        startX = hoffsets[c]
      end
      endX = hoffsets[c]
    end
    drawBorder(startX, lineY, endX, lineY, row.lineAfter)
    ::continue::
  end

  local hspans = {}
  for c = 1,#node.columns-1 do
    local column = node.columns[c]
    if column.lineAfter == nil then
      goto continue
    end

    for r = 1,#node.rows do
      local row = node.rows[r]
      if #row.cells<c then
        goto continue
      end
      local cell = row.cells[c]
      if cell ~= nil and cell.content ~= nil then
        for j = r, r+cell.rowspan do
          hspans[j] = cell.colspan
        end
      end
      ::continue::
    end
    for i = 1,#node.rows do
      hspans[i] = math.max(0, (hspans[i] or 0)-1)
    end

    local lineX = hoffsets[c]
    local startY = y1
    local endY = y1
    for r = 1,#node.rows do
      if hspans[r]>0 then
        drawBorder(lineX, startY, lineX, endY, column.lineAfter)
        startY = voffsets[r]
      end
      endY = voffsets[r]
    end
    drawBorder(lineX, startY, lineX, endY, column.lineAfter)
    ::continue::
  end
end

drawBox = function(node, output, borderWidth, borderColor, borderRadius)
  borderWidth = borderWidth or 0
  borderRadius = borderRadius or 0
  local background = getBackground(node)
  if background=='none' and borderWidth==0 then
    return 
  end
  borderColor = borderColor or node.color

  local attrs = {
    fill=background,
    stroke='none',
    x=string.format('%f', borderWidth/2),
    y=string.format('%f', borderWidth/2-node.height),
    width=string.format('%f', node.width-borderWidth),
    height=string.format('%f', node.height+node.depth-borderWidth),
  }
  if borderWidth~=0 and borderColor ~= nil then
    attrs['stroke'] = borderColor
    attrs['stroke-width'] = string.format('%f', borderWidth)
    if borderRadius~=0 then
      attrs['rx'] = string.format('%f', borderRadius)
      attrs['ry'] = string.format('%f', borderRadius)
    end
  end

  startSVGElement(output, 'rect', attrs)
  endSVGElement(output, 'rect')
end

drawLine = function(output, color, width, x1, y1, x2, y2, strokeattrs)
  local attrs = {
    fill='none',
    stroke=color,
    ['stroke-width']=string.format('%f', width),
    ['stroke-linecap']='square',
    ['stroke-dasharray']='none',
    x1=string.format('%f', x1),
    y1=string.format('%f', y1),
    x2=string.format('%f', x2),
    y2=string.format('%f', y2),
  }
  if strokeattrs ~= nil then
    PYLUA.update(attrs, strokeattrs)
  end

  startSVGElement(output, 'line', attrs)
  endSVGElement(output, 'line')
end

drawTranslatedNode = function(node, output, dx, dy)
  if dx~=0 or dy~=0 then
    startSVGElement(output, 'g', {
      transform=string.format('translate(%f, %f)', dx, dy)
    })
  end
  node:draw(output)
  if dx~=0 or dy~=0 then
    endSVGElement(output, 'g')
  end
end

drawSVGText = function(node, output)
  drawBox(node, output)
  local fontfamilies = PYLUA.collect(node:fontpool(), function(x) if x.used then return x.family end end)
  if #fontfamilies==0 then
    fontfamilies = node.fontfamilies
  end
  local attrs = {
    fill=node.color,
    ['font-family']=table.concat(fontfamilies, ', '),
    ['font-size']=string.format('%f', node.fontSize),
    ['text-anchor']='middle',
    x=string.format('%f', (node.width+node.leftBearing-node.rightBearing)/2/node.textStretch),
    y=string.format('%f', -node.textShift),
  }
  if node.fontweight~='normal' then
    attrs['font-weight'] = node.fontweight
  end
  if node.fontstyle~='normal' then
    attrs['font-style'] = node.fontstyle
  end
  if node.textStretch~=1 then
    attrs['transform'] = string.format('scale(%f, 1)', node.textStretch)
  end

  for oldchar, newchar in pairs(mathnode.specialChars) do
    node.text = PYLUA.replace(node.text, oldchar, newchar)
  end

  startSVGElement(output, 'text', attrs)
  output:characters(node.text)
  endSVGElement(output, 'text')
end

getAlign = function(node, attrName)
  local attrValue = node:getProperty(attrName, 'center')
  if alignKeywords[attrValue] == nil then
    node:error('Bad value %s for %s', attrValue, attrName)
  end
  return alignKeywords[attrValue] or 0.5
end

drawBoxEnclosure = function(node, output, roundRadius)
  roundRadius = roundRadius or 0
  drawBox(node, output, node.borderWidth, nil, roundRadius)
  drawTranslatedNode(node.base, output, (node.width-node.base.width)/2, 0)
end

drawCircleEnclosure = function(node, output)
  local background = getBackground(node)

  local r = (node.width-node.borderWidth)/2
  local cx = node.width/2
  local cy = (node.depth-node.height)/2

  local attrs = {
    fill=background,
    stroke=node.color,
    ['stroke-width']=string.format('%f', node.borderWidth),
    cx=string.format('%f', cx),
    cy=string.format('%f', cy),
    r=string.format('%f', r),
  }
  startSVGElement(output, 'circle', attrs)
  endSVGElement(output, 'circle')

  drawTranslatedNode(node.base, output, (node.width-node.base.width)/2, 0)
end

drawBordersEnclosure = function(node, output)
  local drawBorder = function(x1, y1, x2, y2)
    drawLine(output, node.color, node.borderWidth, x1, y1, x2, y2)
  end

  drawBox(node, output)

  local x1 = node.borderWidth/2
  local y1 = node.borderWidth/2-node.height
  local x2 = node.width-node.borderWidth/2
  local y2 = node.depth-node.borderWidth/2

  local left, right, top, bottom = table.unpack(node.decorationData)
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

  local offset = 0
  if left then
    offset = node.width-node.base.width
    if right then
      offset = offset/2
    end
  end
  drawTranslatedNode(node.base, output, offset, 0)
end

drawStrikesEnclosure = function(node, output)
  local drawStrike = function(x1, y1, x2, y2)
    drawLine(output, node.color, node.borderWidth, x1, y1, x2, y2)
  end

  drawBox(node, output)
  node.base:draw(output)

  local mid_x = node.width/2
  local mid_y = (node.depth-node.height)/2

  local horiz, vert, updiag, downdiag = table.unpack(node.decorationData)
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
  for _, attr in ipairs({'mathbackground', 'background-color', 'background'}) do
    local value = node.attributes[attr]
    if value ~= nil then
      if value=='transparent' then
        return 'none'
      else
        return value
      end
    end
  end
  return 'none'
end

return _ENV
