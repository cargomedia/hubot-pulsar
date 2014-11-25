_ = require('underscore')

class DeploymentMonitor

  timeout = 10000

  constructor: ()->
    @_deployment = null
    @_chat = null
    @_currentTimeout = 0
    @_eventListeners = {
      change: ()=>
        @_resetTimeout()
        @_monitorTimeout()
      close: ()=>
        @.removeDeployment()
      error: ()=>
        @.removeDeployment()
    }

  setDeployment: (deployment, chat)->
    @removeDeployment() if @hasDeployment()
    @_deployment = deployment
    @_chat = chat
    _.each(@_eventListeners, (listener, event)=>
      @_deployment.on(event, listener)
    )

  hasDeployment: ()->
    return null != @_deployment

  getDeployment: ()->
    return @_deployment

  removeDeployment: ()->
    _.each(@_eventListeners, (listener, event)=>
      @_deployment.removeListener(event, listener)
    )
    @_deployment = null
    @_chat = null

  _monitorTimeout: _.debounce(()->
    if !@.hasDeployment()
      return
    @_currentTimeout += timeout
    @_chat.send "Running #{@_currentTimeout}ms: #{getLastText(@_deployment.data.output)}"
    @_monitorTimeout()
  , timeout)

  _resetTimeout: ()->
    if @_currentTimeout > 0
      @_chat.send "Continuing..."
    @_currentTimeout = 0

  getLastText = (text)->
    textLines = text.split(/\r?\n/)
    n = textLines.length - 1
    while(!textLines[n].trim() && n > 0)
      n--
    return textLines[n]


module.exports = DeploymentMonitor
