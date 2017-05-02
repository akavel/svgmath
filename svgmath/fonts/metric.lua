
local math, string, table, require = math, string, table, require
local pairs, ipairs = pairs, ipairs
local _ENV = {package=package}
local PYLUA = require('PYLUA')


CharMetric = PYLUA.class() {

  __init__ = function(self, glyphname, codes, width, bbox, _kw_extra)
    if PYLUA.is_a(glyphname, PYLUA.keywords) then
      local kw = glyphname
      glyphname = codes or kw.glyphname
      codes = width or kw.codes
      width = bbox or kw.width
      bbox = _kw_extra or kw.bbox
    end
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
    -- Get Ascender from the 'd' glyph
    if self.ascender == nil then
      local cm = self.chardata[PYLUA.ord('d')]
      if cm ~= nil then
        self.descender = cm.bbox[4]
      else
        self.ascender = 0.7
      end
    end

    -- Get Descender from the 'p' glyph
    if self.descender == nil then
      cm = self.chardata[PYLUA.ord('p')]
      if cm ~= nil then
        self.descender = cm.bbox[2]
      else
        self.descender = -0.2
      end
    end

    -- Get CapHeight from the 'H' glyph
    if self.capheight == nil then
      cm = self.chardata[PYLUA.ord('H')]
      if cm ~= nil then
        self.capheight = cm.bbox[4]
      else
        self.capheight = self.ascender
      end
    end

    -- Get XHeight from the 'x' glyph
    if self.xheight == nil then
      cm = self.chardata[PYLUA.ord('x')]
      if cm ~= nil then
        self.xheight = cm.bbox[4]
      else
        self.xheight = 0.45
      end
    end

    -- Determine the vertical position of the mathematical axis -
    -- that is, the quote to which fraction separator lines are raised.
    -- We try to deduce it from the median of the following characters:
    -- "equal", "minus", "plus", "less", "greater", "periodcentered")
    -- Default is CapHeight / 2, or 0.3 if there's no CapHeight.
    if self.axisposition == nil then
      self.axisposition = self.capheight/2
      for _, ch in ipairs({PYLUA.ord('+'), 8722, PYLUA.ord('='), PYLUA.ord('<'), PYLUA.ord('>'), 183}) do
        cm = self.chardata[ch]
        if cm ~= nil then
          self.axisposition = (cm.bbox[2]+cm.bbox[4])/2
          break
        end
      end
    end

    -- Determine the dominant rule width for math        
    if self.underlinethickness ~= nil then
      self.rulewidth = self.underlinethickness
    else
      self.rulewidth = 0.05
      for _, ch in ipairs({8211, 8212, 8213, 8722, PYLUA.ord('-')}) do
        cm = self.chardata[ch]
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
      cm = self.chardata[PYLUA.ord('!')]
      if cm ~= nil then
        self.stdvw = cm.bbox[3]-cm.bbox[1]
      end
    end
    if self.stdvw == nil then
      cm = self.chardata[PYLUA.ord('.')]
      if cm ~= nil then
        self.stdvw = cm.bbox[3]-cm.bbox[1]
      else
        self.stdvw = 0.08
      end
    end

    -- Set rule gap
    if self.underlineposition ~= nil then
      self.vgap = -self.underlineposition
    else
      self.vgap = self.rulewidth*2
    end

    -- Set missing glyph to be a space    
    self.missingGlyph = self.chardata[PYLUA.ord(' ')] or self.chardata[160]
  end
  ;

  dump = function(self)
    PYLUA.print('FontName: ', self.fontname, '\n')
    PYLUA.print('FullName: ', self.fullname, '\n')
    PYLUA.print('FontFamily: ', self.family, '\n')
    PYLUA.print('Weight: ', self.weight, '\n')
    PYLUA.print('FontBBox: ')
    for _, x in ipairs(self.bbox) do
      PYLUA.print(x)
    end
    PYLUA.print('\n')
    PYLUA.print('CapHeight: ', self.capheight, '\n')
    PYLUA.print('XHeight: ', self.xheight, '\n')
    PYLUA.print('Ascender: ', self.ascender, '\n')
    PYLUA.print('Descender: ', self.descender, '\n')
    PYLUA.print('StdHW: ', self.stdhw, '\n')
    PYLUA.print('StdVW: ', self.stdvw, '\n')
    PYLUA.print('UnderlinePosition: ', self.underlineposition, '\n')
    PYLUA.print('UnderlineThickness: ', self.underlinethickness, '\n')
    PYLUA.print('ItalicAngle: ', self.italicangle, '\n')
    PYLUA.print('CharWidth: ', self.charwidth, '\n')
    PYLUA.print('MathematicalBaseline: ', self.axisposition, '\n')
    PYLUA.print('Character data: ', '\n')
    local chars = PYLUA.items(self.chardata)
    PYLUA.sort(chars, PYLUA.keywords{key=function(c) return c[1] end})
    for _, PYLUA_x in ipairs(chars) do
      local i, cm = table.unpack(PYLUA_x)
      if cm == nil then
        goto continue
      end
      PYLUA.print('    ', string.format('U+%04X', i), cm.name..':', '  W', cm.width, '  B')
      for _, x in ipairs(cm.bbox) do
        PYLUA.print(x)
      end
      PYLUA.print('\n')
      ::continue::
    end
  end
  ;
}

return _ENV
