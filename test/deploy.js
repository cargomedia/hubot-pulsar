var assert = require('chai').assert;
var sinon = require('sinon');
var _ = require('underscore');
var Promise = require('bluebird');
require('coffee-script/register');
var humock = require('mock-hubot');

var authScript = require('../src/auth');
var deployScript = require('../src/deploy');
var Job = require('pulsar-rest-api-client-node/src/job');
var askHubot = require('./ask-hubot');

describe('Deploy script tests', function() {

  var job;

  before(function() {
    global.pulsarApi = {
      createJob: _.noop,
      runJob: _.noop,
      killJob: _.noop
    };
  });

  after(function() {
    global.pulsarApi = undefined;
  });

  beforeEach(function(done) {
    sinon.stub(pulsarApi, 'createJob', function(app, env, task) {
      job = new Job(app, env, task);
      job.data.stdout = 'stdout';
      return job;
    });

    humock.start(function() {
      humock.learn([authScript, deployScript]);
      done();
    });
  });

  afterEach(function(done) {
    global.pulsarApi.createJob.restore();

    humock.shutdown(function() {
      done();
    });
  });

  context('success job run', function() {

    beforeEach(function() {
      sinon.stub(pulsarApi, 'runJob', function(job) {
        _.delay(function() {
          job.emit('success');
        }, 200);
      });
    });

    afterEach(function() {
      global.pulsarApi.runJob.restore();
    });

    it('deploy pending', function(done) {
      askHubot('hubot deploy pending app env')
        .response(1, function(response) {
          assert.include(response, 'Getting changes');
          job.emit('success');
        })
        .response(2, function(response) {
          assert.include(response, 'Pending changes');
          assert.include(response, job.data.stdout);
          done();
        });
    });

    it('deploy rollback', function(done) {
      askHubot('hubot deploy rollback app env')
        .response(1, function(response) {
          assert.include(response, 'Rolling back');
        })
        .response(2, function(response) {
          assert.include(response, 'Successfully rolled back');
          done();
        });
    });

    it('deploy restart', function(done) {
      askHubot('hubot deploy restart app env')
        .response(1, function(response) {
          assert.include(response, 'Restarting the application');
        })
        .response(2, function(response) {
          assert.include(response, 'Restart is done');
          done();
        });
    });

    context('deploy', function() {
      beforeEach(function() {
        sinon.stub(pulsarApi, 'killJob', function() {
          return Promise.delay(200);
        });
      });

      afterEach(function() {
        global.pulsarApi.killJob.restore();
      });

      it('confirms', function(done) {
        askHubot('hubot deploy app env')
          .response(1, function(response) {
            assert.include(response, 'Getting changes');
          })
          .response(3, function(response) {
            assert.match(response, /confirm[^\n\r]+cancel/ig);
            askHubot('hubot confirm deploy')
              .response(1, function(response) {
                assert.include(response, 'Deployment confirmed');
              })
              .response(2, function(response) {
                assert.include(response, 'Deployment finished');
                done();
              });
          })
      });

      it('cancels', function(done) {
        askHubot('hubot deploy app env')
          .response(3, function(response) {
            assert.match(response, /confirm[^\n\r]+cancel/ig);
            askHubot('hubot cancel deploy')
              .response(1, function(response) {
                assert.include(response, 'Deployment cancelled');
                done();
              })
          })
      });
    });

  });

});
