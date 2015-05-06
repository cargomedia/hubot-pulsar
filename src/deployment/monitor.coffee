_ = require('underscore')

class DeploymentMonitor

  timeout = 10000

  constructor: ()->
    @_deployJob = null
    @_chat = null
    @_currentTimeout = 0
    @_eventListeners = {
      change: ()=>
        @_resetTimeout()
        @_monitorTimeout()
      success: ()=>
        @.removeDeployJob()
      error: ()=>
        @.removeDeployJob()
    }

  setDeployJob: (deployJob, chat)->
    @removeDeployJob() if @hasDeployJob()
    @_deployJob = deployJob
    @_chat = chat
    _.each(@_eventListeners, (listener, event)=>
      @_deployJob.on(event, listener)
    )

  hasDeployJob: ()->
    return null != @_deployJob

  getDeployJob: ()->
    return @_deployJob

  removeDeployJob: ()->
    _.each(@_eventListeners, (listener, event)=>
      @_deployJob.removeListener(event, listener)
    )
    @_deployJob = null
    @_chat = null

  _monitorTimeout: _.debounce(()->
    if !@.hasDeployJob()
      return
    @_currentTimeout += timeout
    @_chat.send "Running #{@_currentTimeout}ms: #{getLastText(@_deployJob.data.output)}"
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
