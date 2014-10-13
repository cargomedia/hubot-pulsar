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
    pulsarApi = data.pulsarApi
    if(!pulsarApi)
      throw new Error('Define `pulsarApi` config options')
    @validatePulsarApiInstance(pulsarApi, 'pulsarApi')
    _.each(pulsarApi.auxiliary, (api, apiName)=>
      if(!/^\w+\/\w+$/i.test(apiName))
        throw new Error("Wrong pulsarApi auxiliary API name: '#{apiName}'. The acceptable format is: [{application}/{environment}].")
      @validatePulsarApiInstance(api, apiName)
    )

  validatePulsarApiInstance: (api, apiName)->
    if(!api.url)
      throw new Error("Define `#{apiName}.url` in the config")


config = new Config(__dirname + '/../config.json')
module.exports = config
