import 'package:shared_preferences/shared_preferences.dart';

class AuthPrefs {
  static const String _biometricEnabledKey = 'biometricEnabled';
  static const String _savedPasscodeKey = 'savedPasscode';

  static Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  static Future<void> setSavedPasscode(String passcode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedPasscodeKey, passcode);
  }

  static Future<String?> getSavedPasscode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_savedPasscodeKey);
  }

  static Future<void> clearPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_biometricEnabledKey);
    await prefs.remove(_savedPasscodeKey);
  }
}
