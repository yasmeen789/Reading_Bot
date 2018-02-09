AUDIOASSETS.JS
'use strict';

// Audio Source - AWS Podcast : https://aws.amazon.com/podcasts/aws-podcast/
var audioData = [
    {
        'title' : 'Episode 139',
        'url' : 'https://feeds.soundcloud.com/stream/274166909-amazon-web-services-306355661-aws-podcast-episode-139.mp3'
    },
    {
        'title' : 'Episode 140',
        'url' : 'https://feeds.soundcloud.com/stream/275202399-amazon-web-services-306355661-amazon-web-services.mp3'
    }
];

module.exports = audioData;

AUDIOEVENTHANDLER.JS
'use strict';

var Alexa = require('alexa-sdk');
var audioData = require('./audioAssets');
var constants = require('./constants');

// Binding audio handlers to PLAY_MODE State since they are expected only in this mode.
var audioEventHandlers = Alexa.CreateStateHandler(constants.states.PLAY_MODE, {
    'PlaybackStarted' : function () {
        /*
         * AudioPlayer.PlaybackStarted Directive received.
         * Confirming that requested audio file began playing.
         * Storing details in dynamoDB using attributes.
         */
        this.attributes['token'] = getToken.call(this);
        this.attributes['index'] = getIndex.call(this);
        this.attributes['playbackFinished'] = false;
        this.emit(':saveState', true);
    },
    'PlaybackFinished' : function () {
        /*
         * AudioPlayer.PlaybackFinished Directive received.
         * Confirming that audio file completed playing.
         * Storing details in dynamoDB using attributes.
         */
        this.attributes['playbackFinished'] = true;
        this.attributes['enqueuedToken'] = false;
        this.emit(':saveState', true);
    },
    'PlaybackStopped' : function () {
        /*
         * AudioPlayer.PlaybackStopped Directive received.
         * Confirming that audio file stopped playing.
         * Storing details in dynamoDB using attributes.
         */
        this.attributes['token'] = getToken.call(this);
        this.attributes['index'] = getIndex.call(this);
        this.attributes['offsetInMilliseconds'] = getOffsetInMilliseconds.call(this);
        this.emit(':saveState', true);
    },
    'PlaybackNearlyFinished' : function () {
        /*
         * AudioPlayer.PlaybackNearlyFinished Directive received.
         * Using this opportunity to enqueue the next audio
         * Storing details in dynamoDB using attributes.
         * Enqueuing the next audio file.
         */
        if (this.attributes['enqueuedToken']) {
            /*
             * Since AudioPlayer.PlaybackNearlyFinished Directive are prone to be delivered multiple times during the
             * same audio being played.
             * If an audio file is already enqueued, exit without enqueuing again.
             */
            return this.context.succeed({});
        }
        
        var enqueueIndex = this.attributes['index'];
        enqueueIndex +=1;
        // Checking if  there are any items to be enqueued.
        if (enqueueIndex === audioData.length) {
            if (this.attributes['loop']) {
                // Enqueueing the first item since looping is enabled.
                enqueueIndex = 0;
            } else {
                // Nothing to enqueue since reached end of the list and looping is disabled.
                return this.context.succeed({});
            }
        }
        // Setting attributes to indicate item is enqueued.
        this.attributes['enqueuedToken'] = String(this.attributes['playOrder'][enqueueIndex]);

        var enqueueToken = this.attributes['enqueuedToken'];
        var playBehavior = 'ENQUEUE';
        var podcast = audioData[this.attributes['playOrder'][enqueueIndex]];
        var expectedPreviousToken = this.attributes['token'];
        var offsetInMilliseconds = 0;
        
        this.response.audioPlayerPlay(playBehavior, podcast.url, enqueueToken, expectedPreviousToken, offsetInMilliseconds);
        this.emit(':responseReady');
    },
    'PlaybackFailed' : function () {
        //  AudioPlayer.PlaybackNearlyFinished Directive received. Logging the error.
        console.log("Playback Failed : %j", this.event.request.error);
        this.context.succeed({});
    }
});

