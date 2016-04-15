var _ = require('underscore');
var JobMonitor = require('./job-monitor');

/**
 * @constructor
 */
function DeployMutex() {
  this._job = null;
  this._chat = null;
  this._jobMonitor = null;
  var self = this;
  this._eventListeners = {
    change: function() {
      self._jobMonitor.reset();
    },
    success: function() {
      self.removeJob();
    },
    error: function() {
      self.removeJob();
    }
  };
}

/**
 * @param {Job} job
 * @param {Response} chat
 */
DeployMutex.prototype.setJob = function(job, chat) {
  if (this.hasJob()) {
    this.removeJob();
  }
  this._job = job;
  this._chat = chat;
  var self = this;

  this._jobMonitor = new JobMonitor(job);
  this._jobMonitor.on('update', function() {
    self._chat.send('Continuing...');
  });
  this._jobMonitor.on('idle', function(runningTime) {
    self._chat.send('Running ' + runningTime + 'secs: ' + (DeployMutex._getLastText(self._job.data.output)));
  });

  _.each(this._eventListeners, function(listener, event) {
    return self._job.on(event, listener);
  });
};

/**
 * @returns {boolean}
 */
DeployMutex.prototype.hasJob = function() {
  return null !== this._job;
};

/**
 * @returns {null|Job}
 */
DeployMutex.prototype.getJob = function() {
  return this._job;
};

/**
 * @param {string} task
 * @returns {null|Job}
 */
DeployMutex.prototype.getJobWithTask = function(task) {
  return this._job && this._job.task == task ? this._job : null;
};

DeployMutex.prototype.removeJob = function() {
  if (this._job) {
    _.each(this._eventListeners, function(listener, event) {
      return this._job.removeListener(event, listener);
    }.bind(this));
    this._job = null;
  }

  if (this._jobMonitor) {
    this._jobMonitor.destroy();
    this._jobMonitor = null;
  }

  this._chat = null;
};

/**
 * @param text
 * @returns {string}
 */
DeployMutex._getLastText = function(text) {
  if (!text) {
    return '';
  }
  var textLines = text.split(/\r?\n/);
  var n = textLines.length - 1;
  while (n > 0 && !textLines[n].trim()) {
    n--;
  }
  return textLines[n];
};

module.exports = DeployMutex;
