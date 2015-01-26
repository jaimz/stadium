require! {
  util: './util.js'
  events: './events.js'
  ConvoResponder: './convo_responder.js'
  PeoplePicker: './people_picker.js'
}

kHubId = '#hub'

# TODO(james): should be in conversation.ls?
kConvoIdAtt = 'data-convo-id'

convo-holder-z = 10


__makeConvoEl = (convo, aux-classes = [ 'card', 'minimised' ]) ->
  unless convo?
    return null

  mk = util.make

  convo-el = mk 'div', 'conversation'
  for c in aux-classes
    convo-el.class-list.add c

  convo-el.set-attribute 'data-convo-id', convo.identity

  mk 'div', 'avatar', convo-el
  mk 'div', [ 'status_pip', 'online' ], convo-el

  card-info = mk 'div', 'card_info', convo-el
  mk 'div', 'convo_name', card-info, convo.name
  mk 'div', 'last_message', card-info, convo.LastMessage

  convo-actions = mk 'div', 'convo_actions', convo-el
  a = mk 'div', 'action', convo-actions, 'call'
  a.set-attribute 'data-cmd-id', 'makeVideoCall'
  a = mk 'div', 'action', convo-actions, 'voice call'
  a.set-attribute 'data-cmd-id', 'makeAudioCall'
  a = mk 'div', 'action', convo-actions, 'add people'
  a.set-attribute 'data-cmd-id', 'addParticipant'

  history = mk 'div', 'history', convo-el
  mk 'div', 'messages', history
  msg-ed = mk 'div', 'message_editor', history
  msg-input = mk 'input', 'message_input', msg-ed
  msg-input.set-attribute 'type', 'text'

  call-actions = mk 'div', 'call_actions', convo-el
  a = mk 'div', 'action', call-actions, 'add'
  a.set-attribute 'data-cmd-id', 'addParticipant'
  a = mk 'div', 'action', call-actions, 'im'
  a.set-attribute 'data-cmd-id', 'toggleIMs'
  a = mk 'div', 'action', call-actions, 'end'
  a.set-attribute 'data-cmd-id', 'endCall'

  convo-el

__populate-convo-panel = (panel, convos) ->
  for convo in convos
    e = __makeConvoEl convo
    if e?
      panel.append-child e