module.exports = audioEventHandlers;

function getToken() {
    // Extracting token received in the request.
    return this.event.request.token;
}

function getIndex() {
    // Extracting index from the token received in the request.
    var tokenValue = parseInt(this.event.request.token);
    return this.attributes['playOrder'].indexOf(tokenValue);
}

function getOffsetInMilliseconds() {
    // Extracting offsetInMilliseconds received in the request.
    return this.event.request.offsetInMilliseconds;
}

CONSTANTS.JS
"use strict";

module.exports = Object.freeze({
    
    // App-ID. TODO: set to your own Skill App ID from the developer portal.
    appId : '',
    
    //  DynamoDB Table name
    dynamoDBTableName : 'LongFormAudioSample',
    
    /*
     *  States:
     *  START_MODE : Welcome state when the audio list has not begun.
     *  PLAY_MODE :  When a playlist is being played. Does not imply only active play.
     *               It remains in the state as long as the playlist is not finished.
     *  RESUME_DECISION_MODE : When a user invokes the skill in PLAY_MODE with a LaunchRequest,
     *                         the skill provides an option to resume from last position, or to start over the playlist.
     */
    states : {
        START_MODE : '',
        PLAY_MODE : '_PLAY_MODE',
        RESUME_DECISION_MODE : '_RESUME_DECISION_MODE'
    },

    // when true, the skill logs additional detail, including the full request received from Alexa
    debug : true    
});

INDEX.JS
'use strict';

var Alexa = require('alexa-sdk');
var constants = require('./constants');
var stateHandlers = require('./stateHandlers');
var audioEventHandlers = require('./audioEventHandlers');

exports.handler = function(event, context, callback){
    var alexa = Alexa.handler(event, context);
    alexa.appId = constants.appId;
    alexa.dynamoDBTableName = constants.dynamoDBTableName;
    alexa.registerHandlers(
        stateHandlers.startModeIntentHandlers,
        stateHandlers.playModeIntentHandlers,
        stateHandlers.remoteControllerHandlers,
        stateHandlers.resumeDecisionModeIntentHandlers,
        audioEventHandlers
    );

    if (constants.debug) {
        console.log("\n" + "******************* REQUEST **********************");
        console.log("\n" + JSON.stringify(event, null, 2));
    }

    var audioPlayerInterface = ((((event.context || {}).System || {}).device || {}).supportedInterfaces || {}).AudioPlayer;
    if (audioPlayerInterface === undefined) {
        alexa.emit(':tell', 'Sorry, this skill is not supported on this device');
    }
    else {
        alexa.execute();
    }
};

