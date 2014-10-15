_ = require('underscore')
{EventEmitter} = require('events')

class PulsarJob extends EventEmitter

  constructor: (@app, @env, @task) ->
    @data = {}

  setData: (jobData)->
    _.extend(@data, jobData)

  toString: ()->
    result = "#{@task} '#{@app}' to '#{@env}'"
    if @data.id
      result += ' id: ' + @data.id
    return result

module.exports = PulsarJob
