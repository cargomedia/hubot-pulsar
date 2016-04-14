var EventEmitter = require('events');
var util = require('util');

/**
 * @param {Job} job
 * @constructor
 */
function JobMonitor(job) {
  EventEmitter.call(this);

  this._job = job;
  this._timeoutId = null;
  this._currentMonitorTime = 0;
  this._update();
}

util.inherits(JobMonitor, EventEmitter);

JobMonitor._monitorTimePeriod = 30000;

JobMonitor.prototype.destroy = function() {
  this.removeAllListeners();
  clearTimeout(this._timeoutId);
  this._timeoutId = null;
  this._job = null;
};

JobMonitor.prototype.reset = function() {
  if (this._currentMonitorTime > 0) {
    this.emit('reset');
  }
  this._currentMonitorTime = 0;
};

JobMonitor.prototype._update = function() {
  if (!this._job) {
    return;
  }
  this._timeoutId = setTimeout(function() {
    this._currentMonitorTime += JobMonitor._monitorTimePeriod;
    this.emit('update', this._currentMonitorTime / 1000);
    this._update();
  }.bind(this), JobMonitor._monitorTimePeriod);
};

module.exports = JobMonitor;
