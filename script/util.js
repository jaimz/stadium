// Generated by LiveScript 1.2.0
(function(){
  var document, make, getEl, indexOfElement, insertionIndexFor, toString$ = {}.toString;
  document = window.document;
  make = function(tagName, className, parent, content){
    var e, i$, len$, cl;
    tagName == null && (tagName = 'div');
    className == null && (className = null);
    parent == null && (parent = null);
    content == null && (content = null);
    e = document.createElement(tagName);
    switch (toString$.call(className).slice(8, -1)) {
    case 'String':
      e.classList.add(className);
      break;
    case 'Array':
      for (i$ = 0, len$ = className.length; i$ < len$; ++i$) {
        cl = className[i$];
        e.classList.add(cl);
      }
    }
    switch (toString$.call(content).slice(8, -1)) {
    case 'String':
      e.appendChild(document.createTextNode(content));
      break;
    default:
      if (content instanceof window.Node) {
        e.appendChild(content);
      }
    }
    if (parent != null) {
      parent.appendChild(e);
    }
    return e;
  };
  getEl = function(el, dflt, root){
    el == null && (el = null);
    dflt == null && (dflt = null);
    root == null && (root = document);
    if (el == null) {
      if (dflt != null) {
        getEl(dflt, null, root);
      } else {
        return null;
      }
    }
    if (el instanceof window.Element) {
      return el;
    } else {
      switch (toString$.call(el).slice(8, -1)) {
      case 'String':
        if (el[0] === '.' || el[0] === '#') {
          return root.querySelector(el);
        } else {
          return root.getElementById(el);
        }
        break;
      case 'DOMElement':
        return el;
      default:
        if (dflt !== null) {
          return getEl(dflt, null, root);
        } else {
          console.log(toString$.call(el).slice(8, -1));
          return null;
        }
      }
    }
  };
  indexOfElement = function(element){
    var parent, children;
    if (element == null) {
      return -1;
    }
    parent = element.parentElement;
    if (parent == null) {
      return -1;
    }
    children = parent.children;
    return Array.prototype.indexOf.call(children, element);
  };
  insertionIndexFor = function(item, collection, comparer){
    var l, idx;
    if (!(item != null && collection != null && comparer != null)) {
      return -1;
    }
    l = collection.length;
    idx = 0;
    while (idx < l && comparer(item, collection[idx]) <= 0) {
      idx += 1;
    }
    return idx;
  };
  module.exports = {
    make: make,
    getEl: getEl,
    indexOfElement: indexOfElement
  };
}).call(this);
