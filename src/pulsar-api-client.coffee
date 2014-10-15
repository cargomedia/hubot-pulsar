_ = require('underscore')
PulsarApiWebsocket = require('./pulsar-api-websocket')
RestlerService = require('restler').Service

class PulsarClient extends RestlerService

  constructor: (url, token) ->
    defaults = {}
    defaults.baseURL = url
    if token
      defaults.username = token
      defaults.password = 'x-oauth-basic'
    super(defaults)
    @pulsarWebsocket = new PulsarApiWebsocket(url, token)

  addJob: (job) ->
    @pulsarWebsocket.addJob(job)

  runJob: (job) ->
    job.run(@)

  jobs: (callback) ->
    @get('/jobs').on 'complete', (jobs) ->
      callback(jobs)


module.exports = PulsarClient
