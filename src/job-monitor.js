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
  this._monitor();
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
  this.emit('update');
  this._currentMonitorTime = 0;
  clearTimeout(this._timeoutId);
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

module.exports = JobMonitor;
