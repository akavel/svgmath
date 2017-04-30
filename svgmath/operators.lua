-- MathML operator dictionary and related functions

local math, string, table, require = math, string, table, require
local pairs, ipairs = pairs, ipairs
local _ENV = {package=package}
local PYLUA = require('PYLUA')

local operatorDictionary = { }

lookup = function(op, form)
  form = form or 'infix'
  -- Find the entry for an operator in the dictionary
  local res = operatorDictionary[op..form]
  if res ~= nil then
    return res
  end
  for _, f in ipairs({'infix', 'postfix', 'prefix'}) do
    res = operatorDictionary[op..f]
    if res ~= nil then
      return res
    end
  end
  return operatorDictionary[''..'infix']  -- default entry
end

local createEntry = function(params)
  params.form = params.form or 'infix'
  params.fence = params.fence or 'false'
  params.separator = params.separator or 'false'
  params.accent = params.accent or 'false'
  params.largeop = params.largeop or 'false'
  params.lspace = params.lspace or 'thickmathspace'
  params.rspace = params.rspace or 'thickmathspace'
  params.stretchy = params.stretchy or 'false'
  params.scaling = params.scaling or 'uniform'
  params.minsize = params.minsize or '1'
  params.maxsize = params.maxsize or 'infinity'
  params.movablelimits = params.movablelimits or 'false'
  params.symmetric = params.symmetric or 'true'

  local key = params.content .. params.form

  if operatorDictionary[key] ~= nil then
    io.stderr:write(string.format('WARNING: duplicate entry in operator dictionary, %s %s\n',
      params.form, params.content))
  end
  params.content = nil
  operatorDictionary[key] = params
end

-- Create default entry
createEntry{content=''}

