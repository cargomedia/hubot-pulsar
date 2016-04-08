var DeployMutex = require('./deploy-mutex');
var deployMutex = new DeployMutex();

module.exports = function(robot) {

  robot.respond(/deploy pending ([^\s]+) ([^\s]+)$/i, function(chat) {
    if (deployMutex.hasJob()) {
      chat.send('Deploy job can not be started because ' + (deployMutex.getJob()) + ' is in progress');
      return;
    }
    var app = chat.match[1];
    var env = chat.match[2];
    chat.send('Getting changes…');
    var job = pulsarApi.createJob(app, env, 'deploy:pending');
    deployMutex.setJob(job, chat);

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
    if (deployMutex.hasJob()) {
      chat.send('Deploy job can not be started because ' + (deployMutex.getJob()) + ' is in progress');
      return;
    }

    var app = chat.match[1];
    var env = chat.match[2];
    chat.send('Getting changes…');

    var deployJob = pulsarApi.createJob(app, env, 'deploy');
    deployMutex.setJob(deployJob, chat);
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
    var job = deployMutex.getJob();
    if (!job || 'deploy' != job.task) {
      chat.send('No deploy job to confirm');
      return;
    }

    pulsarApi.runJob(job);
    chat.send('Deployment confirmed.');
  });

  robot.respond(/cancel deploy$/i, function(chat) {
    if (!robot.userHasRole(chat, 'deployer')) {
      return;
    }
    var job = deployMutex.getJob();
    if (!job || 'deploy' != job.task) {
      chat.send('No deploy job to cancel');
      return;
    }

    chat.send('Deployment cancelled.');
    deployMutex.removeJob();
  });

  robot.respond(/deploy rollback ([^\s]+) ([^\s]+)$/i, function(chat) {
    if (!robot.userHasRole(chat, 'deployer')) {
      return;
    }
    var app = chat.match[1];
    var env = chat.match[2];

    if (deployMutex.hasJob()) {
      chat.send("Deploy rollback can not be started because " + (deployMutex.getJob()) + " is in progress");
      return;
    }
    chat.send("Rolling back the previous deploy…");

    var job = pulsarApi.createJob(app, env, 'deploy:rollback');
    deployMutex.setJob(job, chat);
    job.on('success', function() {
        chat.send("Successfully rolled back deploy for " + this.app + " " + this.env);
        if (this.data.stdout) {
          return chat.send("" + this.data.stdout);
        }
      })
      .on('error', function(error) {
        chat.send("Deploy rollback failed: " + (JSON.stringify(error)));
        if (this.data.url) {
          return chat.send("More info: " + this.data.url);
        }
      });

    pulsarApi.runJob(job);
  });
};
