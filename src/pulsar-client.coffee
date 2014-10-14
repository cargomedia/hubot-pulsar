_ = require('underscore')
{RestlerService} = require('restler').Service

class PulsarClient extends RestlerService

  constructor: (url, token) ->
    defaults = {}
    defaults.baseURL = url
    if token
      defaults.username = token
      defaults.password = 'x-oauth-basic'
    super(defaults)

  runJob: (job) ->
    job.run(this)

  jobs: (callback) ->
    @get('/jobs')
    .on 'complete', (jobs) ->
        callback(_.toArray(jobs))


module.exports = new PulsarApi()
