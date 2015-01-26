require! {
  util: './util.js'
  delegation: './delegation.js'
}

class Responder implements delegation.WithDelegation
  (peopleEl) ->
    # TODO(james)
    @_el = util.get-el peopleEl, 'conversations'

    @_focus = null
    @_focusIdx = null

  willBecomeFirstResponder: !~>
    @_focus = @_el.querySelector '.focused'

    if @_focus
      @_focusIdx = util.index-of-element @_focus
    else
      children = @_el.children
      if children.length > 0
        @_focusIdx = 0
        @_focus = children[@_focusIdx]
        children[@_focusIdx].classList.add("focused")

  _moveFocus: (delta) !~>
    children = @_el.children
    newFocusIdx = @_focusIdx + delta
    if newFocusIdx >= 0 and newFocusIdx < children.length
      @_focusIdx = newFocusIdx
      if (@_focus)
        @_focus.classList.remove('focused')

      @_focus = children[newFocusIdx]
      @_focus.classList.add('focused')


  _moveFocusVertical: @_moveFocus


  _moveFocusHorizontal: (delta) ~>
    @_moveFocus (delta * 2) # '2' is the column height

  _activateSelection: !~>
    l = @_delegates.length
    unless l > 0
      return

    convoId = @_focus.getAttribute('data-convo-id')
    unless convoId?
      console.warn('No convo ID when picking person')
      return


    convo = Stadium.HubRepository.FindConvo(convoId)
    unless convo?
      console.warn('Could not find convo when picking person: ' + convoId)
      return


    unless convo.participants.length > 0
      console.warn('Empty conversation when picking participant?' + convo)
      return


    person = convo.participants[0]

    @call-delegate 'personPicked', person

  _cancelPick: !~>
    # TODO(james): Too many levels to get to end-participant-pick
    Stadium.Hub.end-participant-pick!
    @call-delegate 'personPickCancelled', null

  keyup: (e) ~>
    result = true

    switch e.skKey
    | "Up" =>
      @_moveFocusVertical(-1);
    | "Down" =>
      @_moveFocusVertical(1);
    | "Left" =>
      @_moveFocusHorizontal(-1);
    | "Right" =>
      @_moveFocusHorizontal(1);
    | "Enter" =>
    | "Activate" =>
      @_activateSelection();
    | "Back" =>
      @_cancelPick();
    | _ =>
      result = false;

    result;


module.exports =
  Responder: Responder
  ResponderInstance: new Responder()
