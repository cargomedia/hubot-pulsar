chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

expect = chai.expect

describe 'Pulsar: ', ->
	beforeEach ->
		@robot =
			respond: sinon.spy()
			hear: sinon.spy()
		@msg =
			send: sinon.spy()
			random: sinon.spy()

		require('../src/pulsar')(@robot)
