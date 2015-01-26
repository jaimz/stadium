require! {
  _ : 'prelude-ls'
}


MxWithEvents =
  add-event-listener: (event-name, listener) !~>
    unless _.is-type 'Function', listener
      console.warn "Non-function passed to add-event-listener"
      console.warn listener
      return

    listener-table = @listener-table
    unless listener-table?
      listener-table = {}
      @listener-table = listener-table

    unless event-name of listener-table
      listeners = []
      listener-table[event-name] = listeners
    else
      listeners = listener-table[event-name]

    listeners.push listener

  remove-event-listener: (event-name, listener) !~>
    unless @listener-table and event-name of @listener-table
      return

    listeners = @listener-table[event-name]
    idx = _.elem-idx listener, listeners
    if idx?
      listeners.splice idx, 1

  fireEvent: (event-name, arg) ~>
    unless @listener-table? and event-name of @listener-table
      return

    listeners = @listener-table[event-name]
    _.each (.call @, arg), listeners


module.exports =
  MxWithEvents: MxWithEvents