-- Create real entries
createEntry{content='(', form='prefix', fence='true', stretchy='true', scaling='vertical', lspace='0em', rspace='0em'}
createEntry{content=')', form='postfix', fence='true', stretchy='true', scaling='vertical', lspace='0em', rspace='0em'}
createEntry{content='[', form='prefix', fence='true', stretchy='true', scaling='vertical', lspace='0em', rspace='0em'}
createEntry{content=']', form='postfix', fence='true', stretchy='true', scaling='vertical', lspace='0em', rspace='0em'}
createEntry{content='{', form='prefix', fence='true', stretchy='true', scaling='vertical', lspace='0em', rspace='0em'}
createEntry{content='}', form='postfix', fence='true', stretchy='true', scaling='vertical', lspace='0em', rspace='0em'}
createEntry{content='\xe2\x80\x9d', form='postfix', fence='true', lspace='0em', rspace='0em'} -- CloseCurlyDoubleQuote
createEntry{content='\xe2\x80\x99', form='postfix', fence='true', lspace='0em', rspace='0em'} -- CloseCurlyQuote
createEntry{content='\xe2\x8c\xa9', form='prefix', fence='true', stretchy='true', scaling='vertical', lspace='0em', rspace='0em'} -- LeftAngleBracket
createEntry{content='\xe2\x8c\x88', form='prefix', fence='true', stretchy='true', scaling='vertical', lspace='0em', rspace='0em'} -- LeftCeiling
createEntry{content='\xe3\x80\x9a', form='prefix', fence='true', stretchy='true', scaling='vertical', lspace='0em', rspace='0em'} -- LeftDoubleBracket
createEntry{content='\xe2\x8c\x8a', form='prefix', fence='true', stretchy='true', scaling='vertical', lspace='0em', rspace='0em'} -- LeftFloor
createEntry{content='\xe2\x80\x9c', form='prefix', fence='true', lspace='0em', rspace='0em'} -- OpenCurlyDoubleQuote
createEntry{content='\xe2\x80\x98', form='prefix', fence='true', lspace='0em', rspace='0em'} -- OpenCurlyQuote
createEntry{content='\xe2\x8c\xaa', form='postfix', fence='true', stretchy='true', scaling='vertical', lspace='0em', rspace='0em'} -- RightAngleBracket
createEntry{content='\xe2\x8c\x89', form='postfix', fence='true', stretchy='true', scaling='vertical', lspace='0em', rspace='0em'} -- RightCeiling
createEntry{content='\xe3\x80\x9b', form='postfix', fence='true', stretchy='true', scaling='vertical', lspace='0em', rspace='0em'} -- RightDoubleBracket
createEntry{content='\xe2\x8c\x8b', form='postfix', fence='true', stretchy='true', scaling='vertical', lspace='0em', rspace='0em'} -- RightFloor
createEntry{content='\xe2\x81\xa3', form='infix', separator='true', lspace='0em', rspace='0em'} -- InvisibleComma
createEntry{content=',', form='infix', separator='true', lspace='0em', rspace='verythickmathspace'}
createEntry{content='\xe2\x94\x80', form='infix', stretchy='true', scaling='horizontal', minsize='0', lspace='0em', rspace='0em'} -- HorizontalLine
-- Commented out: collides with '|'. See http://lists.w3.org/Archives/Public/www-math/2004Mar/0028.html
-- createEntry{content="|", form="infix", stretchy="true", scaling="vertical", minsize="0", lspace="0em", rspace="0em"} -- VerticalLine 
createEntry{content=';', form='infix', separator='true', lspace='0em', rspace='thickmathspace'}
createEntry{content=';', form='postfix', separator='true', lspace='0em', rspace='0em'}
createEntry{content=':=', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\x94', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- Assign
createEntry{content='\xe2\x88\xb5', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- Because
createEntry{content='\xe2\x88\xb4', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- Therefore
createEntry{content='\xe2\x9d\x98', form='infix', stretchy='true', scaling='vertical', lspace='thickmathspace', rspace='thickmathspace'} -- VerticalSeparator
createEntry{content='//', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
-- Commented out: collides with Proportional
-- createEntry {content="\u2237", form="infix", lspace="thickmathspace", rspace="thickmathspace"} -- Colon
createEntry{content='&', form='prefix', lspace='0em', rspace='thickmathspace'}
createEntry{content='&', form='postfix', lspace='thickmathspace', rspace='0em'}
createEntry{content='*=', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='-=', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='+=', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='/=', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='->', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content=':', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='..', form='postfix', lspace='mediummathspace', rspace='0em'}
createEntry{content='...', form='postfix', lspace='mediummathspace', rspace='0em'}
-- Commented out: collides with ReverseElement
-- createEntry {content="\u220B", form="infix", lspace="thickmathspace", rspace="thickmathspace"} -- SuchThat
createEntry{content='\xe2\xab\xa4', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- DoubleLeftTee
createEntry{content='\xe2\x8a\xa8', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- DoubleRightTee
createEntry{content='\xe2\x8a\xa4', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- DownTee
createEntry{content='\xe2\x8a\xa3', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- LeftTee
createEntry{content='\xe2\x8a\xa2', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- RightTee
-- Commented out: collides with DoubleRightArrow
-- createEntry (content=u"\u21D2", form=u"infix", stretchy=u"true", scaling="horizontal", lspace=u"thickmathspace", rspace=u"thickmathspace") -- Implies
createEntry{content='\xe2\xa5\xb0', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- RoundImplies
createEntry{content='|', form='infix', stretchy='true', scaling='vertical', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='||', form='infix', lspace='mediummathspace', rspace='mediummathspace'}
createEntry{content='\xe2\xa9\x94', form='infix', stretchy='true', scaling='uniform', lspace='mediummathspace', rspace='mediummathspace'} -- Or
createEntry{content='&&', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\xa9\x93', form='infix', stretchy='true', scaling='uniform', lspace='mediummathspace', rspace='mediummathspace'} -- And
createEntry{content='&', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='!', form='prefix', lspace='0em', rspace='thickmathspace'}
createEntry{content='\xe2\xab\xac', form='prefix', lspace='0em', rspace='thickmathspace'} -- Not
createEntry{content='\xe2\x88\x83', form='prefix', lspace='0em', rspace='thickmathspace'} -- Exists
createEntry{content='\xe2\x88\x80', form='prefix', lspace='0em', rspace='thickmathspace'} -- ForAll
createEntry{content='\xe2\x88\x84', form='prefix', lspace='0em', rspace='thickmathspace'} -- NotExists
createEntry{content='\xe2\x88\x88', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- Element
createEntry{content='\xe2\x88\x89', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotElement
createEntry{content='\xe2\x88\x8c', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotReverseElement
createEntry{content='\xe2\x8a\x8f\xcc\xb8', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotSquareSubset
createEntry{content='\xe2\x8b\xa2', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotSquareSubsetEqual
createEntry{content='\xe2\x8a\x90\xcc\xb8', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotSquareSuperset
createEntry{content='\xe2\x8b\xa3', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotSquareSupersetEqual
createEntry{content='\xe2\x8a\x82\xe2\x83\x92', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotSubset
createEntry{content='\xe2\x8a\x88', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotSubsetEqual
createEntry{content='\xe2\x8a\x83\xe2\x83\x92', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotSuperset
createEntry{content='\xe2\x8a\x89', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotSupersetEqual
createEntry{content='\xe2\x88\x8b', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- ReverseElement
createEntry{content='\xe2\x8a\x8f', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- SquareSubset
createEntry{content='\xe2\x8a\x91', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- SquareSubsetEqual
createEntry{content='\xe2\x8a\x90', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- SquareSuperset
createEntry{content='\xe2\x8a\x92', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- SquareSupersetEqual
createEntry{content='\xe2\x8b\x90', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- Subset
createEntry{content='\xe2\x8a\x86', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- SubsetEqual
createEntry{content='\xe2\x8a\x83', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- Superset
createEntry{content='\xe2\x8a\x87', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- SupersetEqual
createEntry{content='\xe2\x87\x90', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'} -- DoubleLeftArrow
createEntry{content='\xe2\x87\x94', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'} -- DoubleLeftRightArrow
createEntry{content='\xe2\x87\x92', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'} -- DoubleRightArrow
createEntry{content='\xe2\xa5\x90', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'} -- DownLeftRightVector
createEntry{content='\xe2\xa5\x9e', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'} -- DownLeftTeeVector
createEntry{content='\xe2\x86\xbd', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'} -- DownLeftVector
createEntry{content='\xe2\xa5\x96', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'} -- DownLeftVectorBar
createEntry{content='\xe2\xa5\x9f', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'} -- DownRightTeeVector
createEntry{content='\xe2\x87\x81', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'} -- DownRightVector
createEntry{content='\xe2\xa5\x97', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'} -- DownRightVectorBar
createEntry{content='\xe2\x86\x90', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'} -- LeftArrow
createEntry{content='\xe2\x87\xa4', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'} -- LeftArrowBar
createEntry{content='\xe2\x87\x86', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'} -- LeftArrowRightArrow
createEntry{content='\xe2\x86\x94', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'} -- LeftRightArrow
createEntry{content='\xe2\xa5\x8e', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'} -- LeftRightVector
createEntry{content='\xe2\x86\xa4', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'} -- LeftTeeArrow
createEntry{content='\xe2\xa5\x9a', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'} -- LeftTeeVector
createEntry{content='\xe2\x86\xbc', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'} -- LeftVector
createEntry{content='\xe2\xa5\x92', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'} -- LeftVectorBar
createEntry{content='\xe2\x86\x99', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'} -- LowerLeftArrow
createEntry{content='\xe2\x86\x98', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'} -- LowerRightArrow
createEntry{content='\xe2\x86\x92', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'} -- RightArrow
createEntry{content='\xe2\x87\xa5', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'} -- RightArrowBar
createEntry{content='\xe2\x87\x84', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'} -- RightArrowLeftArrow
createEntry{content='\xe2\x86\xa6', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'} -- RightTeeArrow
createEntry{content='\xe2\xa5\x9b', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'} -- RightTeeVector
createEntry{content='\xe2\x87\x80', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'} -- RightVector
createEntry{content='\xe2\xa5\x93', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'} -- RightVectorBar
-- Commented out: collides with LeftArrow
-- createEntry (content=u"\u2190", form=u"infix", lspace=u"thickmathspace", rspace=u"thickmathspace") -- ShortLeftArrow
-- Commented out: collides with RightArrow
-- createEntry (content=u"\u2192", form=u"infix", lspace=u"thickmathspace", rspace=u"thickmathspace") -- ShortRightArrow
createEntry{content='\xe2\x86\x96', form='infix', stretchy='true', scaling='uniform', lspace='thickmathspace', rspace='thickmathspace'} -- UpperLeftArrow
createEntry{content='\xe2\x86\x97', form='infix', stretchy='true', scaling='uniform', lspace='thickmathspace', rspace='thickmathspace'} -- UpperRightArrow
createEntry{content='=', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='<', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='>', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='!=', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='==', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='<=', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='>=', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\xa1', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- Congruent
createEntry{content='\xe2\x89\x8d', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- CupCap
createEntry{content='\xe2\x89\x90', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- DotEqual
createEntry{content='\xe2\x88\xa5', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- DoubleVerticalBar
createEntry{content='\xe2\xa9\xb5', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- Equal
createEntry{content='\xe2\x89\x82', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- EqualTilde
createEntry{content='\xe2\x87\x8c', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'} -- Equilibrium
createEntry{content='\xe2\x89\xa5', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- GreaterEqual
createEntry{content='\xe2\x8b\x9b', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- GreaterEqualLess
createEntry{content='\xe2\x89\xa7', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- GreaterFullEqual
createEntry{content='\xe2\xaa\xa2', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- GreaterGreater
createEntry{content='\xe2\x89\xb7', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- GreaterLess
createEntry{content='\xe2\xa9\xbe', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- GreaterSlantEqual
createEntry{content='\xe2\x89\xb3', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- GreaterTilde
createEntry{content='\xe2\x89\x8e', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- HumpDownHump
createEntry{content='\xe2\x89\x8f', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- HumpEqual
createEntry{content='\xe2\x8a\xb2', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- LeftTriangle
createEntry{content='\xe2\xa7\x8f', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- LeftTriangleBar
createEntry{content='\xe2\x8a\xb4', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- LeftTriangleEqual
createEntry{content='\xe2\x89\xa4', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- le
createEntry{content='\xe2\x8b\x9a', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- LessEqualGreater
createEntry{content='\xe2\x89\xa6', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- LessFullEqual
createEntry{content='\xe2\x89\xb6', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- LessGreater
createEntry{content='\xe2\xaa\xa1', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- LessLess
createEntry{content='\xe2\xa9\xbd', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- LessSlantEqual
createEntry{content='\xe2\x89\xb2', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- LessTilde
createEntry{content='\xe2\x89\xab', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NestedGreaterGreater
createEntry{content='\xe2\x89\xaa', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NestedLessLess
createEntry{content='\xe2\x89\xa2', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotCongruent
createEntry{content='\xe2\x89\xad', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotCupCap
createEntry{content='\xe2\x88\xa6', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotDoubleVerticalBar
createEntry{content='\xe2\x89\xa0', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotEqual
createEntry{content='\xe2\x89\x82\xcc\xb8', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotEqualTilde
createEntry{content='\xe2\x89\xaf', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotGreater
createEntry{content='\xe2\x89\xb1', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotGreaterEqual
createEntry{content='\xe2\x89\xa6\xcc\xb8', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotGreaterFullEqual
createEntry{content='\xe2\x89\xab\xcc\xb8', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotGreaterGreater
createEntry{content='\xe2\x89\xb9', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotGreaterLess
createEntry{content='\xe2\xa9\xbe\xcc\xb8', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotGreaterSlantEqual
createEntry{content='\xe2\x89\xb5', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotGreaterTilde
createEntry{content='\xe2\x89\x8e\xcc\xb8', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotHumpDownHump
createEntry{content='\xe2\x89\x8f\xcc\xb8', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotHumpEqual
createEntry{content='\xe2\x8b\xaa', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotLeftTriangle
createEntry{content='\xe2\xa7\x8f\xcc\xb8', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotLeftTriangleBar
createEntry{content='\xe2\x8b\xac', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotLeftTriangleEqual
createEntry{content='\xe2\x89\xae', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotLess
createEntry{content='\xe2\x89\xb0', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotLessEqual
createEntry{content='\xe2\x89\xb8', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotLessGreater
createEntry{content='\xe2\x89\xaa\xcc\xb8', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotLessLess
createEntry{content='\xe2\xa9\xbd\xcc\xb8', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotLessSlantEqual
createEntry{content='\xe2\x89\xb4', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotLessTilde
createEntry{content='\xe2\xaa\xa2\xcc\xb8', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotNestedGreaterGreater
createEntry{content='\xe2\xaa\xa1\xcc\xb8', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotNestedLessLess
createEntry{content='\xe2\x8a\x80', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotPrecedes
createEntry{content='\xe2\xaa\xaf\xcc\xb8', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotPrecedesEqual
createEntry{content='\xe2\x8b\xa0', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotPrecedesSlantEqual
createEntry{content='\xe2\x8b\xab', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotRightTriangle
createEntry{content='\xe2\xa7\x90\xcc\xb8', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotRightTriangleBar
createEntry{content='\xe2\x8b\xad', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotRightTriangleEqual
createEntry{content='\xe2\x8a\x81', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotSucceeds
createEntry{content='\xe2\xaa\xb0\xcc\xb8', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotSucceedsEqual
createEntry{content='\xe2\x8b\xa1', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotSucceedsSlantEqual
createEntry{content='\xe2\x89\xbf\xcc\xb8', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotSucceedsTilde
createEntry{content='\xe2\x89\x81', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotTilde
createEntry{content='\xe2\x89\x84', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotTildeEqual
createEntry{content='\xe2\x89\x87', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotTildeFullEqual
createEntry{content='\xe2\x89\x89', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotTildeTilde
createEntry{content='\xe2\x88\xa4', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- NotVerticalBar
createEntry{content='\xe2\x89\xba', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- Precedes
createEntry{content='\xe2\xaa\xaf', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- PrecedesEqual
createEntry{content='\xe2\x89\xbc', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- PrecedesSlantEqual
createEntry{content='\xe2\x89\xbe', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- PrecedesTilde
createEntry{content='\xe2\x88\xb7', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- Proportion
createEntry{content='\xe2\x88\x9d', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- Proportional
createEntry{content='\xe2\x87\x8b', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'} -- ReverseEquilibrium
createEntry{content='\xe2\x8a\xb3', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- RightTriangle
createEntry{content='\xe2\xa7\x90', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- RightTriangleBar
createEntry{content='\xe2\x8a\xb5', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- RightTriangleEqual
createEntry{content='\xe2\x89\xbb', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- Succeeds
createEntry{content='\xe2\xaa\xb0', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- SucceedsEqual
createEntry{content='\xe2\x89\xbd', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- SucceedsSlantEqual
createEntry{content='\xe2\x89\xbf', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- SucceedsTilde
createEntry{content='\xe2\x88\xbc', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- Tilde
createEntry{content='\xe2\x89\x83', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- TildeEqual
createEntry{content='\xe2\x89\x85', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- TildeFullEqual
createEntry{content='\xe2\x89\x88', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- TildeTilde
createEntry{content='\xe2\x8a\xa5', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- UpTee
createEntry{content='\xe2\x88\xa3', form='infix', lspace='thickmathspace', rspace='thickmathspace'} -- VerticalBar
createEntry{content='\xe2\x8a\x94', form='infix', stretchy='true', scaling='uniform', lspace='mediummathspace', rspace='mediummathspace'} -- SquareUnion
createEntry{content='\xe2\x8b\x83', form='infix', stretchy='true', scaling='uniform', lspace='mediummathspace', rspace='mediummathspace'} -- Union
createEntry{content='\xe2\x8a\x8e', form='infix', stretchy='true', scaling='uniform', lspace='mediummathspace', rspace='mediummathspace'} -- UnionPlus
createEntry{content='-', form='infix', lspace='mediummathspace', rspace='mediummathspace'}
-- Added an entry for minus sign, separate from hyphen
createEntry{content='\xe2\x88\x92', form='infix', lspace='mediummathspace', rspace='mediummathspace'}
createEntry{content='+', form='infix', lspace='mediummathspace', rspace='mediummathspace'}
createEntry{content='\xe2\x8b\x82', form='infix', stretchy='true', scaling='uniform', lspace='mediummathspace', rspace='mediummathspace'} -- Intersection
createEntry{content='\xe2\x88\x93', form='infix', lspace='mediummathspace', rspace='mediummathspace'} -- MinusPlus
createEntry{content='\xc2\xb1', form='infix', lspace='mediummathspace', rspace='mediummathspace'} -- PlusMinus
createEntry{content='\xe2\x8a\x93', form='infix', stretchy='true', scaling='uniform', lspace='mediummathspace', rspace='mediummathspace'} -- SquareIntersection
createEntry{content='\xe2\x8b\x81', form='prefix', largeop='true', movablelimits='true', stretchy='true', scaling='uniform', lspace='0em', rspace='thinmathspace'} -- Vee
createEntry{content='\xe2\x8a\x96', form='prefix', largeop='true', movablelimits='true', lspace='0em', rspace='thinmathspace'} -- CircleMinus
createEntry{content='\xe2\x8a\x95', form='prefix', largeop='true', movablelimits='true', lspace='0em', rspace='thinmathspace'} -- CirclePlus
createEntry{content='\xe2\x88\x91', form='prefix', largeop='true', movablelimits='true', stretchy='true', scaling='uniform', lspace='0em', rspace='thinmathspace'} -- Sum
createEntry{content='\xe2\x8b\x83', form='prefix', largeop='true', movablelimits='true', stretchy='true', scaling='uniform', lspace='0em', rspace='thinmathspace'} -- Union
createEntry{content='\xe2\x8a\x8e', form='prefix', largeop='true', movablelimits='true', stretchy='true', scaling='uniform', lspace='0em', rspace='thinmathspace'} -- UnionPlus
createEntry{content='lim', form='prefix', movablelimits='true', lspace='0em', rspace='thinmathspace'}
createEntry{content='max', form='prefix', movablelimits='true', lspace='0em', rspace='thinmathspace'}
createEntry{content='min', form='prefix', movablelimits='true', lspace='0em', rspace='thinmathspace'}
createEntry{content='\xe2\x8a\x96', form='infix', lspace='thinmathspace', rspace='thinmathspace'} -- CircleMinus
createEntry{content='\xe2\x8a\x95', form='infix', lspace='thinmathspace', rspace='thinmathspace'} -- CirclePlus
createEntry{content='\xe2\x88\xb2', form='prefix', largeop='true', stretchy='true', scaling='uniform', lspace='0em', rspace='0em'} -- ClockwiseContourIntegral
createEntry{content='\xe2\x88\xae', form='prefix', largeop='true', stretchy='true', scaling='uniform', lspace='0em', rspace='0em'} -- ContourIntegral
createEntry{content='\xe2\x88\xb3', form='prefix', largeop='true', stretchy='true', scaling='uniform', lspace='0em', rspace='0em'} -- CounterClockwiseContourIntegral
createEntry{content='\xe2\x88\xaf', form='prefix', largeop='true', stretchy='true', scaling='uniform', lspace='0em', rspace='0em'} -- DoubleContourIntegral
createEntry{content='\xe2\x88\xab', form='prefix', largeop='true', stretchy='true', scaling='uniform', lspace='0em', rspace='0em'} -- Integral
createEntry{content='\xe2\x8b\x93', form='infix', lspace='thinmathspace', rspace='thinmathspace'} -- Cup
createEntry{content='\xe2\x8b\x92', form='infix', lspace='thinmathspace', rspace='thinmathspace'} -- Cap
createEntry{content='\xe2\x89\x80', form='infix', lspace='thinmathspace', rspace='thinmathspace'} -- VerticalTilde
createEntry{content='\xe2\x8b\x80', form='prefix', largeop='true', movablelimits='true', stretchy='true', scaling='uniform', lspace='0em', rspace='thinmathspace'} -- Wedge
createEntry{content='\xe2\x8a\x97', form='prefix', largeop='true', movablelimits='true', lspace='0em', rspace='thinmathspace'} -- CircleTimes
createEntry{content='\xe2\x88\x90', form='prefix', largeop='true', movablelimits='true', stretchy='true', scaling='uniform', lspace='0em', rspace='thinmathspace'} -- Coproduct
createEntry{content='\xe2\x88\x8f', form='prefix', largeop='true', movablelimits='true', stretchy='true', scaling='uniform', lspace='0em', rspace='thinmathspace'} -- Product
createEntry{content='\xe2\x8b\x82', form='prefix', largeop='true', movablelimits='true', stretchy='true', scaling='uniform', lspace='0em', rspace='thinmathspace'} -- Intersection
createEntry{content='\xe2\x88\x90', form='infix', lspace='thinmathspace', rspace='thinmathspace'} -- Coproduct
createEntry{content='\xe2\x8b\x86', form='infix', lspace='thinmathspace', rspace='thinmathspace'} -- Star
createEntry{content='\xe2\x8a\x99', form='prefix', largeop='true', movablelimits='true', lspace='0em', rspace='thinmathspace'} -- CircleDot
createEntry{content='*', form='infix', lspace='thinmathspace', rspace='thinmathspace'}
createEntry{content='\xe2\x81\xa2', form='infix', lspace='0em', rspace='0em'} -- InvisibleTimes
createEntry{content='\xc2\xb7', form='infix', lspace='thinmathspace', rspace='thinmathspace'} -- CenterDot
createEntry{content='\xe2\x8a\x97', form='infix', lspace='thinmathspace', rspace='thinmathspace'} -- CircleTimes
createEntry{content='\xe2\x8b\x81', form='infix', lspace='thinmathspace', rspace='thinmathspace'} -- Vee
createEntry{content='\xe2\x8b\x80', form='infix', lspace='thinmathspace', rspace='thinmathspace'} -- Wedge
createEntry{content='\xe2\x8b\x84', form='infix', lspace='thinmathspace', rspace='thinmathspace'} -- Diamond
createEntry{content='\xe2\x88\x96', form='infix', stretchy='true', scaling='uniform', lspace='thinmathspace', rspace='thinmathspace'} -- Backslash
createEntry{content='/', form='infix', stretchy='true', scaling='uniform', lspace='thinmathspace', rspace='thinmathspace'}
createEntry{content='-', form='prefix', lspace='0em', rspace='veryverythinmathspace'}
-- Added an entry for minus sign, separate from hyphen
createEntry{content='\xe2\x88\x92', form='prefix', lspace='0em', rspace='veryverythinmathspace'}
createEntry{content='+', form='prefix', lspace='0em', rspace='veryverythinmathspace'}
createEntry{content='\xe2\x88\x93', form='prefix', lspace='0em', rspace='veryverythinmathspace'} -- MinusPlus
createEntry{content='\xc2\xb1', form='prefix', lspace='0em', rspace='veryverythinmathspace'} -- PlusMinus
createEntry{content='.', form='infix', lspace='0em', rspace='0em'}
createEntry{content='\xe2\xa8\xaf', form='infix', lspace='verythinmathspace', rspace='verythinmathspace'} -- Cross
createEntry{content='**', form='infix', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xe2\x8a\x99', form='infix', lspace='verythinmathspace', rspace='verythinmathspace'} -- CircleDot
createEntry{content='\xe2\x88\x98', form='infix', lspace='verythinmathspace', rspace='verythinmathspace'} -- SmallCircle
createEntry{content='\xe2\x96\xa1', form='prefix', lspace='0em', rspace='verythinmathspace'} -- Square
createEntry{content='\xe2\x88\x87', form='prefix', lspace='0em', rspace='verythinmathspace'} -- Del
createEntry{content='\xe2\x88\x82', form='prefix', lspace='0em', rspace='verythinmathspace'} -- PartialD
createEntry{content='\xe2\x85\x85', form='prefix', lspace='0em', rspace='verythinmathspace'} -- CapitalDifferentialD
createEntry{content='\xe2\x85\x86', form='prefix', lspace='0em', rspace='verythinmathspace'} -- DifferentialD
createEntry{content='\xe2\x88\x9a', form='prefix', stretchy='true', scaling='uniform', lspace='0em', rspace='verythinmathspace'} -- Sqrt
createEntry{content='\xe2\x87\x93', form='infix', stretchy='true', scaling='vertical', lspace='verythinmathspace', rspace='verythinmathspace'} -- DoubleDownArrow
createEntry{content='\xe2\x9f\xb8', form='infix', stretchy='true', scaling='horizontal', lspace='verythinmathspace', rspace='verythinmathspace'} -- DoubleLongLeftArrow
createEntry{content='\xe2\x9f\xba', form='infix', stretchy='true', scaling='horizontal', lspace='verythinmathspace', rspace='verythinmathspace'} -- DoubleLongLeftRightArrow
createEntry{content='\xe2\x9f\xb9', form='infix', stretchy='true', scaling='horizontal', lspace='verythinmathspace', rspace='verythinmathspace'} -- DoubleLongRightArrow
createEntry{content='\xe2\x87\x91', form='infix', stretchy='true', scaling='vertical', lspace='verythinmathspace', rspace='verythinmathspace'} -- DoubleUpArrow
createEntry{content='\xe2\x87\x95', form='infix', stretchy='true', scaling='vertical', lspace='verythinmathspace', rspace='verythinmathspace'} -- DoubleUpDownArrow
createEntry{content='\xe2\x86\x93', form='infix', stretchy='true', scaling='vertical', lspace='verythinmathspace', rspace='verythinmathspace'} -- DownArrow
createEntry{content='\xe2\xa4\x93', form='infix', stretchy='true', scaling='vertical', lspace='verythinmathspace', rspace='verythinmathspace'} -- DownArrowBar
createEntry{content='\xe2\x87\xb5', form='infix', stretchy='true', scaling='vertical', lspace='verythinmathspace', rspace='verythinmathspace'} -- DownArrowUpArrow
createEntry{content='\xe2\x86\xa7', form='infix', stretchy='true', scaling='vertical', lspace='verythinmathspace', rspace='verythinmathspace'} -- DownTeeArrow
createEntry{content='\xe2\xa5\xa1', form='infix', stretchy='true', scaling='uniform', lspace='verythinmathspace', rspace='verythinmathspace'} -- LeftDownTeeVector
createEntry{content='\xe2\x87\x83', form='infix', stretchy='true', scaling='uniform', lspace='verythinmathspace', rspace='verythinmathspace'} -- LeftDownVector
createEntry{content='\xe2\xa5\x99', form='infix', stretchy='true', scaling='uniform', lspace='verythinmathspace', rspace='verythinmathspace'} -- LeftDownVectorBar
createEntry{content='\xe2\xa5\x91', form='infix', stretchy='true', scaling='uniform', lspace='verythinmathspace', rspace='verythinmathspace'} -- LeftUpDownVector
createEntry{content='\xe2\xa5\xa0', form='infix', stretchy='true', scaling='uniform', lspace='verythinmathspace', rspace='verythinmathspace'} -- LeftUpTeeVector
createEntry{content='\xe2\x86\xbf', form='infix', stretchy='true', scaling='uniform', lspace='verythinmathspace', rspace='verythinmathspace'} -- LeftUpVector
createEntry{content='\xe2\xa5\x98', form='infix', stretchy='true', scaling='uniform', lspace='verythinmathspace', rspace='verythinmathspace'} -- LeftUpVectorBar
createEntry{content='\xe2\x9f\xb5', form='infix', stretchy='true', scaling='horizontal', lspace='verythinmathspace', rspace='verythinmathspace'} -- LongLeftArrow
createEntry{content='\xe2\x9f\xb7', form='infix', stretchy='true', scaling='horizontal', lspace='verythinmathspace', rspace='verythinmathspace'} -- LongLeftRightArrow
createEntry{content='\xe2\x9f\xb6', form='infix', stretchy='true', scaling='horizontal', lspace='verythinmathspace', rspace='verythinmathspace'} -- LongRightArrow
createEntry{content='\xe2\xa5\xaf', form='infix', stretchy='true', scaling='horizontal', lspace='verythinmathspace', rspace='verythinmathspace'} -- ReverseUpEquilibrium
createEntry{content='\xe2\xa5\x9d', form='infix', stretchy='true', scaling='horizontal', lspace='verythinmathspace', rspace='verythinmathspace'} -- RightDownTeeVector
createEntry{content='\xe2\x87\x82', form='infix', stretchy='true', scaling='horizontal', lspace='verythinmathspace', rspace='verythinmathspace'} -- RightDownVector
createEntry{content='\xe2\xa5\x95', form='infix', stretchy='true', scaling='horizontal', lspace='verythinmathspace', rspace='verythinmathspace'} -- RightDownVectorBar
createEntry{content='\xe2\xa5\x8f', form='infix', stretchy='true', scaling='horizontal', lspace='verythinmathspace', rspace='verythinmathspace'} -- RightUpDownVector
createEntry{content='\xe2\xa5\x9c', form='infix', stretchy='true', scaling='horizontal', lspace='verythinmathspace', rspace='verythinmathspace'} -- RightUpTeeVector
createEntry{content='\xe2\x86\xbe', form='infix', stretchy='true', scaling='horizontal', lspace='verythinmathspace', rspace='verythinmathspace'} -- RightUpVector
createEntry{content='\xe2\xa5\x94', form='infix', stretchy='true', scaling='horizontal', lspace='verythinmathspace', rspace='verythinmathspace'} -- RightUpVectorBar
-- Commented out: collides with DownArrow
-- createEntry (content=u"\u2193", form=u"infix", lspace=u"verythinmathspace", rspace=u"verythinmathspace") -- ShortDownArrow
-- Commented out: collides with UpArrow
-- createEntry (content=u"\u2191", form=u"infix", lspace=u"verythinmathspace", rspace=u"verythinmathspace") -- ShortUpArrow
createEntry{content='\xe2\x86\x91', form='infix', stretchy='true', scaling='vertical', lspace='verythinmathspace', rspace='verythinmathspace'} -- UpArrow
createEntry{content='\xe2\xa4\x92', form='infix', stretchy='true', scaling='vertical', lspace='verythinmathspace', rspace='verythinmathspace'} -- UpArrowBar
createEntry{content='\xe2\x87\x85', form='infix', stretchy='true', scaling='vertical', lspace='verythinmathspace', rspace='verythinmathspace'} -- UpArrowDownArrow
createEntry{content='\xe2\x86\x95', form='infix', stretchy='true', scaling='vertical', lspace='verythinmathspace', rspace='verythinmathspace'} -- UpDownArrow
createEntry{content='\xe2\xa5\xae', form='infix', stretchy='true', scaling='vertical', lspace='verythinmathspace', rspace='verythinmathspace'} -- UpEquilibrium
createEntry{content='\xe2\x86\xa5', form='infix', stretchy='true', scaling='vertical', lspace='verythinmathspace', rspace='verythinmathspace'} -- UpTeeArrow
createEntry{content='^', form='infix', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='<>', form='infix', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\'', form='postfix', lspace='verythinmathspace', rspace='0em'}
-- Added an entry for prime, separate from apostrophe
createEntry{content='\xe2\x80\xb2', form='postfix', lspace='verythinmathspace', rspace='0em'}
createEntry{content='!', form='postfix', lspace='verythinmathspace', rspace='0em'}
createEntry{content='!!', form='postfix', lspace='verythinmathspace', rspace='0em'}
createEntry{content='~', form='infix', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='@', form='infix', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='--', form='postfix', lspace='verythinmathspace', rspace='0em'}
createEntry{content='--', form='prefix', lspace='0em', rspace='verythinmathspace'}
createEntry{content='++', form='postfix', lspace='verythinmathspace', rspace='0em'}
createEntry{content='++', form='prefix', lspace='0em', rspace='verythinmathspace'}
createEntry{content='\xe2\x81\xa1', form='infix', lspace='0em', rspace='0em'} -- ApplyFunction
createEntry{content='?', form='infix', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='_', form='infix', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xcb\x98', form='postfix', accent='true', lspace='0em', rspace='0em'} -- Breve
createEntry{content='\xc2\xb8', form='postfix', accent='true', lspace='0em', rspace='0em'} -- Cedilla
createEntry{content='`', form='postfix', accent='true', lspace='0em', rspace='0em'} -- DiacriticalGrave
createEntry{content='\xcb\x99', form='postfix', accent='true', lspace='0em', rspace='0em'} -- DiacriticalDot
createEntry{content='\xcb\x9d', form='postfix', accent='true', lspace='0em', rspace='0em'} -- DiacriticalDoubleAcute
createEntry{content='\xe2\x86\x90', form='postfix', accent='true', stretchy='true', scaling='horizontal', lspace='0em', rspace='0em'} -- LeftArrow
createEntry{content='\xe2\x86\x94', form='postfix', accent='true', stretchy='true', scaling='horizontal', lspace='0em', rspace='0em'} -- LeftRightArrow
createEntry{content='\xe2\xa5\x8e', form='postfix', accent='true', stretchy='true', scaling='horizontal', lspace='0em', rspace='0em'} -- LeftRightVector
createEntry{content='\xe2\x86\xbc', form='postfix', accent='true', stretchy='true', scaling='horizontal', lspace='0em', rspace='0em'} -- LeftVector
createEntry{content='\xc2\xb4', form='postfix', accent='true', lspace='0em', rspace='0em'} -- DiacriticalAcute
createEntry{content='\xe2\x86\x92', form='postfix', accent='true', stretchy='true', scaling='horizontal', lspace='0em', rspace='0em'} -- RightArrow
createEntry{content='\xe2\x87\x80', form='postfix', accent='true', stretchy='true', scaling='horizontal', lspace='0em', rspace='0em'} -- RightVector
createEntry{content='\xcb\x9c', form='postfix', accent='true', stretchy='true', scaling='horizontal', lspace='0em', rspace='0em'} -- DiacriticalTilde
createEntry{content='\xc2\xa8', form='postfix', accent='true', lspace='0em', rspace='0em'} -- DoubleDot
createEntry{content='\xcc\x91', form='postfix', accent='true', lspace='0em', rspace='0em'} -- DownBreve
createEntry{content='\xcb\x87', form='postfix', accent='true', stretchy='true', scaling='horizontal', lspace='0em', rspace='0em'} -- Hacek
createEntry{content='^', form='postfix', accent='true', stretchy='true', scaling='horizontal', lspace='0em', rspace='0em'} -- Hat
createEntry{content='\xc2\xaf', form='postfix', accent='true', stretchy='true', scaling='horizontal', lspace='0em', rspace='0em'} -- OverBar
createEntry{content='\xef\xb8\xb7', form='postfix', accent='true', stretchy='true', scaling='horizontal', lspace='0em', rspace='0em'} -- OverBrace
createEntry{content='\xe2\x8e\xb4', form='postfix', accent='true', stretchy='true', scaling='horizontal', lspace='0em', rspace='0em'} -- OverBracket
createEntry{content='\xef\xb8\xb5', form='postfix', accent='true', stretchy='true', scaling='horizontal', lspace='0em', rspace='0em'} -- OverParenthesis
createEntry{content='\xe2\x83\x9b', form='postfix', accent='true', lspace='0em', rspace='0em'} -- TripleDot
createEntry{content='\xcc\xb2', form='postfix', accent='true', stretchy='true', scaling='horizontal', lspace='0em', rspace='0em'} -- UnderBar
createEntry{content='\xef\xb8\xb8', form='postfix', accent='true', stretchy='true', scaling='horizontal', lspace='0em', rspace='0em'} -- UnderBrace
createEntry{content='\xe2\x8e\xb5', form='postfix', accent='true', stretchy='true', scaling='horizontal', lspace='0em', rspace='0em'} -- UnderBracket
createEntry{content='\xef\xb8\xb6', form='postfix', accent='true', stretchy='true', scaling='horizontal', lspace='0em', rspace='0em'} -- UnderParenthesis

return _ENV
