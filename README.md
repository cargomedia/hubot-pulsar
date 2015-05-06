[![Build Status](https://travis-ci.org/cargomedia/hubot-pulsar.png?branch=master)](https://travis-ci.org/cargomedia/hubot-pulsar)

hubot-pulsar
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
