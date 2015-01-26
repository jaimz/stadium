require! {
  _ : 'prelude-ls'
  video: './video.js'
}

pid = 1

# TODO(james): We need to separate the notion of person and participant
# a 'participant' is an entity in a conversation and thus has a video and
# message stream.
class Person
  (name = 'anon') ->
    Object.defineProperties @,
      identifier:
        value: "person-#{(pid++)}"
        enumerable: true
        writable: false

      name:
        value: name,
        enumerable: true
        writable: true

      avatar:
        value: "./img/blank_avatar.png"
        enumerable: true,
        writable: true

      remoteVideos:
        value: [ new video.RemoteVideo() ]

  playVideo: !~>
    v = _.find ((v) -> v.Playing is false), @remoteVideos
    unless v?
      v = new video.RemoteVideo()
      @remoteVideos.push v

    v.Playing = true

module.exports =
  Person: Person