import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper over SharedPreferences for the few flags GRID persists
/// locally.
class AppPrefs {
  AppPrefs(this._prefs);

  final SharedPreferences _prefs;

  static const _kOnboardingDone = 'onboarding_done';
  static const _kLoggedIn = 'logged_in';
  static const _kUserName = 'user_name';
  static const _kUserPhone = 'user_phone';
  static const _kUserEmail = 'user_email';

  bool get onboardingDone => _prefs.getBool(_kOnboardingDone) ?? false;
  Future<void> setOnboardingDone() => _prefs.setBool(_kOnboardingDone, true);

  bool get loggedIn => _prefs.getBool(_kLoggedIn) ?? false;
  String? get userName => _prefs.getString(_kUserName);
  String? get userPhone => _prefs.getString(_kUserPhone);
  String? get userEmail => _prefs.getString(_kUserEmail);

  Future<void> saveSession({
    required String name,
    required String phone,
    String? email,
  }) async {
    await _prefs.setBool(_kLoggedIn, true);
    await _prefs.setString(_kUserName, name);
    await _prefs.setString(_kUserPhone, phone);
    if (email != null) await _prefs.setString(_kUserEmail, email);
  }

  Future<void> clearSession() async {
    await _prefs.setBool(_kLoggedIn, false);
    await _prefs.remove(_kUserName);
    await _prefs.remove(_kUserPhone);
    await _prefs.remove(_kUserEmail);
  }
}
