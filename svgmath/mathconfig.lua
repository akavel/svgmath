-- Configuration for MathML-to-SVG formatter.
local os = require('os')
local sys = require('sys')
local sax = require('xml').sax
local AFMMetric = require('fonts.afm').AFMMetric
local TTFMetric = require('fonts.ttf').TTFMetric
local FontFormatError = require('fonts.metric').FontFormatError

MathConfig = PYLUA.class(sax.ContentHandler) {
  -- Configuration for MathML-to-SVG formatter.
  --     
  --     Implements SAX ContentHandler for ease of reading from file.

  __init__ = function(self, configfile)
    self.verbose = false
    self.debug = {}
    self.currentFamily = nil
    self.fonts = { }
    self.variants = { }
    self.defaults = { }
    self.opstyles = { }
    self.fallbackFamilies = {}
    -- PYLUA.FIXME: TRY:
    local parser = sax.make_parser()
    parser.setContentHandler(self)
    parser.setFeature(sax.handler.feature_namespaces, 0)
    parser.parse(configfile)
    -- PYLUA.FIXME: EXCEPT sax.SAXException xcpt:
      io.write('Error parsing configuration file ', configfile, ': ', xcpt.getMessage(), '\n')
      sys.exit(1)
  end
  ;

  startElement = function(self, name, attributes)
    if name=='config' then
      self.verbose = attributes.get('verbose')=='true'
      self.debug = attributes.get('debug', '').replace(',', ' ').split()
    elseif name=='defaults' then
      self.defaults.update(attributes)
    elseif name=='fallback' then
      local familyattr = attributes.get('family', '')
      self.fallbackFamilies = PYLUA.COMPREHENSION()
    elseif name=='family' then
      self.currentFamily = attributes.get('name', '')
      self.currentFamily = PYLUA.str_maybe('').join(self.currentFamily.lower().split())
    elseif name=='font' then
      local weight = attributes.get('weight', 'normal')
      local style = attributes.get('style', 'normal')
      local fontfullname = self.currentFamily
      if weight~='normal' then
        fontfullname = fontfullname+' '+weight
      end
      if style~='normal' then
        fontfullname = fontfullname+' '+style
      end
      -- PYLUA.FIXME: TRY:
      if PYLUA.op_in('afm', PYLUA.keys(attributes)) then
        local fontpath = attributes.get('afm')
        local metric = AFMMetric(fontpath, attributes.get('glyph-list'), sys.stderr)
      elseif PYLUA.op_in('ttf', PYLUA.keys(attributes)) then
        fontpath = attributes.get('ttf')
        metric = TTFMetric(fontpath, sys.stderr)
      else
        sys.stderr.write('Bad record in configuration file: font is neither AFM nor TTF\n')
        sys.stderr.write(PYLUA.mod('Font entry for \'%s\' ignored\n', fontfullname))
        return 
      end
      -- PYLUA.FIXME: EXCEPT FontFormatError err:
        sys.stderr.write(PYLUA.mod('Invalid or unsupported file format in \'%s\': %s\n', {fontpath, err.message}))
        sys.stderr.write(PYLUA.mod('Font entry for \'%s\' ignored\n', fontfullname))
        return 
      -- PYLUA.FIXME: EXCEPT IOError:
        local message = sys.exc_info()[2]
        sys.stderr.write(PYLUA.mod('I/O error reading font file \'%s\': %s\n', {fontpath, str(message)}))
        sys.stderr.write(PYLUA.mod('Font entry for \'%s\' ignored\n', fontfullname))
        return 
      self.fonts[weight+' '+style+' '+self.currentFamily] = metric
    elseif name=='mathvariant' then
      local variantattr = attributes.get('name')
      familyattr = attributes.get('family', '')
      local splitFamily = PYLUA.COMPREHENSION()
      local weightattr = attributes.get('weight', 'normal')
      local styleattr = attributes.get('style', 'normal')
      self.variants[variantattr] = {weightattr, styleattr, splitFamily}
    elseif name=='operator-style' then
      local opname = attributes.get('operator')
      if opname then
        local styling = { }
        styling.update(attributes)
styling['operator']        self.opstyles[opname] = styling
      else
        sys.stderr.write('Bad record in configuration file: operator-style with no operator attribute\n')
      end
    end
  end
  ;

  endElement = function(self, name)
    if name=='family' then
      self.currentFamily = nil
    end
  end
  ;

  findfont = function(self, weight, style, family)
    -- Finds a metric for family+weight+style.
    weight = weight or 'normal'.strip()
    style = style or 'normal'.strip()
    family = PYLUA.str_maybe('').join(family or ''.lower().split())
    for _, w in ipairs({weight, 'normal'}) do
      for _, s in ipairs({style, 'normal'}) do
        local metric = self.fonts.get(w+' '+s+' '+family)
        if metric then
          return metric
        end
      end
    end
    return nil
  end
  ;
}


main = function()
  if len(sys.argv)==1 then
    local config = MathConfig(nil)
  else
    config = MathConfig(sys.argv[2])
  end
  io.write('Options:  verbose =', config.verbose, ' debug =', config.debug, '\n')
  io.write('Fonts:', '\n')
  for font, metric in pairs(config.fonts) do
    io.write('    ', font, '-->', metric.fontname, '\n')
  end
  io.write('Math variants:', '\n')
  for variant, value in pairs(config.variants) do
    io.write('    ', variant, '-->', value, '\n')
  end
  io.write('Defaults:', '\n')
  for attr, value in pairs(config.defaults) do
    io.write('    ', attr, '=', value, '\n')
  end
  io.write('Operator styling:', '\n')
  for opname, value in pairs(config.opstyles) do
    io.write('    ', repr(opname), ':', value, '\n')
  end
  io.write('Fallback font families:', config.fallbackFamilies, '\n')
end
if __name__=='__main__' then
  main()
end
