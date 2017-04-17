-- Table-related formatting functions.
-- 
-- This module contains functions called from measurers.py to format tables.
local sys = require('sys')
local mathnode = require('mathnode')

getByIndexOrLast = function(lst, idx)
  if idx<len(lst) then
    return lst[idx]
  else
    return lst[0]
  end
end

CellDescriptor = PYLUA.class() {
  -- Descriptor of a single cell in a table

  __init__ = function(self, content, halign, valign, colspan, rowspan)
    self.content = content
    self.halign = halign
    self.valign = valign
    self.colspan = colspan
    self.rowspan = rowspan
  end
  ;
}


ColumnDescriptor = PYLUA.class() {
  -- Descriptor of a single column in a table

  __init__ = function(self)
    self.auto = true
    self.fit = false
    self.width = 0
    self.spaceAfter = 0
    self.lineAfter = nil
  end
  ;
}


RowDescriptor = PYLUA.class() {
  -- Descriptor of a single row in a table; contains cells

  __init__ = function(self, node, cells, rowalign, columnaligns, busycells)
    self.alignToAxis = rowalign=='axis'
    self.height = 0
    self.depth = 0
    self.spaceAfter = 0
    self.lineAfter = nil
    self.cells = {}
    for _, c in ipairs(cells) do
len(busycells)>len(self.cells) and busycells[len(self.cells)]>0      self.cells.append(nil)
      halign = getByIndexOrLast(columnaligns, len(self.cells))
      valign = rowalign
      colspan = 1
      rowspan = 1
      if c.elementName=='mtd' then
        halign = c.attributes.get('columnalign', halign)
        valign = c.attributes.get('rowalign', valign)
        colspan = node.parseInt(c.attributes.get('colspan', '1'))
        rowspan = node.parseInt(c.attributes.get('rowspan', '1'))
      end
len(self.cells)>=len(node.columns)      node.columns.append(ColumnDescriptor())
      self.cells.append(CellDescriptor(c, halign, valign, colspan, rowspan))
      for _, i in ipairs(range(1, colspan)) do
        self.cells.append(nil)
      end
len(self.cells)>len(node.columns)      node.columns.append(ColumnDescriptor())
    end
  end
  ;
}


arrangeCells = function(node)
  node.rows = {}
  node.columns = {}
  busycells = {}
  table_rowaligns = node.getListProperty('rowalign')
  table_columnaligns = node.getListProperty('columnalign')
  for _, ch in ipairs(node.children) do
    rowalign = getByIndexOrLast(table_rowaligns, len(node.rows))
    row_columnaligns = table_columnaligns
    if ch.elementName=='mtr' or ch.elementName=='mlabeledtr' then
      cells = ch.children
      rowalign = ch.attributes.get('rowalign', rowalign)
      if PYLUA.op_in('columnalign', ch.attributes.keys()) then
        columnaligns = node.getListProperty('columnalign', ch.attributes.get('columnalign'))
      end
    else
      cells = {ch}
    end
    row = RowDescriptor(node, cells, rowalign, row_columnaligns, busycells)
    node.rows.append(row)
    busycells = PYLUA.COMPREHENSION()
len(busycells)<len(row.cells)    busycells.append(0)
    for _, i in ipairs(range(len(row.cells))) do
      cell = row.cells[i]
      if PYLUA.op_is(cell, nil) then
        goto continue
      end
      if cell.rowspan>1 then
        for _, j in ipairs(range(i, i+cell.colspan)) do
          busycells[j] = cell.rowspan-1
        end
      end
    end
  end
max(busycells)>0  rowalign = getByIndexOrLast(table_rowaligns, len(node.rows))
  node.rows.append(RowDescriptor(node, {}, rowalign, table_columnaligns, busycells))
  busycells = PYLUA.COMPREHENSION()
end

