hourMillis = 60 * 60 * 1000;
dayMillis = 24 * hourMillis;

msgCount = 0;

__callback = null;

__usrIdx = 1;

_randomiseTimestamp = (original) ->
  # Shift between 0 and 3 days...
  dayShift = Math.floor(Math.random() * 4)

  # Jiggle the hour. Don't car about minutes...
  hourShift = Math.floor(Math.random() * 8);

  original - (dayShift * dayMillis)

_createMessage = ->
  contacts = Stadium.HubRepository._people
  userCount = contacts.length
  userIdx = Math.floor(Math.random() * 2)

  #__usrIdx = 1 - __usrIdx;

  user = contacts[userIdx];

  msgId = msgCount++;

  timestamp = Date.now();

  if Math.random! > 0.66
    timestamp = _randomiseTimestamp(timestamp);

  {
    userIdentifier: user.identifier
    author: user.name
    message: "This is the content of message  #{msgId}, #{user.name}"
    id: "message-" + msgId
    timeStamp: timestamp
  }

_randomMessages = (num, cb) ->
  [cb! for i from 1 to num ]


module.exports =
  CreateRandomMessage: _createMessage
  RandomMessages: _randomMessages


