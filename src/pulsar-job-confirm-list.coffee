class PulsarJobConfirmList

  jobList = {}

  _getUser: (chat)->
    return chat.envelope.user.id

  add: (chat, job)->
    user = @_getUser(chat)
    jobList[user] = job
    chat.send 'Please confirm that you still want to deploy.(y/n/ok)'

  get: (chat)->
    user = @_getUser(chat)
    return jobList[user]

  remove: (chat)->
    user = @_getUser(chat)
    chat.send jobList[user] + ' removed from the execution'
    delete jobList[user]

module.exports = new PulsarJobConfirmList
