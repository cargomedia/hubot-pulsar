restler = require('restler')

class PulsarApiRest

  constructor: (url, token) ->
    restService = restler.service((url, token) ->
      if token
        @defaults.username = token
        @defaults.password = 'x-oauth-basic'
      return
    ,
      baseURL: url
    )
    return new restService(url, token)

module.exports = PulsarApiRest
