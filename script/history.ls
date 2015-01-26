require! {
  util: './util.js'
  events: './events.js'
  debug: './debug.js'
}

# For manipulating && formatting dates
__d = new Date()


# Mixin to handle the display of messages in a chat
# TODO(james). Buggy. Needs work. Maybe needs to be more functional'y
MxWithHistoryList =
  /* We currently re-render a whole day when we detect the
       first modification to that day.
       This removes subsequent modifications to a  day since they
       will have already been rendered */
  cleanLog: (indicies, opers, dayIdx, fromIdx) ~>
    l = indicies.length
    idx = fromIdx

    removed = 0
    while idx < l
      if indicies[idx] is dayIdx
        if opers[idx] is 'i'
          break
        else if opers[idx] is 'm'
          indicies.splice(idx, 1)
          opers.splice(idx, 1)
          l = indicies.length
          removed += 1
        else
          idx += 1

      else
        idx += 1

    removed

  # Map dayIdx as it was at 'fromIdx' in a change log to the
  # correct index for the day it refers to (which may have increased
  # due to subsequent insertions in the log)
  mapDayIdx: (dayIdx, indicies, opers, fromIdx) ~>
    idx = fromIdx + 1
    result = dayIdx
    l = indicies.length

    while idx < l
      if indicies[idx] <= result
        if opers[idx] is 'i'
          # A new day was inserted, increasing the actualy index of
          # the currently referenced day
          result += 1

      idx += 1

    result


  # Replay the changes to a conversation
  # 'log' is an object containing two parallel arrays
  #   'i' the index of a changed day
  #   'o' the operation performed on the day, one of 'a' for added
  #       or 'm' for modified.
  # This convoluted log-replay system is here becase we receive modifications
  # out-of-order for P2P chats
  replayChanges: (log) !~>
    indicies = log.i
    opers = log.o

    l = indicies.length
    unless opers.length is l
      console.warn('Opers and Indicies lengths do not match')
      return


    idx = 0
    dayIdx = -1
    dayDataIdx = -1
    oper = null
    dayPanels = @_messages.getElementsByClassName('day')

    while idx < l
      dayIdx = indicies[idx]
      dayDataIdx = @_mapDayIdx dayIdx, indicies, opers, idx
      oper = opers[idx]

      # TODO(james): what exactly is happening below?
      if oper is 'i'
        for p in dayPanels
          if p.children.length is 1
            console.log('screwed up')
            console.log('i: ' + log.i.join(','))
            console.log('o: ' + log.o.join(','))


      @_replay dayIdx, dayDataIdx, indicies, oper, dayPanels

      if oper is 'm'
        l -= @_cleanLog indicies, opers, dayIdx, idx + 1

      idx += 1


  # Replay a specific change to a specific day
  replay: (dayIdx, dayDataIdx, indicies, oper, dayPanels) !~>
    day = this._conversation.History.Days[dayDataIdx]
    messages = this._messages

    # We have to explicitly reverse the order of the rendered days
    # becase Trident fucks up column-reverse flex-boxes (can't scroll them)
    panelIdx = (dayPanels.length - 1) - dayIdx

    switch oper
    | "m" =>
      # a message has been added to an existing day
      @_reRenderDay day, dayPanels[panelIdx]

    | "i" =>
      # a new day was inserted at 'dayIdx'
      newDayPanel = @_createPanelForDay day
      if dayPanels.length > 0
        if panelIdx < dayPanels.length
          existingDayPanel = (panelIdx >= 0) ? dayPanels[panelIdx] : dayPanels[0]
          messages.insertBefore newDayPanel, existingDayPanel
        else
          messages.appendChild newDayPanel
      else
        messages.appendChild(newDayPanel);
    | _ =>
        console.error "Don't recognise operation: #{currOper}"

  _create-panel-for-day: (day) ~>
    panel = util.make "div", "day"
    panel.set-attribute 'data-stamp', "#{day.timeStamp}"

    day-stamp = util.make 'div', 'daystamp'

    __d.setTime day.timeStamp

    date-str = __d.toDateString!
    # Remove the year
    date-str = date-str.substring 0, date-str.length - 5

    day-stamp = util.make "div", "daystamp", panel, day-str

    panel

  _re-render-day: (day, dayPanel) !~>
    sermonPanels = dayPanel.getElementsByClassName 'sermon'
    changes = day.changes
    indicies = changes.i
    opers = changes.o

    unless indicies.length is opers.length
      console.error("Length mis-match between opers and indicies")
      return


    currIdx = -1
    currOper = null
    sermons = day.sermons
    sermon = null
    existingSermonPanel = null
    newSermonPanel = null
    l = indicies.length
    for i from 0 to (l - 1)
      currIdx = indicies[i];
      currOper = opers[i];
      sermon = sermons[currIdx];

      switch currOper
      | 'm' =>
          @_reRenderSermon sermon, sermonPanels[currIdx]
      | 'i' =>
        newSermonPanel = @_createSermonPanel sermon

        if currIdx < sermonPanels.length
          existingSermonPanel = sermonPanels[currIdx]
          dayPanel.insertBefore newSermonPanel, existingSermonPanel
        else
          dayPanel.appendChild(newSermonPanel);
      | _ =>
        console.warn "Don't know what to do with operation: #{currOper}"


    if dayPanel.children.length is 1
      console.log 'screwed up day'
      console.log 'i: ' + changes.i.join(',')
      console.log 'o: ' + changes.o.join(',')


    day.clearChanges!


  /*
    Create DOM to represent a 'sermon' (a continuous collection of
    messages from the same user)
  */
  _createSermonPanel: (sermon) ~>
    messages = sermon.messages

    result = util.make 'div', 'sermon'
    avatar = util.make 'div', 'msg_avatar', result
    avatar.style.backgroundImage = "url(#{sermon.avatar || './img/PictureContact160_trans@2x.png'})"

    __d.setTime messages[0].timeStamp
    timeStamp = util.make 'div', 'timestamp', result, (__d.toTimeString!.substring 0, 5)

    content = util.make 'div', 'content', result
    msgs_content = util.make 'div', 'msgs_content', content
    author = util.make 'div', 'author', content, messages[0].author

    for message in messages
      util.make 'div', 'message', message.message, msg_content

    result


  _reRenderSermon: (sermon, sermonPanel) !~>
    messages = sermon.messages
    l = messages.length

    newContent = util.make 'div', 'content'
    msgs_content = util.make 'div', 'msgs_content', newContent

    if l > 0
      author = util.make 'div', 'author', newContent, messages[0].author

      for message in messages
        util.make 'div', 'message', message.message, msg_content


    existingContent = sermonPanel.getElementsByClassName 'content'
    stamp = sermonPanel.getElementsByClassName 'timestamp'

    while existingContent.length > 0
      sermonPanel.removeChild existingContent[0]


    if stamp.length > 0
      sermonPanel.insertBefore(newContent, stamp[0])
    else
      sermonPanel.appendChild(newContent)


