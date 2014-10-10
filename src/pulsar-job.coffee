pulsarApiCluster = require('./pulsar-api-cluster')
rest = require('restler')
_ = require('underscore')
jobChangeListener = require('./job-change-listener')
{EventEmitter} = require('events')

class PulsarJob extends EventEmitter

  constructor: (@application, @environment, @task) ->
    @data = {}

  run: () ->
    pulsarApi = pulsarApiCluster.get(@application, @environment)
    pulsarApi.post("/#{@application}/#{@environment}",
      data:
        task: @task
    ).on('complete', (jobData) =>
      if jobData.id
        @setData(jobData)
        jobChangeListener.addJob(@)
        @emit 'create'
      else
        @emit 'error', 'Got empty job id. Job was not created.'
    ).on('error', (error) =>
      @emit 'error', error
    ).on('fail', (error) =>
      @emit 'error', error
    )

  setData: (jobData)->
    _.extend(@data, jobData)

  toString: ()->
    result = "#{@task} '#{@application}' to '#{@environment}'"
    if @data.id
      result += ' id: ' + @data.id
    return result

module.exports = PulsarJob
