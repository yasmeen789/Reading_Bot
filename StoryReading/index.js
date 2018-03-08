'use strict';

/**
 * This sample demonstrates a simple skill built with the Amazon Alexa Skills Kit.
 * The Intent Schema, Custom Slots, and Sample Utterances for this skill, as well as
 * testing instructions are located at http://amzn.to/1LzFrj6
 *
 * For additional samples, visit the Alexa Skills Kit Getting Started guide at
 * http://amzn.to/1LGWsLG
 */
const audio1 = 'A mouse took a stroll through the deep dark wood. A fox saw the mouse, and the mouse looked good. ';
const audio2 = 'Where are you going to, little brown mouse? Come and have lunch in my underground house. ';

const question1 = 'What animal\'s name begins with the letter F? ';
const correctAnswer1 = 'That\'s right! Fox begins with an F. F-O-X, fox! ';
const wrongAnswer1 = 'Almost. Fox begins with an F! F-O-X, fox! ';

// --------------- Helpers that build all of the responses -----------------------

function buildSpeechletResponse(title, output, repromptText, shouldEndSession) {
  return {
    outputSpeech: {
      type: 'PlainText',
      text: output,
    },
    card: {
      type: 'Simple',
      title: `SessionSpeechlet - ${title}`,
      content: `SessionSpeechlet - ${output}`,
    },
    reprompt: {
      outputSpeech: {
        type: 'PlainText',
        text: repromptText,
      },
    },
    shouldEndSession,
  };
}

function buildResponse(sessionAttributes, speechletResponse) {
  return {
    version: '1.0',
    sessionAttributes,
    response: speechletResponse,
  };
}


// --------------- Functions that control the skill's behavior -----------------------

function getWelcomeResponse(callback) {
  // If we wanted to initialize the session to have some attributes we could add those here.
  const sessionAttributes = {};
  const cardTitle = 'Welcome';
  const speechOutput = "Welcome to the Reading Bot. " +
    "Which child am I reading with today?";

  // If the user either does not reply to the welcome message or says something that is not
  // understood, they will be prompted again with this text.
  const repromptText = "Welcome to the Reading Bot. " +
    "Which child am I reading with today?";
  const shouldEndSession = false;

  callback(sessionAttributes,
    buildSpeechletResponse(cardTitle, speechOutput, repromptText, shouldEndSession));
}

function handleSessionEndRequest(callback) {
  const cardTitle = 'Session Ended';
  const speechOutput = "Thank you for using your child's companion. Have a nice day! ";
  // Setting this to true ends the session and exits the skill.
  const shouldEndSession = true;

  callback({}, buildSpeechletResponse(cardTitle, speechOutput, null, shouldEndSession));
}

function create_childs_name_attributes(childs_name) {
  return {
    childs_name,
  };
}

/**
 * Sets the color in the session and prepares the speech to reply to the user.
 */

function set_childs_name_in_session(intent, session, callback) {
  const cardTitle = intent.name;
  const childs_nameSlot = intent.slots.Child;
  let repromptText = '';
  let sessionAttributes = {};
  const shouldEndSession = false;
  let speechOutput = '';

  if (childs_nameSlot) {
    const childs_name = childs_nameSlot.value;
    sessionAttributes = create_childs_name_attributes(childs_name);

    speechOutput = `Hi ${childs_name}! ` +
      "What's the name of the book you would like to read today? " +
      "If you would like to hear a list of your available books say, " +
      "What's in my library? ";
    repromptText = "What's the name of the book you would like to read today? " +
      "If you would like to hear a list of your available books say, " +
      "What's in my library? ";

  } else {
    speechOutput = "I'm not sure what your name is. Please try again.";
    repromptText = "I'm not sure what your name is. ";
  }

  callback(sessionAttributes,
    buildSpeechletResponse(cardTitle, speechOutput, repromptText, shouldEndSession));
}

function create_story_choice(story_choice) {
  return {
    story_choice,
  };
}

/**
 * Sets the color in the session and prepares the speech to reply to the user.
 */

function getAvailableBooks(intent, session, callback) {
  let availableBooks;
  const repromptText = null;
  const sessionAttributes = {};
  let shouldEndSession = false;
  let speechOutput = '';

  speechOutput = `Your available books are The Gruffalo, Cinderella ` +
    `and The Three Little Pigs. ` +
    `Which book would you like to begin reading? `;

  // Setting repromptText to null signifies that we do not want to reprompt the user.
  // If the user does not respond or says something that is not understood, the session
  // will end.
  callback(sessionAttributes,
    buildSpeechletResponse(intent.name, speechOutput, repromptText, shouldEndSession));
}

