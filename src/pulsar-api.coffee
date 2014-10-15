_ = require('underscore')
config = require('./config')
rest = require('restler')
async = require('async')
PulsarClient = require('./pulsar-client')

class PulsarApi

  _clientMap = {}

  constructor: ()->
    pulsarApiConfig = config.pulsarApi

    clientDefaultConfig = _.pick(pulsarApiConfig, 'url', 'token')
    @_clientDefault = new PulsarClient(clientDefaultConfig.url, clientDefaultConfig.authToken)

    _.each pulsarApiConfig.auxiliary, (clientConfig, key) ->
      clientConfig = _.defaults({}, clientConfig, clientDefaultConfig)
      _clientMap[key] = new PulsarClient(clientConfig.url, clientConfig.authToken)

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

    async.map clientList, getClientJobs (err, results) ->
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
