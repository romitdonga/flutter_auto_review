// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'enums/enums.dart';
import 'models/model.dart';
import 'services/services.dart';
import 'widgets/widget.dart';

class RateUsManager {
  static final RateUsManager _instance = RateUsManager._internal();
  factory RateUsManager() => _instance;
  RateUsManager._internal();

  late RateUsConfig _config;
  late RateUsRepository _repository;
  RateUsAnalytics? _analytics;
  final InAppReview _inAppReview = InAppReview.instance;

  bool _isInitialized = false;

  Future<void> init({
    required RateUsConfig config,
    RateUsAnalytics? analytics,
  }) async {
    if (_isInitialized) {
      AppLogger.w('Already initialized', tag: 'Manager');
      return;
    }

    AppLogger.section('INITIALIZING RATE US MANAGER');

    _config = config;
    _analytics = analytics;

    final prefs = await SharedPreferences.getInstance();
    _repository = RateUsRepository(prefs);

    final firstInstall = await _repository.getFirstInstallDate();
    if (firstInstall == null) {
      await _repository.setFirstInstallDate(DateTime.now());
      AppLogger.i('First install date set', tag: 'Manager');
    }

    await _repository.incrementAppOpens();
    final appOpens = await _repository.getAppOpens();
    AppLogger.i('App opens: $appOpens', tag: 'Manager');

    await _checkAndResetDaily();

    _isInitialized = true;
    _analytics?.logInitialized(config.toMap());
    AppLogger.s('Manager initialized successfully', tag: 'Manager');
  }

  Future<void> _checkAndResetDaily() async {
    final lastNative = await _repository.getLastNativeAttemptDate();
    final now = DateTime.now();

    if (lastNative != null) {
      final isSameDay =
          lastNative.year == now.year &&
          lastNative.month == now.month &&
          lastNative.day == now.day;

      if (!isSameDay) {
        await _repository.resetDailyFlags();
        _analytics?.logDailyReset();
        AppLogger.s('Daily reset performed', tag: 'Manager');
      }
    }
  }

  /// Main trigger method - handles all scenarios
  Future<void> onTrigger({
    required BuildContext context,
    required TriggerType type,
  }) async {
    if (!_isInitialized) {
      AppLogger.e('Manager not initialized', tag: 'Manager');
      return;
    }

    _analytics?.logTrigger(type);
    AppLogger.section('TRIGGER: ${type.analyticsName.toUpperCase()}');

    final state = await _repository.loadState(_config.cooldownDays);

    final strategy = RateUsDialogStrategy(
      config: _config,
      state: state,
      triggerType: type,
    );
    final decision = await strategy.decide();

    // Handle decision
    if (decision.shouldAbort) {
      AppLogger.w('Trigger aborted: ${decision.abortReason}', tag: 'Manager');
      _logGateFailure(decision.abortReason!);
      return;
    }

    if (decision.showNative) {
      await _callNativeDialog(type);

      if (decision.showCustomAfterNative && context.mounted) {
        await Future.delayed(const Duration(minutes: 2));
        if (context.mounted) {
          await _showCustomDialog(context, type);
        }
      }
    } else if (decision.showCustom) {
      await _showCustomDialog(context, type);
    }
  }

