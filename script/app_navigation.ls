require! {
  util: './util.js'
}


class AppNavResponder
  (view = "app_navigation") ->
    @_view = null
    Object.defineProperties @,
      View:
        get: -> @_view
        set: (v) ->
          if @_view?
            @losing-view!

          @_view = util.get-el v

          @init-view!

    @_cmds =
      'toggleAppMenu': @toggle-app-menu

    @View = view

  init-view: !->
    unless @_view?
      return

    @_view.add-event-listener 'click', @click

  losing-view: !->
    @_view.remove-event-listener 'click' , @click

  click: (e) !~>
    src = e.target
    cmd = src.get-attribute 'data-nav-cmd'
    unless cmd?
      console.warn "No nav cmd on nav event source"
      return

    if cmd of @_cmds
      @_cmds[cmd].call!



  toggle-app-menu: !~>
    Stadium.ToggleAppMenu!


module.exports =
  Responder: AppNavResponder