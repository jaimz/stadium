// Generated by LiveScript 1.2.0
(function(){
  var document, Chain;
  document = window.document;
  Chain = (function(){
    Chain.displayName = 'Chain';
    var prototype = Chain.prototype, constructor = Chain;
    function Chain(){
      this.lostFocus = bind$(this, 'lostFocus', prototype);
      this.gotFocus = bind$(this, 'gotFocus', prototype);
      this.pop = bind$(this, 'pop', prototype);
      this.push = bind$(this, 'push', prototype);
      this.keyIntercept = bind$(this, 'keyIntercept', prototype);
      this.dispatch = bind$(this, 'dispatch', prototype);
      this.chain = [];
      this.keyEventNames = ['keydown', 'keyup'];
      this.eventNames = ['mousedown', 'mouseup', 'mouseup'];
      this.listen(this.keyEventNames, this.keyIntercept);
      window.addEventListener('focusin', this.gotFocus);
      window.addEventListener('focusout', this.lostFocus);
      document.addEventListener('contextmenu', this.dispatch);
    }
    prototype.listen = function(names, dispatch){
      var i$, len$, n;
      names == null && (names = this.eventNames);
      dispatch == null && (dispatch = this.dispatch);
      for (i$ = 0, len$ = names.length; i$ < len$; ++i$) {
        n = names[i$];
        document.addEventListener(n, dispatch);
      }
    };
    prototype.dontListen = function(names, dispatch){
      var i$, len$, n;
      names == null && (names = this.eventNames);
      dispatch == null && (dispatch = this.dispatch);
      for (i$ = 0, len$ = names.length; i$ < len$; ++i$) {
        n = names[i$];
        document.removeEventListener(n, dispatch);
      }
    };
    prototype.dispatch = function(e, evName){
      var i$, ref$, len$, responder;
      evName == null && (evName = e.type);
      for (i$ = 0, len$ = (ref$ = this.chain).length; i$ < len$; ++i$) {
        responder = ref$[i$];
        if (_.isType('Function', responder[evName])) {
          if (responder[evName].call(responder, e) === true) {
            e.preventDefault();
            e.stopPropagation();
            break;
          }
        }
      }
    };
    prototype.keyIntercept = function(e){
      var k;
      k = e.keyIdentifier || e.key;
      switch (k) {
      case "U+0041":
        e.skKey = "Activate";
        break;
      case "U+0042":
        e.skKey = "Back";
        break;
      default:
        e.skKey = k;
      }
      this.dispatch(e);
    };
    prototype.push = function(responder){
      if (responder == null) {
        return;
      }
      if (this.chain[0] !== responder) {
        if (_.isType('Function', responder.willBecomeFirstResponder)) {
          responder.willBecomeFirstResponder.call(responder);
        }
        this.chain.unshift(responder);
      }
    };
    prototype.pop = function(responder){
      responder == null && (responder = null);
      if (this.chain.length > 0) {
        if (responder == null) {
          responder = this.chain[0];
        }
        if (this.chain[0] === responder) {
          if (_.isType('Function', responder.willLoseFirstResponder)) {
            responder.willLoseFirstResponder.call(responder);
          }
          this.chain = this.chain.splice(1);
        }
        if (this.chain.length > 0) {
          if (_.isType('Function', this.chain[0].willBecomeFirstResponder)) {
            this.chain[0].willBecomeFirstResponder.call(this.chain[0]);
          }
        }
      }
    };
    prototype.gotFocus = function(e){
      if (e.srcElement.tagName === 'INPUT' || e.srcElement.tagName === 'BUTTON') {
        this.deInitListeners(this.keyEventNames, this.keyIntercept);
      }
    };
    prototype.lostFocus = function(e){
      if (e.srcElement.tagName === 'INPUT' || e.srcElement.tagName === 'BUTTON') {
        this.initListeners(this.keyEventNames, this.keyIntercept);
      }
    };
    return Chain;
  }());
  module.exports = {
    Chain: Chain
  };
  function bind$(obj, key, target){
    return function(){ return (target || obj)[key].apply(obj, arguments) };
  }
}).call(this);