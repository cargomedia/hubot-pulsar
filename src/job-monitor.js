var EventEmitter = require('events');
var util = require('util');
var _ = require('underscore');
var PulsarJob = require('pulsar-rest-api/lib/pulsar/job');

/**
 * @param {Job} job
 * @constructor
 */
function JobMonitor(job) {
  EventEmitter.call(this);

  this._job = job;
  this._timeoutId = null;
  this._currentMonitorTime = 0;
  this._onJobChange();

  var self = this;
  this._eventListeners = {
    change: function() {
      self._onJobChange();
    },
    success: function() {
      self.destroy();
    },
    error: function() {
      self.destroy();
    }
  };

  _.each(this._eventListeners, function(listener, event) {
    self._job.on(event, listener);
  });
}

util.inherits(JobMonitor, EventEmitter);

JobMonitor._monitorTimePeriod = 30000;

JobMonitor.prototype.destroy = function() {
  this._stopMonitor();
  if (this._job) {
    _.each(this._eventListeners, function(listener, event) {
      this._job.removeListener(event, listener);
    }.bind(this));
    this._job = null;
  }
  this.emit('destroy');
};

JobMonitor.prototype._onJobChange = function() {
  if (PulsarJob.STATUS.RUNNING == this._job.data.status) {
    this._resetMonitor();
  } else {
    this._stopMonitor();
  }
};

JobMonitor.prototype._resetMonitor = function() {
  if (this._currentMonitorTime > 0) {
    //we emit 'resume' only if we in 'idle' state
    this.emit('resume');
  }
  this._stopMonitor();
  this._monitor();
};

JobMonitor.prototype._monitor = function() {
  if (!this._job) {
    return;
  }
  this._timeoutId = setTimeout(function() {
    this._currentMonitorTime += JobMonitor._monitorTimePeriod;
    this.emit('idle', this._currentMonitorTime / 1000);
    this._monitor();
  }.bind(this), JobMonitor._monitorTimePeriod);
};

JobMonitor.prototype._stopMonitor = function() {
  this._currentMonitorTime = 0;
  clearTimeout(this._timeoutId);
  this._timeoutId = null;
};

module.exports = JobMonitor;
