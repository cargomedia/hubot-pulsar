_ = require('underscore')
fs = require('fs')

class Config
  constructor: (filePath) ->
    filePath = @findConfig()
    data = @parse(filePath)
    @validate(data)
    return Object.freeze(data)

  findConfig: () ->
    if(process.env.HUBOT_PULSAR_CONFIG)
      return process.env.HUBOT_PULSAR_CONFIG
    hubotConfPath = './pulsar.config.json'
    if(fs.existsSync(hubotConfPath) && fs.statSync(hubotConfPath).isFile())
      return hubotConfPath
    return __dirname + '/../config.json'

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
