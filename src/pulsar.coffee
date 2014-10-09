# Description:
#   Deploy applications with pulsar
#
# Commands:
#   hubot deploy:pending <application> <environment> - Show pending changes
#   hubot deploy <application> <environment> - Deploy application

_ = require('underscore')
pulsarApi = require('./pulsar-api')
jobConfirmationList = require('./job-confirmation-list.coffee')
PulsarJob = require('./pulsar-job')

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0'

module.exports = (robot) ->
  robot.respond /deploy (-v|)\s?([^\s]+) ([^\s]+)$/i, (chat) ->
    application = chat.match[2]
    environment = chat.match[3]
    isVerbose = chat.match[1] == '-v'

    pending = new PulsarJob(application, environment, 'deploy:pending', chat, true)
    pending.onfinish = ()->
      if(@.data.status != 'FINISHED')
        return
      deploy = new PulsarJob(application, environment, 'deploy', chat, isVerbose)
      deploy.onstart = () ->
        chat.send "#{@}. More info here #{@.data.url}"
      deploy.onfinish = () ->
        chat.send "#{@} finished with status: #{@data.status}. More details here #{@data.url}"
      jobConfirmationList.add(deploy)
    pending.run()

  robot.respond /deploy pending ([^\s]+) ([^\s]+)$/i, (chat) ->
    job = new PulsarJob(chat.match[1], chat.match[2], 'deploy:pending', chat, true)
    job.run()

  robot.respond /jobs/i, (chat) ->
    pulsarApi.get('/jobs')
    .on 'complete', (response) ->
      message = 'Jobs:'
      _.each response, (job) ->
        message += "\n #{job.status} job #{job.task} #{job.app} #{job.env} with ID #{job.id}"
      chat.send message

  robot.respond /((?:y(?:es)?)|(?:no?)|(?:ok))$/i, (chat) ->
    answer = chat.match[1]
    isYes = answer.charAt(0) == 'y' || answer.charAt(0) == 'o'
    if(isYes)
      job = jobConfirmationList.get(chat)
      job.run()
    else
      jobConfirmationList.remove(chat)