PACKAGE-LOCK.JSON
{
  "name": "skill-sample-nodejs-audio-player",
  "version": "1.0.0",
  "lockfileVersion": 1,
  "requires": true,
  "dependencies": {
    "alexa-sdk": {
      "version": "1.0.25",
      "resolved": "https://registry.npmjs.org/alexa-sdk/-/alexa-sdk-1.0.25.tgz",
      "integrity": "sha512-+FVFNi+mxBZm2HL+oi5u4JTNjQ2uDs4Tp9eqcWIxL3AAD+AU4a6gWpu6LEjxIVCqaI1Ro/RyDm3mnJZA9g6G8w==",
      "requires": {
        "aws-sdk": "2.188.0",
        "i18next": "3.5.2",
        "i18next-sprintf-postprocessor": "0.2.2"
      }
    },
    "aws-sdk": {
      "version": "2.188.0",
      "resolved": "https://registry.npmjs.org/aws-sdk/-/aws-sdk-2.188.0.tgz",
      "integrity": "sha1-kGKrx9umOTRZ+i80I89dKU8ARhE=",
      "requires": {
        "buffer": "4.9.1",
        "events": "1.1.1",
        "jmespath": "0.15.0",
        "querystring": "0.2.0",
        "sax": "1.2.1",
        "url": "0.10.3",
        "uuid": "3.1.0",
        "xml2js": "0.4.17",
        "xmlbuilder": "4.2.1"
      }
    },
    "base64-js": {
      "version": "1.2.1",
      "resolved": "https://registry.npmjs.org/base64-js/-/base64-js-1.2.1.tgz",
      "integrity": "sha512-dwVUVIXsBZXwTuwnXI9RK8sBmgq09NDHzyR9SAph9eqk76gKK2JSQmZARC2zRC81JC2QTtxD0ARU5qTS25gIGw=="
    },
    "buffer": {
      "version": "4.9.1",
      "resolved": "https://registry.npmjs.org/buffer/-/buffer-4.9.1.tgz",
      "integrity": "sha1-bRu2AbB6TvztlwlBMgkwJ8lbwpg=",
      "requires": {
        "base64-js": "1.2.1",
        "ieee754": "1.1.8",
        "isarray": "1.0.0"
      }
    },
    "events": {
      "version": "1.1.1",
      "resolved": "https://registry.npmjs.org/events/-/events-1.1.1.tgz",
      "integrity": "sha1-nr23Y1rQmccNzEwqH1AEKI6L2SQ="
    },
    "i18next": {
      "version": "3.5.2",
      "resolved": "https://registry.npmjs.org/i18next/-/i18next-3.5.2.tgz",
      "integrity": "sha1-kwOQ1cMYzqpIWLUt0OQOayA/n0E="
    },
    "i18next-sprintf-postprocessor": {
      "version": "0.2.2",
      "resolved": "https://registry.npmjs.org/i18next-sprintf-postprocessor/-/i18next-sprintf-postprocessor-0.2.2.tgz",
      "integrity": "sha1-LkCfEENXk4Jpi2otpwzapVHWfqQ="
    },
    "ieee754": {
      "version": "1.1.8",
      "resolved": "https://registry.npmjs.org/ieee754/-/ieee754-1.1.8.tgz",
      "integrity": "sha1-vjPUCsEO8ZJnAfbwii2G+/0a0+Q="
    },
    "isarray": {
      "version": "1.0.0",
      "resolved": "https://registry.npmjs.org/isarray/-/isarray-1.0.0.tgz",
      "integrity": "sha1-u5NdSFgsuhaMBoNJV6VKPgcSTxE="
    },
    "jmespath": {
      "version": "0.15.0",
      "resolved": "https://registry.npmjs.org/jmespath/-/jmespath-0.15.0.tgz",
      "integrity": "sha1-o/Iiqarp+Wb10nx5ZRDigJF2Qhc="
    },
    "lodash": {
      "version": "4.17.5",
      "resolved": "https://registry.npmjs.org/lodash/-/lodash-4.17.5.tgz",
      "integrity": "sha512-svL3uiZf1RwhH+cWrfZn3A4+U58wbP0tGVTLQPbjplZxZ8ROD9VLuNgsRniTlLe7OlSqR79RUehXgpBW/s0IQw=="
    },
    "punycode": {
      "version": "1.3.2",
      "resolved": "https://registry.npmjs.org/punycode/-/punycode-1.3.2.tgz",
      "integrity": "sha1-llOgNvt8HuQjQvIyXM7v6jkmxI0="
    },
    "querystring": {
      "version": "0.2.0",
      "resolved": "https://registry.npmjs.org/querystring/-/querystring-0.2.0.tgz",
      "integrity": "sha1-sgmEkgO7Jd+CDadW50cAWHhSFiA="
    },
    "sax": {
      "version": "1.2.1",
      "resolved": "https://registry.npmjs.org/sax/-/sax-1.2.1.tgz",
      "integrity": "sha1-e45lYZCyKOgaZq6nSEgNgozS03o="
    },
    "url": {
      "version": "0.10.3",
      "resolved": "https://registry.npmjs.org/url/-/url-0.10.3.tgz",
      "integrity": "sha1-Ah5NnHcF8hu/N9A861h2dAJ3TGQ=",
      "requires": {
        "punycode": "1.3.2",
        "querystring": "0.2.0"
      }
    },
    "uuid": {
      "version": "3.1.0",
      "resolved": "https://registry.npmjs.org/uuid/-/uuid-3.1.0.tgz",
      "integrity": "sha512-DIWtzUkw04M4k3bf1IcpS2tngXEL26YUD2M0tMDUpnUrz2hgzUBlD55a4FjdLGPvfHxS6uluGWvaVEqgBcVa+g=="
    },
    "xml2js": {
      "version": "0.4.17",
      "resolved": "https://registry.npmjs.org/xml2js/-/xml2js-0.4.17.tgz",
      "integrity": "sha1-F76T6q4/O3eTWceVtBlwWogX6Gg=",
      "requires": {
        "sax": "1.2.1",
        "xmlbuilder": "4.2.1"
      }
    },
    "xmlbuilder": {
      "version": "4.2.1",
      "resolved": "https://registry.npmjs.org/xmlbuilder/-/xmlbuilder-4.2.1.tgz",
      "integrity": "sha1-qlijBBoGb5DqoWwvU4n/GfP0YaU=",
      "requires": {
        "lodash": "4.17.5"
      }
    }
  }
}

