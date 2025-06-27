class RateUsConfig {
  /// Whether the rating feature is enabled (1) or disabled (0)
  final int rateUsInitialize;

  /// Minimum days since install before showing the rating dialog
  final int minDaysSinceInstall;

  /// Minimum number of app opens before showing the rating dialog
  final int minAppOpens;

  /// Minimum number of custom events before showing the rating dialog
  final int minEvents;

  /// Number of screen transitions before auto-triggering the rating dialog
  final int autoTrigger;

  /// Whether to show rating dialog on app exit (1) or not (0)
  final int exitTrigger;

  /// Number of days to wait before showing the rating dialog again after dismissal
  final int cooldownDays;

  /// App Store ID for iOS (used for fallback)
  final String? appStoreId;

  const RateUsConfig({
    this.rateUsInitialize = 1,
    this.minDaysSinceInstall = 3,
    this.minAppOpens = 5,
    this.minEvents = 3,
    this.autoTrigger = 10,
    this.exitTrigger = 0,
    this.cooldownDays = 30,
    this.appStoreId,
  });

  /// Creates a RateUsConfig from a map (e.g., from remote config)
  factory RateUsConfig.fromMap(Map<String, dynamic> map) {
    return RateUsConfig(
      rateUsInitialize: map['rateUS_initialize'] ?? 1,
      minDaysSinceInstall: map['rate_days_since_install'] ?? 3,
      minAppOpens: map['rate_min_opens'] ?? 5,
      minEvents: map['rate_min_events'] ?? 3,
      autoTrigger: map['rate_auto_trigger'] ?? 10,
      exitTrigger: map['rate_exit'] ?? 0,
      cooldownDays: map['rate_cooldown_days'] ?? 30,
      appStoreId: map['app_store_id'],
    );
  }

  /// Creates a copy of this config with the given fields replaced with new values
  RateUsConfig copyWith({
    int? rateUsInitialize,
    int? minDaysSinceInstall,
    int? minAppOpens,
    int? minEvents,
    int? autoTrigger,
    int? exitTrigger,
    int? cooldownDays,
    String? appStoreId,
  }) {
    return RateUsConfig(
      rateUsInitialize: rateUsInitialize ?? this.rateUsInitialize,
      minDaysSinceInstall: minDaysSinceInstall ?? this.minDaysSinceInstall,
      minAppOpens: minAppOpens ?? this.minAppOpens,
      minEvents: minEvents ?? this.minEvents,
      autoTrigger: autoTrigger ?? this.autoTrigger,
      exitTrigger: exitTrigger ?? this.exitTrigger,
      cooldownDays: cooldownDays ?? this.cooldownDays,
      appStoreId: appStoreId ?? this.appStoreId,
    );
  }

  /// Converts this config to a map
  Map<String, dynamic> toMap() {
    return {
      'rateUS_initialize': rateUsInitialize,
      'rate_days_since_install': minDaysSinceInstall,
      'rate_min_opens': minAppOpens,
      'rate_min_events': minEvents,
      'rate_auto_trigger': autoTrigger,
      'rate_exit': exitTrigger,
      'rate_cooldown_days': cooldownDays,
      'app_store_id': appStoreId,
    };
  }
}
