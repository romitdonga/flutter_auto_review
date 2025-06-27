/// A callback function type for handling analytics events
typedef AnalyticsCallback =
    void Function(String eventName, Map<String, dynamic> parameters);

/// Analytics events for the rate us dialog
class RateUsAnalytics {
  /// Callback function for handling analytics events
  final AnalyticsCallback? onEvent;

  /// Creates a new RateUsAnalytics instance
  const RateUsAnalytics({this.onEvent});

  /// Logs an event with the given name and parameters
  void logEvent(String eventName, [Map<String, dynamic>? parameters]) {
    final callback = onEvent;
    if (callback != null) {
      callback(eventName, parameters ?? {});
    }
  }

  /// Logs when the rate us dialog is shown
  void logDialogShown() {
    logEvent('rate_us_dialog_shown');
  }

  /// Logs when the user rates the app
  void logRated() {
    logEvent('rate_us_rated');
  }

  /// Logs when the user dismisses the rate us dialog
  void logDismissed() {
    logEvent('rate_us_dismissed');
  }

  /// Logs when the user is redirected to the store
  void logStoreRedirect() {
    logEvent('rate_us_store_redirect');
  }

  /// Logs when the fallback dialog is shown
  void logFallbackShown() {
    logEvent('rate_us_fallback_shown');
  }

  /// Logs when a trigger condition is met
  void logTriggerCondition(String triggerType) {
    logEvent('rate_us_trigger', {'trigger_type': triggerType});
  }

  /// Logs when the rate us feature is initialized
  void logInitialized(Map<String, dynamic> config) {
    logEvent('rate_us_initialized', config);
  }
}
