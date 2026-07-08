import 'package:shared_preferences/shared_preferences.dart';

class HadithMemoryPlanPreferences {
  const HadithMemoryPlanPreferences();

  static const String enabledKey = 'hadith_memory_plan_enabled';

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(enabledKey) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(enabledKey, value);
  }
}
