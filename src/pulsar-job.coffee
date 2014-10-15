_ = require('underscore')
{EventEmitter} = require('events')

class PulsarJob extends EventEmitter

  constructor: (@app, @env, @task) ->
    @data = {}

  run: (client) ->
    client.post("/#{@app}/#{@env}",
      data:
        task: @task
    ).on('complete', (jobData) =>
      if jobData.id
        @setData(jobData)
        client.addJob(@)
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
    result = "#{@task} '#{@app}' to '#{@env}'"
    if @data.id
      result += ' id: ' + @data.id
    return result

module.exports = PulsarJob