  Future<void> _callNativeDialog(TriggerType trigger) async {
    try {
      AppLogger.i('Calling native dialog', tag: 'Manager');

      final isAvailable = await _inAppReview.isAvailable();

      if (isAvailable) {
        await _inAppReview.requestReview();
        await _repository.setNativeCalledToday(true);
        await _repository.setLastNativeAttemptDate(DateTime.now());
        await _repository.incrementTotalNativeAttempts();

        _analytics?.logNativeCalled(trigger);
        AppLogger.s('Native dialog called successfully', tag: 'Manager');
      } else {
        _analytics?.logNativeFailed('not_available');
        AppLogger.w('Native dialog not available', tag: 'Manager');
      }
    } catch (e, stack) {
      _analytics?.logNativeFailed(e.toString());
      AppLogger.e(
        'Native dialog error',
        tag: 'Manager',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> _showCustomDialog(
    BuildContext context,
    TriggerType trigger,
  ) async {
    try {
      AppLogger.i('Showing custom dialog', tag: 'Manager');

      // Increment daily count
      final currentCount = await _repository.getDailyCustomCount();
      await _repository.setDailyCustomCount(currentCount + 1);
      await _repository.setLastCustomShownDate(DateTime.now());

      _analytics?.logCustomShown(trigger);

      final result = await showDialog<DialogAction>(
        context: context,
        barrierDismissible: false,
        builder: (context) => RateUsCustomDialog(triggerType: trigger),
      );

      await _handleCustomDialogAction(result);
    } catch (e, stack) {
      AppLogger.e(
        'Custom dialog error',
        tag: 'Manager',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Handle custom dialog user action
  Future<void> _handleCustomDialogAction(DialogAction? action) async {
    if (action == null) {
      AppLogger.w('Dialog dismissed without action', tag: 'Manager');
      return;
    }

    switch (action) {
      case DialogAction.submit:
        await _handleCustomSubmit();
        break;
      case DialogAction.dismiss:
      case DialogAction.later:
        await _handleCustomDismiss();
        break;
    }
  }

  Future<void> _handleCustomSubmit() async {
    AppLogger.s('User submitted rating via custom dialog', tag: 'Manager');

    await _repository.setAssumedRatedCustom(true);
    _analytics?.logCustomSubmit(5);

    await _openPlayStore();
  }

  Future<void> _handleCustomDismiss() async {
    AppLogger.i('User dismissed custom dialog', tag: 'Manager');

    final currentDismissals = await _repository.getCustomDismissalCount();
    await _repository.setCustomDismissalCount(currentDismissals + 1);

    _analytics?.logCustomDismiss();

    AppLogger.w(
      'Dismissal count: ${currentDismissals + 1}',
      tag: 'Manager',
      data: {'cooldown_days': _config.cooldownDays},
    );
  }

  Future<void> _openPlayStore() async {
    try {
      String url;

      if (Platform.isAndroid) {
        final packageInfo = await PackageInfo.fromPlatform();
        url =
            "https://play.google.com/store/apps/details?id=${packageInfo.packageName}";
      } else if (Platform.isIOS && _config.appStoreId != null) {
        url =
            "https://apps.apple.com/app/id${_config.appStoreId}?action=write-review";
      } else {
        AppLogger.w('Cannot open store: No app store ID', tag: 'Manager');
        return;
      }

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _analytics?.logPlayStoreRedirect();
        AppLogger.s('Play Store opened: $url', tag: 'Manager');
      } else {
        AppLogger.e('Cannot launch URL: $url', tag: 'Manager');
      }
    } catch (e, stack) {
      AppLogger.e(
        'Error opening Play Store',
        tag: 'Manager',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Log gate failures to analytics
  void _logGateFailure(String reason) {
    switch (reason) {
      case 'feature_disabled':
        _analytics?.logGate1Failed();
        break;
      case 'already_rated_custom':
        _analytics?.logGate2Bypass();
        break;
      case 'in_cooldown':
        _analytics?.logGate3Cooldown();
        break;
      case 'native_already_today':
        _analytics?.logGate4NativeToday();
        break;
    }
  }

  Future<void> onAppOpen(BuildContext context) async {
    final appOpens = await _repository.getAppOpens();
    if (appOpens >= _config.minAppOpens) {
      await onTrigger(context: context, type: TriggerType.appOpen);
    } else {
      AppLogger.d(
        'App opens: $appOpens/${_config.minAppOpens}',
        tag: 'Manager',
      );
    }
  }

  Future<void> onCustomEvent(BuildContext context) async {
    if (!context.mounted) {
      AppLogger.e('Context not mounted for custom event', tag: 'Manager');
      return;
    }

    await _repository.incrementCustomEvents();
    final events = await _repository.getCustomEvents();

    if (events >= _config.minEvents && events % _config.minEvents == 0) {
      await onTrigger(context: context, type: TriggerType.customEvent);
    } else {
      AppLogger.d(
        'Custom events: $events/${_config.minEvents}',
        tag: 'Manager',
      );
    }
  }

  Future<void> onScreenTransition(BuildContext context) async {
    await _repository.incrementAutoTriggerCount();
    final count = await _repository.getAutoTriggerCount();

    if (count >= _config.autoTrigger) {
      await _repository.setAutoTriggerCount(0);
      await onTrigger(context: context, type: TriggerType.screenTransition);
    } else {
      AppLogger.d(
        'Screen transitions: $count/${_config.autoTrigger}',
        tag: 'Manager',
      );
    }
  }

  Future<void> onAppExit(BuildContext context) async {
    if (_config.exitTrigger == 1) {
      await onTrigger(context: context, type: TriggerType.appExit);
    }
  }

  Future<void> onSettingsTrigger(BuildContext context) async {
    if (!context.mounted) {
      AppLogger.e('Context not mounted for settings trigger', tag: 'Manager');
      return;
    }

    AppLogger.section('MANUAL TRIGGER FROM SETTINGS');

    try {
      await _callNativeDialog(TriggerType.manual);

      if (!context.mounted) {
        AppLogger.w('Context unmounted after native dialog', tag: 'Manager');
        return;
      }

      await Future.delayed(const Duration(milliseconds: 500));

      if (context.mounted) {
        await _showCustomDialog(context, TriggerType.manual);
      }
    } catch (e, stack) {
      AppLogger.e(
        'Settings trigger error',
        tag: 'Manager',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> reset() async {
    await _repository.resetAll();
    AppLogger.s('Manager reset complete', tag: 'Manager');
  }

  Future<RateUsState> getState() async {
    return await _repository.loadState(_config.cooldownDays);
  }
}
