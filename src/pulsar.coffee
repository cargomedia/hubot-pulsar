# Description:
#   Deploy applications with pulsar
#
# Commands:
#   hubot deploy:pending <application> <environment> - Show pending changes
#   hubot deploy <application> <environment> - Deploy application

spawn = require('child_process').spawn
rest = require('restler')
_ = require('underscore')
SockJS = require('node-sockjs-client')
API_URL = 'https://api.pulsar.local:8001/'

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0'

jobChangeListener = (->
  jobChatInfo = {}

  connect = (url) ->
    sock = new SockJS(url)
    sock.onmessage = (msg) ->
      data = JSON.parse(msg.data)
      updateJob(data.job) if data.event == 'job.change'

  updateJob = (job)->
    chatInfo = jobChatInfo[job.id]
    if chatInfo.isVerbose
      chat = chatInfo.chat
      lastSentPos = chatInfo.lastSentPos || 0
      chat.send job.output.substring(lastSentPos)
      chatInfo.lastSentPos = job.output.length - 1
    if job.status != 'RUNNING'
      chatInfo.complete(job) if chatInfo.complete
      delete jobChatInfo[job.id]

  addJob = (jobId, chat, isVerbose, complete) ->
    jobChatInfo[jobId] = {chat: chat, isVerbose: isVerbose, complete: complete}

  return {
    connect: connect
    addJob: addJob
  }
)()

jobChangeListener.connect(API_URL + 'websocket')

runJob = (chat, application, environment, task, success) ->
  command = "#{task} '#{application}' to '#{environment}'"
  chat.send command + ' started'
  rest.post(API_URL + application + '/' + environment,
    data:
      task: task
  ).on('complete', (job) ->
    if job.id
      chat.send "#{command} -> assigned job ID #{job.id}"
      success job
    else
      chat.send command + ' failed'
  ).on('error', (error) ->
    chat.send 'Error: ' + JSON.stringify error
  ).on('fail', (error) ->
    chat.send 'Fail: ' + JSON.stringify error
  )


module.exports = (robot) ->
  robot.respond /deploy (-v|)\s?([^\s]+) ([^\s]+)$/i, (chat) ->
    isVerbose = chat.match[1] == '-v'
    application = chat.match[2]
    environment = chat.match[3]
    task = 'deploy'

    runJob(chat, application, environment, task, (job) ->
      jobUrl = job.url
      chat.send "More info here #{jobUrl}"
      jobChangeListener.addJob(job.id, chat, isVerbose, (job)->
        chat.send "Job #{job.id} finished with status: #{job.status}. More details here #{jobUrl}"
      )
    )

  robot.respond /deploy pending ([^\s]+) ([^\s]+)$/i, (chat) ->
    application = chat.match[1]
    environment = chat.match[2]
    task = 'deploy:pending'
    runJob(chat, application, environment, task, (job) ->
      jobChangeListener.addJob(job.id, chat, true)
    )

  robot.respond /jobs/i, (chat) ->
    rest.get(API_URL + 'jobs')
    .on 'complete', (response) ->
      message = 'Jobs:'
      _.each response, (job) ->
        message += "\n #{job.status} job #{job.task} #{job.app} #{job.env} with ID #{job.id}"
      chat.send message
