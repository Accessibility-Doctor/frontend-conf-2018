# Tested in JAWS+IE/FF, NVDA+FF
#
# Known issues:
# - JAWS leaves the input when using up/down without entering something (I guess this is due to screen layout and can be considered intended)
# - Alert not perceivable upon opening options using up/down
#     - Possible solution 1: always show options count when filter focused?
#     - Possible solution 2: wait a moment before adding the alert?
# - VoiceOver/iOS announces radio buttons as disabled?!
# - iOS doesn't select all text when option was chosen
#
# In general: alerts seem to be most robust in all relevant browsers, but aren't polite. Maybe we'll find a better mechanism to serve browsers individually?
class AdgAutocomplete
  uniqueIdCount = 1

  constructor: (el, options = {}) ->
    @$el = $(el)

    @initFilter()
    @initOptions()
    @initAlerts()

    @applyCheckedOptionToFilter()
    @announceOptionsNumber('')

    @attachEvents()

  name: ->
    "adg-autosuggest"

  addAdgDataAttribute: ($target, name, value = '') ->
    $target.attr(@adgDataAttributeName(name), value)

  removeAdgDataAttribute: ($target, name) ->
    $target.removeAttr(@adgDataAttributeName(name))

  adgDataAttributeName: (name = null) ->
    result = "data-#{@name()}"
    result += "-#{name}" if name
    result

  uniqueId: (name) ->
    [@name(), name, uniqueIdCount++].join '-'

  labelOfInput: ($inputs) ->
    $inputs.map (i, input) =>
      $input = $(input)

      id = $input.attr('id')
      $label = @$el.find("label[for='#{id}']")[0]

      if $label.length == 0
        $label = $input.closest('label')
        @throwMessageAndPrintObjectsToConsole "No corresponding input found for input!", input: $input if $label.length == 0

      $label

  show: ($el) ->
    $el.removeAttr('hidden')
    $el.show()

    # TODO Would be cool to renounce CSS and solely use the hidden attribute. But jQuery's :visible doesn't seem to work with it!?
    # @throwMessageAndPrintObjectsToConsole("Element is still hidden, although hidden attribute was removed! Make sure there's no CSS like display:none or visibility:hidden left on it!", element: $el) if $el.is(':hidden')

  hide: ($el) ->
    $el.attr('hidden', '')
    $el.hide()

  throwMessageAndPrintObjectsToConsole: (message, elements = {}) ->
    console.log elements
    throw message

  text: (text, options = {}) ->
    for key, value of options
      text = text.replace "[#{key}]", value

    text

  initFilter: ->
    @$filter = @$el.find('input[type="text"]')
    @addAdgDataAttribute(@$filter, 'filter')
    @$filter.attr('autocomplete', 'off')
    @$filter.attr('aria-expanded', 'false')

  initOptions: ->
    @$optionsContainer = @$el.find('fieldset')
    @addAdgDataAttribute(@$optionsContainer, 'options')

    @$optionsContainerLabel = @$el.find('legend')
    @$optionsContainerLabel.addClass('adg-visually-hidden')

    @$options = @$optionsContainer.find('input[type="radio"]')
    @addAdgDataAttribute(@labelOfInput(@$options), 'option')
    @$options.addClass('adg-visually-hidden')

  initAlerts: ->
    @$alertsContainer = $("<div id='#{@uniqueId('alerts')}'></div>")
    @$optionsContainerLabel.after(@$alertsContainer)
    @$filter.attr('aria-describedby', [@$filter.attr('aria-describedby'), @$alertsContainer.attr('id')].join(' ').trim())
    @addAdgDataAttribute(@$alertsContainer, 'alerts')

  attachEvents: ->
    @attachClickEventToFilter()
    @attachChangeEventToFilter()

    @attachEscapeKeyToFilter()
    @attachEnterKeyToFilter()
    @attachTabKeyToFilter()
    @attachUpDownKeysToFilter()

    @attachChangeEventToOptions()
    @attachClickEventToOptions()

  attachClickEventToFilter: ->
    @$filter.click =>
      if @$optionsContainer.is(':visible')
        @hideOptions()
      else
        @showOptions()

  attachEscapeKeyToFilter: ->
    @$filter.keydown (e) =>
      if e.which == 27
        if @$optionsContainer.is(':visible')
          @applyCheckedOptionToFilterAndResetOptions()
          e.preventDefault()
        else if @$options.is(':checked')
          @$options.prop('checked', false)
          @applyCheckedOptionToFilterAndResetOptions()
          e.preventDefault()
        else # Needed for automatic testing only
          $('body').append('<p>Esc passed on.</p>')

  attachEnterKeyToFilter: ->
    @$filter.keydown (e) =>
      if e.which == 13
        if @$optionsContainer.is(':visible')
          @applyCheckedOptionToFilterAndResetOptions()
          e.preventDefault()
        else # Needed for automatic testing only
          $('body').append('<p>Enter passed on.</p>')

  attachTabKeyToFilter: ->
    @$filter.keydown (e) =>
      if e.which == 9
        if @$optionsContainer.is(':visible')
          @applyCheckedOptionToFilterAndResetOptions()

  attachUpDownKeysToFilter: ->
    @$filter.keydown (e) =>
      if e.which == 38 || e.which == 40
        if @$optionsContainer.is(':visible')
          if e.which == 38
            @moveSelection('up')
          else
            @moveSelection('down')
        else
          @showOptions()

        e.preventDefault() # TODO: Test!

  showOptions: ->
    @show(@$optionsContainer)
    @$filter.attr('aria-expanded', 'true')

  hideOptions: ->
    @hide(@$optionsContainer)
    @$filter.attr('aria-expanded', 'false')

  moveSelection: (direction) ->
    $visibleOptions = @$options.filter(':visible')

    maxIndex = $visibleOptions.length - 1
    currentIndex = $visibleOptions.index($visibleOptions.parent().find(':checked')) # TODO: is parent() good here?!

    upcomingIndex = if direction == 'up'
                      if currentIndex <= 0
                        maxIndex
                      else
                        currentIndex - 1
                    else
                      if currentIndex == maxIndex
                        0
                      else
                        currentIndex + 1

    $upcomingOption = $($visibleOptions[upcomingIndex])
    $upcomingOption.prop('checked', true).trigger('change')

  attachChangeEventToOptions: ->
    @$options.change (e) =>
      @applyCheckedOptionToFilter()
      @$filter.focus().select()

  applyCheckedOptionToFilterAndResetOptions: ->
    @applyCheckedOptionToFilter()
    @hideOptions()
    @filterOptions()

  applyCheckedOptionToFilter: ->
    $previouslyCheckedOptionLabel = $("[#{@adgDataAttributeName('option-selected')}]")
    if $previouslyCheckedOptionLabel.length == 1
      @removeAdgDataAttribute($previouslyCheckedOptionLabel, 'option-selected')

    $checkedOption = @$options.filter(':checked')
    if $checkedOption.length == 1
      $checkedOptionLabel = @labelOfInput($checkedOption)
      @$filter.val($.trim($checkedOptionLabel.text()))
      @addAdgDataAttribute($checkedOptionLabel, 'option-selected')
    else
      @$filter.val('')

  attachClickEventToOptions: ->
    @$options.click (e) =>
      @hideOptions()

  attachChangeEventToFilter: ->
    @$filter.on 'input propertychange paste', (e) =>
      @filterOptions(e.target.value)
      @showOptions()

  filterOptions: (filter = '') ->
    fuzzyFilter = @fuzzifyFilter(filter)
    visibleNumber = 0

    @$options.each (i, el) =>
      $option = $(el)
      $optionContainer = $option.parent()

      regex = new RegExp(fuzzyFilter, 'i')
      if regex.test($optionContainer.text())
        visibleNumber++
        @show($optionContainer)
      else
        @hide($optionContainer)

    @announceOptionsNumber(filter, visibleNumber)

  announceOptionsNumber: (filter = @$filter.val(), number = @$options.length) ->
    @$alertsContainer.find('p').remove() # Remove previous alerts (I'm not sure whether this is the best solution, maybe hiding them would be more robust?)

    message = if filter == ''
                @text('[number] options in total', number: number)
              else
                @text('[number] of [total] options for [filter]', number: number, total: @$options.length, filter: "<kbd>#{filter}</kbd>")

    @$alertsContainer.append("<p role='alert'>#{message}</p>")

  fuzzifyFilter: (filter) ->
    i = 0
    fuzzifiedFilter = ''
    while i < filter.length
      escapedCharacter = filter.charAt(i).replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&") # See https://stackoverflow.com/questions/3446170/escape-string-for-use-in-javascript-regex
      fuzzifiedFilter += "#{escapedCharacter}.*?"
      i++

    fuzzifiedFilter

$(document).ready ->
  $('[data-adg-autosuggest]').each ->
    new AdgAutocomplete @
