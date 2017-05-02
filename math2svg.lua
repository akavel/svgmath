-- Command-line tool to replace MathML with SVG throughout a document.
-- 
-- Replaces all instances of MathML throughout the document

for _, subdir in ipairs{'.', 'tools', 'fonts'} do
  package.path = package.path .. ';./svgmath/'..subdir..'/?.lua'
end

local PYLUA = require('PYLUA')
local sax = require('xml').sax
local XMLGenerator = require('svgmath.tools.saxtools').XMLGenerator
local ContentFilter = require('svgmath.tools.saxtools').ContentFilter
local MathHandler = require('svgmath.mathhandler').MathHandler
local MathNS = require('svgmath.mathhandler').MathNS
local MathEntityResolver = require('svgmath.mathhandler').MathEntityResolver

open_or_die = function(fname, fmode, role)
  local f, err = io.open(fname, fmode)
  if err then
    print(string.format("Cannot open %s file '%s': %s", role, fname, err))
    os.exit(1)
  end
  return f
end

usage = function()
  io.stderr:write [[
Usage: math2svg.lua [options]
Replaces MathML formulae in a document by SVG images.

Options:
    -h, --help               display this synopsis and exit
    -s, --standalone         treat input as a standalone MathML document
    -i=FILE, --input=FILE    read MathML input from FILE instead of stdin
    -o=FILE, --output=FILE   write results to FILE instead of stdout
    -c=FILE, --config=FILE   read configuration from FILE
    -e=ENC,  --encoding=ENC  produce output in ENC encoding
]]
end

MathFilter = PYLUA.class(ContentFilter) {

  __init__ = function(self, out, mathout)
    ContentFilter.__init__(self, out)
    self.plainOutput = out
    self.mathOutput = mathout
    self.depth = 0
  end
  ;

  -- ContentHandler methods
  setDocumentLocator = function(self, locator)
    self.plainOutput:setDocumentLocator(locator)
    self.mathOutput:setDocumentLocator(locator)
  end
  ;

  startElementNS = function(self, elementName, qName, attrs)
    if self.depth==0 then
      local namespace, localName = table.unpack(elementName)
      if namespace==MathNS then
        self.output = self.mathOutput
        self.depth = 1
      end
    else
      self.depth = self.depth+1
    end
    ContentFilter.startElementNS(self, elementName, qName, attrs)
  end
  ;

  endElementNS = function(self, elementName, qName)
    ContentFilter.endElementNS(self, elementName, qName)
    if self.depth>0 then
      self.depth = self.depth-1
      if self.depth==0 then
        self.output = self.plainOutput
      end
    end
  end
  ;
}

local function flag_get(old, s, ...)
  if not s then return old end
  for _, prefix in ipairs{...} do
    if s:sub(1,#prefix+1) == prefix..'=' then
      return s:sub(#prefix+2)
    end
  end
  return old, s
end


main = function(...)
  local inputfile = io.stdin
  local outputfile = io.stdout
  local configfile = nil
  local encoding = 'utf-8'
  local standalone = false

  for _, a in ipairs{...} do
    if a=='-h' or a=='--help' then
      usage()
      os.exit(2)
    end
    inputfile, a = flag_get(inputfile, a, '-i', '--input')
    outputfile, a = flag_get(outputfile, a, '-o', '--output')
    configfile, a = flag_get(configfile, a, '-c', '--config')
    encoding, a = flag_get(encoding, a, '-e', '--encoding')
    if a=='-s' or a=='--standalone' then
      standalone = true
    elseif a then
      error('unknown flag: '..a)
    end
  end

  local source = inputfile
  if type(source)=='string' then
    source = open_or_die(source, 'rb', 'input')
  end

  -- Determine output destination
  local output = outputfile
  if type(output)=='string' then
    output = open_or_die(output, 'wb', 'output')
  end

  -- Determine config file location
  if not configfile then
    configfile = PYLUA.dirname(arg[0]) .. 'svgmath.xml'
  end
  local config = open_or_die(configfile, 'rb', 'configuration')

  -- Create the converter as a content handler. 
  local saxoutput = XMLGenerator(output, encoding)
  local handler = MathHandler(saxoutput, config)
  if not standalone then
    handler = MathFilter(saxoutput, handler)
  end

  -- Parse input file
  local exitcode = 0
  local ok, ret = xpcall(function()
    parser = sax.make_parser()
    parser:setFeature(sax.handler.feature_namespaces, 1)
    --parser:setEntityResolver(MathEntityResolver())
    parser:setContentHandler(handler)
    parser:parse(source)
  end, PYLUA.traceback)
  if not ok then
    local xcpt = ret
    if PYLUA.is_a(ret, sax.SAXException) then
      PYLUA.print(string.format('Error parsing input file: %s', xcpt:getMessage()), '\n')
      exitcode = 1
    else
      error(ret)
    end
  end
  source:close()
  if outputfile ~= nil then
    output:close()
  end
  os.exit(exitcode)
end

if arg and arg[1]==... then
  main(...)
end

