UNMAINTAINED
============
This project is not maintained anymore.
If you want to take over contact us at tech@cargomedia.ch.

hubot-pulsar [![Build Status](https://img.shields.io/travis/cargomedia/hubot-pulsar/master.svg)](https://travis-ci.org/cargomedia/hubot-pulsar) [![npm](https://img.shields.io/npm/v/hubot-pulsar.svg)](https://www.npmjs.com/package/hubot-pulsar)
============

## About

This is ["Pulsar REST API service"](https://github.com/cargomedia/pulsar-rest-api) hubot script.

## Installation
Install it as a usual [hubot script](https://github.com/github/hubot/tree/master/docs#scripting). After that configure it to your needs. For that you need to have a config file. The config file will be searched in the following order:
* The script will try to get the environment variable `HUBOT_PULSAR_CONFIG`. If this variable exists then it is used as a file path to the config file.
* If the variable wasn't found then the script will try to locate the file `pulsar.config.json` in the directory of the hubot installation.

Authorization support is optional, and enabled if the [hubot-auth](https://github.com/hubot-scripts/hubot-auth) script is loaded.

### Config format
```json
{
  "pulsarApi": {
    "url": "<pulsar-rest-api-url>",
    "authToken": "<auth-token>"
  }
}
```

`pulsarApi`: Object. Required. It describes the configuration for [pulsar-rest-api-client-node](https://github.com/cargomedia/pulsar-rest-api-client-node).

## Deploy.js
For deploying applications.
Everyone with the role `deployer` is allowed to trigger deployments.

The script emits the following [events](https://github.com/github/hubot/blob/master/docs/scripting.md#events):
- `deploy:start`: When a deployment is started
- `deploy:success`: When a deployment finished successfully
- `deploy:error`: When a deployment fails

## Real-life usage example
Please look how this script can be used in your everyday workflow [http://www.cargomedia.ch/2015/06/23/pulsar-rest-api.html](http://www.cargomedia.ch/2015/06/23/pulsar-rest-api.html).
