require! {
  Delegation: './delegation.js'
  Responder: './responder.js'
  Switch: './switch.js'
  util: './util.js'
  DebugConvos: './debug_convos.js'
  Hub: './hub.js'
  AppNavigation: './app_navigation.js'
  AppMenu: './app_menu.js'
}

# TODO(james): Awkward that this is here. Find a way of putting this
# in app_menu.ls (it's here because we only want the app object to add
# listeners to 'window')
__block-arrows = (e) !->
  switch e.keyCode
  | 40, 39, 38, 37 =>
    e.preventDefault!


document = window.document

# Main application object
class Stadium implements Delegation.WithDelegation
  # Create global instance. Usually bound to some browser event s.a. DOMContentLoaded
  @CreateInstance = ->
    # Hang a global instance off window
    window.Stadium = new Stadium!
    window.Stadium.init!

    set-timeout(
      (->
        window.Stadium.start!)
      ,200)


  # Constructor
  (view = 'app') ->
    @_el = util.get-el view
    unless @_el?
      throw new Error('Could not find application view')

    @_hubScroller = @_el.querySelector('.hub_scroller')
    @_contact-switch = new Switch.Switch('contacts')

    @_appNavResponder = new AppNavigation.Responder()

    @ResponderChain = new Responder.Chain()
    @HubRepository = new DebugConvos.Repository()
    @Hub = new Hub.Responder()
    @AppMenuResponder = new AppMenu.Responder(document.getElementById('AppMenu'), @Hub)


  # A keyup event has not been handled by anything else
  # on the responder chain
  keyup: (e) !~>
    k = e.keyIdentifier || e.key

    switch k
    | "U+0020", " " =>
      # have space trigger the app menu
      @contextmenu e
      true
    | _ =>
      false

  # A context menu event has not been handled by anything else on the responder chain
  contextmenu: (e) !~>
    cl = @_el.classList
    unless cl.contains('app-menu-active')
      @ShowAppMenu!
    else
      @HideAppMenu!

    true

  ShowAppMenu: !~>
    cl = @_el.class-list

    cl.add 'app-menu-visible'

    set-timeout(
      (->
        cl.add 'app-menu-will-open'

        set-timeout(
          (->
            cl.add 'app-menu-visible')
            cl.remove 'app-menu-will-open'
          ,100)
        )
      ,100)

    responder = @AppMenuResponder
    @ResponderChain.push @AppMenuResponder

    window.add-event-listener 'keydown', __block-arrows
    return



    set-timeout(
      (->
        cl.add 'app-menu-preprep'

        set-timeout(
          (->
            cl.add 'app-menu-prep'

            set-timeout(
              (->
                cl.add 'app-menu-active'
                responder._calculateHubScroll!
              ),
              500)
          ),
          30)
        ),
        30
      )


  HideAppMenu: (new-location) !~>
    cl = @_el.class-list

    set-timeout(
      (->
        cl.add 'app-menu-will-close'

        set-timeout(
          (->
            cl.remove 'app-menu-visible'

            set-timeout(
              (->
               cl.remove 'app-menu-will-close')
              ,50)
          ),
          50)
      ),
      100)

    @ResponderChain.pop!
    return

    cl.remove 'app-menu-visible'
    return

    cl.remove 'app-menu-preprep'
    cl.remove 'app-menu-prep'
    cl.remove 'app-menu-active'

    scrollerStyle = @_hubScroller.style
    activeCount = @Hub.ActiveCount

    set-timeout(
      (->
        scrollerStyle.overflow = 'hidden'),
      30)



    window.remove-event-listener 'keydown', __block-arrows

    if new-location?
      @Hub.GoTo new-location

  ToggleAppMenu: !~>
    if @_el.class-list.contains 'app-menu-visible'
      @HideAppMenu!
    else
      @ShowAppMenu!

  init: !~>
    @Hub.init!

  start: !~>
    @Hub.start!


document.add-event-listener 'DOMContentLoaded' Stadium.CreateInstance