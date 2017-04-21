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
      PYLUA.print('Error parsing configuration file ', configfile, ': ', xcpt.getMessage(), '\n')
      sys.exit(1)
  end
  ;

  startElement = function(self, name, attributes)
    if name=='config' then
      self.verbose = attributes['verbose']=='true'
      self.debug = PYLUA.split(PYLUA.replace(attributes['debug'] or '', ',', ' '))
    elseif name=='defaults' then
      PYLUA.update(self.defaults, attributes)
    elseif name=='fallback' then
      local familyattr = attributes['family'] or ''
      self.fallbackFamilies = PYLUA.COMPREHENSION()
    elseif name=='family' then
      self.currentFamily = attributes['name'] or ''
      self.currentFamily = string.gsub(PYLUA.lower(self.currentFamily), '%s+', '')
    elseif name=='font' then
      local weight = attributes['weight'] or 'normal'
      local style = attributes['style'] or 'normal'
      local fontfullname = self.currentFamily
      if weight~='normal' then
        fontfullname = fontfullname+' '+weight
      end
      if style~='normal' then
        fontfullname = fontfullname+' '+style
      end
      -- PYLUA.FIXME: TRY:
      if PYLUA.op_in('afm', PYLUA.keys(attributes)) then
        local fontpath = attributes['afm']
        local metric = AFMMetric(fontpath, attributes['glyph-list'], sys.stderr)
      elseif PYLUA.op_in('ttf', PYLUA.keys(attributes)) then
        fontpath = attributes['ttf']
        metric = TTFMetric(fontpath, sys.stderr)
      else
        sys.stderr.write('Bad record in configuration file: font is neither AFM nor TTF\n')
        sys.stderr.write(string.format('Font entry for \'%s\' ignored\n', fontfullname))
        return 
      end
      -- PYLUA.FIXME: EXCEPT FontFormatError err:
        sys.stderr.write(string.format('Invalid or unsupported file format in \'%s\': %s\n', fontpath, err.message))
        sys.stderr.write(string.format('Font entry for \'%s\' ignored\n', fontfullname))
        return 
      -- PYLUA.FIXME: EXCEPT IOError:
        local message = sys.exc_info()[2]
        sys.stderr.write(string.format('I/O error reading font file \'%s\': %s\n', fontpath, tostring(message)))
        sys.stderr.write(string.format('Font entry for \'%s\' ignored\n', fontfullname))
        return 
      self.fonts[weight+' '+style+' '+self.currentFamily] = metric
    elseif name=='mathvariant' then
      local variantattr = attributes['name']
      familyattr = attributes['family'] or ''
      local splitFamily = PYLUA.COMPREHENSION()
      local weightattr = attributes['weight'] or 'normal'
      local styleattr = attributes['style'] or 'normal'
      self.variants[variantattr] = {weightattr, styleattr, splitFamily}
    elseif name=='operator-style' then
      local opname = attributes['operator']
      if opname then
        local styling = { }
        PYLUA.update(styling, attributes)
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
    weight = PYLUA.strip(weight or 'normal')
    style = PYLUA.strip(style or 'normal')
    family = string.gsub(PYLUA.lower(family or ''), '%s+', '')
    for _, w in ipairs({weight, 'normal'}) do
      for _, s in ipairs({style, 'normal'}) do
        local metric = self.fonts[w+' '+s+' '+family]
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
  if #sys.argv==1 then
    local config = MathConfig(nil)
  else
    config = MathConfig(sys.argv[2])
  end
  PYLUA.print('Options:  verbose =', config.verbose, ' debug =', config.debug, '\n')
  PYLUA.print('Fonts:', '\n')
  for font, metric in pairs(config.fonts) do
    PYLUA.print('    ', font, '-->', metric.fontname, '\n')
  end
  PYLUA.print('Math variants:', '\n')
  for variant, value in pairs(config.variants) do
    PYLUA.print('    ', variant, '-->', value, '\n')
  end
  PYLUA.print('Defaults:', '\n')
  for attr, value in pairs(config.defaults) do
    PYLUA.print('    ', attr, '=', value, '\n')
  end
  PYLUA.print('Operator styling:', '\n')
  for opname, value in pairs(config.opstyles) do
    PYLUA.print('    ', repr(opname), ':', value, '\n')
  end
  PYLUA.print('Fallback font families:', config.fallbackFamilies, '\n')
end
if __name__=='__main__' then
  main()
end
