// Generated by LiveScript 1.2.0
(function(){
  var _, video, pid, Person;
  _ = require('prelude-ls');
  video = require('./video.js');
  pid = 1;
  Person = (function(){
    Person.displayName = 'Person';
    var prototype = Person.prototype, constructor = Person;
    function Person(name){
      name == null && (name = 'anon');
      this.playVideo = bind$(this, 'playVideo', prototype);
      Object.defineProperties(this, {
        identifier: {
          value: "person-" + (pid++),
          enumerable: true,
          writable: false
        },
        name: {
          value: name,
          enumerable: true,
          writable: true
        },
        avatar: {
          value: "./img/blank_avatar.png",
          enumerable: true,
          writable: true
        },
        remoteVideos: {
          value: [new video.RemoteVideo()]
        }
      });
    }
    prototype.playVideo = function(){
      var v;
      v = _.find(function(v){
        return v.Playing === false;
      }, this.remoteVideos);
      if (v == null) {
        v = new video.RemoteVideo();
        this.remoteVideos.push(v);
      }
      v.Playing = true;
    };
    return Person;
  }());
  module.exports = {
    Person: Person
  };
  function bind$(obj, key, target){
    return function(){ return (target || obj)[key].apply(obj, arguments) };
  }
}).call(this);
