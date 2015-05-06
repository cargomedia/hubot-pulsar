PulsarApiClient = require('pulsar-rest-api-client-node')
Config = require('./config')

config = new Config(Config.findConfigPath())
global.pulsarApi = new PulsarApiClient(config.pulsarApi)

module.exports = (robot) ->
  require('./auth')(robot)
  require('./deploy')(robot)
