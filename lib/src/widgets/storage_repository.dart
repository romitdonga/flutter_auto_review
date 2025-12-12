import 'package:shared_preferences/shared_preferences.dart';

class StorageRepository {
  static const _kFirstInstallDate = 'first_install_date';
  static const _kNativeCalledDate = 'native_called_date';
  static const _kAssumedRatedCustom = 'assumed_rated_custom';
  static const _kLastCustomCancel = 'last_custom_cancel';
  static const _kCustomShownCount = 'custom_shown_count';
  static const _kAppOpens = 'app_opens';

  final SharedPreferences _prefs;

  StorageRepository._(this._prefs);

  static Future<StorageRepository> init() async {
    final prefs = await SharedPreferences.getInstance();
    final repo = StorageRepository._(prefs);
    await repo._ensureFirstInstallDate();
    return repo;
  }

  Future<void> _ensureFirstInstallDate() async {
    if (!_prefs.containsKey(_kFirstInstallDate)) {
      await _prefs.setString(
        _kFirstInstallDate,
        DateTime.now().toIso8601String(),
      );
    }
  }

  DateTime get firstInstallDate {
    final s = _prefs.getString(_kFirstInstallDate);
    return s == null ? DateTime.now() : DateTime.parse(s);
  }

  String? get nativeCalledDate => _prefs.getString(_kNativeCalledDate);
  Future<void> setNativeCalledDate(String iso) =>
      _prefs.setString(_kNativeCalledDate, iso);

  bool get assumedRatedCustom => _prefs.getBool(_kAssumedRatedCustom) ?? false;
  Future<void> setAssumedRatedCustom(bool v) =>
      _prefs.setBool(_kAssumedRatedCustom, v);

  DateTime? get lastCustomCancel {
    final s = _prefs.getString(_kLastCustomCancel);
    return s == null ? null : DateTime.parse(s);
  }

  Future<void> setLastCustomCancel(DateTime dt) =>
      _prefs.setString(_kLastCustomCancel, dt.toIso8601String());

  int get customShownCount => _prefs.getInt(_kCustomShownCount) ?? 0;
  Future<void> incrementCustomShown() =>
      _prefs.setInt(_kCustomShownCount, customShownCount + 1);

  int get appOpens => _prefs.getInt(_kAppOpens) ?? 0;
  Future<void> incrementAppOpens() => _prefs.setInt(_kAppOpens, appOpens + 1);

  Future<void> resetDailyNativeFlag() async {
    // Typically called if date is different
    await _prefs.remove(_kNativeCalledDate);
  }

  bool nativeCalledToday() {
    final s = _prefs.getString(_kNativeCalledDate);
    if (s == null) return false;
    final dt = DateTime.parse(s);
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }
}
