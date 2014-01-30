# Description:
#   Deploy applications with pulsar
#
# Commands:
#   hubot deploy:pending <application> <environment> - Show pending changes
#   hubot deploy <application> <environment> - Deploy application

spawn = require('child_process').spawn
rest = require('restler')
_ = require('underscore')

process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0"

module.exports = (robot) ->
	robot.respond /deploy ([^\s]+) ([^\s]+)$/i, (msg) ->
		application = msg.match[1]
		environment = msg.match[2]

		msg.send "Deploying `#{application}` to `#{environment}`"

		rest.post('https://api.pulsar.local:8001/' + application + '/' + environment,
			data:
				action: '_deploy_'
		).on 'complete', (data) ->
			msg.send 'Response wait for deploy -> assigned task ID ' + response.taskId

	robot.respond /deploy pending ([^\s]+) ([^\s]+)$/i, (msg) ->
		application = msg.match[1]
		environment = msg.match[2]

		msg.send "Deploy pending for `#{application}` to `#{environment}`"

		rest.post('https://api.pulsar.local:8001/' + application + '/' + environment,
			data:
				action: 'deploy:pending'
		).on 'complete', (response) ->
				taskChangeListener response.taskId, msg
				msg.send 'Response wait for deploy:pending -> assigned task ID ' + response.taskId


	robot.respond /deploy tasks/i, (msg) ->
		rest.get('https://api.pulsar.local:8001/tasks')
		.on 'complete', (response) ->
				message = 'Tasks:'
				_.each response, (task) ->
					message += "\n" + task.status + ' task "' + task.action + ' ' + task.app + ' ' + task.env + '" with ID ' + task.id
				msg.send message

taskChangeListener = (taskId, msg) ->
	rest.get('https://api.pulsar.local:8001/task/' + taskId + '/state')
	.on 'complete', (response) ->
		if response.changed
			msg.send response.task.output
		if response.task.status == 'running'
			taskChangeListener taskId, msg
