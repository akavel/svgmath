-- Command-line tool to replace MathML with SVG throughout a document.

Replaces all instances of MathML throughout the document

open_or_die = function(fname, fmode, role)
  return open(fname, fmode)
IOErrorxcptprint(pylua.mod('Cannot open %s file \'%s\': %s', role, fname, str(xcpt)))  sys.exit(1)
end

usage = function()
  sys.stderr.write('\nUsage: math2svg.py [options] FILE\nReplaces MathML formulae in a document by SVG images. Argument is a file name.\n\nOptions:\n    -h, --help               display this synopsis and exit\n    -s, --standalone         treat input as a standalone MathML document\n    -o FILE, --output=FILE   write results to FILE instead of stdout\n    -c FILE, --config=FILE   read configuration from FILE\n    -e ENC,  --encoding=ENC  produce output in ENC encoding\n')
end
ContentFilter
__init__ = function(self, out, mathout)
  ContentFilter.__init__(self, out)
  self.plainOutput = out
  self.mathOutput = mathout
  self.depth = 0
end

setDocumentLocator = function(self, locator)
  self.plainOutput.setDocumentLocator(locator)
  self.mathOutput.setDocumentLocator(locator)
end

startElementNS = function(self, elementName, qName, attrs)
  if self.depth==0 then
    namespace, localName = elementName
    if namespace==MathNS then
      self.output = self.mathOutput
      self.depth = 1
    end
  else
    self.depth = self.depth+1
  end
  ContentFilter.startElementNS(self, elementName, qName, attrs)
end

endElementNS = function(self, elementName, qName)
  ContentFilter.endElementNS(self, elementName, qName)
  if self.depth>0 then
    self.depth = self.depth-1
    if self.depth==0 then
      self.output = self.plainOutput
    end
  end
end

main = function()
  opts, args = getopt.getopt(pylua.slice(sys.argv, 1, nil), 'c:e:ho:s', {'config=', 'encoding=', 'help', 'output=', 'standalone'})
getopt.GetoptError  usage()
  sys.exit(2)
  outputfile = nil
  configfile = nil
  encoding = 'utf-8'
  standalone = false
  for o, a in ipairs(opts) do
    if pylua.op_in(o, '-h', '--help') then
      usage()
      sys.exit(0)
    end
    if pylua.op_in(o, '-o', '--output') then
      outputfile = a
    end
    if pylua.op_in(o, '-c', '--config') then
      configfile = a
    end
    if pylua.op_in(o, '-e', '--encoding') then
      encoding = a
    end
    if pylua.op_in(o, '-s', '--standalone') then
      standalone = true
    end
  end
  if len(args)<1 then
    sys.stderr.write('No input file specified!\n')
    usage()
    sys.exit(1)
  elseif len(args)>1 then
    sys.stderr.write('WARNING: extra command line arguments ignored\n')
  end
  source = open_or_die(args[1], 'rb', 'input')
  if pylua.op_is(outputfile, nil) then
    output = sys.stdout
  else
    output = open_or_die(outputfile, 'wb', 'output')
  end
  if pylua.op_is(configfile, nil) then
    configfile = pylua.str_maybe(os.path).join(os.path.dirname(__file__), 'svgmath.xml')
  end
  config = open_or_die(configfile, 'rb', 'configuration')
  saxoutput = XMLGenerator(output, encoding)
  handler = MathHandler(saxoutput, config)
  if  not standalone then
    handler = MathFilter(saxoutput, handler)
  end
  exitcode = 0
  parser = sax.make_parser()
  parser.setFeature(sax.handler.feature_namespaces, 1)
  parser.setEntityResolver(MathEntityResolver())
  parser.setContentHandler(handler)
  parser.parse(source)
sax.SAXExceptionxcptprint(pylua.mod('Error parsing input file %s: %s', args[1], xcpt.getMessage()))  exitcode = 1
  source.close()
  if pylua.op_is_not(outputfile, nil) then
    output.close()
  end
  sys.exit(exitcode)
end
if __name__=='__main__' then
  main()
end
