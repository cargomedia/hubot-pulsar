class JobConfirmationList

  jobList = {}

  _getUser: (chat)->
    return chat.envelope.user.id

  add: (job)->
    user = @_getUser(job.chat)
    jobList[user] = job
    job.chat.send 'Please confirm that you still want to deploy.(y/n/ok)'

  get: (chat)->
    user = @_getUser(chat)
    return jobList[user]

  remove: (chat)->
    user = @_getUser(chat)
    chat.send jobList[user] + ' removed from the execution'
    delete jobList[user]

jobConfirmationList = new JobConfirmationList

module.exports = jobConfirmationList
