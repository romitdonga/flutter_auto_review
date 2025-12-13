/// Configuration for the rate us feature
class RateUsConfig {
  /// Whether the rating feature is enabled (1) or disabled (0)
  final int rateUsInitialize;

  /// Minimum number of app opens before showing the rating dialog
  final int minAppOpens;

  /// Minimum number of custom events before showing the rating dialog
  final int minEvents;

  /// Number of screen transitions before auto-triggering the rating dialog
  final int autoTrigger;

  /// Whether to show rating dialog on app exit (1) or not (0)
  final int exitTrigger;

  /// Number of days to wait before showing the custom dialog again after dismissal
  final int cooldownDays;

  /// Maximum number of custom dialogs per day
  final int maxCustomPerDay;

  /// App Store ID for iOS (used for fallback)
  final String? appStoreId;

  const RateUsConfig({
    this.rateUsInitialize = 1,
    this.minAppOpens = 2,
    this.minEvents = 3,
    this.autoTrigger = 10,
    this.exitTrigger = 0,
    this.cooldownDays = 2,
    this.maxCustomPerDay = 3,
    this.appStoreId,
  });

  factory RateUsConfig.fromMap(Map<String, dynamic> map) {
    return RateUsConfig(
      rateUsInitialize: map['rateUS_initialize'] ?? 1,
      minAppOpens: map['rate_min_opens'] ?? 2,
      minEvents: map['rate_min_events'] ?? 3,
      autoTrigger: map['rate_auto_trigger'] ?? 10,
      exitTrigger: map['rate_exit'] ?? 0,
      cooldownDays: map['rate_cooldown_days'] ?? 2,
      maxCustomPerDay: map['max_custom_per_day'] ?? 3,
      appStoreId: map['app_store_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rateUS_initialize': rateUsInitialize,
      'rate_min_opens': minAppOpens,
      'rate_min_events': minEvents,
      'rate_auto_trigger': autoTrigger,
      'rate_exit': exitTrigger,
      'rate_cooldown_days': cooldownDays,
      'max_custom_per_day': maxCustomPerDay,
      'app_store_id': appStoreId,
    };
  }

  RateUsConfig copyWith({
    int? rateUsInitialize,
    int? minAppOpens,
    int? minEvents,
    int? autoTrigger,
    int? exitTrigger,
    int? cooldownDays,
    int? maxCustomPerDay,
    String? appStoreId,
  }) {
    return RateUsConfig(
      rateUsInitialize: rateUsInitialize ?? this.rateUsInitialize,
      minAppOpens: minAppOpens ?? this.minAppOpens,
      minEvents: minEvents ?? this.minEvents,
      autoTrigger: autoTrigger ?? this.autoTrigger,
      exitTrigger: exitTrigger ?? this.exitTrigger,
      cooldownDays: cooldownDays ?? this.cooldownDays,
      maxCustomPerDay: maxCustomPerDay ?? this.maxCustomPerDay,
      appStoreId: appStoreId ?? this.appStoreId,
    );
  }
}
