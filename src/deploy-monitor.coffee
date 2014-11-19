_ = require('underscore')

class DeployMonitor

  timeout = 10000

  constructor: ()->
    @_deploy = null
    @_chat = null
    @_currentTimeout = 0

  setDeploy: (deploy, chat)->
    @_deploy = deploy
    @_chat = chat
    @_deploy.on('change', ()=>
      @_resetTimeoutMonitor()
      @_timeoutMonitor()
    )
    @_deploy.on('close', ()=>
      @.removeDeploy()
    )
    @_deploy.on('error', ()=>
      @.removeDeploy()
    )

  hasDeploy: ()->
    return null != @_deploy

  getDeploy: ()->
    return @_deploy

  removeDeploy: ()->
    @_deploy = null

  _timeoutMonitor: _.debounce(()->
    if !@.hasDeploy()
      return
    @_currentTimeout += timeout
    @_chat.send "Running #{@_currentTimeout}ms: #{getLastText(@_deploy.data.output)}"
    @_timeoutMonitor()
  , timeout)

  _resetTimeoutMonitor: ()->
    if @_currentTimeout > 0
      @_chat.send "Continuing..."
    @_currentTimeout = 0

  getLastText = (text)->
    textLines = text.split(/\r?\n/)
    n = textLines.length - 1
    while(!textLines[n].trim() && n > 0)
      n--
    return textLines[n]


module.exports = DeployMonitor
