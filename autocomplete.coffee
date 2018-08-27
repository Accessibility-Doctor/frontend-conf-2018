class Autocomplete
  constructor: (el) ->
    @$el = $(el)

    @$text     = @$el.find('input[type="text"]')
    @$fieldset = @$el.find('fieldset')
    @$radios   = @$fieldset.find('input[type="radio"]')
    @$alerts   = @$el.find('#alerts')

    @applyCheckedOptionToInput()
    @announceOptionsCount('')

    @attachEvents()

  attachEvents: ->
    @attachClickEventToInput()
    @attachChangeEventToInput()

    @attachEscapeKeyToInput()
    @attachSpaceKeyToInput()
    @attachEnterKeyToInput()
    @attachTabKeyToInput()
    @attachUpDownKeysToInput()

    @attachChangeEventToOptions()
    @attachClickEventToOptions()

    @attachFocusOut()

  attachClickEventToInput: ->
    @$text.click =>
      if !@$fieldset.attr('hidden')
        @hideOptions()
      else
        @showOptions()

  attachChangeEventToInput: ->
    @$text.on 'input propertychange paste', (e) =>
      @applyFilterToOptions(e.target.value)
      @showOptions()

  attachEscapeKeyToInput: ->
    @$text.keydown (e) =>
      if e.which == 27
        if !@$fieldset.attr('hidden')
          @applyCheckedOptionToInputAndResetOptions()
          e.preventDefault()
        else if @$radios.is(':checked')
          @$radios.prop('checked', false)
          @applyCheckedOptionToInputAndResetOptions()
          e.preventDefault()
        else # Needed for automatic testing only
          $('body').append('<p>Esc passed on.</p>')

  attachSpaceKeyToInput: ->
    @$text.keydown (e) =>
      if e.which == 32
        if @$fieldset.attr('hidden') && @$text.val() == ''
          @showOptions()
          e.preventDefault()
        else # Needed for automatic testing only
          $('body').append('<p>Space passed on.</p>')

  attachEnterKeyToInput: ->
    @$text.keydown (e) =>
      if e.which == 13
        if !@$fieldset.attr('hidden')
          @applyCheckedOptionToInputAndResetOptions()
          e.preventDefault()
        else # Needed for automatic testing only
          $('body').append('<p>Enter passed on.</p>')

  attachTabKeyToInput: ->
    @$text.keydown (e) =>
      if e.which == 9
        if !@$fieldset.attr('hidden')
          @applyCheckedOptionToInputAndResetOptions()

  attachUpDownKeysToInput: ->
    @$text.keydown (e) =>
      if e.which == 38 || e.which == 40
        if !@$fieldset.attr('hidden')
          if e.which == 38
            @walkThroughOptions('up')
          else
            @walkThroughOptions('down')
        else
          @showOptions()

        e.preventDefault()

  attachChangeEventToOptions: ->
    @$radios.change (e) =>
      @applyCheckedOptionToInput()
      @$text.focus().select()

  attachClickEventToOptions: ->
    @$radios.click (e) =>
      @hideOptions()

  attachFocusOut: ->
    @$el.focusout =>
      if !@$fieldset.attr('hidden') && !@$el.is(':hover')
        @applyCheckedOptionToInputAndResetOptions()
        @hideOptions()

  showOptions: ->
    @$fieldset.removeAttr('hidden')
    @$text.attr('aria-expanded', 'true')

  hideOptions: ->
    @$fieldset.attr('hidden', '')
    @$text.attr('aria-expanded', 'false')

  walkThroughOptions: (direction) ->
    $visibleOptions = @$radios.filter(':visible')

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

  applyCheckedOptionToInput: ->
    $previouslyCheckedOptionLabel = $(@$el.find('.selected'))
    if $previouslyCheckedOptionLabel.length == 1
      $previouslyCheckedOptionLabel.removeClass('selected')

    $checkedOption = @$radios.filter(':checked')
    if $checkedOption.length == 1
      $checkedOptionLabel = $($checkedOption.parent()[0])
      @$text.val($.trim($checkedOptionLabel.text()))
      $checkedOptionLabel.addClass('selected')
    else
      @$text.val('')

  applyFilterToOptions: (filter) ->
    fuzzifiedFilter = @fuzzifyFilter(filter)
    visibleCount = 0

    @$radios.each (i, el) =>
      $option = $(el)
      $optionContainer = $option.parent()

      regex = new RegExp(fuzzifiedFilter, 'i')
      if regex.test($optionContainer.text())
        visibleCount++
        $optionContainer.removeAttr('hidden')
      else
        $optionContainer.attr('hidden', '')

    @announceOptionsCount(filter, visibleCount)

  applyCheckedOptionToInputAndResetOptions: ->
    @applyCheckedOptionToInput()
    @hideOptions()
    @applyFilterToOptions('')

  announceOptionsCount: (filter = @$text.val(), count = @$radios.length) ->
    @$alerts.find('p').remove() # Remove previous alerts

    message = if filter == ''
                "#{count} options in total"
              else
                "#{count} of #{@$radios.length} options for <kbd>#{filter}</kbd>"

    @$alerts.append("<p role='alert'>#{message}</p>")

  # See https://stackoverflow.com/questions/3446170/escape-string-for-use-in-javascript-regex
  fuzzifyFilter: (filter) ->
    i = 0
    fuzzifiedFilter = ''

    while i < filter.length
      escapedCharacter = filter.charAt(i).replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&")
      fuzzifiedFilter += "#{escapedCharacter}.*?"
      i++

    fuzzifiedFilter

$(document).ready ->
  $('form').each ->
    new Autocomplete @
