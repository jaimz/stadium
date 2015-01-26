// Generated by LiveScript 1.2.0
(function(){
  var _, MxWithEvents, this$ = this;
  _ = require('prelude-ls');
  MxWithEvents = {
    addEventListener: function(eventName, listener){
      var listenerTable, listeners;
      if (!_.isType('Function', listener)) {
        console.warn("Non-function passed to add-event-listener");
        console.warn(listener);
        return;
      }
      listenerTable = this$.listenerTable;
      if (listenerTable == null) {
        listenerTable = {};
        this$.listenerTable = listenerTable;
      }
      if (!(eventName in listenerTable)) {
        listeners = [];
        listenerTable[eventName] = listeners;
      } else {
        listeners = listenerTable[eventName];
      }
      listeners.push(listener);
    },
    removeEventListener: function(eventName, listener){
      var listeners, idx;
      if (!(this$.listenerTable && eventName in this$.listenerTable)) {
        return;
      }
      listeners = this$.listenerTable[eventName];
      idx = _.elemIdx(listener, listeners);
      if (idx != null) {
        listeners.splice(idx, 1);
      }
    },
    fireEvent: function(eventName, arg){
      var listeners;
      if (!(this$.listenerTable != null && eventName in this$.listenerTable)) {
        return;
      }
      listeners = this$.listenerTable[eventName];
      return _.each(function(it){
        return it.call(this, arg);
      }, listeners);
    }
  };
  module.exports = {
    MxWithEvents: MxWithEvents
  };
}).call(this);
