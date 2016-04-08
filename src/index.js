// Description:
//   Deploy applications with pulsar
//
// Commands:
//   hubot deploy pending <application> <environment> - Show pending changes
//   hubot deploy <application> <environment> - Deploy application
//   hubot deploy rollback <application> <environment> - Roll back to the previous release
//   hubot deploy restart <application> <environment> - Restarts application
//   hubot confirm deploy - Confirms the deploy that was requested by `deploy` command. Actual only if there was the requested deploy.
//   hubot cancel deploy - Cancels the deploy that was requested by `deploy` command. Actual only if there was the requested deploy.

var PulsarApiClient = require('pulsar-rest-api-client-node');
var Config = require('./config');
var config = new Config(Config.findConfigPath());
global.pulsarApi = new PulsarApiClient(config.pulsarApi);

module.exports = function(robot) {
  require('./auth')(robot);
  return require('./deploy')(robot);
};
