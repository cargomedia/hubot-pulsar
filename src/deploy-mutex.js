var _ = require('underscore');

function DeployMutex() {
  this._job = null;
  this._chat = null;
  this._currentTimeout = 0;
  var mutex = this;
  this._eventListeners = {
    change: function() {
      mutex._resetTimeout();
      mutex._monitorTimeout();
    },
    success: function() {
      mutex.removeJob();
    },
    error: function() {
      mutex.removeJob();
    }
  };
}

DeployMutex.prototype.setJob = function(job, chat) {
  if (this.hasJob()) {
    this.removeJob();
  }
  this._job = job;
  this._chat = chat;

  return _.each(this._eventListeners, function(listener, event) {
    return this._job.on(event, listener);
  }.bind(this));
};

DeployMutex.prototype.hasJob = function() {
  return null !== this._job;
};

DeployMutex.prototype.getJob = function() {
  return this._job;
};

DeployMutex.prototype.removeJob = function() {
  _.each(this._eventListeners, function(listener, event) {
    return this._job.removeListener(event, listener);
  }.bind(this));

  this._job = null;
  this._chat = null;
};

DeployMutex.prototype._monitorTimeout = _.debounce(function() {
  if (!this.hasJob()) {
    return;
  }
  this._currentTimeout += DeployMutex._monitorTimeoutPeriod;
  this._chat.send('Running ' + (this._currentTimeout / 1000) + 'secs: ' + (DeployMutex._getLastText(this._job.data.output)));
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
