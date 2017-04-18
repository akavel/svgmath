
CharMetric = PYLUA.class() {

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
  ;
}


FontFormatError = PYLUA.class(Exception) {

  __init__ = function(self, msg)
    self.message = msg
  end
  ;

  __str__ = function(self)
    return self.message
  end
  ;
}


FontMetric = PYLUA.class() {

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
  ;

  postParse = function(self)
    if self.ascender == nil then
      local cm = self.chardata.get(ord('d'))
      if cm ~= nil then
        self.descender = cm.bbox[4]
      else
        self.ascender = 0.7
      end
    end
    if self.descender == nil then
      cm = self.chardata.get(ord('p'))
      if cm ~= nil then
        self.descender = cm.bbox[2]
      else
        self.descender = -0.2
      end
    end
    if self.capheight == nil then
      cm = self.chardata.get(ord('H'))
      if cm ~= nil then
        self.capheight = cm.bbox[4]
      else
        self.capheight = self.ascender
      end
    end
    if self.xheight == nil then
      cm = self.chardata.get(ord('x'))
      if cm ~= nil then
        self.xheight = cm.bbox[4]
      else
        self.xheight = 0.45
      end
    end
    if self.axisposition == nil then
      for _, ch in ipairs({ord('+'), 8722, ord('='), ord('<'), ord('>'), 183}) do
        cm = self.chardata.get(ch)
        if cm ~= nil then
          self.axisposition = (cm.bbox[2]+cm.bbox[4])/2
          break
        end
      end
    end
    if self.underlinethickness ~= nil then
      self.rulewidth = self.underlinethickness
    else
      for _, ch in ipairs({8211, 8212, 8213, 8722, ord('-')}) do
        cm = self.chardata.get(ch)
        if cm ~= nil then
          self.rulewidth = cm.bbox[4]-cm.bbox[2]
          break
        end
      end
    end
    if self.stdhw == nil then
      self.stdhw = 0.03
    end
    if self.stdvw == nil and  not self.italicangle then
      cm = self.chardata.get(ord('!'))
      if cm ~= nil then
        self.stdvw = cm.bbox[3]-cm.bbox[1]
      end
    end
    if self.stdvw == nil then
      cm = self.chardata.get(ord('.'))
      if cm ~= nil then
        self.stdvw = cm.bbox[3]-cm.bbox[1]
      else
        self.stdvw = 0.08
      end
    end
    if self.underlineposition ~= nil then
      self.vgap = -self.underlineposition
    else
      self.vgap = self.rulewidth*2
    end
    self.missingGlyph = self.chardata.get(ord(' ')) or self.chardata.get(160)
  end
  ;

  dump = function(self)
    io.write('FontName: ', self.fontname, '\n')
    io.write('FullName: ', self.fullname, '\n')
    io.write('FontFamily: ', self.family, '\n')
    io.write('Weight: ', self.weight, '\n')
    io.write('FontBBox: ')
    for _, x in ipairs(self.bbox) do
      io.write(x)
    end
    io.write('\n')
    io.write('CapHeight: ', self.capheight, '\n')
    io.write('XHeight: ', self.xheight, '\n')
    io.write('Ascender: ', self.ascender, '\n')
    io.write('Descender: ', self.descender, '\n')
    io.write('StdHW: ', self.stdhw, '\n')
    io.write('StdVW: ', self.stdvw, '\n')
    io.write('UnderlinePosition: ', self.underlineposition, '\n')
    io.write('UnderlineThickness: ', self.underlinethickness, '\n')
    io.write('ItalicAngle: ', self.italicangle, '\n')
    io.write('CharWidth: ', self.charwidth, '\n')
    io.write('MathematicalBaseline: ', self.axisposition, '\n')
    io.write('Character data: ', '\n')
    local chars = self.chardata.items()
    chars.sort(PYLUA.keywords{key=cc[1]})
    for _, {i, cm} in ipairs(chars) do
      if cm == nil then
        goto continue
      end
      io.write('    ', PYLUA.mod('U+%04X', i), cm.name+':', '  W', cm.width, '  B')
      for _, x in ipairs(cm.bbox) do
        io.write(x)
      end
      io.write('\n')
    end
  end
  ;
}

