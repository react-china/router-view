
Immutable = require 'immutable'

{fromJS} = Immutable
o = Immutable.Map()

trimSlash = (chunk) ->
  if chunk.substr(0, 1) is '/'
    trimSlash chunk.substr(1)
  else if chunk.substr(-1) is '/'
    trimSlash chunk.substr(0, chunk.length-1)
  else chunk

parseQuery = (data, chunks) ->
  if (chunks.size is 0)
    data
  else
    chunk = chunks.first()
    pieces = chunk.split('=')
    [key, value] = pieces
    key = decodeURIComponent key
    value = decodeURIComponent value
    parseQuery data.set(key, value), chunks.slice(1)

routerBase = Immutable.fromJS
  name: null
  data: {}
  query: {}
  router: null

parsePathSegments = (pathSegments, rules, theQuery) ->
  if pathSegments.size is 0
    routerBase
    .set 'name', 'home'
    .set 'query', theQuery
  else
    pathName = pathSegments.get 0
    if rules.has(pathName)
      argsTemplate = rules.get pathName
      restOfSegments = pathSegments.rest()
      if restOfSegments.size < argsTemplate.size
        routerBase
        .set 'name', '404'
        .set 'query', theQuery
      else
        data = argsTemplate.reduce (acc, argName, idx) ->
          acc.set argName, restOfSegments.get(idx)
        , o
        nextPathSegments = restOfSegments.slice(argsTemplate.size)
        if nextPathSegments.size > 0
          childRouter = parsePathSegments nextPathSegments, rules, theQuery
        else
          childRouter = null
        if childRouter?
          routerBase
          .set 'name', pathName
          .set 'data', data
          .set 'router', childRouter
        else
          routerBase
          .set 'name', pathName
          .set 'data', data
          .set 'query', theQuery
    else
      routerBase
      .set 'name', '404'
      .set 'query', theQuery

parseAddress = (address, rules) ->
  [chunkPath, chunkQuery] = address.split('?')
  chunkQuery = chunkQuery or ''

  chunkPath = trimSlash(chunkPath)
  thePath = if (chunkPath.length > 0) then chunkPath.split('/') else []
  pathSegments = Immutable.fromJS(thePath.map decodeURIComponent)
  if chunkQuery.length > 0
    theQuery = parseQuery o, Immutable.fromJS(chunkQuery.split('&'))
  else
    theQuery = o

  parsePathSegments pathSegments, rules, theQuery

stringifyQuery = (query) ->
  stringQuery = query
  .filter (value, key) ->
    value?
  .map (value, key) ->
    key = encodeURIComponent key
    value = encodeURIComponent value
    "#{key}=#{value}"
  .join '&'

addressRunner = (acc, router, rules, query) ->
  if not router?
    queryPart = stringifyQuery query
    if queryPart.length > 0
      if acc.length > 0
        "#{acc[...-1]}?#{queryPart}"
      else
        queryPart
    else
      acc
  else
    routerName = router.get 'name'
    if rules.has(routerName)
      argsTemplate = rules.get routerName
      nextQuery = router.get('query') or o
      if routerName is 'home' and argsTemplate.size is 0
        addressRunner acc, null, rules, nextQuery
      else
        args = argsTemplate.map (argName) ->
          router.get('data').get(argName)
        pieces = args.unshift routerName
        nextAcc = "#{acc}#{pieces.join '/'}/"
        nextRouter = router.get('router')
        addressRunner nextAcc, nextRouter, rules, nextQuery
    else
      "#{acc}404"

makeAddress = (router, rules) ->
  addressRunner '/', router, rules, router.get('query')

exports.trimSlash = trimSlash
exports.parseQuery = parseQuery
exports.makeAddress = makeAddress
exports.parseAddress = parseAddress
