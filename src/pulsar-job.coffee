rest = require('restler')

PulsarJob = (application, environment, task, chat)->
  @application = application
  @environment = environment
  @task = task
  @chat = chat
  @onstart = null

PulsarJob.API_URL = ''

PulsarJob::run = ()->
  command = "#{@task} '#{@application}' to '#{@environment}'"
  @chat.send command + ' started'
  self = @
  rest.post(PulsarJob.API_URL + @application + '/' + @environment,
    data:
      task: @task
  ).on('complete', (job) =>
    if job.id
      @chat.send "#{command} -> assigned job ID #{job.id}"
      @onstart job if @onstart
    else
      @chat.send command + ' failed'
  ).on('error', (error) =>
    @chat.send 'Error: ' + JSON.stringify error
  ).on('fail', (error) =>
    @chat.send 'Fail: ' + JSON.stringify error
  )

module.exports = (url)->
  PulsarJob.API_URL = url
  return PulsarJob
