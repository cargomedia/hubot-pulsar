var _ = require('underscore');

function DeployMutex() {
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

DeployMutex.prototype.setDeployJob = function(deployJob, chat) {
  if (this.hasDeployJob()) {
    this.removeDeployJob();
  }
  this._deployJob = deployJob;
  this._chat = chat;

  return _.each(this._eventListeners, function(listener, event) {
    return this._deployJob.on(event, listener);
  }.bind(this));
};

DeployMutex.prototype.hasDeployJob = function() {
  return null !== this._deployJob;
};

DeployMutex.prototype.getDeployJob = function() {
  return this._deployJob;
};

DeployMutex.prototype.removeDeployJob = function() {
  _.each(this._eventListeners, function(listener, event) {
    return this._deployJob.removeListener(event, listener);
  }.bind(this));

  this._deployJob = null;
  this._chat = null;
};

DeployMutex.prototype._monitorTimeout = _.debounce(function() {
  if (!this.hasDeployJob()) {
    return;
  }
  this._currentTimeout += DeployMutex._monitorTimeoutPeriod;
  this._chat.send('Running ' + (this._currentTimeout / 1000) + 'secs: ' + (DeployMutex._getLastText(this._deployJob.data.output)));
  return this._monitorTimeout();
}, DeployMutex._monitorTimeoutPeriod);

DeployMutex.prototype._resetTimeout = function() {
  if (this._currentTimeout > 0) {
    this._chat.send('Continuing...');
  }
  return this._currentTimeout = 0;
};

DeployMutex._getLastText = function(text) {
  var textLines = text.split(/\r?\n/);
  var n = textLines.length - 1;
  while (!textLines[n].trim() && n > 0) {
    n--;
  }
  return textLines[n];
};

DeployMutex._monitorTimeoutPeriod = 30000;

module.exports = DeployMutex;
