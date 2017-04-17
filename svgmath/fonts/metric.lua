
__init__ = function(self, glyphname, codes, width, bbox)
  self.name = glyphname
  if codes then
    self.codes = codes
  else
    self.codes = {}
  end
  self.width = width
  self.bbox = bbox
end
Exception
__init__ = function(self, msg)
  self.message = msg
end

__str__ = function(self)
  return self.message
end

__init__ = function(self, log)
  self.fontname = nil
  self.fullname = nil
  self.family = nil
  self.weight = nil
  self.bbox = nil
  self.capheight = nil
  self.xheight = nil
  self.ascender = nil
  self.descender = nil
  self.stdhw = nil
  self.stdvw = nil
  self.underlineposition = nil
  self.underlinethickness = nil
  self.italicangle = nil
  self.charwidth = nil
  self.axisposition = nil
  self.chardata = { }
  self.missingGlyph = nil
  self.log = log
end

postParse = function(self)
  if pylua.op_is(self.ascender, nil) then
    cm = self.chardata.get(ord('d'))
    if pylua.op_is_not(cm, nil) then
      self.descender = cm.bbox[4]
    else
      self.ascender = 0.7
    end
  end
  if pylua.op_is(self.descender, nil) then
    cm = self.chardata.get(ord('p'))
    if pylua.op_is_not(cm, nil) then
      self.descender = cm.bbox[2]
    else
      self.descender = -0.2
    end
  end
  if pylua.op_is(self.capheight, nil) then
    cm = self.chardata.get(ord('H'))
    if pylua.op_is_not(cm, nil) then
      self.capheight = cm.bbox[4]
    else
      self.capheight = self.ascender
    end
  end
  if pylua.op_is(self.xheight, nil) then
    cm = self.chardata.get(ord('x'))
    if pylua.op_is_not(cm, nil) then
      self.xheight = cm.bbox[4]
    else
      self.xheight = 0.45
    end
  end
  if pylua.op_is(self.axisposition, nil) then
    for ch in ipairs({ord('+'), 8722, ord('='), ord('<'), ord('>'), 183}) do
      cm = self.chardata.get(ch)
      if pylua.op_is_not(cm, nil) then
        self.axisposition = (cm.bbox[2]+cm.bbox[4])/2
      end
    end
  end
  if pylua.op_is_not(self.underlinethickness, nil) then
    self.rulewidth = self.underlinethickness
  else
    for ch in ipairs({8211, 8212, 8213, 8722, ord('-')}) do
      cm = self.chardata.get(ch)
      if pylua.op_is_not(cm, nil) then
        self.rulewidth = cm.bbox[4]-cm.bbox[2]
      end
    end
  end
  if pylua.op_is(self.stdhw, nil) then
    self.stdhw = 0.03
  end
  if pylua.op_is(self.stdvw, nil) and  not self.italicangle then
    cm = self.chardata.get(ord('!'))
    if pylua.op_is_not(cm, nil) then
      self.stdvw = cm.bbox[3]-cm.bbox[1]
    end
  end
  if pylua.op_is(self.stdvw, nil) then
    cm = self.chardata.get(ord('.'))
    if pylua.op_is_not(cm, nil) then
      self.stdvw = cm.bbox[3]-cm.bbox[1]
    else
      self.stdvw = 0.08
    end
  end
  if pylua.op_is_not(self.underlineposition, nil) then
    self.vgap = -self.underlineposition
  else
    self.vgap = self.rulewidth*2
  end
  self.missingGlyph = self.chardata.get(ord(' ')) or self.chardata.get(160)
end

dump = function(self)
print('FontName: 'self.fontname)print('FullName: 'self.fullname)print('FontFamily: 'self.family)print('Weight: 'self.weight)print('FontBBox: ')  for x in ipairs(self.bbox) do
print(x)  end
print()print('CapHeight: 'self.capheight)print('XHeight: 'self.xheight)print('Ascender: 'self.ascender)print('Descender: 'self.descender)print('StdHW: 'self.stdhw)print('StdVW: 'self.stdvw)print('UnderlinePosition: 'self.underlineposition)print('UnderlineThickness: 'self.underlinethickness)print('ItalicAngle: 'self.italicangle)print('CharWidth: 'self.charwidth)print('MathematicalBaseline: 'self.axisposition)print('Character data: ')  chars = self.chardata.items()
  chars.sort(pylua.keywords{key=cc[1]})
  for i, cm in ipairs(chars) do
    if pylua.op_is(cm, nil) then
      goto continue
    end
print('    'pylua.mod('U+%04X', i)cm.name+':''  W'cm.width'  B')    for x in ipairs(cm.bbox) do
print(x)    end
print()  end
end
