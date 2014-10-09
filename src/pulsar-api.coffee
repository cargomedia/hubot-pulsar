_ = require('underscore')
config = require('./config')
rest = require('restler')

PulsarApi = rest.service(() ->
  if config.pulsarApi.authToken
    @defaults.username = config.pulsarApi.authToken
    @defaults.password = 'x-oauth-basic'
  return
,
  baseURL: config.pulsarApi.url
)

module.exports = new PulsarApi
