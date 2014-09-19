JobConfirmationList = ->
  @jobList = {}
  return

JobConfirmationList::_getUser = (chat)->
  return chat.envelope.user.id

JobConfirmationList::add = (job)->
  user = @_getUser(job.chat)
  @jobList[user] = job

JobConfirmationList::get = (chat)->
  user = @_getUser(chat)
  return @jobList[user]

JobConfirmationList::remove = (chat)->
  user = @_getUser(chat)
  delete @jobList[user]

jobConfirmationList = new JobConfirmationList()

module.exports = jobConfirmationList
