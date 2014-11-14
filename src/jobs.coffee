# Description:
#   Get info about pulsar jobs
#
# Commands:
#   hubot jobs - Show all the jobs that are executing or were executed.

_ = require('underscore')

module.exports = (robot) ->
  robot.respond /(?:([^\s]+) ([^\s]+) )?jobs/i, (chat) ->
    return unless robot.isAuthorized(chat)
    app = chat.match[1]
    env = chat.match[2]

    pulsarApi.jobs (jobs) ->
      jobs = _.filter jobs, (job) ->
        return false if app && app != job.app
        return false if env && env != job.env
        return true
      message = 'Jobs:'
      _.each jobs, (job) ->
        message += "\n #{job.status} job #{job.task} #{job.app} #{job.env} with ID #{job.id}"
      chat.send message
