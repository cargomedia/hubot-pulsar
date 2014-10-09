# Description:
#   Deploy applications with pulsar
#
# Commands:
#   hubot deploy:pending <application> <environment> - Show pending changes
#   hubot deploy <application> <environment> - Deploy application

_ = require('underscore')
config = require('./config')
pulsarApi = require('./pulsar-api')
jobConfirmationList = require('./job-confirmation-list.coffee')
PulsarJob = require('./pulsar-job')

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0'

module.exports = (robot) ->
  isAuthorized = (chat)->
    if robot.auth.hasRole(chat.envelope.user, config.hipchatRoles)
      return true

    chat.reply 'You don\'t have the rights to run pulsar commands'
    chat.finish()
    return false

  robot.respond /deploy (-v|)\s?([^\s]+) ([^\s]+)$/i, (chat) ->
    return unless isAuthorized(chat)
    application = chat.match[2]
    environment = chat.match[3]
    isVerbose = chat.match[1] == '-v'

    pending = new PulsarJob(application, environment, 'deploy:pending')
    pending.on('finish', ()->
      chat.send @data.output
      return if(@data.status != 'FINISHED')
      deploy = new PulsarJob(application, environment, 'deploy')
      deploy.on('create', () ->
        chat.send "Job was created: #{@}. More info here #{@data.url}"
      ).on('finish', () ->
        chat.send "#{@} finished with status: #{@data.status}. More details here #{@data.url}"
      ).on('error', () ->
        chat.send "#{@} failed due to #{JSON.stringify(error)}"
      )
      if isVerbose
        deploy.on('change', (output)->
          chat.send output
        )
      jobConfirmationList.add(chat, deploy)
    ).on('error', (error)->
      chat.send "#{@} failed due to #{JSON.stringify(error)}"
    )
    pending.run()
    chat.send pending + ' in progress'

  robot.respond /deploy pending ([^\s]+) ([^\s]+)$/i, (chat) ->
    return unless isAuthorized(chat)
    job = new PulsarJob(chat.match[1], chat.match[2], 'deploy:pending')
    job.on('change', (output) ->
      chat.send output
    ).on('error', (error)->
      chat.send "#{@} failed due to #{JSON.stringify(error)}"
    )
    job.run()

  robot.respond /jobs/i, (chat) ->
    return unless isAuthorized(chat)
    pulsarApi.get('/jobs')
    .on 'complete', (response) ->
      message = 'Jobs:'
      _.each response, (job) ->
        message += "\n #{job.status} job #{job.task} #{job.app} #{job.env} with ID #{job.id}"
      chat.send message

  robot.respond /((?:y(?:es)?)|(?:no?)|(?:ok))$/i, (chat) ->
    return unless isAuthorized(chat)
    answer = chat.match[1]
    isYes = answer.charAt(0) == 'y' || answer.charAt(0) == 'o'
    if(isYes)
      job = jobConfirmationList.get(chat)
      job.run()
      chat.send job + ' in progress'
    else
      jobConfirmationList.remove(chat)
