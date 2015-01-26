document = window.document

# Make a DOM element. Parameters:
#    tag-name: the type of element to create
#    class-name: a class, or array of classes, to apply to the
#               element
#    content: (optional) string content to create under the
#             element
#    parent:  (optional) the node to parent the new node
#
# E.g. make('div', [ 'menu_item', 'focused' ], 'Preferences')
make = (tag-name = 'div', class-name = null, parent = null, content = null) ->
  e = document.create-element tag-name

  switch typeof! class-name
  | 'String' =>
    e.classList.add(class-name)
  | 'Array' =>
    for cl in class-name
      e.classList.add(cl)

  switch typeof! content
  | 'String' =>
    e.appendChild (document.createTextNode content)
  | _ =>
    if content instanceof window.Node
      e.appendChild(content)

  if parent?
    parent.appendChild(e)

  e

# Find the element 'el' starting at 'root'
# 'el' is usually a class name or ID but my also
# be an instance of an element (or DOMElement) in which
# case it is returned straight away.
#
# If 'el' is an unrecognised type then we will try to find
# 'deflt'.
#
# If 'el' is not found we return null
get-el = (el = null, dflt = null, root = document) ->
  unless el?
    if dflt?
      get-el dflt, null, root
    else
      return null

  if el instanceof window.Element
    el
  else
    switch typeof! el
    | 'String' =>
      if el[0] is '.' or el[0] is '#'
        root.query-selector el
      else
        root.getElementById el
    | 'DOMElement' =>
      el
    | _ =>
      if dflt isnt null
        get-el dflt, null, root
      else
        console.log typeof! el
        null


# Return the index of an element within it's
# parent's children.
# Returns -1 if we can't find the element.
index-of-element = (element) ->
  unless element?
    return -1

  parent = element.parentElement
  unless parent?
    return -1

  children = parent.children

  Array.prototype.indexOf.call(children, element)


insertion-index-for = (item, collection, comparer) ->
  unless item? and collection? and comparer?
    return -1

  l = collection.length
  idx = 0
  while idx < l and comparer(item, collection[idx]) <= 0
    idx += 1

  idx



module.exports =
  make: make
  getEl: get-el
  indexOfElement: index-of-element