_ = require('underscore')
config = require('./config')
async = require('async')
PulsarApiClient = require('./pulsar-api-client')

class PulsarApi

  _clientMap = {}

  constructor: ()->
    pulsarApiConfig = config.pulsarApi
    @_clientDefault = new PulsarApiClient(pulsarApiConfig.url, pulsarApiConfig.authToken)
    _.each pulsarApiConfig.auxiliary, (clientConfig, key) ->
      _clientMap[key] = new PulsarApiClient(clientConfig.url, clientConfig.authToken)

  getClientDefault: () ->
    @_clientDefault

  getClient: (app, env) ->
    name = @_getClientName(app, env)
    if (_clientMap[name])
      _clientMap[name]
    else
      @getClientDefault()

  runJob: (job) ->
    client = @getClient(job.app, job.env)
    client.runJob(job)

  jobs: (callback) ->
    clientList = _.toArray(_clientMap)
    clientList.unshift @_clientDefault

    getClientJobs = (client, callback) ->
      client.jobs(callback)

    async.map clientList, getClientJobs, (results) ->
      concatenator = (all, items) ->
        all.concat items
      jobs = _.reduce(results, concatenator, [])
      callback(jobs)

  _getClientName: (app, env) ->
    name = ''
    name += app if app
    name += '/' + env if env
    return name

module.exports = new PulsarApi()
