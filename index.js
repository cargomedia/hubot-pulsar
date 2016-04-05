var fs = require('fs');
var path = require('path');

module.exports = function(robot) {
  var scriptsPath = path.resolve(__dirname, 'src');
  return robot.loadFile(scriptsPath, 'index.js');
};
