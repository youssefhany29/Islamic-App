import 'package:shared_preferences/shared_preferences.dart';

class QuranReminderPreferences {
  static const String _enabledKey = 'quran_wird_reminder_enabled';
  static const String _hourKey = 'quran_wird_reminder_hour';
  static const String _minuteKey = 'quran_wird_reminder_minute';

  static const int defaultHour = 8;
  static const int defaultMinute = 0;

  static Future<QuranReminderSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final enabled = prefs.getBool(_enabledKey) ?? false;
    final hour = (prefs.getInt(_hourKey) ?? defaultHour).clamp(0, 23).toInt();
    final minute = (prefs.getInt(_minuteKey) ?? defaultMinute).clamp(0, 59).toInt();

    return QuranReminderSettings(
      enabled: enabled,
      hour: hour,
      minute: minute,
    );
  }

  static Future<bool> isReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  static Future<void> setReminderEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }

  static Future<void> setReminderTime({
    required int hour,
    required int minute,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hourKey, hour.clamp(0, 23).toInt());
    await prefs.setInt(_minuteKey, minute.clamp(0, 59).toInt());
  }

  static String formatReminderTime({
    required int hour,
    required int minute,
  }) {
    final safeHour = hour.clamp(0, 23).toInt();
    final safeMinute = minute.clamp(0, 59).toInt();
    final period = safeHour >= 12 ? 'م' : 'ص';
    final displayHour = safeHour % 12 == 0 ? 12 : safeHour % 12;
    final displayMinute = safeMinute.toString().padLeft(2, '0');

    return '$displayHour:$displayMinute $period';
  }
}

class QuranReminderSettings {
  final bool enabled;
  final int hour;
  final int minute;

  const QuranReminderSettings({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  String get timeText => QuranReminderPreferences.formatReminderTime(
    hour: hour,
    minute: minute,
  );

  QuranReminderSettings copyWith({
    bool? enabled,
    int? hour,
    int? minute,
  }) {
    return QuranReminderSettings(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }
}
