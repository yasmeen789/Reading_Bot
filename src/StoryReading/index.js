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
const ChildAnswer1 = 'That\'s right! Fox begins with an F. F-O-X, fox! ';
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


// --------------- Functions that control the skill's behavior -----------------

/**
 * Initial speech that welcomes the user.
 */
function getWelcomeResponse(callback) {
  const sessionAttributes = {};
  const cardTitle = 'Welcome';
  const speechOutput = "Hi, I'm Reading Bot. " +
    "What's your first name?";
  const repromptText = "What's your first name?";
  const shouldEndSession = false;

  callback(sessionAttributes,
    buildSpeechletResponse(cardTitle, speechOutput, repromptText, shouldEndSession));
}

/**
 * Ends the session.
 */
function handleSessionEndRequest(callback) {
  const cardTitle = 'Session Ended';
  const speechOutput = "Thanks for reading with me! See you next time!";
  // Setting this to true ends the session and exits the skill.
  const shouldEndSession = true;

  callback({}, buildSpeechletResponse(cardTitle, speechOutput, null, shouldEndSession));
}

/**
 * Initiates the child's first name.
 */
function createChildsNameAttributes(childs_name) {
  return {
    childs_name,
  };
}

/**
 * Checks child's name and asks about books.
 */
function setChildsNameInSession(intent, session, callback) {
  const cardTitle = intent.name;
  const childs_nameSlot = intent.slots.Child;
  let repromptText = '';
  let sessionAttributes = {};
  const shouldEndSession = false;
  let speechOutput = '';

  if (childs_nameSlot) {
    const childs_name = childs_nameSlot.value;
    sessionAttributes = createChildsNameAttributes(childs_name);
    if (childs_name == `Toby`) {
      speechOutput = `Hi ${childs_name}! ` +
        "What's the name of the book you would like to read today? " +
        "If you would like to hear a list of your available books say, " +
        "What's in my library? ";
      repromptText = "What's the name of the book you would like to read today? " +
        "If you would like to hear a list of your available books say, " +
        "What's in my library? ";
    } else {
      speechOutput = `You said, ${childs_name}. I don't think that's right.` +
        " What's your first name? ";
      repromptText = "What's your first name?";
    }
  }

  callback(sessionAttributes,
    buildSpeechletResponse(cardTitle, speechOutput, repromptText, shouldEndSession));
}

/**
 * Initiates the child's story choice.
 */
function createStoryChoice(story_choice) {
  return {
    story_choice,
  };
}

/**
 * Lists all available books.
 */
function getAvailableBooks(intent, session, callback) {
  let availableBooks;
  const repromptText = null;
  const sessionAttributes = {};
  let shouldEndSession = false;
  let speechOutput = '';

  speechOutput = `Your available books are The Gruffalo, Jack and the Beanstalk, ` +
    `and The Three Little Pigs. ` +
    `Which book would you like to begin reading? `;

  // Setting repromptText to null signifies that we do not want to reprompt the user.
  // If the user does not respond or says something that is not understood, the session
  // will end.
  callback(sessionAttributes,
    buildSpeechletResponse(intent.name, speechOutput, repromptText, shouldEndSession));
}

/**
 * Starts reading story.
 */
function setStoryChoiceInSession(intent, session, callback) {
  const cardTitle = intent.name;
  const story_choiceSlot = intent.slots.StoryChoice;
  let repromptText = '';
  let sessionAttributes = {};
  const shouldEndSession = false;
  let speechOutput = '';

  if (story_choiceSlot) {
    const story_choice = story_choiceSlot.value;
    sessionAttributes = createStoryChoice(story_choice);
    if (story_choice == `the gruffalo`) {
      speechOutput = `You have chosen ${story_choice}. Great choice!` + audio1 + question1;
      repromptText = question1;
    } else {
      speechOutput = `You said ${story_choice}. That's not an available book. `;
    }
  }

  callback(sessionAttributes,
    buildSpeechletResponse(cardTitle, speechOutput, repromptText, shouldEndSession));
}

/**
 * Initiates the child's answer.
 */
function createAnswerAcceptance(child_answer) {
  return {
    child_answer,
  };
}

/**
 * Responds to child's answer and continues story.
 */
function setAnswerFromSession(intent, session, callback) {
  const cardTitle = intent.name;
  const child_answerSlot = intent.slots.ChildAnswer;
  let repromptText = '';
  let sessionAttributes = {};
  const shouldEndSession = true;
  let speechOutput = '';

  if (child_answerSlot) {
    const child_answer = child_answerSlot.value;
    sessionAttributes = createAnswerAcceptance(child_answer);
    if (child_answer == 'fox') {
      speechOutput = ChildAnswer1 + audio2;
    } else {
      speechOutput = wrongAnswer1 + audio2;
    }
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
    setChildsNameInSession(intent, session, callback);
  } else if (intentName === 'StoryChoiceIntent') {
    setStoryChoiceInSession(intent, session, callback);
  } else if (intentName === 'AvailableBooksIntent') {
    getAvailableBooks(intent, session, callback);
  } else if (intentName === 'ChildAnswerIntent') {
    setAnswerFromSession(intent, session, callback);
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
