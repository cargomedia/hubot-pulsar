SockJS = require('node-sockjs-client')

module.exports = (->
  jobChatInfo = {}

  connect = (url) ->
    sock = new SockJS(url)
    sock.onmessage = (msg) ->
      data = JSON.parse(msg.data)
      updateJob(data.job) if data.event == 'job.change'

  updateJob = (job)->
    chatInfo = jobChatInfo[job.id]
    if chatInfo.isVerbose
      chat = chatInfo.chat
      lastSentPos = chatInfo.lastSentPos || 0
      chat.send job.output.substring(lastSentPos)
      chatInfo.lastSentPos = job.output.length - 1
    if job.status != 'RUNNING'
      chatInfo.complete(job) if chatInfo.complete
      delete jobChatInfo[job.id]

  addJob = (jobId, chat, isVerbose, complete) ->
    jobChatInfo[jobId] = {chat: chat, isVerbose: isVerbose, complete: complete}

  return {
    connect: connect
    addJob: addJob
  }
)()
