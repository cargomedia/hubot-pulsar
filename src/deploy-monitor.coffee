class DeployMonitor

  deploy = null
  chat = null
  monitorInterval = null
  monitorPeriodMs = 10000
  deployHangTimeMs = 0
  lastDeployStdout = null

  setDeploy: (deployJob, chatArg)->
    deploy = deployJob
    chat = chatArg
    deploy.on('create', ()=>
      @.startMonitoring()
    )
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
    @.stopMonitoring()
    deploy = null

  startMonitoring: ()->
    if(deploy.data.stdout)
      lastDeployStdout = deploy.data.stdout
    else
      lastDeployStdout = ''
    monitorInterval = setInterval(()=>
      if(lastDeployStdout.length == deploy.data.stdout.length)
        deployHangTimeMs += monitorPeriodMs
        chat.send "Running #{Math.round(deployHangTimeMs / 1000)} secs: #{@_getLastText(lastDeployStdout)}"
      else
        lastDeployStdout = deploy.data.stdout
        deployHangTimeMs = 0
    , monitorPeriodMs)

  stopMonitoring: ()->
    clearInterval(monitorInterval)

  _getLastText: (text)->
    textLines = text.split(/\r?\n/)
    n = textLines.length - 1
    while(!textLines[n].trim() && n > 0)
      n--
    return textLines[n]


module.exports = new DeployMonitor
