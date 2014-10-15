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

  getClient: (application, environment) ->
    name = @_getClientName(application, environment)
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

  _getClientName: (application, environment) ->
    name = ''
    name += application if application
    name += '/' + environment if environment
    return name

module.exports = new PulsarApi()
