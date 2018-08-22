class Autocomplete
  constructor: (el, options = {}) ->
    @$el = $(el)

    @initFilter()
    @initOptions()
    @initAlerts()

    @applyCheckedOptionToFilter()
    @announceOptionsNumber('')

    @attachEvents()

  labelOfInput: ($inputs) ->
    $inputs.map (i, input) =>
      $input = $(input)

      id = $input.attr('id')
      $label = @$el.find("label[for='#{id}']")[0]

      if $label.length == 0
        $label = $input.closest('label')

      $label

  show: ($el) ->
    $el.removeAttr('hidden')
    $el.show()

  hide: ($el) ->
    $el.attr('hidden', '')
    $el.hide()

  text: (text, options = {}) ->
    for key, value of options
      text = text.replace "[#{key}]", value

    text

  initFilter: ->
    @$filter = @$el.find('input[type="text"]')
    @$filter.attr("data-autosuggest-filter", '')
    @$filter.attr('autocomplete', 'off')
    @$filter.attr('aria-expanded', 'false')

  initOptions: ->
    @$optionsContainer = @$el.find('fieldset')
    @$optionsContainer.attr("data-autosuggest-options", '')

    @$optionsContainerLabel = @$el.find('legend')
    @$optionsContainerLabel.addClass('adg-visually-hidden')

    @$options = @$optionsContainer.find('input[type="radio"]')
    @labelOfInput(@$options).attr("data-autosuggest-option", '')
    @$options.addClass('adg-visually-hidden')

  initAlerts: ->
    @$alertsContainer = $("<div id='alerts'></div>")
    @$optionsContainerLabel.after(@$alertsContainer)
    @$filter.attr('aria-describedby', [@$filter.attr('aria-describedby'), @$alertsContainer.attr('id')].join(' ').trim())
    @$alertsContainer.attr("data-autosuggest-alerts", '')

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

        e.preventDefault()

  showOptions: ->
    @show(@$optionsContainer)
    @$filter.attr('aria-expanded', 'true')

  hideOptions: ->
    @hide(@$optionsContainer)
    @$filter.attr('aria-expanded', 'false')

  moveSelection: (direction) ->
    $visibleOptions = @$options.filter(':visible')

    maxIndex = $visibleOptions.length - 1
    currentIndex = $visibleOptions.index($visibleOptions.parent().find(':checked'))

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
    $previouslyCheckedOptionLabel = $("[data-autosuggest-option-selected]")
    if $previouslyCheckedOptionLabel.length == 1
      $previouslyCheckedOptionLabel.removeAttr('data-autosuggest-option-selected')

    $checkedOption = @$options.filter(':checked')
    if $checkedOption.length == 1
      $checkedOptionLabel = @labelOfInput($checkedOption)
      @$filter.val($.trim($checkedOptionLabel.text()))
      $checkedOptionLabel.attr("data-autosuggest-option-selected", '')
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
    @$alertsContainer.find('p').remove() # Remove previous alerts

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
  $('[data-autosuggest]').each ->
    new Autocomplete @
