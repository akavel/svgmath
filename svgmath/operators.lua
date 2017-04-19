-- MathML operator dictionary and related functions

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

createEntry{content=''}
createEntry{content='(', form='prefix', fence='true', stretchy='true', scaling='vertical', lspace='0em', rspace='0em'}
createEntry{content=')', form='postfix', fence='true', stretchy='true', scaling='vertical', lspace='0em', rspace='0em'}
createEntry{content='[', form='prefix', fence='true', stretchy='true', scaling='vertical', lspace='0em', rspace='0em'}
createEntry{content=']', form='postfix', fence='true', stretchy='true', scaling='vertical', lspace='0em', rspace='0em'}
createEntry{content='{', form='prefix', fence='true', stretchy='true', scaling='vertical', lspace='0em', rspace='0em'}
createEntry{content='}', form='postfix', fence='true', stretchy='true', scaling='vertical', lspace='0em', rspace='0em'}
createEntry{content='\xe2\x80\x9d', form='postfix', fence='true', lspace='0em', rspace='0em'}
createEntry{content='\xe2\x80\x99', form='postfix', fence='true', lspace='0em', rspace='0em'}
createEntry{content='\xe2\x8c\xa9', form='prefix', fence='true', stretchy='true', scaling='vertical', lspace='0em', rspace='0em'}
createEntry{content='\xe2\x8c\x88', form='prefix', fence='true', stretchy='true', scaling='vertical', lspace='0em', rspace='0em'}
createEntry{content='\xe3\x80\x9a', form='prefix', fence='true', stretchy='true', scaling='vertical', lspace='0em', rspace='0em'}
createEntry{content='\xe2\x8c\x8a', form='prefix', fence='true', stretchy='true', scaling='vertical', lspace='0em', rspace='0em'}
createEntry{content='\xe2\x80\x9c', form='prefix', fence='true', lspace='0em', rspace='0em'}
createEntry{content='\xe2\x80\x98', form='prefix', fence='true', lspace='0em', rspace='0em'}
createEntry{content='\xe2\x8c\xaa', form='postfix', fence='true', stretchy='true', scaling='vertical', lspace='0em', rspace='0em'}
createEntry{content='\xe2\x8c\x89', form='postfix', fence='true', stretchy='true', scaling='vertical', lspace='0em', rspace='0em'}
createEntry{content='\xe3\x80\x9b', form='postfix', fence='true', stretchy='true', scaling='vertical', lspace='0em', rspace='0em'}
createEntry{content='\xe2\x8c\x8b', form='postfix', fence='true', stretchy='true', scaling='vertical', lspace='0em', rspace='0em'}
createEntry{content='\xe2\x81\xa3', form='infix', separator='true', lspace='0em', rspace='0em'}
createEntry{content=',', form='infix', separator='true', lspace='0em', rspace='verythickmathspace'}
createEntry{content='\xe2\x94\x80', form='infix', stretchy='true', scaling='horizontal', minsize='0', lspace='0em', rspace='0em'}
createEntry{content=';', form='infix', separator='true', lspace='0em', rspace='thickmathspace'}
createEntry{content=';', form='postfix', separator='true', lspace='0em', rspace='0em'}
createEntry{content=':=', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\x94', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x88\xb5', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x88\xb4', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x9d\x98', form='infix', stretchy='true', scaling='vertical', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='//', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
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
createEntry{content='\xe2\xab\xa4', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x8a\xa8', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x8a\xa4', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x8a\xa3', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x8a\xa2', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\xa5\xb0', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='|', form='infix', stretchy='true', scaling='vertical', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='||', form='infix', lspace='mediummathspace', rspace='mediummathspace'}
createEntry{content='\xe2\xa9\x94', form='infix', stretchy='true', scaling='uniform', lspace='mediummathspace', rspace='mediummathspace'}
createEntry{content='&&', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\xa9\x93', form='infix', stretchy='true', scaling='uniform', lspace='mediummathspace', rspace='mediummathspace'}
createEntry{content='&', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='!', form='prefix', lspace='0em', rspace='thickmathspace'}
createEntry{content='\xe2\xab\xac', form='prefix', lspace='0em', rspace='thickmathspace'}
createEntry{content='\xe2\x88\x83', form='prefix', lspace='0em', rspace='thickmathspace'}
createEntry{content='\xe2\x88\x80', form='prefix', lspace='0em', rspace='thickmathspace'}
createEntry{content='\xe2\x88\x84', form='prefix', lspace='0em', rspace='thickmathspace'}
createEntry{content='\xe2\x88\x88', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x88\x89', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x88\x8c', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x8a\x8f\xcc\xb8', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x8b\xa2', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x8a\x90\xcc\xb8', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x8b\xa3', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x8a\x82\xe2\x83\x92', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x8a\x88', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x8a\x83\xe2\x83\x92', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x8a\x89', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x88\x8b', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x8a\x8f', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x8a\x91', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x8a\x90', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x8a\x92', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x8b\x90', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x8a\x86', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x8a\x83', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x8a\x87', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x87\x90', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x87\x94', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x87\x92', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\xa5\x90', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\xa5\x9e', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x86\xbd', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\xa5\x96', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\xa5\x9f', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x87\x81', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\xa5\x97', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x86\x90', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x87\xa4', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x87\x86', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x86\x94', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\xa5\x8e', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x86\xa4', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\xa5\x9a', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x86\xbc', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\xa5\x92', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x86\x99', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x86\x98', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x86\x92', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x87\xa5', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x87\x84', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x86\xa6', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\xa5\x9b', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x87\x80', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\xa5\x93', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x86\x96', form='infix', stretchy='true', scaling='uniform', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x86\x97', form='infix', stretchy='true', scaling='uniform', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='=', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='<', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='>', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='!=', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='==', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='<=', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='>=', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\xa1', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\x8d', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\x90', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x88\xa5', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\xa9\xb5', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\x82', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x87\x8c', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\xa5', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x8b\x9b', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\xa7', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\xaa\xa2', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\xb7', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\xa9\xbe', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\xb3', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\x8e', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\x8f', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x8a\xb2', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\xa7\x8f', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x8a\xb4', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\xa4', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x8b\x9a', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\xa6', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\xb6', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\xaa\xa1', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\xa9\xbd', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\xb2', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\xab', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\xaa', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\xa2', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\xad', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x88\xa6', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\xa0', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\x82\xcc\xb8', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\xaf', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\xb1', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\xa6\xcc\xb8', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\xab\xcc\xb8', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\xb9', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\xa9\xbe\xcc\xb8', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\xb5', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\x8e\xcc\xb8', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\x8f\xcc\xb8', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x8b\xaa', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\xa7\x8f\xcc\xb8', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x8b\xac', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\xae', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\xb0', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\xb8', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\xaa\xcc\xb8', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\xa9\xbd\xcc\xb8', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\xb4', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\xaa\xa2\xcc\xb8', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\xaa\xa1\xcc\xb8', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x8a\x80', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\xaa\xaf\xcc\xb8', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x8b\xa0', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x8b\xab', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\xa7\x90\xcc\xb8', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x8b\xad', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x8a\x81', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\xaa\xb0\xcc\xb8', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x8b\xa1', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\xbf\xcc\xb8', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\x81', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\x84', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\x87', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\x89', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x88\xa4', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\xba', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\xaa\xaf', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\xbc', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\xbe', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x88\xb7', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x88\x9d', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x87\x8b', form='infix', stretchy='true', scaling='horizontal', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x8a\xb3', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\xa7\x90', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x8a\xb5', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\xbb', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\xaa\xb0', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\xbd', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\xbf', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x88\xbc', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\x83', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\x85', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x89\x88', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x8a\xa5', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x88\xa3', form='infix', lspace='thickmathspace', rspace='thickmathspace'}
createEntry{content='\xe2\x8a\x94', form='infix', stretchy='true', scaling='uniform', lspace='mediummathspace', rspace='mediummathspace'}
createEntry{content='\xe2\x8b\x83', form='infix', stretchy='true', scaling='uniform', lspace='mediummathspace', rspace='mediummathspace'}
createEntry{content='\xe2\x8a\x8e', form='infix', stretchy='true', scaling='uniform', lspace='mediummathspace', rspace='mediummathspace'}
createEntry{content='-', form='infix', lspace='mediummathspace', rspace='mediummathspace'}
createEntry{content='\xe2\x88\x92', form='infix', lspace='mediummathspace', rspace='mediummathspace'}
createEntry{content='+', form='infix', lspace='mediummathspace', rspace='mediummathspace'}
createEntry{content='\xe2\x8b\x82', form='infix', stretchy='true', scaling='uniform', lspace='mediummathspace', rspace='mediummathspace'}
createEntry{content='\xe2\x88\x93', form='infix', lspace='mediummathspace', rspace='mediummathspace'}
createEntry{content='\xc2\xb1', form='infix', lspace='mediummathspace', rspace='mediummathspace'}
createEntry{content='\xe2\x8a\x93', form='infix', stretchy='true', scaling='uniform', lspace='mediummathspace', rspace='mediummathspace'}
createEntry{content='\xe2\x8b\x81', form='prefix', largeop='true', movablelimits='true', stretchy='true', scaling='uniform', lspace='0em', rspace='thinmathspace'}
createEntry{content='\xe2\x8a\x96', form='prefix', largeop='true', movablelimits='true', lspace='0em', rspace='thinmathspace'}
createEntry{content='\xe2\x8a\x95', form='prefix', largeop='true', movablelimits='true', lspace='0em', rspace='thinmathspace'}
createEntry{content='\xe2\x88\x91', form='prefix', largeop='true', movablelimits='true', stretchy='true', scaling='uniform', lspace='0em', rspace='thinmathspace'}
createEntry{content='\xe2\x8b\x83', form='prefix', largeop='true', movablelimits='true', stretchy='true', scaling='uniform', lspace='0em', rspace='thinmathspace'}
createEntry{content='\xe2\x8a\x8e', form='prefix', largeop='true', movablelimits='true', stretchy='true', scaling='uniform', lspace='0em', rspace='thinmathspace'}
createEntry{content='lim', form='prefix', movablelimits='true', lspace='0em', rspace='thinmathspace'}
createEntry{content='max', form='prefix', movablelimits='true', lspace='0em', rspace='thinmathspace'}
createEntry{content='min', form='prefix', movablelimits='true', lspace='0em', rspace='thinmathspace'}
createEntry{content='\xe2\x8a\x96', form='infix', lspace='thinmathspace', rspace='thinmathspace'}
createEntry{content='\xe2\x8a\x95', form='infix', lspace='thinmathspace', rspace='thinmathspace'}
createEntry{content='\xe2\x88\xb2', form='prefix', largeop='true', stretchy='true', scaling='uniform', lspace='0em', rspace='0em'}
createEntry{content='\xe2\x88\xae', form='prefix', largeop='true', stretchy='true', scaling='uniform', lspace='0em', rspace='0em'}
createEntry{content='\xe2\x88\xb3', form='prefix', largeop='true', stretchy='true', scaling='uniform', lspace='0em', rspace='0em'}
createEntry{content='\xe2\x88\xaf', form='prefix', largeop='true', stretchy='true', scaling='uniform', lspace='0em', rspace='0em'}
createEntry{content='\xe2\x88\xab', form='prefix', largeop='true', stretchy='true', scaling='uniform', lspace='0em', rspace='0em'}
createEntry{content='\xe2\x8b\x93', form='infix', lspace='thinmathspace', rspace='thinmathspace'}
createEntry{content='\xe2\x8b\x92', form='infix', lspace='thinmathspace', rspace='thinmathspace'}
createEntry{content='\xe2\x89\x80', form='infix', lspace='thinmathspace', rspace='thinmathspace'}
createEntry{content='\xe2\x8b\x80', form='prefix', largeop='true', movablelimits='true', stretchy='true', scaling='uniform', lspace='0em', rspace='thinmathspace'}
createEntry{content='\xe2\x8a\x97', form='prefix', largeop='true', movablelimits='true', lspace='0em', rspace='thinmathspace'}
createEntry{content='\xe2\x88\x90', form='prefix', largeop='true', movablelimits='true', stretchy='true', scaling='uniform', lspace='0em', rspace='thinmathspace'}
createEntry{content='\xe2\x88\x8f', form='prefix', largeop='true', movablelimits='true', stretchy='true', scaling='uniform', lspace='0em', rspace='thinmathspace'}
createEntry{content='\xe2\x8b\x82', form='prefix', largeop='true', movablelimits='true', stretchy='true', scaling='uniform', lspace='0em', rspace='thinmathspace'}
createEntry{content='\xe2\x88\x90', form='infix', lspace='thinmathspace', rspace='thinmathspace'}
createEntry{content='\xe2\x8b\x86', form='infix', lspace='thinmathspace', rspace='thinmathspace'}
createEntry{content='\xe2\x8a\x99', form='prefix', largeop='true', movablelimits='true', lspace='0em', rspace='thinmathspace'}
createEntry{content='*', form='infix', lspace='thinmathspace', rspace='thinmathspace'}
createEntry{content='\xe2\x81\xa2', form='infix', lspace='0em', rspace='0em'}
createEntry{content='\xc2\xb7', form='infix', lspace='thinmathspace', rspace='thinmathspace'}
createEntry{content='\xe2\x8a\x97', form='infix', lspace='thinmathspace', rspace='thinmathspace'}
createEntry{content='\xe2\x8b\x81', form='infix', lspace='thinmathspace', rspace='thinmathspace'}
createEntry{content='\xe2\x8b\x80', form='infix', lspace='thinmathspace', rspace='thinmathspace'}
createEntry{content='\xe2\x8b\x84', form='infix', lspace='thinmathspace', rspace='thinmathspace'}
createEntry{content='\xe2\x88\x96', form='infix', stretchy='true', scaling='uniform', lspace='thinmathspace', rspace='thinmathspace'}
createEntry{content='/', form='infix', stretchy='true', scaling='uniform', lspace='thinmathspace', rspace='thinmathspace'}
createEntry{content='-', form='prefix', lspace='0em', rspace='veryverythinmathspace'}
createEntry{content='\xe2\x88\x92', form='prefix', lspace='0em', rspace='veryverythinmathspace'}
createEntry{content='+', form='prefix', lspace='0em', rspace='veryverythinmathspace'}
createEntry{content='\xe2\x88\x93', form='prefix', lspace='0em', rspace='veryverythinmathspace'}
createEntry{content='\xc2\xb1', form='prefix', lspace='0em', rspace='veryverythinmathspace'}
createEntry{content='.', form='infix', lspace='0em', rspace='0em'}
createEntry{content='\xe2\xa8\xaf', form='infix', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='**', form='infix', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xe2\x8a\x99', form='infix', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xe2\x88\x98', form='infix', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xe2\x96\xa1', form='prefix', lspace='0em', rspace='verythinmathspace'}
createEntry{content='\xe2\x88\x87', form='prefix', lspace='0em', rspace='verythinmathspace'}
createEntry{content='\xe2\x88\x82', form='prefix', lspace='0em', rspace='verythinmathspace'}
createEntry{content='\xe2\x85\x85', form='prefix', lspace='0em', rspace='verythinmathspace'}
createEntry{content='\xe2\x85\x86', form='prefix', lspace='0em', rspace='verythinmathspace'}
createEntry{content='\xe2\x88\x9a', form='prefix', stretchy='true', scaling='uniform', lspace='0em', rspace='verythinmathspace'}
createEntry{content='\xe2\x87\x93', form='infix', stretchy='true', scaling='vertical', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xe2\x9f\xb8', form='infix', stretchy='true', scaling='horizontal', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xe2\x9f\xba', form='infix', stretchy='true', scaling='horizontal', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xe2\x9f\xb9', form='infix', stretchy='true', scaling='horizontal', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xe2\x87\x91', form='infix', stretchy='true', scaling='vertical', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xe2\x87\x95', form='infix', stretchy='true', scaling='vertical', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xe2\x86\x93', form='infix', stretchy='true', scaling='vertical', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xe2\xa4\x93', form='infix', stretchy='true', scaling='vertical', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xe2\x87\xb5', form='infix', stretchy='true', scaling='vertical', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xe2\x86\xa7', form='infix', stretchy='true', scaling='vertical', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xe2\xa5\xa1', form='infix', stretchy='true', scaling='uniform', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xe2\x87\x83', form='infix', stretchy='true', scaling='uniform', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xe2\xa5\x99', form='infix', stretchy='true', scaling='uniform', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xe2\xa5\x91', form='infix', stretchy='true', scaling='uniform', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xe2\xa5\xa0', form='infix', stretchy='true', scaling='uniform', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xe2\x86\xbf', form='infix', stretchy='true', scaling='uniform', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xe2\xa5\x98', form='infix', stretchy='true', scaling='uniform', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xe2\x9f\xb5', form='infix', stretchy='true', scaling='horizontal', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xe2\x9f\xb7', form='infix', stretchy='true', scaling='horizontal', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xe2\x9f\xb6', form='infix', stretchy='true', scaling='horizontal', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xe2\xa5\xaf', form='infix', stretchy='true', scaling='horizontal', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xe2\xa5\x9d', form='infix', stretchy='true', scaling='horizontal', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xe2\x87\x82', form='infix', stretchy='true', scaling='horizontal', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xe2\xa5\x95', form='infix', stretchy='true', scaling='horizontal', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xe2\xa5\x8f', form='infix', stretchy='true', scaling='horizontal', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xe2\xa5\x9c', form='infix', stretchy='true', scaling='horizontal', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xe2\x86\xbe', form='infix', stretchy='true', scaling='horizontal', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xe2\xa5\x94', form='infix', stretchy='true', scaling='horizontal', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xe2\x86\x91', form='infix', stretchy='true', scaling='vertical', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xe2\xa4\x92', form='infix', stretchy='true', scaling='vertical', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xe2\x87\x85', form='infix', stretchy='true', scaling='vertical', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xe2\x86\x95', form='infix', stretchy='true', scaling='vertical', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xe2\xa5\xae', form='infix', stretchy='true', scaling='vertical', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xe2\x86\xa5', form='infix', stretchy='true', scaling='vertical', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='^', form='infix', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='<>', form='infix', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\'', form='postfix', lspace='verythinmathspace', rspace='0em'}
createEntry{content='\xe2\x80\xb2', form='postfix', lspace='verythinmathspace', rspace='0em'}
createEntry{content='!', form='postfix', lspace='verythinmathspace', rspace='0em'}
createEntry{content='!!', form='postfix', lspace='verythinmathspace', rspace='0em'}
createEntry{content='~', form='infix', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='@', form='infix', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='--', form='postfix', lspace='verythinmathspace', rspace='0em'}
createEntry{content='--', form='prefix', lspace='0em', rspace='verythinmathspace'}
createEntry{content='++', form='postfix', lspace='verythinmathspace', rspace='0em'}
createEntry{content='++', form='prefix', lspace='0em', rspace='verythinmathspace'}
createEntry{content='\xe2\x81\xa1', form='infix', lspace='0em', rspace='0em'}
createEntry{content='?', form='infix', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='_', form='infix', lspace='verythinmathspace', rspace='verythinmathspace'}
createEntry{content='\xcb\x98', form='postfix', accent='true', lspace='0em', rspace='0em'}
createEntry{content='\xc2\xb8', form='postfix', accent='true', lspace='0em', rspace='0em'}
createEntry{content='`', form='postfix', accent='true', lspace='0em', rspace='0em'}
createEntry{content='\xcb\x99', form='postfix', accent='true', lspace='0em', rspace='0em'}
createEntry{content='\xcb\x9d', form='postfix', accent='true', lspace='0em', rspace='0em'}
createEntry{content='\xe2\x86\x90', form='postfix', accent='true', stretchy='true', scaling='horizontal', lspace='0em', rspace='0em'}
createEntry{content='\xe2\x86\x94', form='postfix', accent='true', stretchy='true', scaling='horizontal', lspace='0em', rspace='0em'}
createEntry{content='\xe2\xa5\x8e', form='postfix', accent='true', stretchy='true', scaling='horizontal', lspace='0em', rspace='0em'}
createEntry{content='\xe2\x86\xbc', form='postfix', accent='true', stretchy='true', scaling='horizontal', lspace='0em', rspace='0em'}
createEntry{content='\xc2\xb4', form='postfix', accent='true', lspace='0em', rspace='0em'}
createEntry{content='\xe2\x86\x92', form='postfix', accent='true', stretchy='true', scaling='horizontal', lspace='0em', rspace='0em'}
createEntry{content='\xe2\x87\x80', form='postfix', accent='true', stretchy='true', scaling='horizontal', lspace='0em', rspace='0em'}
createEntry{content='\xcb\x9c', form='postfix', accent='true', stretchy='true', scaling='horizontal', lspace='0em', rspace='0em'}
createEntry{content='\xc2\xa8', form='postfix', accent='true', lspace='0em', rspace='0em'}
createEntry{content='\xcc\x91', form='postfix', accent='true', lspace='0em', rspace='0em'}
createEntry{content='\xcb\x87', form='postfix', accent='true', stretchy='true', scaling='horizontal', lspace='0em', rspace='0em'}
createEntry{content='^', form='postfix', accent='true', stretchy='true', scaling='horizontal', lspace='0em', rspace='0em'}
createEntry{content='\xc2\xaf', form='postfix', accent='true', stretchy='true', scaling='horizontal', lspace='0em', rspace='0em'}
createEntry{content='\xef\xb8\xb7', form='postfix', accent='true', stretchy='true', scaling='horizontal', lspace='0em', rspace='0em'}
createEntry{content='\xe2\x8e\xb4', form='postfix', accent='true', stretchy='true', scaling='horizontal', lspace='0em', rspace='0em'}
createEntry{content='\xef\xb8\xb5', form='postfix', accent='true', stretchy='true', scaling='horizontal', lspace='0em', rspace='0em'}
createEntry{content='\xe2\x83\x9b', form='postfix', accent='true', lspace='0em', rspace='0em'}
createEntry{content='\xcc\xb2', form='postfix', accent='true', stretchy='true', scaling='horizontal', lspace='0em', rspace='0em'}
createEntry{content='\xef\xb8\xb8', form='postfix', accent='true', stretchy='true', scaling='horizontal', lspace='0em', rspace='0em'}
createEntry{content='\xe2\x8e\xb5', form='postfix', accent='true', stretchy='true', scaling='horizontal', lspace='0em', rspace='0em'}
createEntry{content='\xef\xb8\xb6', form='postfix', accent='true', stretchy='true', scaling='horizontal', lspace='0em', rspace='0em'}
