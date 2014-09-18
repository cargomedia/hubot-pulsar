# Description:
#   Deploy applications with pulsar
#
# Commands:
#   hubot deploy:pending <application> <environment> - Show pending changes
#   hubot deploy <application> <environment> - Deploy application

_ = require('underscore')
jobChangeListener = require('./job-change-listener')
API_URL = 'https://api.pulsar.local:8001/'
runJob = require('./run-job')(API_URL)

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0'

jobChangeListener.connect(API_URL + 'websocket')

module.exports = (robot) ->
  robot.respond /deploy (-v|)\s?([^\s]+) ([^\s]+)$/i, (chat) ->
    isVerbose = chat.match[1] == '-v'
    application = chat.match[2]
    environment = chat.match[3]
    task = 'deploy'

    runJob(chat, application, environment, task, (job) ->
      jobUrl = job.url
      jobChangeListener.addJob(job.id, chat, isVerbose, (job)->
        chat.send "Job #{job.id} finished with status: #{job.status}. More details here #{jobUrl}"
      )
      chat.send "More info here #{jobUrl}"
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