arrangeLines = function(node)
  spacings = map(node.parseLength, node.getListProperty('rowspacing'))
  lines = node.getListProperty('rowlines')
  for _, i in ipairs(range(len(node.rows)-1)) do
    node.rows[i].spaceAfter = getByIndexOrLast(spacings, i)
    line = getByIndexOrLast(lines, i)
    if line~='none' then
      node.rows[i].lineAfter = line
      node.rows[i].spaceAfter = node.rows[i].spaceAfter+node.lineWidth
    end
  end
  spacings = map(node.parseSpace, node.getListProperty('columnspacing'))
  lines = node.getListProperty('columnlines')
  for _, i in ipairs(range(len(node.columns)-1)) do
    node.columns[i].spaceAfter = getByIndexOrLast(spacings, i)
    line = getByIndexOrLast(lines, i)
    if line~='none' then
      node.columns[i].lineAfter = line
      node.columns[i].spaceAfter = node.columns[i].spaceAfter+node.lineWidth
    end
  end
  node.framespacings = {0, 0}
  node.framelines = {nil, nil}
  spacings = map(node.parseSpace, node.getListProperty('framespacing'))
  lines = node.getListProperty('frame')
  for _, i in ipairs(range(2)) do
    line = getByIndexOrLast(lines, i)
    if line~='none' then
      node.framespacings[i] = getByIndexOrLast(spacings, i)
      node.framelines[i] = line
    end
  end
end

calculateColumnWidths = function(node)
  fullwidthattr = node.attributes.get('width', 'auto')
  if fullwidthattr=='auto' then
    fullwidth = nil
  else
    fullwidth = node.parseLength(fullwidthattr)
    if fullwidth<=0 then
      fullwidth = nil
    end
  end
  columnwidths = node.getListProperty('columnwidth')
  for _, i in ipairs(range(len(node.columns))) do
    column = node.columns[i]
    attr = getByIndexOrLast(columnwidths, i)
    if PYLUA.op_in(attr, {'auto', 'fit'}) then
      column.fit = attr=='fit'
    elseif attr.endswith('%') then
      if PYLUA.op_is(fullwidth, nil) then
        node.error(PYLUA.mod('Percents in column widths supported only in tables with explicit width; width of column %d treated as \'auto\'', i+1))
      else
        value = node.parseFloat(PYLUA.slice(attr, nil, -1))
        if value and value>0 then
          column.width = fullwidth*value/100
          column.auto = false
        end
      end
    else
      column.width = node.parseSpace(attr)
      column.auto = false
    end
  end
  for _, r in ipairs(node.rows) do
    for _, i in ipairs(range(len(r.cells))) do
      c = r.cells[i]
      if PYLUA.op_is(c, nil) or PYLUA.op_is(c.content, nil) or c.colspan>1 then
        goto continue
      end
      column = node.columns[i]
      if column.auto then
        column.width = max(column.width, c.content.width)
      end
    end
  end
true  adjustedColumns = {}
  adjustedWidth = 0
  for _, r in ipairs(node.rows) do
    for _, i in ipairs(range(len(r.cells))) do
      c = r.cells[i]
      if PYLUA.op_is(c, nil) or PYLUA.op_is(c.content, nil) or c.colspan==1 then
        goto continue
      end
      columns = PYLUA.slice(node.columns, i, i+c.colspan)
      autoColumns = PYLUA.COMPREHENSION()
      if len(autoColumns)==0 then
        goto continue
      end
      fixedColumns = PYLUA.COMPREHENSION()
      fixedWidth = sum(PYLUA.COMPREHENSION())
      if len(fixedColumns)>0 then
        fixedWidth = fixedWidth+sum(PYLUA.COMPREHENSION())
      end
      autoWidth = sum(PYLUA.COMPREHENSION())
      if c.content.width<=fixedWidth+autoWidth then
        goto continue
      end
      requiredWidth = c.content.width-fixedWidth
      unitWidth = requiredWidth/len(autoColumns)
true      oversizedColumns = PYLUA.COMPREHENSION()
      if len(oversizedColumns)==0 then
      end
      autoColumns = PYLUA.COMPREHENSION()
      if len(autoColumns)==0 then
      end
      requiredWidth = requiredWidth-sum(PYLUA.COMPREHENSION())
      unitWidth = requiredWidth/len(autoColumns)
      if len(autoColumns)==0 then
        goto continue
      end
      if unitWidth>adjustedWidth then
        adjustedWidth = unitWidth
        adjustedColumns = autoColumns
      end
    end
  end
  if len(adjustedColumns)==0 then
  end
  for _, col in ipairs(adjustedColumns) do
    col.width = adjustedWidth
  end
  if node.getProperty('equalcolumns')=='true' then
    globalWidth = max(PYLUA.COMPREHENSION())
    for _, col in ipairs(node.columns) do
      if col.auto then
        col.width = globalWidth
      end
    end
  end
  if PYLUA.op_is_not(fullwidth, nil) then
    delta = fullwidth
    delta = delta-sum(PYLUA.COMPREHENSION())
    delta = delta-sum(PYLUA.COMPREHENSION())
    delta = delta-2*node.framespacings[1]
    if delta~=0 then
      sizableColumns = PYLUA.COMPREHENSION()
      if len(sizableColumns)==0 then
        sizableColumns = PYLUA.COMPREHENSION()
      end
      if len(sizableColumns)==0 then
        node.error('Overconstrained table layout: explicit table width specified, but no column has automatic width; table width attribute ignored')
      else
        delta = delta/len(sizableColumns)
        for _, col in ipairs(sizableColumns) do
          col.width = col.width+delta
        end
      end
    end
  end
