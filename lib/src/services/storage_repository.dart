import 'package:shared_preferences/shared_preferences.dart';

import 'app_logger.dart';
import '../models/rate_us_state.dart';

class RateUsRepository {
  static const String _keyFirstInstallDate = 'rate_us_first_install_date';
  static const String _keyLastNativeAttemptDate =
      'rate_us_last_native_attempt_date';
  static const String _keyLastCustomShownDate =
      'rate_us_last_custom_shown_date';
  static const String _keyNativeCalledToday = 'rate_us_native_called_today';
  static const String _keyAssumedRatedCustom = 'rate_us_assumed_rated_custom';
  static const String _keyCustomDismissalCount =
      'rate_us_custom_dismissal_count';
  static const String _keyDailyCustomCount = 'rate_us_daily_custom_count';
  static const String _keyAppOpens = 'rate_us_app_opens';
  static const String _keyCustomEvents = 'rate_us_custom_events';
  static const String _keyAutoTriggerCount = 'rate_us_auto_trigger_count';
  static const String _keyTotalNativeAttempts = 'rate_us_total_native_attempts';

  final SharedPreferences _prefs;

  RateUsRepository(this._prefs);

  // Date getters/setters
  Future<DateTime?> getFirstInstallDate() async {
    final timestamp = _prefs.getInt(_keyFirstInstallDate);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  Future<void> setFirstInstallDate(DateTime date) async {
    await _prefs.setInt(_keyFirstInstallDate, date.millisecondsSinceEpoch);
  }

  Future<DateTime?> getLastNativeAttemptDate() async {
    final timestamp = _prefs.getInt(_keyLastNativeAttemptDate);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  Future<void> setLastNativeAttemptDate(DateTime date) async {
    await _prefs.setInt(_keyLastNativeAttemptDate, date.millisecondsSinceEpoch);
  }

  Future<DateTime?> getLastCustomShownDate() async {
    final timestamp = _prefs.getInt(_keyLastCustomShownDate);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  Future<void> setLastCustomShownDate(DateTime date) async {
    await _prefs.setInt(_keyLastCustomShownDate, date.millisecondsSinceEpoch);
  }

  // Boolean flags
  Future<bool> getNativeCalledToday() async {
    return _prefs.getBool(_keyNativeCalledToday) ?? false;
  }

  Future<void> setNativeCalledToday(bool value) async {
    await _prefs.setBool(_keyNativeCalledToday, value);
  }

  Future<bool> getAssumedRatedCustom() async {
    return _prefs.getBool(_keyAssumedRatedCustom) ?? false;
  }

  Future<void> setAssumedRatedCustom(bool value) async {
    await _prefs.setBool(_keyAssumedRatedCustom, value);
  }

  // Counters
  Future<int> getCustomDismissalCount() async {
    return _prefs.getInt(_keyCustomDismissalCount) ?? 0;
  }

  Future<void> setCustomDismissalCount(int count) async {
    await _prefs.setInt(_keyCustomDismissalCount, count);
  }

  Future<int> getDailyCustomCount() async {
    return _prefs.getInt(_keyDailyCustomCount) ?? 0;
  }

  Future<void> setDailyCustomCount(int count) async {
    await _prefs.setInt(_keyDailyCustomCount, count);
  }

  Future<int> getAppOpens() async {
    return _prefs.getInt(_keyAppOpens) ?? 0;
  }

  Future<void> setAppOpens(int count) async {
    await _prefs.setInt(_keyAppOpens, count);
  }

  Future<void> incrementAppOpens() async {
    final current = await getAppOpens();
    await setAppOpens(current + 1);
  }

  Future<int> getCustomEvents() async {
    return _prefs.getInt(_keyCustomEvents) ?? 0;
  }

  Future<void> setCustomEvents(int count) async {
    await _prefs.setInt(_keyCustomEvents, count);
  }

  Future<void> incrementCustomEvents() async {
    final current = await getCustomEvents();
    await setCustomEvents(current + 1);
  }

  Future<int> getAutoTriggerCount() async {
    return _prefs.getInt(_keyAutoTriggerCount) ?? 0;
  }

  Future<void> setAutoTriggerCount(int count) async {
    await _prefs.setInt(_keyAutoTriggerCount, count);
  }

  Future<void> incrementAutoTriggerCount() async {
    final current = await getAutoTriggerCount();
    await setAutoTriggerCount(current + 1);
  }

  Future<int> getTotalNativeAttempts() async {
    return _prefs.getInt(_keyTotalNativeAttempts) ?? 0;
  }

  Future<void> incrementTotalNativeAttempts() async {
    final current = await getTotalNativeAttempts();
    await _prefs.setInt(_keyTotalNativeAttempts, current + 1);
  }

  // State loader
  Future<RateUsState> loadState(int cooldownDays) async {
    final lastCustomShown = await getLastCustomShownDate();
    final now = DateTime.now();

    bool isInCooldown = false;
    if (lastCustomShown != null) {
      final daysSince = now.difference(lastCustomShown).inDays;
      isInCooldown = daysSince < cooldownDays;
    }

    return RateUsState(
      nativeCalledToday: await getNativeCalledToday(),
      assumedRatedCustom: await getAssumedRatedCustom(),
      isInCooldown: isInCooldown,
      dailyCustomCount: await getDailyCustomCount(),
      customDismissalCount: await getCustomDismissalCount(),
      lastNativeAttemptDate: await getLastNativeAttemptDate(),
      lastCustomShownDate: lastCustomShown,
      firstInstallDate: await getFirstInstallDate(),
    );
  }

  // Reset daily flags (call at midnight)
  Future<void> resetDailyFlags() async {
    await setNativeCalledToday(false);
    await setDailyCustomCount(0);
    AppLogger.i('Daily flags reset', tag: 'Repository');
  }

  // Complete reset
  Future<void> resetAll() async {
    await _prefs.remove(_keyFirstInstallDate);
    await _prefs.remove(_keyLastNativeAttemptDate);
    await _prefs.remove(_keyLastCustomShownDate);
    await _prefs.remove(_keyNativeCalledToday);
    await _prefs.remove(_keyAssumedRatedCustom);
    await _prefs.remove(_keyCustomDismissalCount);
    await _prefs.remove(_keyDailyCustomCount);
    await _prefs.remove(_keyAppOpens);
    await _prefs.remove(_keyCustomEvents);
    await _prefs.remove(_keyAutoTriggerCount);
    await _prefs.remove(_keyTotalNativeAttempts);
    AppLogger.s('All data reset', tag: 'Repository');
  }
}
