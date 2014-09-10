# Description:
#   Deploy applications with pulsar
#
# Commands:
#   hubot deploy:pending <application> <environment> - Show pending changes
#   hubot deploy <application> <environment> - Deploy application

spawn = require('child_process').spawn
rest = require('restler')
_ = require('underscore')
SockJS = require('node-sockjs-client')
API_URL = 'https://api.pulsar.local:8001/'

process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0"

jobChangeListener = (->
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
			lastSentPos = chatInfo.lastSentPos
			chat.send job.output.substring(lastSentPos)
			chatInfo.lastSentPos = job.output.length - 1
		if job.status != 'RUNNING'
			chatInfo.chat.send "Job #{job.id} finished with status: #{job.status}. More details here #{chatInfo.jobUrl}"
			delete jobChatInfo[job.id]

	addJob = (jobId, chat, jobUrl, isVerbose) ->
		jobChatInfo[jobId] = {chat: chat, lastSentPos: 0, jobUrl: jobUrl, isVerbose: isVerbose}

	return {
		connect: connect
		addJob: addJob
	}
)()

jobChangeListener.connect(API_URL + 'websocket')

module.exports = (robot) ->
	robot.respond /deploy\s?(-v|) (pending|)\s?([^\s]+) ([^\s]+)$/i, (chat) ->
		isVerbose = chat.match[1] == '-v'
		isPending = chat.match[2] == 'pending'
		task = (if isPending then "deploy:pending" else "deploy")
		application = chat.match[3]
		environment = chat.match[4]

		command = "#{task} '#{application}' to '#{environment}'"
		chat.send command + " started"

		rest.post(API_URL + application + '/' + environment,
			data:
				task: task
		).on("complete", (job) ->
			if job.id
				jobChangeListener.addJob(job.id, chat, job.url, isVerbose)
				chat.send "#{command} -> assigned job ID " + job.id
				chat.send "More info here #{job.url}"
			else
				chat.send "Your request failed"
		).on("error", (error) ->
			chat.send "Error: " + JSON.stringify error
		).on("fail", (error) ->
			chat.send "Fail: " + JSON.stringify error
		)

	robot.respond /jobs/i, (chat) ->
		rest.get(API_URL + 'jobs')
		.on 'complete', (response) ->
			message = 'Jobs:'
			_.each response, (job) ->
				message += "\n" + job.status + ' job "' + job.task + ' ' + job.app + ' ' + job.env + '" with ID ' + job.id
			chat.send message
