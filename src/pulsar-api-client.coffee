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
    @.post("/#{job.app}/#{job.env}",
      data:
        task: job.task
    ).on('complete', (jobData) =>
      if jobData.id
        job.setData(jobData)
        @.addJob(job)
        job.emit 'create'
      else
        job.emit 'error', 'Got empty job id. Job was not created.'
    ).on('error', (error) =>
      job.emit 'error', error
    ).on('fail', (error) =>
      job.emit 'error', error
    )

  jobs: (callback) ->
    @get('/jobs').on 'complete', (jobs) ->
      callback(jobs)


module.exports = PulsarClient