function set_story_choice_in_session(intent, session, callback) {
  const cardTitle = intent.name;
  const story_choiceSlot = intent.slots.StoryChoice;
  let repromptText = '';
  let sessionAttributes = {};
  const shouldEndSession = true;
  let speechOutput = '';

  if (story_choiceSlot) {
    const story_choice = story_choiceSlot.value;
    sessionAttributes = create_story_choice(story_choice);
    speechOutput = `You have chosen ${story_choice}. `;
    repromptText = `You have chosen ${story_choice}. `;
  } else {
    speechOutput = "I'm not sure what your child's name is. Please try again.";
    repromptText = "I'm not sure what your child's name is. " +
      "Please tell me the name and date of birth of the child " +
      " that will be using this application." +
      " For example, my child's name is " +
      "Scarlet and her date of birth is the 21st September 2003.";
  }

  callback(sessionAttributes,
    buildSpeechletResponse(cardTitle, speechOutput, repromptText, shouldEndSession));
}

// --------------- Events -----------------------

/**
 * Called when the session starts.
 */
function onSessionStarted(sessionStartedRequest, session) {
  console.log(`
    onSessionStarted requestId = $ {
      sessionStartedRequest.requestId
    }, sessionId = $ {
      session.sessionId
    }
    `);
}

/**
 * Called when the user launches the skill without specifying what they want.
 */
function onLaunch(launchRequest, session, callback) {
  console.log(`
    onLaunch requestId = $ {
      launchRequest.requestId
    }, sessionId = $ {
      session.sessionId
    }
    `);

  // Dispatch to your skill's launch.
  getWelcomeResponse(callback);
}

/**
 * Called when the user specifies an intent for this skill.
 */
function onIntent(intentRequest, session, callback) {
  console.log(`
    onIntent requestId = $ {
      intentRequest.requestId
    }, sessionId = $ {
      session.sessionId
    }
    `);

  const intent = intentRequest.intent;
  const intentName = intentRequest.intent.name;

  // Dispatch to your skill's intent handlers
  if (intentName === 'MyChildsNameIsIntent') {
    set_childs_name_in_session(intent, session, callback);
  } else if (intentName === 'StoryChoiceIntent') {
    set_story_choice_in_session(intent, session, callback);
  } else if (intentName === 'StartIntent') {
    start_instructions(intent, session, callback);
  } else if (intentName === 'AvailableBooksIntent') {
    getAvailableBooks(intent, session, callback);
  } else if (intentName === 'AMAZON.NextIntent') {
    get_next(intent, session, callback);
  } else if (intentName === 'AMAZON.PauseIntent') {
    set_pause(intent, session, callback);
  } else if (intentName === 'AMAZON.ResumeIntent') {
    get_repeat(intent, session, callback);
  } else if (intentName === 'StartReadingBook') {
    startStory(intent, session, callback);
  } else if (intentName === 'CorrectAnswerIntent') {
    set_answer_from_session(intent, session, callback);
  } else if (intentName === 'FinishBook') {
    get_request_start_reading(intent, session, callback);
  } else if (intentName === 'AMAZON.HelpIntent') {
    getWelcomeResponse(callback);
  } else if (intentName === 'AMAZON.StopIntent' || intentName === 'AMAZON.CancelIntent') {
    handleSessionEndRequest(callback);
  } else {
    throw new Error('Invalid intent');
  }
}

/**
 * Called when the user ends the session.
 * Is not called when the skill returns shouldEndSession=true.
 */
function onSessionEnded(sessionEndedRequest, session) {
  console.log(`
    onSessionEnded requestId = $ {
      sessionEndedRequest.requestId
    }, sessionId = $ {
      session.sessionId
    }
    `);
  // Add cleanup logic here
}


// --------------- Main handler -----------------------

// Route the incoming request based on type (LaunchRequest, IntentRequest,
// etc.) The JSON body of the request is provided in the event parameter.
exports.handler = (event, context, callback) => {
  try {
    console.log(`
    event.session.application.applicationId = $ {
      event.session.application.applicationId
    }
    `);

    /**
     * Uncomment this if statement and populate with your skill's application ID to
     * prevent someone else from configuring a skill that sends requests to this function.
     */
    /*
    if (event.session.application.applicationId !== 'amzn1.echo-sdk-ams.app.[unique-value-here]') {
         callback('Invalid Application ID');
    }
    */

    if (event.session.new) {
      onSessionStarted({
        requestId: event.request.requestId
      }, event.session);
    }

    if (event.request.type === 'LaunchRequest') {
      onLaunch(event.request,
        event.session,
        (sessionAttributes, speechletResponse) => {
          callback(null, buildResponse(sessionAttributes, speechletResponse));
        });
    } else if (event.request.type === 'IntentRequest') {
      onIntent(event.request,
        event.session,
        (sessionAttributes, speechletResponse) => {
          callback(null, buildResponse(sessionAttributes, speechletResponse));
        });
    } else if (event.request.type === 'SessionEndedRequest') {
      onSessionEnded(event.request, event.session);
      callback();
    }
  } catch (err) {
    callback(err);
  }
};