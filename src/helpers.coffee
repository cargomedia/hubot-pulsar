module.exports = (robot) ->
  robot.isAuthorized = (chat)->
    if robot.auth.hasRole(chat.envelope.user, config.hipchatRoles)
      return true

    chat.reply 'You don\'t have the rights to run pulsar commands'
    chat.finish()
    return false
