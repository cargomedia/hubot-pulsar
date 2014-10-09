config = require('./config')
SockJS = require('node-sockjs-client')

class JobChangeListener

  jobList = {}
  jobOutputList = {}

  constructor: ()->
    @connect(config.pulsarApi.url + '/websocket', config.pulsarApi.authToken)

  connect: (url, authToken)->
    sock = new SockJS(url)
    if authToken
      sock.onopen = () ->
        sock.send(JSON.stringify({token: authToken}))
    sock.onmessage = (msg) =>
      data = JSON.parse(msg.data)
      @updateJob(data.job) if data.event == 'job.change'

  updateJob: (jobData)->
    job = jobList[jobData.id]
    return unless job
    job.setData(jobData)
    @emitChange job
    if jobData.status != 'RUNNING'
      @finishJob(job)

  emitChange: (job)->
    lastSentPosition = jobOutputList[job.data.id] || 0
    job.emit 'change', job.data.output.substring(lastSentPosition)
    jobOutputList[job.data.id] = job.data.output.length - 1

  finishJob: (job) ->
    delete jobList[job.data.id]
    delete jobOutputList[job.data.id]
    job.emit 'finish'

  addJob: (job) ->
    jobList[job.data.id] = job

jobChangeListener = new JobChangeListener()
module.exports = jobChangeListener
