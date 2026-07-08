import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileService {
  const UserProfileService();

  static const String userNameKey = 'user_name';
  static const String _defaultUserName = 'ضيفنا';

  static final ValueNotifier<String> userNameNotifier =
  ValueNotifier<String>(_defaultUserName);

  Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString(userNameKey)?.trim();

    if (savedName == null || savedName.isEmpty) {
      userNameNotifier.value = _defaultUserName;
      return _defaultUserName;
    }

    userNameNotifier.value = savedName;
    return savedName;
  }

  Future<void> setUserName(String name) async {
    final String cleanName = _cleanName(name);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userNameKey, cleanName);

    userNameNotifier.value = cleanName;
  }

  String _cleanName(String name) {
    final String trimmed = name.trim();

    if (trimmed.isEmpty) {
      return _defaultUserName;
    }

    if (trimmed.length <= 24) {
      return trimmed;
    }

    return trimmed.substring(0, 24).trim();
  }
}
