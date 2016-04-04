# Description:
#   Deploy applications with pulsar
#
# Commands:
#   hubot deploy pending <application> <environment> - Show pending changes
#   hubot deploy <application> <environment> - Deploy application
#   hubot confirm deploy - Confirms the deploy that was requested by `deploy` command. Actual only if there was the requested deploy.
#   hubot cancel deploy - Cancels the deploy that was requested by `deploy` command. Actual only if there was the requested deploy.

PulsarApiClient = require('pulsar-rest-api-client-node')
Config = require('./config')

config = new Config(Config.findConfigPath())
global.pulsarApi = new PulsarApiClient(config.pulsarApi)

module.exports = (robot) ->
  require('./auth')(robot)
  require('./deploy')(robot)
