var _ = require('underscore');

function DeploymentMonitor() {
  this._deployJob = null;
  this._chat = null;
  this._currentTimeout = 0;
  var monitor = this;
  this._eventListeners = {
    change: function() {
      monitor._resetTimeout();
      monitor._monitorTimeout();
    },
    success: function() {
      monitor.removeDeployJob();
    },
    error: function() {
      monitor.removeDeployJob();
    }
  };
}

DeploymentMonitor.prototype.setDeployJob = function(deployJob, chat) {
  if (this.hasDeployJob()) {
    this.removeDeployJob();
  }
  this._deployJob = deployJob;
  this._chat = chat;

  return _.each(this._eventListeners, function(listener, event) {
    return this._deployJob.on(event, listener);
  }.bind(this));
};

DeploymentMonitor.prototype.hasDeployJob = function() {
  return null !== this._deployJob;
};

DeploymentMonitor.prototype.getDeployJob = function() {
  return this._deployJob;
};

DeploymentMonitor.prototype.removeDeployJob = function() {
  _.each(this._eventListeners, function(listener, event) {
    return this._deployJob.removeListener(event, listener);
  }.bind(this));

  this._deployJob = null;
  this._chat = null;
};

DeploymentMonitor.prototype._monitorTimeout = _.debounce(function() {
  if (!this.hasDeployJob()) {
    return;
  }
  this._currentTimeout += DeploymentMonitor._monitorTimeoutPeriod;
  this._chat.send('Running ' + (this._currentTimeout / 1000) + 'secs: ' + (DeploymentMonitor._getLastText(this._deployJob.data.output)));
  return this._monitorTimeout();
}, DeploymentMonitor._monitorTimeoutPeriod);

DeploymentMonitor.prototype._resetTimeout = function() {
  if (this._currentTimeout > 0) {
    this._chat.send('Continuing...');
  }
  return this._currentTimeout = 0;
};

DeploymentMonitor._getLastText = function(text) {
  var textLines = text.split(/\r?\n/);
  var n = textLines.length - 1;
  while (!textLines[n].trim() && n > 0) {
    n--;
  }
  return textLines[n];
};

DeploymentMonitor._monitorTimeoutPeriod = 30000;

module.exports = DeploymentMonitor;
