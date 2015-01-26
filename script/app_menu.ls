require! {
  util: './util.js'
}

class Responder
  (@View, @Hub) ->
    @_hubView = @Hub.View
    @_hubEL = document.getElementById 'hub'
    @_generateAllConvoItems!

    @_items = @View.getElementsByClassName 'app-menu-item'
    @_focus = @View.querySelector '.focused'

    @_focusIdx = util.index-of-element @_focus
    @_focusParent = @_focus ? @_focus.parentElement : null

    @_active = false
    @_hubOffset = 0



  willBecomeFirstResponder: !~>
    @_active = true

  willLoseFirstResponder: !~>
    @_active = false

    s = Stadium.Hub.View.style;
    s.removeProperty 'transform'
    s.removeProperty '-webkit-transform'

  _generateAllConvoItems: !~>
    for c in @Hub.ActiveConversations
      @_createConvoItem c

  _createConvoItem: (convo) !~>
    item = util.make 'div', [ 'app-menu-item', 'location' ], @View, convo.name
    item.set-attribute "data-convo-id", convo.identity
    @_changeFocus item

  _removeConvoItem: (convo) !~>
      item = @View.querySelector(".app-menu-item[data-convo-id=#{convo.identity}]")
      if item?
        if item.classList.contains('focused')
          @_changeFocus @View.children[2]

        @View.removeChild(item)

  _changeFocus: !~>
    if item.parentElement isnt @_focusParent
      @_focusParent = item.parentElement

    if @_focus
      @_focus.classList.remove 'focused'

    @_focusIdx = SkIndexOfElement(item)
    @_focus = item
    @_focus.classList.add('focused')

    @_focusChange(@_focus)

  _moveFocus: !~>
    focusParent = @_focusParent;
    unless focusParent
      return

    children = focusParent.children
    newFocusIdx = @_focusIdx + delta
    if newFocusIdx >= 0 && newFocusIdx < children.length
      @_focusIdx = newFocusIdx
      if (@_focus)
        @_focus.classList.remove('focused')

      @_focus = children[newFocusIdx]
      @_focus.classList.add('focused')

      @_focusChange(@_focus)


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


  _moveFocusVertical: (delta) !~>
    if @_focusParent === @_view || @_focusParent === @_hubEl
      @_moveFocus(delta)
    else
      console.warn("Don't know how to move focus for: #{@_focusParent}")


  _focusChange: (newFocus) !~>
    if newFocus.classList.contains('location') is false
      return

    @_calculateHubScroll!


  _calculateHubScroll: !~>
    # Don't have locations for settings or add participant yet
    locIdx = @_focusIdx - 2
    offs = 700 * locIdx

    if locIdx > 0
      offs += 20


    @hubOffset = 0 - offs

    if @_active
      s = Stadium.Hub.View.style
      if @hubOffset isnt 0
        s.webkitTransform = [ 'transdisalateY(', @hubOffset, 'px)' ].join('')
        s.transform = [ 'translateY(', @hubOffset, 'px)' ].join('')
      else
        s.removeProperty('transform')
        s.removeProperty('-webkit-transform')

  _activateSelection: !~>
    if this._focus.classList.contains('location')
      location = this._focus.getAttribute('data-convo-id')
      Stadium.HideAppMenu(location)


  keyup: !~>
    result = true

    switch e.skKey
    | "Up" =>
      @_moveFocusVertical2(-1)
    | "Down" =>
      @_moveFocusVertical2(1)
#    | "Left" =>
#      @_moveFocusHorizontal(-1)
#    | "Right" =>
#      @_moveFocusHorizontal(1)
    | "Enter", "Activate" =>
      @_activateSelection()
    | _ =>
      result = false

    result

module.exports =
  Responder: Responder

