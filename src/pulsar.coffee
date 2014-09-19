# Description:
#   Deploy applications with pulsar
#
# Commands:
#   hubot deploy:pending <application> <environment> - Show pending changes
#   hubot deploy <application> <environment> - Deploy application

_ = require('underscore')
jobChangeListener = require('./job-change-listener')
API_URL = 'https://api.pulsar.local:8001/'
PulsarJob = require('./pulsar-job')(API_URL)

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0'

jobChangeListener.connect(API_URL + 'websocket')

module.exports = (robot) ->
  robot.respond /deploy (-v|)\s?([^\s]+) ([^\s]+)$/i, (chat) ->
    job = new PulsarJob(chat.match[2], chat.match[3], 'deploy', chat)
    isVerbose = chat.match[1] == '-v'
    job.onstart = (jobData) ->
      jobUrl = jobData.url
      jobChangeListener.addJob(jobData.id, chat, isVerbose, (jobData)->
        chat.send "Job #{jobData.id} finished with status: #{jobData.status}. More details here #{jobUrl}"
      )
      chat.send "More info here #{jobUrl}"
    job.run()

  robot.respond /deploy pending ([^\s]+) ([^\s]+)$/i, (chat) ->
    job = new PulsarJob(chat.match[1], chat.match[2], 'deploy:pending', chat)
    job.onstart = (jobData) ->
      jobChangeListener.addJob(jobData.id, chat, true)
    job.run()

  robot.respond /jobs/i, (chat) ->
    rest.get(API_URL + 'jobs')
    .on 'complete', (response) ->
      message = 'Jobs:'
      _.each response, (job) ->
        message += "\n #{job.status} job #{job.task} #{job.app} #{job.env} with ID #{job.id}"
      chat.send message
