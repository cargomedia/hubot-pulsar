_ = require('underscore')

class DeployMonitor

  deploy = null
  chat = null
  timeout = 10000
  currentTimeout = 0

  setDeploy: (deployJob, chatArg)->
    deploy = deployJob
    chat = chatArg
    deploy.on('change', ()=>
      resetTimeoutMonitor()
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
    deploy = null

  timeoutMonitor = _.debounce(()->
    if null == deploy
      return
    currentTimeout += timeout
    chat.send "Running #{currentTimeout}ms: #{getLastText(deploy.data.output)}"
    timeoutMonitor()
  , timeout)

  resetTimeoutMonitor = ()->
    if currentTimeout > 0
      chat.send "Continuing..."
    currentTimeout = 0
    timeoutMonitor()

  getLastText = (text)->
    textLines = text.split(/\r?\n/)
    n = textLines.length - 1
    while(!textLines[n].trim() && n > 0)
      n--
    return textLines[n]


module.exports = new DeployMonitor
