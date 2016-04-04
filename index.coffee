fs = require 'fs'
path = require 'path'

module.exports = (robot) ->
  scriptsPath = path.resolve(__dirname, 'src')
  robot.loadFile(scriptsPath, 'index.coffee')
