# Description:
#   Deploy applications with pulsar
#
# Commands:
#   hubot deploy:pending <application> <environment> - Show pending changes
#   hubot deploy <application> <environment> - Deploy application

_ = require('underscore')
Config = require('./config')
config = new Config(Config.findConfig())
PulsarApiClient = require('pulsar-rest-api-client-node')
pulsarJobConfirmList = require('./pulsar-job-confirm-list')

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0'
pulsarApi = new PulsarApiClient(config.pulsarApi)

module.exports = (robot) ->
  isAuthorized = (chat)->
    if robot.auth.hasRole(chat.envelope.user, config.hipchatRoles)
      return true

    chat.reply 'You don\'t have the rights to run pulsar commands'
    chat.finish()
    return false


  robot.respond /deploy (-v|)\s?([^\s]+) ([^\s]+)$/i, (chat) ->
    return unless isAuthorized(chat)
    app = chat.match[2]
    env = chat.match[3]
    isVerbose = chat.match[1] == '-v'

    pending = pulsarApi.createJob(app, env, 'deploy:pending')
    pending.on('finish',()->
      chat.send @data.output
      return if(@data.status != 'FINISHED')
      deploy = pulsarApi.createJob(app, env, 'deploy')
      deploy.on('create',() ->
        chat.send "Job was created: #{@}. More info here #{@data.url}"
      ).on('finish',() ->
        chat.send "#{@} finished with status: #{@data.status}. More details here #{@data.url}"
      ).on('error', () ->
        chat.send "#{@} failed due to #{JSON.stringify(error)}"
      )
      if isVerbose
        deploy.on('change', (output)->
          chat.send output
        )
      pulsarJobConfirmList.add(chat, deploy)
    ).on('error', (error)->
      chat.send "#{@} failed due to #{JSON.stringify(error)}"
    )
    pulsarApi.runJob(pending)
    chat.send pending + ' in progress'

  robot.respond /deploy pending ([^\s]+) ([^\s]+)$/i, (chat) ->
    return unless isAuthorized(chat)
    job = pulsarApi.createJob(chat.match[1], chat.match[2], 'deploy:pending')
    job.on('change',(output) ->
      chat.send output
    ).on('error', (error)->
      chat.send "#{@} failed due to #{JSON.stringify(error)}"
    )
    pulsarApi.runJob(job)

  robot.respond /(?:([^\s]+) ([^\s]+) )?jobs/i, (chat) ->
    return unless isAuthorized(chat)
    app = chat.match[1]
    env = chat.match[2]

    pulsarApi.jobs (jobs) ->
      jobs = _.filter jobs, (job) ->
        return false if app && app != job.app
        return false if env && env != job.env
        return true
      message = 'Jobs:'
      _.each jobs, (job) ->
        message += "\n #{job.status} job #{job.task} #{job.app} #{job.env} with ID #{job.id}"
      chat.send message

  robot.respond /((?:y(?:es)?)|(?:no?)|(?:ok))$/i, (chat) ->
    return unless isAuthorized(chat)
    answer = chat.match[1]
    isYes = answer.charAt(0) == 'y' || answer.charAt(0) == 'o'
    if(isYes)
      job = pulsarJobConfirmList.get(chat)
      pulsarApi.runJob(job)
      chat.send job + ' in progress'
    else
      pulsarJobConfirmList.remove(chat)
