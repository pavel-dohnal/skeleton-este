goog.provide 'app.ErrorReporter'

goog.require 'app.errors.InnocuousError'
goog.require 'app.errors.SilentError'
goog.require 'goog.Promise'
goog.require 'goog.async.throwException'
goog.require 'goog.debug.ErrorReporter'
goog.require 'goog.labs.net.xhr'
goog.require 'goog.net.HttpStatus'

# Disable default error rethrowing.
goog.Promise.setUnhandledRejectionHandler ->

class app.ErrorReporter

  ###*
    @param {app.Routes} routes
    @constructor
  ###
  constructor: (@routes) ->
    @alreadyReported_ = Object.create null

    if !goog.DEBUG
      @reporter = goog.debug.ErrorReporter.install @routes.api.clientErrors.url()

  @MSG_APP_ERROR: goog.getMsg 'Application error. Please reload browser.'
  @MSG_CONNECTION_ERROR: goog.getMsg 'Connection error. Check your connection please.'

  ###*
    Set after login and remove before logout.
    @type {string}
  ###
  userName: ''

  ###*
    @param {este.Dispatcher} dispatcher
  ###
  init: (dispatcher) ->
    dispatcher.onError = @onError_.bind @

  ###*
    @param {string} action
    @param {*} reason
    @private
  ###
  onError_: (action, reason) ->
    return if !@isWorthReporting_ reason

    # TODO: Show something more beautiful then alert. Add button to reload app.
    # Auto-reload is bad idea because it can cause reload looping.
    alert ErrorReporter.MSG_APP_ERROR

    if !@isAlreadyReported_ reason
      @reporter?.setAdditionalArguments
        action: action
        user: @userName

      # Propagate error to other promises. It also ensures reason is shown in
      # console therefore catched and reported by goog.debug.ErrorReporter.
      goog.async.throwException reason

  ###*
    @param {*} reason
    @return {boolean}
  ###
  isWorthReporting_: (reason) ->
    isSilent =
      reason == 404 ||
      reason instanceof app.errors.SilentError ||
      reason instanceof goog.Promise.CancellationError
    return false if isSilent

    if reason instanceof app.errors.InnocuousError
      alert reason.message
      return false

    if reason instanceof goog.labs.net.xhr.Error
      alert ErrorReporter.MSG_CONNECTION_ERROR
      return false

    true

  ###*
    Don't report already reported reason.
    @param {*} reason
    @return {boolean}
  ###
  isAlreadyReported_: (reason) ->
    stringReason = String reason
    if @alreadyReported_[stringReason]
      return true
    @alreadyReported_[stringReason] = true
    false
