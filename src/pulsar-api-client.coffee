_ = require('underscore')
PulsarApiRest = require('./pulsar-api-rest')
PulsarApiWebsocket = require('./pulsar-api-websocket')

class PulsarApiClient

  rest = null
  websocket = null

  constructor: (url, token) ->
    rest = new PulsarApiRest(url, token)
    websocket = new PulsarApiWebsocket(url, token)

  runJob: (job) ->
    rest.post("/#{job.app}/#{job.env}",
      data:
        task: job.task
    ).on('complete', (jobData) ->
      if jobData.id
        job.setData(jobData)
        websocket.addJob(job)
        job.emit 'create'
      else
        job.emit 'error', 'Got empty job id. Job was not created.'
    ).on('error', (error) ->
      job.emit 'error', error
    ).on('fail', (error) ->
      job.emit 'error', error
    )

  jobs: (callback) ->
    rest.get('/jobs').on 'complete', (jobs) ->
      callback(jobs)


module.exports = PulsarApiClient
