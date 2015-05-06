# Description:
#   Deploy applications with pulsar
#
# Commands:
#   hubot deploy pending <application> <environment> - Show pending changes
#   hubot deploy <application> <environment> - Deploy application

_ = require('underscore')

DeploymentMonitor = require('./deploy/monitor')
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
      chat.send "#{@} failed due to #{JSON.stringify(error)}"
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
      chat.send "Job was created: #{@}.\nMore info: #{@data.url}"
    ).on('success', () ->
      chat.send "#{@} finished."
    ).on('error', (error) ->
      chat.send "#{@} failed with error: #{JSON.stringify(error)}"
    )

    pendingJob = pulsarApi.createJob(app, env, 'deploy:pending')
    pendingJob.on('success', ()->
      deployJob.taskVariables = revision: @.taskVariables.revision
      chat.send "Pending changes for #{@app} #{@env}:\n#{@data.stdout}"
      chat.send "Please confirm that you still want to #{deployJob}.\nSay 'CONFIRM DEPLOY' or 'CANCEL DEPLOY'."
    ).on('error', (error)->
      deployJob.emit('error', error)
      chat.send "More info: #{@data.url}"
    )

    showNextRevisionJob = pulsarApi.createJob(app, env, 'deploy:show_next_revision')
    showNextRevisionJob.on('success', ()->
      if(!@data.stdout || !@data.stdout.trim())
        @.emit('error', new Error("#{@} does not have a revision number."))
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
    chat.send deployJob + ' in progress'

  robot.respond /cancel deploy$/i, (chat) ->
    return unless robot.userHasRole(chat, 'deployer')
    if(!deploymentMonitor.hasDeployJob())
      chat.send 'No deploy job to cancel'
      return
    chat.send deploymentMonitor.getDeployJob() + ' cancelled'
    deploymentMonitor.removeDeployJob()
