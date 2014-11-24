_ = require('underscore')

class DeploymentMonitor

  timeout = 10000

  constructor: ()->
    @_deployment = null
    @_chat = null
    @_currentTimeout = 0

  setDeployment: (deployment, chat)->
    @_deployment = deployment
    @_chat = chat
    @_eventListeners = {
      'change': ()=>
        @_resetTimeoutMonitor()
        @_timeoutMonitor()
      'close': ()=>
        @.removeDeployment()
      'error': ()=>
        @.removeDeployment()
    }
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

  _timeoutMonitor: _.debounce(()->
    if !@.hasDeployment()
      return
    @_currentTimeout += timeout
    @_chat.send "Running #{@_currentTimeout}ms: #{getLastText(@_deployment.data.output)}"
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


module.exports = DeploymentMonitor
