MxWithFullscreen =
  toggleFullscreen: (panel) !~>
    if panel.classList.contains 'is-fullscreen'
      @_dropFullscreen panel
    else
      @_goFullscreen panel

  _goFullscreen: (toFullscreen) !~>
    panels = @_participantPanels
    vcl = @View.classList


    for panel in panels
      cl = panel.classList;
      if panel is toFullscreen
        if cl.contains('is-rostered')
          cl.remove('is-rostered');

        cl.add('is-fullscreen');
      else
        if cl.contains('is-fullscreen')
          cl.remove('is-fullscreen');

        cl.add('is-rostered');

    unless vcl.contains 'has-fullscreen'
      vcl.add 'has-fullscreen'

  _dropFullscreen: !~>
    @View.classList.remove 'has-fullscreen'

    for {classList} in @_participantPanels
      classList.remove 'is-fullscreen'
      classList.remove 'is-rostered'

module.exports =
  MxWithFullscreen: MxWithFullscreen