var assert = require('chai').assert;
var sinon = require('sinon');
var _ = require('underscore');
var Job = require('pulsar-rest-api-client-node/src/job');
var DeployMutex = require('../src/deploy-mutex');
var JobMonitor = require('../src/job-monitor');
var PulsarJob = require('pulsar-rest-api/lib/pulsar/job');

describe('DeployMutex tests', function() {

  var deployMutex, job;

  beforeEach(function() {
    deployMutex = new DeployMutex();
    job = new Job('app', 'env', 'task');
  });

  context('monitor job', function() {
    var previousMonitorTimePeriod;

    before(function() {
      previousMonitorTimePeriod = JobMonitor._monitorTimePeriod;
      JobMonitor._monitorTimePeriod = 500;
    });

    beforeEach(function() {
      job.data.output = 'job.output';
      job.data.status = PulsarJob.STATUS.RUNNING;
    });

    after(function() {
      JobMonitor._monitorTimePeriod = previousMonitorTimePeriod;
    });

    afterEach(function() {
      deployMutex.removeJob();
    });

    it('should print stdout on job idle', function(done) {
      var startTime = new Date().getTime();
      var chat = {
        send: function(message) {
          assert.isAtLeast(new Date().getTime() - startTime, JobMonitor._monitorTimePeriod);
          assert.include(message, job.data.output);
          done();
        }
      };
      deployMutex.setJob(job, chat);
    });

    it('should not print "continue" on usual job change', function(done) {
      var startTime = new Date().getTime();
      var chat = {send: sinon.stub()};
      deployMutex.setJob(job, chat);

      deployMutex._jobMonitor.on('idle', function() {
        assert.equal(chat.send.callCount, 1);
        assert.isAbove(new Date().getTime() - startTime, JobMonitor._monitorTimePeriod);
        var firstCall = chat.send.getCall(0);
        assert.notInclude(firstCall.args[0], 'Continue');
        done();
      });

      deployMutex._jobMonitor.on('resume', function() {
        done(new Error('Invalid "resume" event'));
      });

      job.emit('change');
    });

    it('should print "continue" on job update after idle only', function(done) {
      var startTime = new Date().getTime();
      var chat = {send: sinon.stub()};
      deployMutex.setJob(job, chat);
      deployMutex._jobMonitor.on('idle', function() {
        job.emit('change');
      });
      deployMutex._jobMonitor.on('resume', function() {
        _.defer(function() {
          assert.isAbove(new Date().getTime() - startTime, JobMonitor._monitorTimePeriod);
          assert.equal(chat.send.callCount, 2);
          var secondCall = chat.send.getCall(1);
          assert.include(secondCall.args[0], 'Continue');
          done();
        });
      });
    });

    it('should not print anything after job finished', function(done) {
      var chat = {send: sinon.stub()};
      deployMutex.setJob(job, chat);
      job.emit('success');
      job.emit('change');
      setTimeout(function() {
        assert.equal(chat.send.callCount, 0);
        done();
      }, 3 * JobMonitor._monitorTimePeriod);
    });
  });

  context('when job set is set', function() {

    beforeEach(function() {
      deployMutex.setJob(job);
    });

    afterEach(function() {
      deployMutex.removeJob();
    });

    it('sets job', function() {
      assert.strictEqual(deployMutex.getJob(), job);
      assert.isTrue(deployMutex.hasJob());
    });

    it('removes previous job', function() {
      var newJob = new Job('newapp', 'newenv');
      deployMutex.setJob(newJob);
      assert.strictEqual(deployMutex.getJob(), newJob);
    });

    it('removeJob', function() {
      deployMutex.removeJob();
      assert.isNull(deployMutex.getJob());
      assert.isFalse(deployMutex.hasJob());
    });

    it('getJobWithTask', function() {
      assert.strictEqual(deployMutex.getJobWithTask('task'), job);
    });

    it('should remove job on job error', function() {
      sinon.stub(deployMutex, 'removeJob');
      job.emit('error');
      assert.isTrue(deployMutex.removeJob.calledOnce);
    });

    it('should remove job on job success', function() {
      sinon.stub(deployMutex, 'removeJob');
      job.emit('success');
      assert.isTrue(deployMutex.removeJob.calledOnce);
    });

  });
});
