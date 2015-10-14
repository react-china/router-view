
pathUtil = require './path'

Immutable = require 'immutable'

module.exports = pathUtil.expandRoutes [
  ['home', '/']
  ['demo', '/demo']
  ['skip', '/skip/~']
  ['team', 'team/:teamId']
  ['room', 'team/:teamId/room/:roomId']
  ['404', '404']
]
