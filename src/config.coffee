_ = require('underscore')
fs = require('fs')

class Config
  constructor: (filePath) ->
    data = @parse(filePath)
    @validate(data)
    return Object.freeze(data)

  parse: (filePath) ->
    content = fs.readFileSync(filePath, {encoding: 'utf8'})
    return JSON.parse(content)

  validate: (data) ->
    throw new Error('Specify pulsar-rest-api url `pulsarUrl`') unless data.pulsarUrl

config = new Config(__dirname + '/../config.json')
module.exports = config