end

calculateRowHeights = function(node)
  commonAxis = node.axis()
  for _, r in ipairs(node.rows) do
    r.height = 0
    r.depth = 0
    for _, c in ipairs(r.cells) do
      if PYLUA.op_is(c, nil) or PYLUA.op_is(c.content, nil) or c.rowspan~=1 then
        goto continue
      end
      cellAxis = c.content.axis()
      c.vshift = 0
      if c.valign=='baseline' then
        if r.alignToAxis then
          cell.vshift = cell.vshift-commonAxis
        end
        if c.content.alignToAxis then
          c.vshift = c.vshift+cellAxis
        end
      elseif c.valign=='axis' then
        if  not r.alignToAxis then
          c.vshift = c.vshift+commonAxis
        end
        if  not c.content.alignToAxis then
          c.vshift = c.vshift-cellAxis
        end
      else
        c.vshift = (r.height-r.depth-c.content.height+c.content.depth)/2
      end
      r.height = max(r.height, c.content.height+c.vshift)
      r.depth = max(r.depth, c.content.depth-c.vshift)
    end
  end
true  adjustedRows = {}
  adjustedSize = 0
  for _, i in ipairs(range(len(node.rows))) do
    r = node.rows[i]
    for _, c in ipairs(r.cells) do
      if PYLUA.op_is(c, nil) or PYLUA.op_is(c.content, nil) or c.rowspan==1 then
        goto continue
      end
      rows = PYLUA.slice(node.rows, i, i+c.rowspan)
      requiredSize = c.content.height+c.content.depth
      requiredSize = requiredSize-sum(PYLUA.COMPREHENSION())
      fullSize = sum(PYLUA.COMPREHENSION())
      if fullSize>=requiredSize then
        goto continue
      end
      unitSize = requiredSize/len(rows)
true      oversizedRows = PYLUA.COMPREHENSION()
      if len(oversizedRows)==0 then
      end
      rows = PYLUA.COMPREHENSION()
      if len(rows)==0 then
      end
      requiredSize = requiredSize-sum(PYLUA.COMPREHENSION())
      unitSize = requiredSize/len(rows)
      if len(rows)==0 then
        goto continue
      end
      if unitSize>adjustedSize then
        adjustedSize = unitSize
        adjustedRows = rows
      end
    end
  end
  if len(adjustedRows)==0 then
  end
  for _, r in ipairs(adjustedRows) do
    delta = (adjustedSize-r.height-r.depth)/2
    r.height = r.height+delta
    r.depth = r.depth+delta
  end
  if node.getProperty('equalrows')=='true' then
    maxvsize = max(PYLUA.COMPREHENSION())
    for _, r in ipairs(node.rows) do
      delta = (maxvsize-r.height-r.depth)/2
      r.height = r.height+delta
      r.depth = r.depth+delta
    end
  end
end

getAlign = function(node)
  alignattr = node.getProperty('align').strip()
  if len(alignattr)==0 then
    alignattr = mathnode.globalDefaults['align']
  end
  splitalign = alignattr.split()
  alignType = splitalign[1]
  if len(splitalign)==1 then
    alignRow = nil
  else
    alignRow = node.parseInt(splitalign[2])
    if alignrownumber==0 then
      node.error('Alignment row number cannot be zero')
      alignrownumber = nil
    elseif alignrownumber>len(node.rows) then
      node.error('Alignment row number cannot exceed row count')
      alignrownumber = len(node.rows)
    elseif alignrownumber<-len(node.rows) then
      node.error('Negative alignment row number cannot exceed row count')
      alignrownumber = 1
    elseif alignrownumber<0 then
      alignrownumber = len(node.rows)-alignrownumber+1
    end
  end
  return alignType, alignRow
end
