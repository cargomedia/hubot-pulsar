_ = require('underscore')
fs = require('fs')

class Config
  constructor: (filePath) ->
    data = @parse(filePath)
    @format(data)
    @validate(data)
    return Object.freeze(data)

  parse: (filePath) ->
    content = fs.readFileSync(filePath, {encoding: 'utf8'})
    return JSON.parse(content)

  format: (data)->
    if(data.pulsarApi && _.isObject(data.pulsarApi))
      data.pulsarApi = [data.pulsarApi]

  validate: (data) ->
    pulsarApiList = data.pulsarApi
    if(!pulsarApiList)
      throw new Error('Define `pulsarApi` config options')
    if(!_.isArray(pulsarApiList))
      throw new Error('Config option `pulsarApi` must be an array or an object')
    _.each(pulsarApiList, (api)->
      if(!api.url)
        throw new Error('Define `pulsarApi.url` in the config')
    )
    if(pulsarApiList.length > 1)
      hasDefaultApi = false
      _.each(pulsarApiList, (api)->
        if(!api.application)
          if(hasDefaultApi)
            throw new Error('Config option `pulsarApi.application` can be omitted only once for the default `pulsarApi`')
          else
            hasDefaultApi = true
      )

config = new Config(__dirname + '/../config.json')
module.exports = config
