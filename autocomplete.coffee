class Autocomplete
  constructor: (el) ->
    @$el = $(el)

    @initFilter()
    @initOptions()
    @initAlerts()

    @applyCheckedOptionToFilter()
    @announceOptionsCount('')

    @attachEvents()

  show: ($el) ->
    $el.removeAttr('hidden')

  hide: ($el) ->
    $el.attr('hidden', '')

  initFilter: ->
    @$filter = @$el.find('input[type="text"]')

  initOptions: ->
    @$optionsContainer = @$el.find('fieldset')
    @$optionsContainerLabel = @$el.find('legend')
    @$options = @$optionsContainer.find('input[type="radio"]')

  initAlerts: ->
    @$alertsContainer = $("<div id='alerts'></div>")
    @$optionsContainerLabel.after(@$alertsContainer)
    @$filter.attr('aria-describedby', [@$filter.attr('aria-describedby'), 'alerts'].join(' ').trim())

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
      if !@$optionsContainer.attr('hidden')
        @hideOptions()
      else
        @showOptions()

  attachEscapeKeyToFilter: ->
    @$filter.keydown (e) =>
      if e.which == 27
        if !@$optionsContainer.attr('hidden')
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
        if !@$optionsContainer.attr('hidden')
          @applyCheckedOptionToFilterAndResetOptions()
          e.preventDefault()
        else # Needed for automatic testing only
          $('body').append('<p>Enter passed on.</p>')

  attachTabKeyToFilter: ->
    @$filter.keydown (e) =>
      if e.which == 9
        if !@$optionsContainer.attr('hidden')
          @applyCheckedOptionToFilterAndResetOptions()

  attachUpDownKeysToFilter: ->
    @$filter.keydown (e) =>
      if e.which == 38 || e.which == 40
        if !@$optionsContainer.attr('hidden')
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
    $previouslyCheckedOptionLabel = $(@$el.find('.selected'))
    if $previouslyCheckedOptionLabel.length == 1
      $previouslyCheckedOptionLabel.removeClass('selected')

    $checkedOption = @$options.filter(':checked')
    if $checkedOption.length == 1
      $checkedOptionLabel = $(@$el.find("label[for='#{$checkedOption.attr('id')}']")[0])
      @$filter.val($.trim($checkedOptionLabel.text()))
      $checkedOptionLabel.addClass('selected')
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
    visibleCount = 0

    @$options.each (i, el) =>
      $option = $(el)
      $optionContainer = $option.parent()

      regex = new RegExp(fuzzyFilter, 'i')
      if regex.test($optionContainer.text())
        visibleCount++
        @show($optionContainer)
      else
        @hide($optionContainer)

    @announceOptionsCount(filter, visibleCount)

  announceOptionsCount: (filter = @$filter.val(), count = @$options.length) ->
    @$alertsContainer.find('p').remove() # Remove previous alerts

    message = if filter == ''
                "#{count} options in total"
              else
                "#{count} of #{@$options.length} options for <kbd>#{filter}</kbd>"

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
  $('[data-autocomplete]').each ->
    new Autocomplete @
