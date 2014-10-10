[![Build Status](https://travis-ci.org/cargomedia/hubot-pulsar.png?branch=master)](https://travis-ci.org/cargomedia/hubot-pulsar)

(unstable, currently in development)

hubot-pulsar
============

## About

This is a hubot script to a [Pulsar REST API service](https://github.com/cargomedia/pulsar-rest-api)

## Installation
Install it as a usual [hubot script](https://github.com/github/hubot/tree/master/docs#scripting). After that configure it for your needs. For that you need to have a config file. The config file will be searched in the next order:
* The script will try to get the environment variable `HUBOT_PULSAR_CONFIG`. If this variable exists then its is used as a file path to the config file.
* If the variable wasn't found then the script will try to locate the file `pulsar.config.json` in the directory of the hubot installation which uses the script. If the `pulsar.config.json` was found then the script will use it.
* If all the previous steps failed then the script will try to read the file `config.json` in its `src` directory which is probably not what you want.


### Config format
```json
{
  "pulsarApi": {
    "url": "",
    "authToken": ""
  },
  "hipchatRoles": ""
}
```

`pulsarApi.url`: String. Required. Url of Pulsar REST API.
`pulsarApi.authToken`: String. Optional. Authentication token for Pulsar REST API if it requires authentication. Details [here](https://github.com/cargomedia/pulsar-rest-api#authentication).
`hipchatRoles`: String or Array of Strings. Optional. Hipchat user roles that are allowed to communicate with the hubot.
