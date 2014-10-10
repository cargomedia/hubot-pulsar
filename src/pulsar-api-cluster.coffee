_ = require('underscore')
config = require('./config')
rest = require('restler')

class PulsarApiCluster
  constructor: ()->
    apiConfigList = config.pulsarApi
    @instanceMap = {}
    _.each(apiConfigList, (apiConfig)=>
      name = @_getApiName(apiConfig.application, apiConfig.environment)
      api = @_createApi(apiConfig)
      @instanceMap[name] = api
      if(!name)
        @defaultApi = api
    )
    if(!@defaultApi)
      @defaultApi = _.first(@instanceMap)

  get: (application, environment) ->
    if(_.size(@instanceMap) == 1)
      return @defaultApi
    name = @_getApiName(application, environment)
    if(@instanceMap[name])
      return @instanceMap[name]
    else
      return @defaultApi

  _getApiName: (application, environment) ->
    name = ''
    name += application if application
    name += '/' + environment if environment
    return name

  _createApi: (config) ->
    return rest.service(() ->
      if config.authToken
        @defaults.username = config.authToken
        @defaults.password = 'x-oauth-basic'
      return
    ,
      baseURL: config.url
    )

module.exports = new PulsarApiCluster()
