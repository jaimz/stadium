require! {
  _: 'prelude-ls'
  events: './events.js'
  history: './history.js'
  video: './video.js'
}

/*
  This responder handles interaction with a conversation
  view in both call and non-call modes
*/
class ConversationResponder implements events.MxWithEvents, history.MxWithHistoryList, video.MxWithFullscreen
  ->
    @_conversation = null
    @_view = null

    # Action button in normal view
    @_actions = null

    # Action buttons in call view
    @_callActions = null

    @_reset-focus!

    @_allActions = null

    @_commands = {}

    Object.defineProperties @,
      Conversation:
        enumerable: true
        set: (v) ->
          if @_conversation?
            @_unloadConversation!

          @_conversation = v || null

          if @_conversation?
            @_inspectConversation
        get: -> @_conversation

      View:
        enumerable: true
        set: (v) ->
          @_view = v || null
          @_reset-focus!

          @_inspectView!

    @_init-commands!


  _reset-focus: !~>
    @_focus = null
    @_focusIdx = 0
    @_focusParent = null


  _inspectView: !~>
    @_convoActions = @_view.querySelector('.convo_actions')
    @_callActions = @_view.querySelector('.call_actions')

    @_participantContainer = @_view.querySelector('.participants')
    @_participantPanels = @_participantContainer.querySelectorAll('.participant')

    @_messages = @_view.querySelector('.messages')

    if @_view.classList.contains("in-call")
      @_changeFocusParent(@_callActions)
    else
      @_changeFocusParent(@_convoActions)


    @_deregisterEvents!

    @_allActions = @_view.querySelectorAll('.action')

    @_registerEvents!


  _inspectConversation: !~>
    convo = @Conversation

    convo.addEventListener('participants_changed', @_participantsChanged)
    convo.addEventListener('participant_arrived', @_participantArrived)
    convo.addEventListener('participant_left', @_participantLeft)
    convo.addEventListener('participant_voice_change', @_participantVoiceChange)
    convo.addEventListener('gained_participant_video', @_gainedParticipantVideo)
    convo.addEventListener('lost_participant_video', @_lostParticipantVideo)
    convo.History.addEventListener('messages_arrived', @_messagesArrived)

  _unloadConversation: !~>
    convo = @Conversation

    unless convo?
      return

    convo.addEventListener('participants_changed', @_participantsChanged)
    convo.addEventListener('participant_arrived', @_participantArrived)
    convo.addEventListener('participant_left', @_participantLeft)
    convo.addEventListener('participant_voice_change', @_participantVoiceChange)
    convo.addEventListener('gained_participant_video', @_gainedParticipantVideo)
    convo.addEventListener('lost_participant_video', @_lostParticipantVideo)
    convo.History.addEventListener('messages_arrived', @_messagesArrived)

  _listen: !~>
    unless @_allActions and @_allActions.length > 0
      return

    activateSelection = @_activateSelection
    _.each (.addEventListener 'click', activateSelection), @_allActions

  _dontListen: !~>
    unless @_allActions and @_allActions.length > 0
      return

    activateSelection = @_activateSelection
    _.each (.removeEventListener 'click', activateSelection), @_allActions

  _init-commands: !~>
    @_commands =
      makeVideoCall: -> @__makeCallDebug 'video-call'
      makeAudioCall: -> @__makeCallDebug 'audio-call'
      endCall: ->
        cl = @_view.classList
        cl.remove('calling')
        cl.remove('has-video')
        cl.remove('is-group')
        cl.remove('in-call')
        cl.remove('video-call')
        cl.remove('audio-call')

        pc = @_participantContainer
        c = pc.children
        while c.length > 0
          pc.removeChild(c[0])

        @_changeFocusParent @_convoActions

      toggleIMs: -> @_view.classList.toggle('ims-visible')

      addParticipant: ->
        Stadium.Responders.PeoplePickerInstance.addDelegate(this)
        Stadium.Instance.Hub.start-participant-pick!

  __makeCallDebug: (callType) !~>
      v = @_view
      cl = v.classList
      cl.add('calling')
      convo = @_conversation

      setTimeout(
        (!~>
          cl.remove("calling")
          cl.add("ringing")

          setTimeout(
            (!~>
              cl.remove('ringing')
              cl.add('in-call')


              setTimeout(
                (!~>
                  if @_participantPanels.length > 1
                    cl.add('is-group')

                    cl.add(callType)

                    @_changeFocusParent(@_callActions)

                    f = (p) !->
                      panel = @_createPanelForParticipant p
                      @_participantContainer.appendChild panel
                      @_calculateGroupStatus!

                    _.each f, convo.participants
                  ),
                500)
              ),
            2000)
          ),
        1200)

  _changeFocusParent: (newParent) !~>
    if newParent is @_focusParent
      return

    if @_focus?
      @_focus.classList.remove('focused')

    @_focusParent = newParent

    children = newParent.children
    l = children.length
    if l > 0
      @_focusIdx = 0
      @_focus = children[0]
      @_focus.classList.add('focused')

  _moveFocus: (delta) !~>
      focusParent = @_focusParent
      unless focusParent?
        return

      children = focusParent.children
      newFocusIdx = @_focusIdx + delta
      if newFocusIdx >= 0 and newFocusIdx < children.length
        @_focusIdx = newFocusIdx
        if @_focus
          @_focus.classList.remove('focused')

        @_focus = children[newFocusIdx]
        @_focus.classList.add('focused')

  _moveFocusVertical: (delta) !~>
    if @_focusParent is @_convoActions
      @_moveFocus delta
    else if @_focusParent is @_callActions
      # Can only move up from the call actions
      if delta < 0
        # Can only focus participants if there are multiple
        if @_participantPanels.length > 1
          @_changeFocusParent @_participantContainer
    else if @_focusParent is @_participantContainer
      if delta > 0
        @_changeFocusParent @_callActions

  _moveFocusHorizontal: (delta) !~>
    @_moveFocus delta

  _activateSelection: (e) !~>
    selection = e ? e.currentTarget : @_focus

    unless selection?
      return

    selectionType = selection.classList[0]
    switch selectionType
    | "action" =>
        cmdId = selection.getAttribute('data-cmd-id')
        if cmdId? and cmdId id @_commands
            @_commands[cmdId].call(@, @Conversation, @View)
    | "participant" =>
        # A participant in a call is selected
        @_toggleFullscreen selection
    | otherwise =>
        # nothing

    if e?
      e.preventDefault()
      e.stopPropagation()

  _createPanelForParticipant: (participant) ~>
    pTag = util.make 'div', 'participant'
    pTag.setAttribute 'data-id', participant.identifier

    avatar = util.make 'div', 'avatar', pTag
    if participant.avatar?
      avatar.style.backgroundImage = "url(#{participant.avatar})"

    name = util.make 'div', 'name', avatar, (participant.name || "")

    @_participantPanels = @_participantContainer.querySelectorAll('.participant')
    l = @_participantPanels.length
    cl = @_view.classList
    if l > 1
      if cl.contains('is-group') is false
        cl.add('is-group')

      if l > 2
        cl.add('three-group')
      else
        cl.remove('three-group')
    else
      cl.remove('is-group')

    pTag

  _getPanelForParticipant: (participants) ~>
    _.find ((panel) -> panel.getAttribute('data-id') is participant.identifier), @_participantPanels

  _participantsChanged: (participants) !~>
    #TODO(james): We just blow away the current roster and create a
    # whole new one. Should probably be smarter
    rm_fn = (panel) !~> @_participantContainer.removeChild(panel)
    _.each rm_fn, @_participantPanels

    add_fn = ((participant) !~> @_participantContainer.appendChild (@_createPanelForParticipant participant))
    _.each add_fn, participants

    @_calculateGroupStatus!

  _participantArrived: (participant) !~>
    @_participantContainer.appendChild (@_createPanelForParticipant participant)
    @_calculateGroupStatus!

  _participantLeft: (participant) !~>
    panel = @_getPanelForParticipant participant

    unless panel?
      console.warn "Could not find panel for participant #{participant.identifier}"
      return

    pcl = panel.classList
    v = @_view
    vcl = v.classList

    if pcl.contains 'with-video'
      @_dropVideoFromPanel panel


    pcl.add 'lost'

    set-timeout(
      (!~>
        @_participantContainer.remove-child panel
        @_calculateGroupStatus!
        ),
      1000)

  _gainedParticipantVideo: (participant) !~>
    panel = @_getPanelForParticipant participant

    unless panel
      console.warn "Could not get panel for: #{participant.identifier}"
      return


    videos = participant.remoteVideos
    unless videos?
      return

    videoTags = panel.getElementsByTagName 'video'
    @_addNewVideos panel, videoTags, videos

  _lostParticipantVideo: (participant) !~>
    panel = @_getPanelForParticipant participant
    unless panel?
      console.warn "Could not get panel for #{participant.identifier}"
      return

    @_dropVideoFromPanel panel

  _addNewVideos: (panel, videoTags, remoteVideos) ~>
    added-videos =
      (remoteVideos
      |> _.filter (.Playing is true)
      |> _.filter ((rv) -> not (_.find (.getAttribute 'data-vid-id' is rv.identifier))?)
      |> _.each (
        (rv) ->
          t = rv.VideoTag
          t.class-list.add 'video-feed'
          t.set-attribute 'data-vid-id', rv.identifier

          # videoTags is a live NodeList so length should update automatically
          panel.insertBefore(t, videoTags[0])
        )
      )

    if added-videos.length > 0
      if @_view.class-list.contains('has-video') is false
        @_view.class-list.add 'has-video'

      set-timeout(
        (->
          for v in added-videos
            v.VideoTag.play()
        ),
        0)

  _dropVideoFromPanel: (panel) !~>
    # TODO(james): this

  _calculateGroupStatus: !~>
    @_participantPanels = @_participantContainer.querySelectorAll('.participant')
    l = @_participantPanels.length
    cl = @_view.classList

    if l < 2
      cl.remove('is-group')
    else
      unless cl.contains('is-group')
        setTimeout (!-> cl.add 'is-group'), 200

      if l > 2
        unless cl.contains('three-group')
          setTimeout (!-> cl.add 'three-group'), 250
        else
          setTimeout (!~> cl.remove 'three-group'), 250
      else
        if cl.contains('three-group')
          setTimeout (!-> cl.remove 'three-group'), 200

  keyup: (e) !~>
    unless @View? and @Conversation?
      return

    switch e.stKey
    | "Up" => @_moveFocusVertical -1
    | "Down" => @_moveFocusVertical 1
    | "Left" => @_moveFocusHorizontal -1
    | "Right" => @_moveFocusHorizontal 1
    | "Enter", "Activate" => @_activateSelection!
    | "Back" =>
      if @View?
        cl = @View.class-list
        if cl.contains 'ims-visible'
          cl.remove 'ims-visible'
        else
          if cl.contains 'in-call'
            cl.remove 'in-call'

          Stadium.Instance.Hub.pop-out-conversation @View
    | "U+0056", "v" =>
      if @_conversation?
        @_conversation._playParticipantVideo!


Instance = new ConversationResponder!

module.exports =
  Instance: Instance
