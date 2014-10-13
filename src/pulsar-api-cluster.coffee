_ = require('underscore')
config = require('./config')
rest = require('restler')

class PulsarApiCluster
  constructor: ()->
    defaultApiConfig = _.omit(config.pulsarApi, 'auxiliary')
    @defaultApi = @_createApi(defaultApiConfig)
    @instanceMap = {}
    _.each(config.pulsarApi.auxiliary, (apiConfig, apiName)=>
      api = @_createApi(apiConfig)
      @instanceMap[apiName] = api
    )

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
