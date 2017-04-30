-- Functions to format enclosures around MathML elements.

local math, string, table, require = math, string, table, require
local pairs, ipairs = pairs, ipairs
local _ENV = {package=package}
local PYLUA = require('PYLUA')

local mathnode = require('mathnode')

addRadicalEnclosure = function(node)
  -- The below is full of heuristics
  node.lineWidth = node:nominalThinStrokeWidth()
  node.thickLineWidth = node:nominalThickStrokeWidth()
  node.gap = node:nominalLineGap()
  if  not node.displaystyle then
    node.gap = node.gap/2  -- more compact style if inline
  end

  node.rootHeight = math.max(node.base.height, node.base.ascender)
  node.rootHeight = math.max(node.rootHeight, node:nominalAscender())
  node.rootHeight = node.rootHeight+node.gap+node.lineWidth
  node.height = node.rootHeight

  node.alignToAxis = node.base.alignToAxis
  -- Root extends to baseline for elements aligned on the baseline,
  -- and to the bottom for elements aligned on the axis. An extra
  -- line width is added to the depth, to account for radical sign 
  -- protruding below the baseline.
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
    node.width = node.width+node.hdelta  -- left
  end
  if borders[2] then
    node.width = node.width+node.hdelta  -- right
  end
  if borders[3] then
    node.height = node.height+node.vdelta  -- top
  end
  if borders[4] then
    node.depth = node.depth+node.vdelta  -- bottom
  end
  node.decorationData = borders
  node.ascender = node.base.ascender
  node.descender = node.base.descender
end

return _ENV
