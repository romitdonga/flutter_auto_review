import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models/rate_us_analytics.dart';
import 'models/rate_us_config.dart';
import 'widgets/rate_us_fallback_dialog.dart';

/// The main manager class for handling app review functionality
class RateUsManager {
  static final RateUsManager _instance = RateUsManager._internal();

  /// Singleton instance of the RateUsManager
  factory RateUsManager() => _instance;

  RateUsManager._internal();

  static const String _keyFirstInstallTime = 'rate_us_first_install_time';
  static const String _keyAppOpens = 'rate_us_app_opens';
  static const String _keyCustomEvents = 'rate_us_custom_events';
  static const String _keyAutoTriggerCount = 'rate_us_auto_trigger_count';
  static const String _keyLastDismissTime = 'rate_us_last_dismiss_time';
  static const String _keyConfig = 'rate_us_config';

  /// The InAppReview instance used to request reviews
  final InAppReview inAppReview = InAppReview.instance;

  /// The configuration for the rate us feature
  late RateUsConfig _config;

  /// The analytics handler for the rate us feature
  RateUsAnalytics? _analytics;

  /// The shared preferences instance used for storing data
  late SharedPreferences _prefs;

  /// Whether the manager has been initialized
  bool _isInitialized = false;

  /// Get the current configuration
  RateUsConfig get config => _config;

  /// Initialize the manager with the given configuration
  Future<void> init({
    required RateUsConfig config,
    RateUsAnalytics? analytics,
  }) async {
    if (_isInitialized) {
      debugPrint('RateUsManager already initialized');
      return;
    }

    _config = config;
    _analytics = analytics;
    _prefs = await SharedPreferences.getInstance();

    // Store first install time if not already stored
    if (!_prefs.containsKey(_keyFirstInstallTime)) {
      await _prefs.setInt(
        _keyFirstInstallTime,
        DateTime.now().millisecondsSinceEpoch,
      );
    }

    // Increment app opens count
    final int appOpens = _prefs.getInt(_keyAppOpens) ?? 0;
    await _prefs.setInt(_keyAppOpens, appOpens + 1);

    _isInitialized = true;

    _analytics?.logInitialized(_config.toMap());
    debugPrint('RateUsManager initialized with config: ${_config.toMap()}');
  }

  /// Reset all stored data (useful for testing)
  Future<void> reset() async {
    if (!_isInitialized) {
      debugPrint('RateUsManager not initialized');
      return;
    }

    await _prefs.remove(_keyFirstInstallTime);
    await _prefs.remove(_keyAppOpens);
    await _prefs.remove(_keyCustomEvents);
    await _prefs.remove(_keyAutoTriggerCount);
    await _prefs.remove(_keyLastDismissTime);

    debugPrint('RateUsManager reset');
  }

  /// Update the configuration
  void updateConfig(RateUsConfig newConfig) {
    _config = newConfig;
    _prefs.setString(_keyConfig, newConfig.toMap().toString());
    debugPrint('RateUsManager config updated: ${newConfig.toMap()}');
  }

  /// Check if the rate us dialog should be shown based on days since install
  Future<bool> _shouldShowBasedOnDaysSinceInstall() async {
    if (_config.rateUsInitialize != 1 || _config.minDaysSinceInstall <= 0) {
      return false;
    }

    final int firstInstallTime =
        _prefs.getInt(_keyFirstInstallTime) ??
        DateTime.now().millisecondsSinceEpoch;

    final int daysSinceInstall = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(firstInstallTime))
        .inDays;

