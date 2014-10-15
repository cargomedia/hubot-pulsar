_ = require('underscore')
JobChangeListener = require('./job-change-listener')
RestlerService = require('restler').Service

class PulsarClient extends RestlerService

  constructor: (url, token) ->
    defaults = {}
    defaults.baseURL = url
    if token
      defaults.username = token
      defaults.password = 'x-oauth-basic'
    super(defaults)
    @jobChangeListener = new JobChangeListener(url, token)

  addJob: (job) ->
    @jobChangeListener.addJob(job)

  runJob: (job) ->
    job.run(@)

  jobs: (callback) ->
    @get('/jobs').on 'complete', (jobs) ->
      callback(jobs)


module.exports = PulsarClient
