var DeploymentMonitor = require('./deployment/monitor');
var deploymentMonitor = new DeploymentMonitor();

module.exports = function(robot) {

  robot.respond(/deploy pending ([^\s]+) ([^\s]+)$/i, function(chat) {
    var app = chat.match[1];
    var env = chat.match[2];
    chat.send('Getting changes…');
    var job = pulsarApi.createJob(app, env, 'deploy:pending');

    job.on('success', function() {
      return chat.send('Pending changes for ' + this.app + ' ' + this.env + ':\n' + this.data.stdout);
    }).on('error', function(error) {
      chat.send('Pending changes failed: ' + (JSON.stringify(error)));
      if (this.data.url) {
        return chat.send('More info: ' + this.data.url);
      }
    });

    pulsarApi.runJob(job);
  });

  robot.respond(/deploy ([^\s]+) ([^\s]+)$/i, function(chat) {
    if (!robot.userHasRole(chat, 'deployer')) {
      return;
    }
    if (deploymentMonitor.hasDeployJob()) {
      chat.send('Deploy job can not be started because ' + (deploymentMonitor.getDeployJob()) + ' is in progress');
      return;
    }

    var app = chat.match[1];
    var env = chat.match[2];
    chat.send('Getting changes…');

    var deployJob = pulsarApi.createJob(app, env, 'deploy');
    deploymentMonitor.setDeployJob(deployJob, chat);
    deployJob.on('create', function() {
      return chat.send('Deployment started: ' + this.data.url);
    }).on('success', function() {
      return chat.send('Deployment finished.');
    }).on('error', function(error) {
      return chat.send('Deployment failed: ' + (JSON.stringify(error)));
    });

    var pendingJob = pulsarApi.createJob(app, env, 'deploy:pending');
    pendingJob.on('success', function() {
      deployJob.taskVariables = {
        revision: this.taskVariables.revision
      };
      chat.send('Pending changes for ' + this.app + ' ' + this.env + ':\n' + this.data.stdout);
      return chat.send('Say "CONFIRM DEPLOY" or "CANCEL DEPLOY".');
    }).on('error', function(error) {
      deployJob.emit('error', error);
      if (this.data.url) {
        return chat.send('More info: ' + this.data.url);
      }
    });

    var showNextRevisionJob = pulsarApi.createJob(app, env, 'deploy:show_next_revision');
    showNextRevisionJob.on('success', function() {
      var revision;
      if (!this.data.stdout || !this.data.stdout.trim()) {
        this.emit('error', new Error('Cannot retrieve revision number.'));
        return;
      }
      revision = this.data.stdout.trim();
      pendingJob.taskVariables = {
        revision: revision
      };
      return pulsarApi.runJob(pendingJob);
    }).on('error', function(error) {
      deployJob.emit('error', error);
      if (this.data.url) {
        return chat.send('More info: ' + this.data.url);
      }
    });

    pulsarApi.runJob(showNextRevisionJob);
  });

  robot.respond(/confirm deploy$/i, function(chat) {
    if (!robot.userHasRole(chat, 'deployer')) {
      return;
    }
    if (!deploymentMonitor.hasDeployJob()) {
      chat.send('No deploy job to confirm');
      return;
    }

    var deployJob = deploymentMonitor.getDeployJob();
    pulsarApi.runJob(deployJob);
    chat.send('Deployment confirmed.');
  });

  robot.respond(/cancel deploy$/i, function(chat) {
    if (!robot.userHasRole(chat, 'deployer')) {
      return;
    }
    if (!deploymentMonitor.hasDeployJob()) {
      chat.send('No deploy job to cancel');
      return;
    }

    chat.send('Deployment cancelled.');
    deploymentMonitor.removeDeployJob();
  });
};