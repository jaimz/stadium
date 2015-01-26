require! {
  _ : 'prelude-ls'
}

delegate = (delegates = [], fn-name = 'delegate', ...params) ->
  unless delegates and fn-name
    return

  for d in delegates
    if _.is-type 'Function' d[fn-name]
      d[fn-name].apply(d, params)


WithDelegation =
  add-delegate: (d) ->
    unless @delegates?
      @delegates = []

    if _.is-type 'Object', d
      @delegates.push d

  remove-delegate: (d) ->
    i = @delegates.index-of(d)
    if i isnt -1
      @delegates.splice(i, 1)

  call-delegate: (fn-name = 'delegate', ...params) ->
    if @delegates? and @delegates.length > 0
      delegate @delegates, fn-name, ...params


module.exports =
  WithDelegation: WithDelegation