PACKAGE.JSON
{
  "name": "skill-sample-nodejs-audio-player",
  "version": "1.0.0",
  "description": "An audio player sample skill.",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [
    "alexa",
    "skill",
    "audio player"
  ],
  "author": "Amazon.com",
  "license": "See license in ../LICENSE.txt",
  "dependencies": {
    "alexa-sdk": "^1.0.4"
  },
  "repository": {
    "type": "git",
    "url": "https://github.com/alexa/skill-sample-nodejs-audio-player"
  }
}

STATEHANDLER.JS
'use strict';

var Alexa = require('alexa-sdk');
var audioData = require('./audioAssets');
var constants = require('./constants');

var stateHandlers = {
    startModeIntentHandlers : Alexa.CreateStateHandler(constants.states.START_MODE, {
        /*
         *  All Intent Handlers for state : START_MODE
         */
        'LaunchRequest' : function () {
            // Initialize Attributes
            this.attributes['playOrder'] = Array.apply(null, {length: audioData.length}).map(Number.call, Number);
            this.attributes['index'] = 0;
            this.attributes['offsetInMilliseconds'] = 0;
            this.attributes['loop'] = false; //do not loop on the list of podcast
            this.attributes['shuffle'] = false;
            this.attributes['playbackIndexChanged'] = true;
            //  Change state to START_MODE
            this.handler.state = constants.states.START_MODE;

            var message = 'Welcome to the AWS Podcast. You can say, play the audio to begin the podcast.';
            var reprompt = 'You can say, play the audio, to begin.';

            this.response.speak(message).listen(reprompt);
            this.emit(':responseReady');
        },
        'PlayAudio' : function () {
            if (!this.attributes['playOrder']) {
                // Initialize Attributes if undefined.
                this.attributes['playOrder'] = Array.apply(null, {length: audioData.length}).map(Number.call, Number);
                this.attributes['index'] = 0;
                this.attributes['offsetInMilliseconds'] = 0;
                this.attributes['loop'] = false; //do not loop on the list of podcast
                this.attributes['shuffle'] = false;
                this.attributes['playbackIndexChanged'] = true;
                //  Change state to START_MODE
                this.handler.state = constants.states.START_MODE;
            }
            controller.play.call(this);
        },
        'AMAZON.HelpIntent' : function () {
            var message = 'Welcome to the AWS Podcast. You can say, play the audio, to begin the podcast.';
            this.response.speak(message).listen(message);
            this.emit(':responseReady');
        },
        'AMAZON.StopIntent' : function () {
            var message = 'Good bye.';
            this.response.speak(message);
            this.emit(':responseReady');
        },
        'AMAZON.CancelIntent' : function () {
            var message = 'Good bye.';
            this.response.speak(message);
            this.emit(':responseReady');
        },
        'SessionEndedRequest' : function () {
            // No session ended logic
        },
        'Unhandled' : function () {
            var message = 'Sorry, I could not understand. Please say, play the audio, to begin the audio.';
            this.response.speak(message).listen(message);
            this.emit(':responseReady');
        }
    }),
    playModeIntentHandlers : Alexa.CreateStateHandler(constants.states.PLAY_MODE, {
        /*
         *  All Intent Handlers for state : PLAY_MODE
         */
        'LaunchRequest' : function () {
            /*
             *  Session resumed in PLAY_MODE STATE.
             *  If playback had finished during last session :
             *      Give welcome message.
             *      Change state to START_STATE to restrict user inputs.
             *  Else :
             *      Ask user if he/she wants to resume from last position.
             *      Change state to RESUME_DECISION_MODE
             */
            var message;
            var reprompt;
            if (this.attributes['playbackFinished']) {
                this.handler.state = constants.states.START_MODE;
                message = 'Welcome to the AWS Podcast. You can say, play the audio to begin the podcast.';
                reprompt = 'You can say, play the audio, to begin.';
            } else {
                this.handler.state = constants.states.RESUME_DECISION_MODE;
                message = 'You were listening to ' + audioData[this.attributes['playOrder'][this.attributes['index']]].title +
                    ' Would you like to resume?';
                reprompt = 'You can say yes to resume or no to play from the top.';
            }

            this.response.speak(message).listen(reprompt);
            this.emit(':responseReady');
        },
        'PlayAudio' : function () { controller.play.call(this) },
        'AMAZON.NextIntent' : function () { controller.playNext.call(this) },
        'AMAZON.PreviousIntent' : function () { controller.playPrevious.call(this) },
        'AMAZON.PauseIntent' : function () { controller.stop.call(this) },
        'AMAZON.StopIntent' : function () { controller.stop.call(this) },
        'AMAZON.CancelIntent' : function () { controller.stop.call(this) },
        'AMAZON.ResumeIntent' : function () { controller.play.call(this) },
        'AMAZON.LoopOnIntent' : function () { controller.loopOn.call(this) },
        'AMAZON.LoopOffIntent' : function () { controller.loopOff.call(this) },
        'AMAZON.ShuffleOnIntent' : function () { controller.shuffleOn.call(this) },
        'AMAZON.ShuffleOffIntent' : function () { controller.shuffleOff.call(this) },
        'AMAZON.StartOverIntent' : function () { controller.startOver.call(this) },
        'AMAZON.HelpIntent' : function () {
            // This will called while audio is playing and a user says "ask <invocation_name> for help"
            var message = 'You are listening to the AWS Podcast. You can say, Next or Previous to navigate through the playlist. ' +
                'At any time, you can say Pause to pause the audio and Resume to resume.';
            this.response.speak(message).listen(message);
            this.emit(':responseReady');
        },
        'SessionEndedRequest' : function () {
            // No session ended logic
        },
        'Unhandled' : function () {
            var message = 'Sorry, I could not understand. You can say, Next or Previous to navigate through the playlist.';
            this.response.speak(message).listen(message);
            this.emit(':responseReady');
        }
    }),
    remoteControllerHandlers : Alexa.CreateStateHandler(constants.states.PLAY_MODE, {
        /*
         *  All Requests are received using a Remote Control. Calling corresponding handlers for each of them.
         */
        'PlayCommandIssued' : function () { controller.play.call(this) },
        'PauseCommandIssued' : function () { controller.stop.call(this) },
        'NextCommandIssued' : function () { controller.playNext.call(this) },
        'PreviousCommandIssued' : function () { controller.playPrevious.call(this) }
    }),
    resumeDecisionModeIntentHandlers : Alexa.CreateStateHandler(constants.states.RESUME_DECISION_MODE, {
        /*
         *  All Intent Handlers for state : RESUME_DECISION_MODE
         */
        'LaunchRequest' : function () {
            var message = 'You were listening to ' + audioData[this.attributes['playOrder'][this.attributes['index']]].title +
                ' Would you like to resume?';
            var reprompt = 'You can say yes to resume or no to play from the top.';
            this.response.speak(message).listen(reprompt);
            this.emit(':responseReady');
        },
        'AMAZON.YesIntent' : function () { controller.play.call(this) },
        'AMAZON.NoIntent' : function () { controller.reset.call(this) },
        'AMAZON.HelpIntent' : function () {
            var message = 'You were listening to ' + audioData[this.attributes['index']].title +
                ' Would you like to resume?';
            var reprompt = 'You can say yes to resume or no to play from the top.';
            this.response.speak(message).listen(reprompt);
            this.emit(':responseReady');
        },
        'AMAZON.StopIntent' : function () {
            var message = 'Good bye.';
            this.response.speak(message);
            this.emit(':responseReady');
        },
        'AMAZON.CancelIntent' : function () {
            var message = 'Good bye.';
            this.response.speak(message);
            this.emit(':responseReady');
        },
        'SessionEndedRequest' : function () {
            // No session ended logic
        },
        'Unhandled' : function () {
            var message = 'Sorry, this is not a valid command. Please say help to hear what you can say.';
            this.response.speak(message).listen(message);
            this.emit(':responseReady');
        }
    })
};

