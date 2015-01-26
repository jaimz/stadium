"use strict"

require! {
  util: './util.js'
  _: 'prelude-ls'
}


kStackClass = 'nav_stack'
kItemClass = 'nav_item'
kSwitchesClass = 'switches'
kSwitchClass = 'switch'
kOffRightClass = 'off_right'
kOffLeftClass = 'off_left'
kSelectedClass = 'selected'
kVisibleClass = 'visible'
kVisibleItemClass = "#{kItemClass} #{kVisibleClass}"


class Switch
  (el) ->
    unless el?
      throw new Error('Need an element to switch')

    @selected = null
    @selected-idx = -1
    @delegates = []
    @off-left = []
    @off-right = []
    @set-view el

  set-view: (el) ~>
    if @View?
      @dont-listen!

    @View = util.get-el(el)

    if @View?
      @triggers = @View.getElementsByClassName kSwitchClass
      @off-right = @View.getElementsByClassName kOffRightClass
      @off-left = @View.getElementsByClassName kOffLeftClass

      @listen!
      @selected-idx = _.find-index ((e) -> e.class-list.contains kSelectedClass), @triggers
      if @selected-idx?
        @selected = @triggers[@selected-idx]
      else
        @selected = null
        @selected-idx = -1

      @visible-panel = @View.getElementsByClassName kVisibleItemClass


  listen: ~>
    if @View?
      @View.add-event-listener 'click', @click

  dont-listen: ~>
    if @View?
      @View.remove-event-listener 'click', @click


  click: (e) ~>
    item = e.srcElement
    if item?
      item-cl = item.class-list
      if item-cl.contains 'switch'
        unless item-cl.contains 'selected'
          if @selected?
            @selected.class-list.remove 'selected'

          @selected = item

          if @selected-idx isnt -1
            new-idx = Array.prototype.indexOf.call(@triggers, @selected)
            if new-idx isnt -1
              d = new-idx - @selected-idx
              if d > 0
                _inc = -1
                from-class = kOffRightClass
                from-items = @off-right
                to-class = kOffLeftClass
              else
                _inc = 1
                from-class = kOffLeftClass
                from-items = @off-left
                to-class = kOffRightClass

              d += _inc

              while @visible-panel.length > 0
                cl = @visible-panel[0].class-list
                cl.add to-class
                cl.remove kVisibleClass


              while d isnt 0 and from-items > 0
                i = from-items[0]
                i.class-list.remove from-class
                i.class-list.add to-class

              if from-items.length > 0
                cl = from-items[0].class-list
                cl.remove from-class
                cl.add kVisibleClass

            item-cl.add 'selected'
          else
            # errr
            console.warn "could not find trigger in collection"
            console.warn @selected


module.exports =
  Switch: Switch
