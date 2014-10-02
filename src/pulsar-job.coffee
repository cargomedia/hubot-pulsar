rest = require('restler')
_ = require('underscore')
jobChangeListener = require('./job-change-listener')

class PulsarJob

  constructor: (@application, @environment, @task, @chat, @isVerbose) ->
    @data = {}
    @onstart = null
    @onfinish = null

  PulsarJob.API_URL = ''

  run: () ->
    @chat.send @ + ' started'
    rest.post(PulsarJob.API_URL + @application + '/' + @environment,
      data:
        task: @task
    ).on('complete', (jobData) =>
      if jobData.id
        @setData(jobData)
        jobChangeListener.addJob(@)
        if @onstart
          @onstart()
      else
        @chat.send @ + ' failed'
    ).on('error', (error) =>
      @chat.send 'Error: ' + JSON.stringify error
    ).on('fail', (error) =>
      @chat.send 'Fail: ' + JSON.stringify error
    )

  setData: (jobData)->
    _.extend(@data, jobData)

  toString: ()->
    result = "#{@task} '#{@application}' to '#{@environment}'"
    if @data.id
      result += ' id: ' + @data.id
    return result

module.exports = (apiUrl)->
  jobChangeListener.connect(apiUrl + 'websocket')
  PulsarJob.API_URL = apiUrl
  return PulsarJob
