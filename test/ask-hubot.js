require('coffee-script/register');
var humock = require('mock-hubot');

module.exports = function(text) {
  var counter = 0;
  var callbacks = {};
  humock.test(text, function(response, strings) {
    counter++;
    if (callbacks[counter]) {
      callbacks[counter](strings[0]);
    }
  });

  var responses = {
    response: function(number, callback){
      callbacks[number] = callback;
      return responses;
    }
  };

  return responses;
};
