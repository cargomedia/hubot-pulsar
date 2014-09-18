rest = require('restler')

module.exports = (url) ->
  return (chat, application, environment, task, success) ->
    command = "#{task} '#{application}' to '#{environment}'"
    chat.send command + ' started'
    rest.post(url + application + '/' + environment,
      data:
        task: task
    ).on('complete', (job) ->
      if job.id
        chat.send "#{command} -> assigned job ID #{job.id}"
        success job
      else
        chat.send command + ' failed'
    ).on('error', (error) ->
      chat.send 'Error: ' + JSON.stringify error
    ).on('fail', (error) ->
      chat.send 'Fail: ' + JSON.stringify error
    )
