class RateUsConfig {
  /// Master switch: 1 enabled, 0 disabled
  final int rateUsInitialize;

  /// Minimum app opens (optional, if enabled)
  final int minAppOpens;

  /// Custom dialog cooldown days after CANCEL
  final int cooldownDays;

  /// App store id for iOS fallback
  final String? appStoreId;

  const RateUsConfig({
    this.rateUsInitialize = 1,
    this.minAppOpens = 0,
    this.cooldownDays = 2,
    this.appStoreId,
  });
}
