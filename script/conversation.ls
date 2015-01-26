require! {
  _: 'prelude-ls'
  history: './history.js'
  debug: './debug.js'
  events: './events.js'
}

__cid = 0

class Conversation implements events.MxWithEvents
  ->
    @_listeners = {}
    @participants = []
    @History = new history.History()
    @name = null
    @image = "./img/PictureContact160_trans@2x.png"
    @contactMood = "designing"

    @_lastMessage = null

    @_identity = "convo_#{__cid++}"

    Object.defineProperties @,
      LastMessage:
        enumerable: true
        get:
          ->
            unless @_lastMessage
              @_lastMessage = debug.CreateRandomMessage!

            @_lastMessage

  addParticipant: (participant) !~>
    @participants.push participant

    if @name?
      @name = [ @name, participant.name ].join(',')
    else
      @name = participant.name

    @fireEvent 'name_changed', @name

    if @participants.length is 1
      @image = @participants[0].avatar
      @fireEvent 'image_changed', @image

    @fireEvent 'participant_arrived', participant

  __playParticipantVideo: ~>
    p = _.find (.remoteVideos[0].Playing is false), @participants
    unless p?
      console.warn "All participants are playing videos"
      return

    p.playVideo!

    @fireEvent 'gained_participant_video', p

module.exports =
  Conversation: Conversation