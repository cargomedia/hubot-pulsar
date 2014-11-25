PulsarApiClient = require('pulsar-rest-api-client-node')
Config = require('./config')

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0'
global.config = new Config(Config.findConfigPath())
global.pulsarApi = new PulsarApiClient(config.pulsarApi)

module.exports = (robot) ->
  require('./helpers')(robot)
  require('./jobs')(robot)
