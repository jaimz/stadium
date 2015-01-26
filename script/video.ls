_vid = 0

_create-video-tag = ->
  t = document.createElement 'video'
  t.setAttribute 'src', './videos/big_buck_bunny.webm'

  t

class RemoteVideo
  ->
    @_starting = false
    @_playing = false
    @_videoTag = null
    @_identifier = null

    Object.defineProperties @,
      Playing:
        value: false
        writable: true
        enumerable: true

      Starting:
        value: false
        writable: true
        enumerable: true

      VideoTag:
        get: ->
          unless @_videoTag?
            @_videoTag = _create-video-tag!
            @_identifier = @_videoTag.src

          @_videoTag

        set: (v) !->
          @_videoTag = v
          @_identifier = @_videoTag.src

        enumerable: true

      identifier:
        value: "foo"
        enumerable: true
        writable: true

module.exports =
  RemoteVideo: RemoteVideo