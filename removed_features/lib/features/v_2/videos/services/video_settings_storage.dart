import 'package:shared_preferences/shared_preferences.dart';

class VideoSettingsStorage {
  VideoSettingsStorage._();

  static const String _preferHdKey = 'video_prefer_hd_when_possible';

  static Future<bool> getPreferHd() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_preferHdKey) ?? false;
  }

  static Future<void> setPreferHd(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_preferHdKey, value);
  }
}