import '../enums/enums.dart';
import '../models/model.dart';
import '../services/services.dart';

class RateUsDialogStrategy {
  final RateUsConfig config;
  final RateUsState state;
  final TriggerType triggerType;

  RateUsDialogStrategy({
    required this.config,
    required this.state,
    required this.triggerType,
  });

  /// Main decision tree
  Future<DialogDecision> decide() async {
    AppLogger.section('RATE US DECISION ENGINE');
    AppLogger.d('Trigger: ${triggerType.analyticsName}', tag: 'Strategy');

    // GATE 1: Feature enabled?
    if (config.rateUsInitialize != 1) {
      AppLogger.w('Gate 1 FAILED: Feature disabled', tag: 'Strategy');
      return DialogDecision.abort('feature_disabled');
    }
    AppLogger.s('Gate 1 PASSED: Feature enabled', tag: 'Strategy');

    // GATE 2: Already rated via custom?
    if (state.assumedRatedCustom) {
      AppLogger.w(
        'Gate 2 BYPASS: User already rated via custom',
        tag: 'Strategy',
      );
      return _handleNativeOnlyBranch();
    }
    AppLogger.s('Gate 2 PASSED: No custom rating yet', tag: 'Strategy');

    // GATE 3: In cooldown?
    if (state.isInCooldown) {
      AppLogger.w(
        'Gate 3 FAILED: In cooldown period',
        tag: 'Strategy',
        data: {
          'last_custom_shown': state.lastCustomShownDate?.toString() ?? 'never',
          'cooldown_days': config.cooldownDays,
        },
      );
      return DialogDecision.abort('in_cooldown');
    }
    AppLogger.s('Gate 3 PASSED: Not in cooldown', tag: 'Strategy');

    // GATE 4: Native already called today?
    if (state.nativeCalledToday) {
      AppLogger.i(
        'Gate 4: Native already called today, going to custom',
        tag: 'Strategy',
      );
      return _handleCustomBranch();
    }
    AppLogger.s('Gate 4 PASSED: Native not called today', tag: 'Strategy');

    // Default: Native first branch
    return _handleNativeFirstBranch();
  }

  DialogDecision _handleNativeFirstBranch() {
    AppLogger.i('📍 Branch: NATIVE_FIRST', tag: 'Strategy');
    return DialogDecision.showNativeThenCustom();
  }

  DialogDecision _handleCustomBranch() {
    AppLogger.i('📍 Branch: CUSTOM', tag: 'Strategy');

    // Check daily limit
    if (state.dailyCustomCount >= config.maxCustomPerDay) {
      AppLogger.w(
        'Daily custom limit reached: ${state.dailyCustomCount}/${config.maxCustomPerDay}',
        tag: 'Strategy',
      );
      return DialogDecision.abort('daily_custom_limit');
    }

    // Check dismissal count (permanent opt-out after 3)
    if (state.customDismissalCount >= 3) {
      AppLogger.w(
        'Permanent opt-out: ${state.customDismissalCount} dismissals',
        tag: 'Strategy',
      );
      return DialogDecision.abort('permanent_optout');
    }

    return DialogDecision.showCustomOnly();
  }

  DialogDecision _handleNativeOnlyBranch() {
    AppLogger.i('📍 Branch: NATIVE_ONLY (post-custom rating)', tag: 'Strategy');

    if (state.nativeCalledToday) {
      AppLogger.w('Native already called today, aborting', tag: 'Strategy');
      return DialogDecision.abort('native_already_today');
    }

    return DialogDecision.showNativeOnly();
  }
}

/// Decision result from the strategy
class DialogDecision {
  final bool showNative;
  final bool showCustom;
  final bool showCustomAfterNative;
  final String? abortReason;

  const DialogDecision._({
    required this.showNative,
    required this.showCustom,
    required this.showCustomAfterNative,
    this.abortReason,
  });

  factory DialogDecision.showNativeThenCustom() {
    return const DialogDecision._(
      showNative: true,
      showCustom: true,
      showCustomAfterNative: true,
    );
  }

  factory DialogDecision.showNativeOnly() {
    return const DialogDecision._(
      showNative: true,
      showCustom: false,
      showCustomAfterNative: false,
    );
  }

  factory DialogDecision.showCustomOnly() {
    return const DialogDecision._(
      showNative: false,
      showCustom: true,
      showCustomAfterNative: false,
    );
  }

  factory DialogDecision.abort(String reason) {
    return DialogDecision._(
      showNative: false,
      showCustom: false,
      showCustomAfterNative: false,
      abortReason: reason,
    );
  }

  bool get shouldAbort => abortReason != null;
}
