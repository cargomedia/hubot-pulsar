var _ = require('underscore');
var fs = require('fs');

function Config(filePath) {
  var data = this.parse(filePath);
  this.validate(data);
  return Object.freeze(data);
}

Config.prototype.parse = function(filePath) {
  var content = fs.readFileSync(filePath, {
    encoding: 'utf8'
  });
  return JSON.parse(content);
};

Config.prototype.validate = function(data) {
  var pulsarApi = data.pulsarApi;
  if (!pulsarApi) {
    throw new Error('Define `pulsarApi` config options');
  }
};

Config.findConfigPath = function() {
  if (process.env.HUBOT_PULSAR_CONFIG) {
    return process.env.HUBOT_PULSAR_CONFIG;
  }
  return './pulsar.config.json';
};

module.exports = Config;