# We group any messages from the same source sent
# within this time span together
twoMinuteMillis = 2 * 60 * 1000

__getDayStampOfMessage = (message) ->
  __d.setTime(message.timeStamp);
  __d.setHours(0);
  __d.setMinutes(0);
  __d.setSeconds(0);
  __d.setMilliseconds(0);
  __d.getTime();

__pushChange = (changes, index, oper) ->
  i = changes.i
  o = changes.o

  l = i.length
  unless o.length is l
    console.error('Mis-matches lengths between opers and indicies!')
    return

  if l > 0
    if i[l - 1] is index and o[l - 1] is oper
      # Coalesce commutative modifications
      return

  i.push(index)
  o.push(oper)

__sermonMessageCmp = (message, sermon) ->
  sermon.timeStamp - message.timeStamp

__msgCmp = (first, second) ->
  first.timeStamp - second.timeStamp

__stampDayCmp = (day-stamp, day) ->
  day-stamp - day.timeStamp

# A 'sermon' is a bunch of messages from the same author sent very
# close togther without anyone else sending any replies
class Sermon
  (message) ->
    Object.defineProperties @,
      messages:
        value: [ message ]
        writable: true
        enumerable: true

      userId:
        value: message.userIdentifier
        writable: true
        enumerable: true

      userName:
        value: message.userName
        writable: true
        enumerable: true

      avatar:
        value: "./img/PictureContact160_trans@2x.png"
        writable: true
        enumerable: true

      timeStamp:
        value: message.timeStamp
        writable: true
        enumerable: true

  insert: (message) !~>
    messages = @messages
    i = util.insertion-index-for message, messages, __msgCmp
    if i < messages.length
      messages.splice i, 0, message
    else
      message.push message

  append: (message) ~>
    @messages.push message


