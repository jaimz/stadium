
document = window.document

# A responder chain manages a stack of objects interested in
# responding to events
class Chain
  ->
    @chain = []

    @key-event-names = [
      'keydown'
      'keyup'
    ]

    @event-names = [
      'mousedown'
      'mouseup'
      'mouseup'
    ]

    @listen @key-event-names, @key-intercept

    window.add-event-listener 'focusin', @got-focus
    window.add-event-listener 'focusout', @lost-focus
    document.add-event-listener 'contextmenu', @dispatch


  listen: (names = @event-names, dispatch = @dispatch) !->
    for n in names
      document.add-event-listener n, dispatch


  dont-listen: (names = @event-names, dispatch = @dispatch) !->
    for n in names
      document.remove-event-listener n, dispatch



  # Dispatch an event down the chain
  dispatch: (e, ev-name=e.type) !~>
    for responder in @chain
      if _.is-type 'Function' responder[ev-name]
        if responder[ev-name].call(responder, e) is true
          e.preventDefault()
          e.stopPropagation()
          break



  key-intercept: (e) !~>
    k = e.keyIdentifier || e.key
    switch k
    | "U+0041" =>
      # 'A'
      e.skKey = "Activate"
    | "U+0042" =>
      # 'B'
      e.skKey = "Back"
    | _ =>
      e.skKey = k

    @dispatch e


    # Push a responder onto the top of the chain
  push: (responder) !~>
    unless responder?
      return

    if @chain[0] isnt responder
      if _.is-type 'Function' responder.will-become-first-responder
        responder.will-become-first-responder.call(responder)

      # We push something onto the front of an array using the
      # wonderfully logical 'unshift'
      @chain.unshift responder

  # Remove the topmost responder from the chain
  pop: (responder = null) !~>
    if @chain.length > 0
      if not responder?
        responder = @chain[0]

      if @chain[0] is responder
        if _.is-type 'Function' responder.will-lose-first-responder
          responder.will-lose-first-responder.call(responder)

        @chain = @chain.splice(1);

      # The next responder down the chain now becomes the first responder
      if @chain.length > 0
        if _.is-type 'Function' @chain[0].will-become-first-responder
          @chain[0].will-become-first-responder.call(@chain[0])


  # NOTE(james): Can't *quite* remember what these are for
  got-focus: (e) !~>
    if e.srcElement.tagName is 'INPUT' or e.srcElement.tagName is 'BUTTON'
      @deInitListeners(@key-event-names, @keyIntercept)

  lost-focus: (e) !~>
    if e.srcElement.tagName is 'INPUT' or e.srcElement.tagName is 'BUTTON'
      @initListeners(@key-event-names, @keyIntercept)


module.exports =
  Chain: Chain