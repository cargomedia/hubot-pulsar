class DeployMonitor

  deploy = null
  chat = null
  monitorInterval = null
  monitorPeriodMs = 10000
  deployHangTimeMs = 0
  lastDeployOutput = null

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
    return null != deploy

  getDeploy: ()->
    return deploy

  removeDeploy: ()->
    @.stopMonitoring()
    deploy = null

  startMonitoring: ()->
    if(deploy.data.output)
      lastDeployOutput = deploy.data.output
    else
      lastDeployOutput = ''
    monitorInterval = setInterval(()=>
      if(lastDeployOutput.length == deploy.data.output.length)
        deployHangTimeMs += monitorPeriodMs
        chat.send "Running #{Math.round(deployHangTimeMs / 1000)} secs: #{@_getLastText(lastDeployOutput)}"
      else
        lastDeployOutput = deploy.data.output
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