class Day
  ->
    Object.defineProperties @,
      sermons:
        value: []
        writable: true
        enumerable: true

      timeStamp:
        value: null
        writable: true
        enumerable: true

      changes:
        value:
          i: []
          o: []
        writable: true
        enumerable: true

  insertMessage: (message) !~>
    idx = util.insertion-index-for message, @sermons, __sermonMessageCmp
    modifiedExisting = false
    l = sermons.length

    if idx > -1
      if idx > 0
        prevSermon = @sermons[idx - 1]

        if prevSermon.userId is message.userIdentifier
          messageCount = prevSermon.messages.length
          prevMessage = prevSermon.messages[messageCount - 1]
          if (message.timeStamp - prevMessage.timeStamp) < twoMinuteMillis
            idx -= 1
            prevSermon.append message

            # yuck
            modifiedExisting = true

        unless modifiedExisting
          sermon = new Sermon(message)
          if idx < l
            @Sermons.splice idx, 0, sermon
          else
            @Sermons.push sermon

        unless @timeStamp?
          @timeStamp = __getDayStampOfMessage message

      __pushChange(@changes, idx, (modifiedExisting ? 'm' : 'i'))


  insertMessages: (messageCollection) !~>
    for m in messageCollection
      @insertMessage(m)

  clearChanges: !~>
    @changes.i.splice(0)
    @changes.o.splice(0)



class History implements events.MxWithEvents
  ->
    Object.defineProperties @,
      Days:
        value: []
        writable: true
        enumerable: true

      changes:
        value: { i: [], o: [] }
        writable: true
        enumerable: true

      earlistMessageTime:
        value: Date.now()
        writable: true
        enumerable: true

      targetMessageTime:
        value: Date.now()
        writable: true
        enumerable: true

      cache:
        value: {}
        writable: true
        enumerable: true

  _gotMessages: (messages) !~>
    days = @Days
    for message in messages
      dayStamp = __getDayStampOfMessage message
      dayIdx = util.insertion-index-for dayStamp, days, __stampDayCmp

      if dayIdx > 0 and days[dayIdx - 1].timeStamp is dayStamp
        # message belongs in an existing day
        dayIdx -= 1
        day = days[dayIdx]
        day.insertMessage(message)

        __pushChange @changes, dayIdx, 'm'
      else
        # need to insert a new day...
        day = new Day()
        if dayIdx < days.length
          days.splice dayIdx, 0, day
        else
          days.push day

        __pushChange @changes, dayIdx, 'i'

        # Insert the message separately so the day captures the change...
        day.insertMessage message
        __pushChange changes, dayIdx, 'm'

    if messages.length > 0
      @fireEvent 'messages_arrived', @

  _failedMessages: (error) !~>
    console.error "Message load failed: #{error}"

  clearChanges: !~>
    for day in @Days
      day.clearChanges!

    @changes.i.splice(0)
    @changes.o.splice(0)

  load: !~>
    debug.RandomMessages(10, @_gotMessages)

module.exports =
  MxWithHistoryList: MxWithHistoryList
  History: History