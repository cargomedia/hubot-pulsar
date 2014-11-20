# Description:
#   Deploy applications with pulsar
#
# Commands:
#   hubot deploy:pending <application> <environment> - Show pending changes
#   hubot deploy <application> <environment> - Deploy application

_ = require('underscore')
DeploymentMonitor = require('./deployment-monitor')
deploymentMonitor = new DeploymentMonitor()

module.exports = (robot) ->
  robot.respond /deploy ([^\s]+) ([^\s]+)$/i, (chat) ->
    return unless robot.isAuthorized(chat)
    if(deploymentMonitor.hasDeployment())
      chat.send "Deployment can not be started because #{deploymentMonitor.getDeployment()} is in progress"
      return
    app = chat.match[1]
    env = chat.match[2]

    deployment = pulsarApi.createJob(app, env, 'deploy')
    deploymentMonitor.setDeployment(deployment, chat)
    deployment.on('create', () ->
      chat.send "Job was created: #{@}. More info here #{@data.url}"
    ).on('close', () ->
      chat.send "#{@} finished with status: #{@data.status}. More details here #{@data.url}"
    ).on('error', () ->
      chat.send "#{@} failed due to #{JSON.stringify(error)}"
    )

    pending = pulsarApi.createJob(app, env, 'deploy:pending')
    pending.on('close', ()->
      chat.send "Pending changes for #{@app} #{@env}:\n#{@data.stdout}"
      if(@data.status != 'FINISHED')
        @.emit('error', new Error("#{@} finished with incorrect status #{data.status}"))
        return
      chat.send "Please confirm that you still want to #{deployment}.(confirm deploy/cancel deploy)"
    ).on('error', (error)->
      deploymentMonitor.removeDeployment()
      chat.send "#{@} failed due to #{JSON.stringify(error)}"
    )
    pulsarApi.runJob(pending)
    chat.send pending + ' in progress'

  robot.respond /deploy pending ([^\s]+) ([^\s]+)$/i, (chat) ->
    return unless robot.isAuthorized(chat)
    job = pulsarApi.createJob(chat.match[1], chat.match[2], 'deploy:pending')
    job.on('close', () ->
      chat.send "Pending changes for #{@app} #{@env}:\n#{@data.stdout}"
    ).on('error', (error)->
      chat.send "#{@} failed due to #{JSON.stringify(error)}"
    )
    pulsarApi.runJob(job)

  robot.respond /confirm deploy$/i, (chat) ->
    return unless robot.isAuthorized(chat)
    if(!deploymentMonitor.hasDeployment())
      chat.send 'No deployment to confirm'
      return
    deployment = deploymentMonitor.getDeployment()
    pulsarApi.runJob(deployment)
    chat.send deployment + ' in progress'

  robot.respond /cancel deploy$/i, (chat) ->
    return unless robot.isAuthorized(chat)
    if(!deploymentMonitor.hasDeployment())
      chat.send 'No deployment to cancel'
      return
    deployment = deploymentMonitor.getDeployment()
    chat.send deployment + ' cancelled'
    deploymentMonitor.removeDeployment()
