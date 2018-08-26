// Tested in JAWS+IE/FF, NVDA+FF

// Known issues:
// - JAWS leaves the input when using up/down without entering something (I guess this is due to screen layout and can be considered intended)
// - Alert not perceivable upon opening options using up/down
//     - Possible solution 1: always show options count when filter focused?
//     - Possible solution 2: wait a moment before adding the alert?
// - VoiceOver/iOS announces radio buttons as disabled?!
// - iOS doesn't select all text when option was chosen

// In general: alerts seem to be most robust in all relevant browsers, but aren't polite. Maybe we'll find a better mechanism to serve browsers individually?
var AdgAutocomplete;

AdgAutocomplete = (function() {
  var config, uniqueIdCount;

  class AdgAutocomplete {
    constructor(el, options = {}) {
      var jsonOptions, key, val;
      this.$el = $(el);
      this.config = config;
      for (key in options) {
        val = options[key];
        this.config[key] = val;
      }
      jsonOptions = this.$el.attr(this.adgDataAttributeName());
      if (jsonOptions) {
        for (key in jsonOptions) {
          val = jsonOptions[key];
          this.config[key] = val;
        }
      }
      this.initFilter();
      this.initOptions();
      this.initAlerts();
      this.applyCheckedOptionToFilter();
      this.announceOptionsNumber('');
      this.attachEvents();
    }

    // Executes the given selector on @$el and returns the element. Makes sure exactly one element exists.
    findOne(selector) {
      var result;
      result = this.$el.find(selector);
      switch (result.length) {
        case 0:
          return this.throwMessageAndPrintObjectsToConsole(`No object found for ${selector}!`, {
            result: result
          });
        case 1:
          return $(result.first());
        default:
          return this.throwMessageAndPrintObjectsToConsole(`More than one object found for ${selector}!`, {
            result: result
          });
      }
    }

    name() {
      return "adg-autosuggest";
    }

    addAdgDataAttribute($target, name, value = '') {
      $target.attr(this.adgDataAttributeName(name), value);
    }

    removeAdgDataAttribute($target, name) {
      $target.removeAttr(this.adgDataAttributeName(name));
    }

    adgDataAttributeName(name = null) {
      var result;
      result = `data-${this.name()}`;
      if (name) {
        result += `-${name}`;
      }
      return result;
    }

    uniqueId(name) {
      return [this.name(), name, uniqueIdCount++].join('-');
    }

    labelOfInput($inputs) {
      return $inputs.map((i, input) => {
        var $input, $label, id;
        $input = $(input);
        id = $input.attr('id');
        $label = this.findOne(`label[for='${id}']`)[0];
        if ($label.length === 0) {
          $label = $input.closest('label');
          if ($label.length === 0) {
            this.throwMessageAndPrintObjectsToConsole("No corresponding input found for input!", {
              input: $input
            });
          }
        }
        return $label;
      });
    }

    show($el) {
      $el.removeAttr('hidden');
      $el.show();
    }

    // TODO Would be cool to renounce CSS and solely use the hidden attribute. But jQuery's :visible doesn't seem to work with it!?
    // @throwMessageAndPrintObjectsToConsole("Element is still hidden, although hidden attribute was removed! Make sure there's no CSS like display:none or visibility:hidden left on it!", element: $el) if $el.is(':hidden')
    hide($el) {
      $el.attr('hidden', '');
      $el.hide();
    }

    throwMessageAndPrintObjectsToConsole(message, elements = {}) {
      console.log(elements);
      throw message;
    }

    text(text, options = {}) {
      var key, value;
      text = this.config[`${text}Text`];
      for (key in options) {
        value = options[key];
        text = text.replace(`[${key}]`, value);
      }
      return text;
    }

    initFilter() {
      this.$filter = this.findOne('input[type="text"]');
      this.addAdgDataAttribute(this.$filter, 'filter');
      this.$filter.attr('autocomplete', 'off');
      this.$filter.attr('aria-expanded', 'false');
    }

    initOptions() {
      this.$optionsContainer = this.findOne(this.config.optionsContainer);
      this.addAdgDataAttribute(this.$optionsContainer, 'options');
      this.$optionsContainerLabel = this.findOne(this.config.optionsContainerLabel);
      this.$optionsContainerLabel.addClass(this.config.hiddenCssClass);
      this.$options = this.$optionsContainer.find('input[type="radio"]');
      this.addAdgDataAttribute(this.labelOfInput(this.$options), 'option');
      this.$options.addClass(this.config.hiddenCssClass);
    }

    initAlerts() {
      this.$alertsContainer = $(`<div id='${this.uniqueId(this.config.alertsContainerId)}'></div>`);
      this.$optionsContainerLabel.after(this.$alertsContainer);
      this.$filter.attr('aria-describedby', [this.$filter.attr('aria-describedby'), this.$alertsContainer.attr('id')].join(' ').trim());
      this.addAdgDataAttribute(this.$alertsContainer, 'alerts');
    }

    attachEvents() {
      this.attachClickEventToFilter();
      this.attachChangeEventToFilter();
      this.attachEscapeKeyToFilter();
      this.attachEnterKeyToFilter();
      this.attachTabKeyToFilter();
      this.attachUpDownKeysToFilter();
      this.attachChangeEventToOptions();
      this.attachClickEventToOptions();
    }

    attachClickEventToFilter() {
      this.$filter.click(() => {
        if (this.$optionsContainer.is(':visible')) {
          this.hideOptions();
        } else {
          this.showOptions();
        }
      });
    }

    attachEscapeKeyToFilter() {
      this.$filter.keydown((e) => {
        if (e.which === 27) {
          if (this.$optionsContainer.is(':visible')) {
            this.applyCheckedOptionToFilterAndResetOptions();
            e.preventDefault();
          } else if (this.$options.is(':checked')) {
            this.$options.prop('checked', false);
            this.applyCheckedOptionToFilterAndResetOptions();
            e.preventDefault();
          }
        }
      });
    }

    attachEnterKeyToFilter() {
      this.$filter.keydown((e) => {
        if (e.which === 13) {
          if (this.$optionsContainer.is(':visible')) {
            this.applyCheckedOptionToFilterAndResetOptions();
            e.preventDefault();
          }
        }
      });
    }

    attachTabKeyToFilter() {
      this.$filter.keydown((e) => {
        if (e.which === 9) {
          if (this.$optionsContainer.is(':visible')) {
            this.applyCheckedOptionToFilterAndResetOptions();
          }
        }
      });
    }

    attachUpDownKeysToFilter() {
      this.$filter.keydown((e) => {
        if (e.which === 38 || e.which === 40) {
          if (this.$optionsContainer.is(':visible')) {
            if (e.which === 38) {
              this.moveSelection('up');
            } else {
              this.moveSelection('down');
            }
          } else {
            this.showOptions();
          }
          e.preventDefault(); // TODO: Test!
        }
      });
    }

    showOptions() {
      this.show(this.$optionsContainer);
      this.$filter.attr('aria-expanded', 'true');
    }

    hideOptions() {
      this.hide(this.$optionsContainer);
      this.$filter.attr('aria-expanded', 'false');
    }

    moveSelection(direction) {
      var $upcomingOption, $visibleOptions, currentIndex, maxIndex, upcomingIndex;
      $visibleOptions = this.$options.filter(':visible');
      maxIndex = $visibleOptions.length - 1;
      currentIndex = $visibleOptions.index($visibleOptions.parent().find(':checked')); // TODO: is parent() good here?!
      upcomingIndex = direction === 'up' ? currentIndex <= 0 ? maxIndex : currentIndex - 1 : currentIndex === maxIndex ? 0 : currentIndex + 1;
      $upcomingOption = $($visibleOptions[upcomingIndex]);
      $upcomingOption.prop('checked', true).trigger('change');
    }

    attachChangeEventToOptions() {
      this.$options.change((e) => {
        this.applyCheckedOptionToFilter();
        this.$filter.focus().select();
      });
    }

    applyCheckedOptionToFilterAndResetOptions() {
      this.applyCheckedOptionToFilter();
      this.hideOptions();
      this.filterOptions();
    }

    applyCheckedOptionToFilter() {
      var $checkedOption, $checkedOptionLabel, $previouslyCheckedOptionLabel;
      $previouslyCheckedOptionLabel = $(`[${this.adgDataAttributeName('option-selected')}]`);
      if ($previouslyCheckedOptionLabel.length === 1) {
        this.removeAdgDataAttribute($previouslyCheckedOptionLabel, 'option-selected');
      }
      $checkedOption = this.$options.filter(':checked');
      if ($checkedOption.length === 1) {
        $checkedOptionLabel = this.labelOfInput($checkedOption);
        this.$filter.val($.trim($checkedOptionLabel.text()));
        this.addAdgDataAttribute($checkedOptionLabel, 'option-selected');
      } else {
        this.$filter.val('');
      }
    }

    attachClickEventToOptions() {
      this.$options.click((e) => {
        this.hideOptions();
      });
    }

    attachChangeEventToFilter() {
      this.$filter.on('input propertychange paste', (e) => {
        this.filterOptions(e.target.value);
        this.showOptions();
      });
    }

    filterOptions(filter = '') {
      var fuzzyFilter, visibleNumber;
      fuzzyFilter = this.fuzzifyFilter(filter);
      visibleNumber = 0;
      this.$options.each((i, el) => {
        var $option, $optionContainer, regex;
        $option = $(el);
        $optionContainer = $option.parent();
        regex = new RegExp(fuzzyFilter, 'i');
        if (regex.test($optionContainer.text())) {
          visibleNumber++;
          this.show($optionContainer);
        } else {
          this.hide($optionContainer);
        }
      });
      this.announceOptionsNumber(filter, visibleNumber);
    }

    announceOptionsNumber(filter = this.$filter.val(), number = this.$options.length) {
      var message;
      this.$alertsContainer.find('p').remove(); // Remove previous alerts (I'm not sure whether this is the best solution, maybe hiding them would be more robust?)
      message = filter === '' ? this.text('numberInTotal', {
        number: number
      }) : this.text('numberFiltered', {
        number: number,
        total: this.$options.length,
        filter: `<kbd>${filter}</kbd>`
      });
      this.$alertsContainer.append(`<p role='alert'>${message}</p>`);
    }

    fuzzifyFilter(filter) {
      var escapedCharacter, fuzzifiedFilter, i;
      i = 0;
      fuzzifiedFilter = '';
      while (i < filter.length) {
        escapedCharacter = filter.charAt(i).replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&"); // See https://stackoverflow.com/questions/3446170/escape-string-for-use-in-javascript-regex
        fuzzifiedFilter += `${escapedCharacter}.*?`;
        i++;
      }
      return fuzzifiedFilter;
    }

  };

  uniqueIdCount = 1;

  config = {
    hiddenCssClass: 'adg-visually-hidden',
    optionsContainer: 'fieldset',
    optionsContainerLabel: 'legend',
    alertsContainerId: 'alerts',
    numberInTotalText: '[number] options in total',
    numberFilteredText: '[number] of [total] options for [filter]'
  };

  return AdgAutocomplete;

})();

$(document).ready(function() {
  $('[data-adg-autosuggest]').each(function() {
    new AdgAutocomplete(this);
  });
});