module.exports = stateHandlers;

var controller = function () {
    return {
        play: function () {
            /*
             *  Using the function to begin playing audio when:
             *      Play Audio intent invoked.
             *      Resuming audio when stopped/paused.
             *      Next/Previous commands issued.
             */
            this.handler.state = constants.states.PLAY_MODE;

            if (this.attributes['playbackFinished']) {
                // Reset to top of the playlist when reached end.
                this.attributes['index'] = 0;
                this.attributes['offsetInMilliseconds'] = 0;
                this.attributes['playbackIndexChanged'] = true;
                this.attributes['playbackFinished'] = false;
            }

            var token = String(this.attributes['playOrder'][this.attributes['index']]);
            var playBehavior = 'REPLACE_ALL';
            var podcast = audioData[this.attributes['playOrder'][this.attributes['index']]];
            var offsetInMilliseconds = this.attributes['offsetInMilliseconds'];
            // Since play behavior is REPLACE_ALL, enqueuedToken attribute need to be set to null.
            this.attributes['enqueuedToken'] = null;

            if (canThrowCard.call(this)) {
                var cardTitle = 'Playing ' + podcast.title;
                var cardContent = 'Playing ' + podcast.title;
                this.response.cardRenderer(cardTitle, cardContent, null);
            }

            var message = "This is " + audioData[this.attributes['index']].title;
            this.response.speak(message).audioPlayerPlay(playBehavior, podcast.url, token, null, offsetInMilliseconds);
            this.emit(':responseReady');
        },
        stop: function () {
            /*
             *  Issuing AudioPlayer.Stop directive to stop the audio.
             *  Attributes already stored when AudioPlayer.Stopped request received.
             */
            this.response.audioPlayerStop();
            this.emit(':responseReady');
        },
        playNext: function () {
            /*
             *  Called when AMAZON.NextIntent or PlaybackController.NextCommandIssued is invoked.
             *  Index is computed using token stored when AudioPlayer.PlaybackStopped command is received.
             *  If reached at the end of the playlist, choose behavior based on "loop" flag.
             */
            var index = this.attributes['index'];
            index += 1;
            // Check for last audio file.
            if (index === audioData.length) {
                if (this.attributes['loop']) {
                    index = 0;
                } else {
                    // Reached at the end. Thus reset state to start mode and stop playing.
                    this.handler.state = constants.states.START_MODE;

                    var message = 'You have reached at the end of the playlist.';
                    this.response.speak(message).audioPlayerStop();
                    return this.emit(':responseReady');
                }
            }
            // Set values to attributes.
            this.attributes['index'] = index;
            this.attributes['offsetInMilliseconds'] = 0;
            this.attributes['playbackIndexChanged'] = true;

            controller.play.call(this);
        },
        playPrevious: function () {
            /*
             *  Called when AMAZON.PreviousIntent or PlaybackController.PreviousCommandIssued is invoked.
             *  Index is computed using token stored when AudioPlayer.PlaybackStopped command is received.
             *  If reached at the end of the playlist, choose behavior based on "loop" flag.
             */
            var index = this.attributes['index'];
            index -= 1;
            // Check for last audio file.
            if (index === -1) {
                if (this.attributes['loop']) {
                    index = audioData.length - 1;
                } else {
                    // Reached at the end. Thus reset state to start mode and stop playing.
                    this.handler.state = constants.states.START_MODE;

                    var message = 'You have reached at the start of the playlist.';
                    this.response.speak(message).audioPlayerStop();
                    return this.emit(':responseReady');
                }
            }
            // Set values to attributes.
            this.attributes['index'] = index;
            this.attributes['offsetInMilliseconds'] = 0;
            this.attributes['playbackIndexChanged'] = true;

            controller.play.call(this);
        },
        loopOn: function () {
            // Turn on loop play.
            this.attributes['loop'] = true;
            var message = 'Loop turned on.';
            this.response.speak(message);
            this.emit(':responseReady');
        },
        loopOff: function () {
            // Turn off looping
            this.attributes['loop'] = false;
            var message = 'Loop turned off.';
            this.response.speak(message);
            this.emit(':responseReady');
        },
        shuffleOn: function () {
            // Turn on shuffle play.
            this.attributes['shuffle'] = true;
            shuffleOrder((newOrder) => {
                // Play order have been shuffled. Re-initializing indices and playing first song in shuffled order.
                this.attributes['playOrder'] = newOrder;
                this.attributes['index'] = 0;
                this.attributes['offsetInMilliseconds'] = 0;
                this.attributes['playbackIndexChanged'] = true;
                controller.play.call(this);
            });
        },
        shuffleOff: function () {
            // Turn off shuffle play. 
            if (this.attributes['shuffle']) {
                this.attributes['shuffle'] = false;
                // Although changing index, no change in audio file being played as the change is to account for reordering playOrder
                this.attributes['index'] = this.attributes['playOrder'][this.attributes['index']];
                this.attributes['playOrder'] = Array.apply(null, {length: audioData.length}).map(Number.call, Number);
            }
            controller.play.call(this);
        },
        startOver: function () {
            // Start over the current audio file.
            this.attributes['offsetInMilliseconds'] = 0;
            controller.play.call(this);
        },
        reset: function () {
            // Reset to top of the playlist.
            this.attributes['index'] = 0;
            this.attributes['offsetInMilliseconds'] = 0;
            this.attributes['playbackIndexChanged'] = true;
            controller.play.call(this);
        }
    }
}();

function canThrowCard() {
    /*
     * To determine when can a card should be inserted in the response.
     * In response to a PlaybackController Request (remote control events) we cannot issue a card,
     * Thus adding restriction of request type being "IntentRequest".
     */
    if (this.event.request.type === 'IntentRequest' && this.attributes['playbackIndexChanged']) {
        this.attributes['playbackIndexChanged'] = false;
        return true;
    } else {
        return false;
    }
}

function shuffleOrder(callback) {
    // Algorithm : Fisher-Yates shuffle
    var array = Array.apply(null, {length: audioData.length}).map(Number.call, Number);
    var currentIndex = array.length;
    var temp, randomIndex;

    while (currentIndex >= 1) {
        randomIndex = Math.floor(Math.random() * currentIndex);
        currentIndex -= 1;
        temp = array[currentIndex];
        array[currentIndex] = array[randomIndex];
        array[randomIndex] = temp;
    }
    callback(array);
}