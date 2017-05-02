-- Configuration for MathML-to-SVG formatter.

local math, string, table, io, arg = math, string, table, io, arg
local pairs, ipairs, require, pcall, xpcall, error = pairs, ipairs, require, pcall, xpcall, error
local _ENV = {package=package}
local PYLUA = require('PYLUA')

local os = require('os')
local sax = require('xml').sax
local AFMMetric = require('fonts.afm').AFMMetric
local TTFMetric = require('fonts.ttf').TTFMetric
local FontFormatError = require('fonts.metric').FontFormatError
local IOError = PYLUA.IOError

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

    local ok, ret = xpcall(function()
      local parser = sax.make_parser()
      parser:setContentHandler(self)
      parser:setFeature(sax.handler.feature_namespaces, 0)
      parser:parse(configfile)
    end, PYLUA.traceback)
    if not ok then
      local xcpt = ret
      if PYLUA.is_a(ret, sax.SAXException) then
        PYLUA.print('Error parsing configuration file ', configfile, ': ', xcpt:getMessage(), '\n')
        os.exit(1)
      else
        error(ret)
      end
    end
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
      self.fallbackFamilies = PYLUA.collect(PYLUA.split(familyattr, ','), function(x) return string.gsub(x, '%s+', ' ') end)

    elseif name=='family' then
      self.currentFamily = attributes['name'] or ''
      self.currentFamily = string.gsub(PYLUA.lower(self.currentFamily), '%s+', '')

    elseif name=='font' then
      local weight = attributes['weight'] or 'normal'
      local style = attributes['style'] or 'normal'
      local fontfullname = self.currentFamily
      if weight~='normal' then
        fontfullname = fontfullname..' '..weight
      end
      if style~='normal' then
        fontfullname = fontfullname..' '..style
      end
      local ok, ret = xpcall(function()
        local metric
        if attributes['afm'] then
          local fontpath = attributes['afm']
          metric = AFMMetric(fontpath, attributes['glyph-list'], io.stderr)
        elseif attributes['ttf'] then
          local fontpath = attributes['ttf']
          metric = TTFMetric(fontpath, io.stderr)
        else
          io.stderr:write('Bad record in configuration file: font is neither AFM nor TTF\n')
          io.stderr:write(string.format('Font entry for \'%s\' ignored\n', fontfullname))
          return 
        end
        return metric
      end, PYLUA.traceback)
      if ok and not ret then
        return
      end
      if not ok then
        local err = ret
        if PYLUA.is_a(err, FontFormatError) then
          io.stderr:write(string.format('Invalid or unsupported file format in \'%s\': %s\n', fontpath, err.message))
          io.stderr:write(string.format('Font entry for \'%s\' ignored\n', fontfullname))
          return 
        elseif PYLUA.is_a(err, IOError) then
          local message = sys.exc_info()[2]
          io.stderr:write(string.format('I/O error reading font file \'%s\': %s\n', fontpath, tostring(message)))
          io.stderr:write(string.format('Font entry for \'%s\' ignored\n', fontfullname))
          return 
        else
          error(err)
        end
      end
      local metric = ret
      self.fonts[weight..' '..style..' '..self.currentFamily] = metric

    elseif name=='mathvariant' then
      local variantattr = attributes['name']
      local familyattr = attributes['family'] or ''
      local splitFamily = PYLUA.collect(PYLUA.split(familyattr, ','), function(x) return string.gsub(x, '%s+', ' ') end)
      local weightattr = attributes['weight'] or 'normal'
      local styleattr = attributes['style'] or 'normal'
      self.variants[variantattr] = {weightattr, styleattr, splitFamily}

    elseif name=='operator-style' then
      local opname = attributes['operator']
      if opname then
        local styling = { }
        PYLUA.update(styling, attributes)
        styling['operator'] = nil
        self.opstyles[opname] = styling
      else
        io.stderr:write('Bad record in configuration file: operator-style with no operator attribute\n')
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
        local metric = self.fonts[w..' '..s..' '..family]
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
  if #arg==0 then
    local config = MathConfig(nil)
  else
    config = MathConfig(arg[1])
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

if arg and arg[1]==... then
  main()
end

return _ENV
