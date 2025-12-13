import '../enums/trigger_type.dart';

typedef AnalyticsCallback =
    void Function(String eventName, Map<String, dynamic> parameters);

class RateUsAnalytics {
  final AnalyticsCallback? onEvent;

  const RateUsAnalytics({this.onEvent});

  void logEvent(String eventName, [Map<String, dynamic>? parameters]) {
    onEvent?.call(eventName, parameters ?? {});
  }

  // Gate events
  void logGate1Failed() =>
      logEvent('rate_us_gate_1_failed', {'reason': 'feature_disabled'});
  void logGate2Bypass() =>
      logEvent('rate_us_gate_2_bypass', {'reason': 'already_rated_custom'});
  void logGate3Cooldown() =>
      logEvent('rate_us_gate_3_cooldown', {'reason': 'in_cooldown'});
  void logGate4NativeToday() => logEvent('rate_us_gate_4_native_today', {
    'reason': 'native_already_called',
  });

  // Dialog events
  void logNativeCalled(TriggerType trigger) =>
      logEvent('rate_us_native_called', {'trigger': trigger.analyticsName});
  void logNativeFailed(String reason) =>
      logEvent('rate_us_native_failed', {'reason': reason});
  void logCustomShown(TriggerType trigger) =>
      logEvent('rate_us_custom_shown', {'trigger': trigger.analyticsName});
  void logCustomSubmit(int stars) =>
      logEvent('rate_us_custom_submit', {'stars': stars});
  void logCustomDismiss() => logEvent('rate_us_custom_dismiss');
  void logPlayStoreRedirect() => logEvent('rate_us_playstore_redirect');

  // Trigger events
  void logTrigger(TriggerType type) =>
      logEvent('rate_us_trigger', {'type': type.analyticsName});

  // System events
  void logInitialized(Map<String, dynamic> config) =>
      logEvent('rate_us_initialized', config);
  void logDailyReset() => logEvent('rate_us_daily_reset');
}
