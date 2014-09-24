_ = require('underscore')
config = require('./config')
rest = require('restler')

PulsarApi = rest.service(() ->
  if config.pulsarAuthToken
    @defaults.username = config.pulsarAuthToken
    @defaults.password = 'x-oauth-basic'
  return
,
  baseURL: config.pulsarUrl
)

module.exports = new PulsarApi