    return daysSinceInstall >= _config.minDaysSinceInstall;
  }

  /// Check if the rate us dialog should be shown based on app opens
  bool _shouldShowBasedOnAppOpens() {
    if (_config.rateUsInitialize != 1 || _config.minAppOpens <= 0) {
      return false;
    }

    final int appOpens = _prefs.getInt(_keyAppOpens) ?? 0;
    return appOpens == _config.minAppOpens;
  }

  /// Check if the rate us dialog should be shown based on custom events
  bool _shouldShowBasedOnCustomEvents() {
    if (_config.rateUsInitialize != 1 || _config.minEvents <= 0) {
      return false;
    }

    final int customEvents = _prefs.getInt(_keyCustomEvents) ?? 0;
    return customEvents % _config.minEvents == 0 && customEvents > 0;
  }

  /// Check if the rate us dialog should be shown based on auto trigger count
  bool _shouldShowBasedOnAutoTrigger() {
    if (_config.rateUsInitialize != 1 || _config.autoTrigger <= 0) {
      return false;
    }

    final int autoTriggerCount = _prefs.getInt(_keyAutoTriggerCount) ?? 0;
    return autoTriggerCount == _config.autoTrigger;
  }

  /// Check if the cooldown period has passed since the last dismissal
  bool _hasCooldownPassed() {
    final int lastDismissTime = _prefs.getInt(_keyLastDismissTime) ?? 0;
    if (lastDismissTime == 0) {
      return true;
    }

    final int daysSinceDismiss = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(lastDismissTime))
        .inDays;

    return daysSinceDismiss >= _config.cooldownDays;
  }

  /// Check if the rate us dialog should be shown
  Future<bool> shouldShowRateDialog() async {
    if (!_isInitialized) {
      debugPrint('RateUsManager not initialized');
      return false;
    }

    // If the feature is disabled, don't show
    if (_config.rateUsInitialize != 1) {
      return false;
    }

    // Check if the cooldown period has passed
    if (!_hasCooldownPassed()) {
      return false;
    }

    // Check all trigger conditions
    final bool daysSinceInstallMet = await _shouldShowBasedOnDaysSinceInstall();
    final bool appOpensMet = _shouldShowBasedOnAppOpens();
    final bool customEventsMet = _shouldShowBasedOnCustomEvents();
    final bool autoTriggerMet = _shouldShowBasedOnAutoTrigger();

    return daysSinceInstallMet &&
        (appOpensMet || customEventsMet || autoTriggerMet);
  }

  /// Show the rate us dialog
  Future<void> showRateDialog(BuildContext context) async {
    if (!_isInitialized) {
      debugPrint('RateUsManager not initialized');
      return;
    }

    try {
      final bool isAvailable = await inAppReview.isAvailable();

      if (isAvailable) {
        _analytics?.logDialogShown();
        await inAppReview.requestReview();
        _analytics?.logRated();
      } else {
        _showFallbackDialog(context);
      }
    } catch (e) {
      debugPrint('Error showing rate dialog: $e');
      _showFallbackDialog(context);
    }
  }

  /// Show a fallback dialog if the native dialog fails
  Future<void> _showFallbackDialog(BuildContext context) async {
    _analytics?.logFallbackShown();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const RateUsFallbackDialog(),
    );

    if (result == true) {
      await _openStoreListing();
      _analytics?.logRated();
    } else {
      await _prefs.setInt(
        _keyLastDismissTime,
        DateTime.now().millisecondsSinceEpoch,
      );
      _analytics?.logDismissed();
    }
  }

  /// Open the store listing
  Future<void> _openStoreListing() async {
    try {
      if (Platform.isIOS && _config.appStoreId != null) {
        final url = 'https://apps.apple.com/app/id${_config.appStoreId}';
        await _launchUrl(url);
      } else if (Platform.isAndroid) {
        final packageInfo = await PackageInfo.fromPlatform();
        final url =
            'https://play.google.com/store/apps/details?id=${packageInfo.packageName}';
        await _launchUrl(url);
      } else {
        await inAppReview.openStoreListing(appStoreId: _config.appStoreId);
      }
      _analytics?.logStoreRedirect();
    } catch (e) {
      debugPrint('Error opening store listing: $e');
    }
  }

  /// Launch a URL
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  /// Manually trigger the rate us dialog
  Future<void> onSettingsTrigger(BuildContext context) async {
    if (!_isInitialized) {
      debugPrint('RateUsManager not initialized');
      return;
    }

    _analytics?.logTriggerCondition('settings');
    await showRateDialog(context);
  }

  /// Trigger the rate us dialog on app exit
  Future<void> onAppExit(BuildContext context) async {
    if (!_isInitialized ||
        _config.rateUsInitialize != 1 ||
        _config.exitTrigger != 1) {
      return;
    }

    if (!_hasCooldownPassed()) {
      return;
    }

    _analytics?.logTriggerCondition('exit');
    await showRateDialog(context);
  }

  /// Increment the custom events counter and check if the rate us dialog should be shown
  Future<bool> onCustomEvent() async {
    if (!_isInitialized || _config.rateUsInitialize != 1) {
      return false;
    }

    final int customEvents = _prefs.getInt(_keyCustomEvents) ?? 0;
    await _prefs.setInt(_keyCustomEvents, customEvents + 1);

    // Modified to not require days since install check for custom events
    final bool shouldShow =
        _shouldShowBasedOnCustomEvents() && _hasCooldownPassed();

    if (shouldShow) {
      _analytics?.logTriggerCondition('custom_event');
    }

    // Log the status
    logCustomEventStatus(
      customEvents: [customEvents.toString()],
      shouldShow: shouldShow,
      shouldShowBasedOnDaysSinceInstall: _shouldShowBasedOnDaysSinceInstall,
      shouldShowBasedOnCustomEvents: () => _shouldShowBasedOnCustomEvents(),
      hasCooldownPassed: () => _hasCooldownPassed(),
    );

    return shouldShow;
  }

  /// Increment the auto trigger counter and check if the rate us dialog should be shown
  Future<bool> onAutoTrigger() async {
    if (!_isInitialized || _config.rateUsInitialize != 1) {
      return false;
    }

    final int autoTriggerCount = _prefs.getInt(_keyAutoTriggerCount) ?? 0;

    if (autoTriggerCount + 1 >= _config.autoTrigger) {
      await _prefs.setInt(_keyAutoTriggerCount, 0);
    } else {
      await _prefs.setInt(_keyAutoTriggerCount, autoTriggerCount + 1);
    }

    final bool shouldShow =
        _shouldShowBasedOnAutoTrigger() &&
        await _shouldShowBasedOnDaysSinceInstall() &&
        _hasCooldownPassed();

    if (shouldShow) {
      _analytics?.logTriggerCondition('auto_trigger');
    }

    return shouldShow;
  }

  /// Check if the rate us dialog should be shown based on minimum days since install
  Future<bool> onMinDaysSinceInstall() async {
    if (!_isInitialized || _config.rateUsInitialize != 1) {
      return false;
    }

    final bool shouldShow =
        await _shouldShowBasedOnDaysSinceInstall() && _hasCooldownPassed();

    if (shouldShow) {
      _analytics?.logTriggerCondition('min_days_since_install');
    }

    return shouldShow;
  }

  /// Check if the rate us dialog should be shown based on minimum app opens
  Future<bool> onMinAppOpens() async {
    if (!_isInitialized || _config.rateUsInitialize != 1) {
      return false;
    }

    final bool shouldShow =
        _shouldShowBasedOnAppOpens() &&
        await _shouldShowBasedOnDaysSinceInstall() &&
        _hasCooldownPassed();

    if (shouldShow) {
      _analytics?.logTriggerCondition('min_app_opens');
    }

    return shouldShow;
  }
}

void logCustomEventStatus({
  required List<String> customEvents,
  required bool shouldShow,
  required Future<bool> Function() shouldShowBasedOnDaysSinceInstall,
  required bool Function() shouldShowBasedOnCustomEvents,
  required bool Function() hasCooldownPassed,
}) async {
  final now = DateTime.now();
  final timestamp =
      '${now.hour.toString().padLeft(2, '0')}:'
      '${now.minute.toString().padLeft(2, '0')}:'
      '${now.second.toString().padLeft(2, '0')}';

  final log =
      '''
═══════════════════════════════════════════════════════════════════════════════
 Log Time: $timestamp
 Custom Events: $customEvents
⭐ Should Show 'Rate Us': $shouldShow

 Conditions:
 - Based on Custom Events      : ${shouldShowBasedOnCustomEvents()}
 - Based on Days Since Install : ${await shouldShowBasedOnDaysSinceInstall()}
 - Has Cooldown Passed         : ${hasCooldownPassed()}
═══════════════════════════════════════════════════════════════════════════════
''';

  debugPrint(log, wrapWidth: 100);
}
