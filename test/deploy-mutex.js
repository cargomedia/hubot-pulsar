var assert = require('chai').assert;
var sinon = require('sinon');
var Job = require('pulsar-rest-api-client-node/src/job');
var DeployMutex = require('../src/deploy-mutex');

describe('DeployMutex tests', function() {

  var deployMutex, job;

  beforeEach(function() {
    deployMutex = new DeployMutex();
    job = new Job('app', 'env', 'task');
  });

  it('job events trigger _eventListeners', function() {
    ['success', 'error', 'change'].forEach(function(event) {
      sinon.stub(deployMutex._eventListeners, event);
    });
    deployMutex.setJob(job, {});
    ['success', 'error', 'change'].forEach(function(event) {
      job.emit(event);
    });
    ['success', 'error', 'change'].forEach(function(event) {
      assert.isTrue(deployMutex._eventListeners[event].calledOnce);
    });
  });

  context('when job set is set', function() {

    beforeEach(function() {
      deployMutex.setJob(job);
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

    it('should print stdout on job change', function(done) {
      job.data.output = 'output';
      var chat = {
        send: function(message) {
          assert.include(message, job.data.output);
          done();
        }
      };
      deployMutex.setJob(job, chat);
      job.emit('change');
    });

  });
});
