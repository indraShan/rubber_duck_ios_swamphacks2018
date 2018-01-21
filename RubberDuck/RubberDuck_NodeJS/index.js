'use strict';

var Alexa = require('alexa-sdk');
var http = require('http');
var zlib = require("zlib");


exports.handler = function(event, context, callback) {
    const alexa = Alexa.handler(event, context);
    alexa.registerHandlers(handlers);
    alexa.execute();

};

const handlers = {
    'LaunchRequest': function () {
        this.emit('RubberDuck');
    },
    'RubberDuckIntent': function () {
        this.emit('RubberDuck')
    },
    'RubberDuck': function () {
       
       var options = {
        host: 'api.stackexchange.com',
        port: 80,
        path: '/2.2/search?order=desc&sort=activity&tagged=ios&site=stackoverflow',
        method: 'GET',
        headers: {
        'Content-Type': 'application/json'
    	}
  	};
var robj = this;
http.get(options, function(res) {
		var robj1 = robj;
       	var gunzip = zlib.createGunzip();            
        res.pipe(gunzip);
        var buffer = [];
        gunzip.on('data', function(data) {
            // decompression chunk ready, add it to the buffer
            //console.log(data.toString());
            buffer.push(data.toString())

        }).on("end", function() {
            // response and decompression complete, join the buffer and return
            //callback(null, buffer.join("")); 
            var obj = JSON.parse(buffer.join(""));
            //console.log(obj);
            robj.response.speak('You can try the following topic on stack overflow , ' + obj.items[0].title);
            robj.emit(':responseReady');

        }).on("error", function(e) {
            //callback(e);
        }); 
 }).end();
			//this.response.speak('You can try the following topic on stack overflow');
            //this.emit(':responseReady');
    },
    'AMAZON.HelpIntent': function () {
        const speechOutput = 'This is the Hello World Sample Skill. ';
        const reprompt = 'Say hello, to hear me speak.';

        this.response.speak(speechOutput).listen(reprompt);
        this.emit(':responseReady');
    },
    'AMAZON.CancelIntent': function () {
        this.response.speak('Goodbye!');
        this.emit(':responseReady');
    },
    'AMAZON.StopIntent': function () {
        this.response.speak('See you later!');
        this.emit(':responseReady');
    }
};