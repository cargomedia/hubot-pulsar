# Description:
#   Deploy applications with pulsar
#
# Commands:
#   hubot deploy:pending <application> <environment> - Show pending changes
#   hubot deploy <application> <environment> - Deploy application

spawn = require('child_process').spawn

module.exports = (robot) ->
	robot.respond /deploy ([^\s]+) ([^\s]+)$/i, (msg) ->
		application = msg.match[1]
		environment = msg.match[2]

		msg.send "Deploying `#{application}` to `#{environment}`"

		execute msg, 'whoami', null, (output) =>
			username = output.replace(/(\r\n|\n|\r)/gm,"")
			msg.send "Deployed `#{application}` successfully to `#{environment}` by `#{username}`."

	robot.respond /deploy:pending ([^\s]+) ([^\s]+)$/i, (msg) ->
		application = msg.match[1]
		environment = msg.match[2]

		execute msg, 'date', null, (output) =>
			msg.send "Pending changes for deploying `#{application}` to `#{environment}`:\n#{output}"


execute = (msg, command, args, onSuccess) ->
	onError = (error) ->
		msg.send "Command failed: `#{command}`:\n#{error}"

	process = spawn command, args
	output = ''
	process.stdout.on 'data', (data) ->
		output += data
	process.stderr.on 'data', (data) ->
		output += data
	process.on 'exit', (code) ->
		if 0 != code
			onError(output)
		else
			onSuccess(output)
	process.on 'error', (code) ->
		onError(output)
