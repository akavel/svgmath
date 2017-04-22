-- Functions to format enclosures around MathML elements.
local sys = require('sys')
local math = require('math')
local mathnode = require('mathnode')

addRadicalEnclosure = function(node)
  node.lineWidth = node:nominalThinStrokeWidth()
  node.thickLineWidth = node:nominalThickStrokeWidth()
  node.gap = node:nominalLineGap()
  if  not node.displaystyle then
    node.gap = node.gap/2
  end
  node.rootHeight = math.max(node.base.height, node.base.ascender)
  node.rootHeight = math.max(node.rootHeight, node:nominalAscender())
  node.rootHeight = node.rootHeight+node.gap+node.lineWidth
  node.height = node.rootHeight
  node.alignToAxis = node.base.alignToAxis
  if node.alignToAxis then
    node.rootDepth = math.max(0, node.base.depth-node.lineWidth)
    node.depth = math.max(node.base.depth, node.rootDepth+node.lineWidth)
  else
    node.rootDepth = 0
    node.depth = math.max(node.base.depth, node.lineWidth)
  end
  node.rootWidth = (node.rootHeight+node.rootDepth)*0.6
  node.cornerWidth = node.rootWidth*0.9-node.gap-node.lineWidth/2
  node.cornerHeight = (node.rootHeight+node.rootDepth)*0.5-node.gap-node.lineWidth/2
  node.width = node.base.width+node.rootWidth+2*node.gap
  node.ascender = node.height
  node.descender = node.base.descender
  node.leftspace = node.lineWidth
  node.rightspace = node.lineWidth
end

addBoxEnclosure = function(node)
  node.width = node.width+2*node.hdelta
  node.height = node.height+node.vdelta
  node.depth = node.depth+node.vdelta
  node.ascender = node.base.ascender
  node.descender = node.base.descender
end

addCircleEnclosure = function(node)
  local d = math.sqrt(math.pow(node.width, 2)+math.pow(node.height, 2))
  d = math.max(d, node.width+2*node.hdelta)
  d = math.max(d, node.height+node.depth+2*node.vdelta)
  local cy = (node.height-node.depth)/2
  node.width = d
  node.height = d/2+cy
  node.depth = d/2-cy
  node.ascender = node.base.ascender
  node.descender = node.base.descender
end

addBorderEnclosure = function(node, borders)
  if borders[1] then
    node.width = node.width+node.hdelta
  end
  if borders[2] then
    node.width = node.width+node.hdelta
  end
  if borders[3] then
    node.height = node.height+node.vdelta
  end
  if borders[4] then
    node.depth = node.depth+node.vdelta
  end
  node.decorationData = borders
  node.ascender = node.base.ascender
  node.descender = node.base.descender
end
