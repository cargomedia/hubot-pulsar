class DeployMonitor

  deploy = null

  setDeploy: (deployJob)->
    deploy = deployJob
    deploy.on('close', ()=>
      @.removeDeploy()
    )
    deploy.on('error', ()=>
      @.removeDeploy()
    )

  hasDeploy: ()->
    return !!deploy

  getDeploy: ()->
    return deploy

  removeDeploy: ()->
    deploy = null

module.exports = new DeployMonitor
