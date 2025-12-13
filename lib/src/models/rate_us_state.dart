class RateUsState {
  final bool nativeCalledToday;
  final bool assumedRatedCustom;
  final bool isInCooldown;
  final int dailyCustomCount;
  final int customDismissalCount;
  final DateTime? lastNativeAttemptDate;
  final DateTime? lastCustomShownDate;
  final DateTime? firstInstallDate;

  const RateUsState({
    required this.nativeCalledToday,
    required this.assumedRatedCustom,
    required this.isInCooldown,
    required this.dailyCustomCount,
    required this.customDismissalCount,
    this.lastNativeAttemptDate,
    this.lastCustomShownDate,
    this.firstInstallDate,
  });

  RateUsState copyWith({
    bool? nativeCalledToday,
    bool? assumedRatedCustom,
    bool? isInCooldown,
    int? dailyCustomCount,
    int? customDismissalCount,
    DateTime? lastNativeAttemptDate,
    DateTime? lastCustomShownDate,
    DateTime? firstInstallDate,
  }) {
    return RateUsState(
      nativeCalledToday: nativeCalledToday ?? this.nativeCalledToday,
      assumedRatedCustom: assumedRatedCustom ?? this.assumedRatedCustom,
      isInCooldown: isInCooldown ?? this.isInCooldown,
      dailyCustomCount: dailyCustomCount ?? this.dailyCustomCount,
      customDismissalCount: customDismissalCount ?? this.customDismissalCount,
      lastNativeAttemptDate:
          lastNativeAttemptDate ?? this.lastNativeAttemptDate,
      lastCustomShownDate: lastCustomShownDate ?? this.lastCustomShownDate,
      firstInstallDate: firstInstallDate ?? this.firstInstallDate,
    );
  }
}
