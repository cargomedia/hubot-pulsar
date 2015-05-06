module.exports = (robot) ->
  robot.userHasRole = (chat, role)->
    if !robot.auth
      return true

    if robot.auth.hasRole(chat.envelope.user, role)
      return true

    chat.reply "You don't have the `#{role}` role."
    chat.finish()
    return false
