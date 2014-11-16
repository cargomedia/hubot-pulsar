# Description:
#   Deploy applications with pulsar
#
# Commands:
#   hubot deploy:pending <application> <environment> - Show pending changes
#   hubot deploy <application> <environment> - Deploy application

_ = require('underscore')
pulsarJobConfirmList = require('./pulsar-job-confirm-list')

module.exports = (robot) ->
  robot.respond /deploy (-v|)\s?([^\s]+) ([^\s]+)$/i, (chat) ->
    return unless robot.isAuthorized(chat)
    app = chat.match[2]
    env = chat.match[3]
    isVerbose = chat.match[1] == '-v'

    pending = pulsarApi.createJob(app, env, 'deploy:pending')
    pending.on('close', ()->
      chat.send "Pending changes for #{@app} #{@env}: #{@data.stdout}"
      return if(@data.status != 'FINISHED')
      deploy = pulsarApi.createJob(app, env, 'deploy')
      deploy.on('create', () ->
        chat.send "Job was created: #{@}. More info here #{@data.url}"
      ).on('close', () ->
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
    return unless robot.isAuthorized(chat)
    job = pulsarApi.createJob(chat.match[1], chat.match[2], 'deploy:pending')
    job.on('close', () ->
      chat.send "Pending changes for #{@app} #{@env}: #{@data.stdout}"
    ).on('error', (error)->
      chat.send "#{@} failed due to #{JSON.stringify(error)}"
    )
    pulsarApi.runJob(job)

  robot.respond /((?:y(?:es)?)|(?:no?)|(?:ok))$/i, (chat) ->
    return unless robot.isAuthorized(chat)
    answer = chat.match[1]
    isYes = answer.charAt(0) == 'y' || answer.charAt(0) == 'o'
    if(isYes)
      job = pulsarJobConfirmList.get(chat)
      pulsarApi.runJob(job)
      chat.send job + ' in progress'
    else
      pulsarJobConfirmList.remove(chat)
