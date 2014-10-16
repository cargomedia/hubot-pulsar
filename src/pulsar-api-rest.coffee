RestlerService = require('restler').Service

class PulsarApiRest extends RestlerService

  constructor: (url, token) ->
    defaults = {}
    defaults.baseURL = url
    if token
      defaults.username = token
      defaults.password = 'x-oauth-basic'
    super(defaults)

module.exports = PulsarApiRest