class Responder implements events.MxWithEvents
  (el = kHubId) !->
    @_el = util.get-el el

    @_dragX = 0
    @_dragY = 0
    @_holdTimeout = null

    @_memoBounds = null
    @_memoContainer = null
    @_memoSibling = null

    @_focusParent = null
    @_focusIdx = -1

    @set-view el

    @_convoHolderStack = []

    @_holdTimeout = null
    @_dragging = false
    @_dragX = 0
    @_dragY = 0
    @_dragOriginX = 0
    @_dragOriginY = 0


    Object.defineProperties @,
      ActiveCount:
        get: -> @_convoHolderStack.length
        enumerable: true

      ActiveConversations:
        get: -> @_convoHolderStack
        enumerable: true

      View:
        value: @_el
        writable: false
        enumerable: true


  set-view: (el) !~>
    if @View?
      @dont-listen!

    @View = util.get-el(el)

    if @View?
      @listen!


  _moveFocus: (delta) !~>
    focusParent = @_focusParent
    if (!focusParent)
      return

    children = focusParent.children
    newFocusIdx = @_focusIdx + delta
    if newFocusIdx >= 0 and newFocusIdx < children.length
      @_focusIdx = newFocusIdx
      if @_focus
        @_focus.classList.remove 'focused'

      @_focus = children[newFocusIdx]
      @_focus.classList.add 'focused'

  _moveFocusVertical: (delta) !~>
    if @_focusParent is @_recents or @_focusParent is @_favourites
      @_moveFocus delta
    else
      console.warn "Dont know how to move focus for: #{this._focusParent}"


  _moveFocusHorizontal: (delta) !~>
    if @_focusParent is @_recents
      @_changeFocusParent @_favourites
    else if @_focusParent is @_favourites
      if (@_focusIdx + delta) < 0
        @_changeFocusParent @_recents
      else
        # '2' === column height
        @_moveFocus delta * 2
    else
      console.warn "Dont know how to move focus for: #{@_focusParent}"


  _activateSelection: (e) !~>
    focus = @_focus
    unless focus?
      return

    if focus.classList.contains 'conversation'
      @_popInConversation(focus)


  keyup: (e) !~>
    result = true

    switch e.skKey
    | "Up" =>
      @_moveFocusVertical(-1)
    | "Down" =>
      @_moveFocusVertical(1)
    | "Left" =>
      @_moveFocusHorizontal(-1)
    | "Right" =>
      @_moveFocusHorizontal(1)
    | "Enter", "Activate" =>
      @_activateSelection()
    | _ =>
      result = false

    result


  init: !~>
    @_focus = @View.querySelector('.focused')
    @_focusIdx = util.index-of-element(@_focus)
    @_focusParent = @_recents

  populate-view: !~>
    unless @View?
      console.warn "Hub did not have a view when asked to init"
      return

    # meh
    @Recents = document.get-element-by-id 'recents'
    @Favourites = document.get-element-by-id 'favourites'
    @Contacts = document.get-element-by-id 'all_contacts'

    hubRepo = Stadium.HubRepository

    card-classes = [ 'card', 'minimised' ]

    if @Recents?
      __populate-convo-panel @Recents, hubRepo.Recents

    if @Favourites?
      __populate-convo-panel @Favourites, hubRepo.Favourites

    if @Contacts?
      __populate-convo-panel @Contacts, hubRepo.Contacts


    # TODO(james): this seems weird, moveFocus(1)?
    @_moveFocus(1)


  start: !~>
    unless @View?
      console.warn "Attempt to start hub without a view"
      return

    @populate-view!

    @View.class-list.remove 'starting'

  # TODO(James): not the right class for *-the participant-pick
  # methods...
  start-participant-pick: !~>
    @_el.class-list.add 'picking-participant'
    @ResponderChain.push PeoplePicker.ResponderInstance

  end-participant-pick: !~>
    @_el.class-list.remove 'picking-participant'
    @ResponderChain.pop PeoplePicker.ResponderInstance

  go-to: (location) !~>
    convos = @_convoHolderStack
    view = null

    for convo-panel in convos
      cl = convo-panel.class-list
      id = convo-panel.get-attribute 'data-convo-id'

      unless id is location
        cl.add 'aside'
      else
        cl.remove 'aside'
        view = convo-panel

    if location is 'home'
      @_favourites.class-list.remove 'is-people-picker'

      # Pop the convo responder if it is top of the responder chain
      Stadium.ResponderChain.pop ConvoResponder.Instance
    else
      @_favourites.class-list.add 'is-people-picker'

      convo = Stadium.HubRepository.FindConvo location
      if convo?
        ConvoResponder.Instance.Conversation = convo
        ConvoResponder.Instance.View = view.children[0]
        Stadium.ResponderChain.push ConvoResponder.Instance
      else
        console.warn "Could not find conversation: #{location}"

  will-become-first-responder: !~>
    if @_focusParent is null
      @_changeFocusParent @_recent


  listen: !~>
    unless @View?
      return

    @View.add-event-listener 'mousedown', @_mouse-down
    @View.add-event-listener 'mouseup', @_mouse-up
    @View.add-event-listener 'mousemove', @_mouse-move
    @View.add-event-listener 'click', @_mouse-click

  dont-listen: !~>
    unless @View?
      return

    @View.remove-event-listener 'mousedown', @_mouse-down
    @View.remove-event-listener 'mouseup', @_mouse-up
    @View.remove-event-listener 'mousemove', @_mouse-move
    @View.remove-event-listener 'click', @_mouse-click



  _convo-for-event: (e) !~>
    el = e.target

    until el is null or el.class-list.contains 'conversation'
      el = el.parent-element

    el

  _mouse-click: (e) !~>
    convo =  @_convo-for-event e
    if convo?
      if convo.class-list.contains 'minimised'
        @_pop-in-conversation convo
      else
        @_pop-out-conversation convo

  _mouse-down: (e) !~>
    @_dragX = e.clientX
    @_dragY = e.clientY

    @_holdTimeout = set-timeout (~> @_held(e)), 200

  _mouse_up: (e) !~>
    if @_dragging?
      d = @_dragging
      s = @_drag-holder.style
      ds = d.style

      cl = d.class-list

      if cl.contains 'maximised'
        # TODO(james): proper drop targets
        if e.clientY <= window.innerHeight / 2
          @_pop-in-conversation d
        else
          c = @_memo-containe
          sib = @_memo-sibling

          c.insert-before s, sib

          cl.remove 'maximised'
          cl.add 'minimised'

      else
        ds.remove-property('width')
        ds.remove-property('height')
        ds.remove-property('top')
        ds.remove-property('left')

        s.remove-property('transform')
        s.remove-property('-webkit-transform')

        @_pop-in-conversation(d)

      cl.remove 'is-dragged'

      @_dragging = null
      @View.class-list.remove 'dragging'

    clear-timeout @_holdTimeout if @_holdTimeout?

  _drag-move: (e) !~>
    d = @_dragging
    unless d?
      return

    x = e.clientX
    y = e.clientY

    deltaX = @_drag-origin-x + (x - @_dragX)
    deltaY = @_drag-origin-y + (y - @_dragY)

    style = @_dragHolder.style
    transform = [ 'translateX(', deltaX, 'px) translateY(', deltaY, 'px)' ].join('')
    style.transform = transform
    style.webkitTransform = transform

  _held: (e) !~>
    convo = @_convo-for-event e
    unless convo?
      return

    maximised = convo.class-list.contains('maximised')
    if not maximised
      @_setup-minimised-drag e, convo

    @_drag-holder.append-child convo

    if maximised
      s = @_drag-holder.style

      @_drag-origin-x = (0 - (window.innerWidth / 2)) + e.clientX
      @_drag-origin-y = (0 - (window.innerHeight / 2)) + e.clientY


      transform = [ 'translateX(', this._drag-origin-x, 'px) translateY(', @_drag-origin-y, 'px)' ].join('')
      s.transform = transform
      s.webkitTransform = transform

      @View.removeChild(this._convoHolderStack.pop())

    @View.class-list.add 'dragging'
    convo.class-list.add 'is-dragged'

    @_dragging = convo

  _setup-minimised-drag: (e, convo) !~>
    bounds = convo.getBoundingClientRect()
    @_memoBounds = bounds
    @_memoContainer = convo.parentElement
    @_memoSibling = convo.nextSibling

    topDelta = 0 - bounds.top
    leftDelta = 0 - bounds.left

    style = convo.style
    style.top = bounds.top + 'px'
    style.left = bounds.left + 'px'
    style.width = bounds.width + 'px'
    style.height = bounds.height + 'px'

  _pop-in-conversation: (conversation) !~>
    unless @_memoContainer?
      @_memoContainer = conversation.parent-element
      @_memoSibling = conversation.nextElementSibling

    convo-holder = util.make 'section', 'convo_holder'
    convo-holder.class-list.add 'hidden'
    convo-holder.style.zIndex = convo-holder-z++

    @_lost-focused-element!

    convo-holder.append-child conversation
    conversation.class-list.remove 'minimised'
    conversation.class-list.add 'maximised'

    @_convoHolderStack.push convo-holder

    @View.append-child convo-holder


    # Delay this to allow the animation to complete
    # TODO(james): Only a perf problem on old IE - do we
    # still need this?
    set-timeout(
      (!~>
        convo-holder.class-list.remove 'hidden'
        ConvoResponder.Instance.SetView = conversation

        convo-id = conversation.getAttribute kConvoIdAtt
        if convoId?
          convo = Stadium.HubRepository.FindConvo convoId
          if convo?
            convo-holder.set-attribute 'data-convo-id', convo.identity

            ConvoResponder.Instance.SetConversation convo
            Stadium.ResponderChain.push ConvoResponder.Instance

            @_fireEvent 'active_conversation_added', convo

            convo.History.Load!
          else
            console.warn "Can't find conversation #{convoId}"
        else
          console.warn "Element does not have conversation ID"
        ),
      100)

  _pop-out-conversation: !~>
    Stadium.ResponderChain.pop ConvoResponder.Instance
    convo-holder-stack = @_convoHolderStack

    convoHolder = convo-holder-stack.pop!
    conversation = convoHolder.children[0]

    convoHolder.classList.add('hidden')

    conversation.classList.remove('maximised')
    conversation.classList.add('minimised')
    c = @_memoContainer
    s = @_memoSibling
    hubEl = @_el

    set-timeout(
      (!~>
        c.insertBefore(conversation, s)
        hubEl.removeChild(convoHolder)

        if convoHolderStack.length is 0
          favourites.classList.remove('is-people-picker')

        @_memoContainer = null
        @_memoSibling = null

        convoId = conversation.getAttribute kConvoIdAtt
        if convoId?
          convo = Stadium.HubRepository.FindConvo convoId
          if convo?
            @_fireEvent 'active_conversation_removed', convo
          else
            console.warn "Could not find convo #{convoId}"
        else
          console.warn 'Could not get convo ID from element'
      ),
      300
    )


module.exports =
  Responder: Responder
