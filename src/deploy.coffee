# Description:
#   Deploy applications with pulsar
#
# Commands:
#   hubot deploy pending <application> <environment> - Show pending changes
#   hubot deploy <application> <environment> - Deploy application

_ = require('underscore')

DeploymentMonitor = require('./deployment/monitor')
deploymentMonitor = new DeploymentMonitor()

module.exports = (robot) ->
  robot.respond /deploy pending ([^\s]+) ([^\s]+)$/i, (chat) ->
    app = chat.match[1]
    env = chat.match[2]
    chat.send "Getting changes…"

    job = pulsarApi.createJob(app, env, 'deploy:pending')
    job.on('success', () ->
      chat.send "Pending changes for #{@app} #{@env}:\n#{@data.stdout}"
    ).on('error', (error)->
      chat.send "Pending changes failed: #{JSON.stringify(error)}"
      chat.send "More info: #{@data.url}"
    )
    pulsarApi.runJob(job)

  robot.respond /deploy ([^\s]+) ([^\s]+)$/i, (chat) ->
    return unless robot.userHasRole(chat, 'deployer')
    if(deploymentMonitor.hasDeployJob())
      chat.send "Deploy job can not be started because #{deploymentMonitor.getDeployJob()} is in progress"
      return
    app = chat.match[1]
    env = chat.match[2]
    chat.send "Getting changes…"

    deployJob = pulsarApi.createJob(app, env, 'deploy')
    deploymentMonitor.setDeployJob(deployJob, chat)
    deployJob.on('create', () ->
      chat.send "Deployment started: #{@data.url}"
    ).on('success', () ->
      chat.send "Deployment finished."
    ).on('error', (error) ->
      chat.send "Deployment failed: #{JSON.stringify(error)}"
    )

    pendingJob = pulsarApi.createJob(app, env, 'deploy:pending')
    pendingJob.on('success', ()->
      deployJob.taskVariables = revision: @.taskVariables.revision
      chat.send "Pending changes for #{@app} #{@env}:\n#{@data.stdout}"
      chat.send "Say 'CONFIRM DEPLOY' or 'CANCEL DEPLOY'."
    ).on('error', (error)->
      deployJob.emit('error', error)
      chat.send "More info: #{@data.url}"
    )

    showNextRevisionJob = pulsarApi.createJob(app, env, 'deploy:show_next_revision')
    showNextRevisionJob.on('success', ()->
      if(!@data.stdout || !@data.stdout.trim())
        @.emit('error', new Error("Cannot retrieve revision number."))
        return
      revision = @data.stdout.trim()
      pendingJob.taskVariables = revision: revision
      pulsarApi.runJob(pendingJob)
    ).on('error', (error)->
      deployJob.emit('error', error)
      chat.send "More info: #{@data.url}"
    )
    pulsarApi.runJob(showNextRevisionJob)

  robot.respond /confirm deploy$/i, (chat) ->
    return unless robot.userHasRole(chat, 'deployer')
    if(!deploymentMonitor.hasDeployJob())
      chat.send 'No deploy job to confirm'
      return
    deployJob = deploymentMonitor.getDeployJob()
    pulsarApi.runJob(deployJob)
    chat.send 'Deployment confirmed.'

  robot.respond /cancel deploy$/i, (chat) ->
    return unless robot.userHasRole(chat, 'deployer')
    if(!deploymentMonitor.hasDeployJob())
      chat.send 'No deploy job to cancel'
      return
    chat.send 'Deployment cancelled.'
    deploymentMonitor.removeDeployJob()
