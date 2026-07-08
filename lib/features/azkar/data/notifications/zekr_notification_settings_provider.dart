import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'zekr_notification_scheduler.dart';

class ZekrNotificationSettingsProvider extends ChangeNotifier {
  final ZekrNotificationScheduler _scheduler =
      const ZekrNotificationScheduler();

  static const String enabledKey = 'zekr_notifications_enabled';

  static const String salawatEnabledKey = 'zekr_salawat_enabled';
  static const String duaRotationEnabledKey = 'zekr_dua_rotation_enabled';
  static const String zekrRotationEnabledKey = 'zekr_rotation_enabled';

  static const String salawatIntervalKey = 'zekr_salawat_interval';
  static const String duaIntervalKey = 'zekr_dua_interval';
  static const String zekrIntervalKey = 'zekr_interval';

  bool _isLoaded = false;
  bool _isChanging = false;

  bool _enabled = true;

  bool _morningEnabled = true;
  bool _eveningEnabled = true;
  bool _sleepEnabled = false;
  bool _reviewEnabled = true;

  bool _salawatEnabled = false;
  bool _duaRotationEnabled = false;
  bool _zekrRotationEnabled = false;

  int _morningHour = 7;
  int _morningMinute = 0;

  int _eveningHour = 18;
  int _eveningMinute = 0;

  int _sleepHour = 22;
  int _sleepMinute = 30;

  int _reviewHour = 20;
  int _reviewMinute = 30;

  int _salawatIntervalMinutes = 60;
  int _duaIntervalMinutes = 120;
  int _zekrIntervalMinutes = 180;

  bool get isLoaded => _isLoaded;
  bool get isChanging => _isChanging;

  bool get enabled => _enabled;

  bool get morningEnabled => _morningEnabled;
  bool get eveningEnabled => _eveningEnabled;
  bool get sleepEnabled => _sleepEnabled;
  bool get reviewEnabled => _reviewEnabled;

  bool get salawatEnabled => _salawatEnabled;
  bool get duaRotationEnabled => _duaRotationEnabled;
  bool get zekrRotationEnabled => _zekrRotationEnabled;

  int get salawatIntervalMinutes => _salawatIntervalMinutes;
  int get duaIntervalMinutes => _duaIntervalMinutes;
  int get zekrIntervalMinutes => _zekrIntervalMinutes;

  TimeOfDay get morningTime =>
      TimeOfDay(hour: _morningHour, minute: _morningMinute);

  TimeOfDay get eveningTime =>
      TimeOfDay(hour: _eveningHour, minute: _eveningMinute);

  TimeOfDay get sleepTime => TimeOfDay(hour: _sleepHour, minute: _sleepMinute);

  TimeOfDay get reviewTime =>
      TimeOfDay(hour: _reviewHour, minute: _reviewMinute);

  String get morningTimeText => _formatTime(_morningHour, _morningMinute);
  String get eveningTimeText => _formatTime(_eveningHour, _eveningMinute);
  String get sleepTimeText => _formatTime(_sleepHour, _sleepMinute);
  String get reviewTimeText => _formatTime(_reviewHour, _reviewMinute);

  ZekrNotificationSettingsProvider() {
    load();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    _enabled = prefs.getBool(enabledKey) ?? true;

    _morningEnabled =
        prefs.getBool(ZekrNotificationScheduler.morningEnabledKey) ?? true;
    _eveningEnabled =
        prefs.getBool(ZekrNotificationScheduler.eveningEnabledKey) ?? true;
    _sleepEnabled =
        prefs.getBool(ZekrNotificationScheduler.sleepEnabledKey) ?? false;
    _reviewEnabled =
        prefs.getBool(ZekrNotificationScheduler.reviewEnabledKey) ?? true;

    _salawatEnabled = prefs.getBool(salawatEnabledKey) ?? false;
    _duaRotationEnabled = prefs.getBool(duaRotationEnabledKey) ?? false;
    _zekrRotationEnabled = prefs.getBool(zekrRotationEnabledKey) ?? false;

    _salawatIntervalMinutes = prefs.getInt(salawatIntervalKey) ?? 60;
    _duaIntervalMinutes = prefs.getInt(duaIntervalKey) ?? 120;
    _zekrIntervalMinutes = prefs.getInt(zekrIntervalKey) ?? 180;

    _morningHour = prefs.getInt(ZekrNotificationScheduler.morningHourKey) ?? 7;
    _morningMinute =
        prefs.getInt(ZekrNotificationScheduler.morningMinuteKey) ?? 0;

    _eveningHour = prefs.getInt(ZekrNotificationScheduler.eveningHourKey) ?? 18;
    _eveningMinute =
        prefs.getInt(ZekrNotificationScheduler.eveningMinuteKey) ?? 0;

    _sleepHour = prefs.getInt(ZekrNotificationScheduler.sleepHourKey) ?? 22;
    _sleepMinute = prefs.getInt(ZekrNotificationScheduler.sleepMinuteKey) ?? 30;

    _reviewHour = prefs.getInt(ZekrNotificationScheduler.reviewHourKey) ?? 20;
    _reviewMinute =
        prefs.getInt(ZekrNotificationScheduler.reviewMinuteKey) ?? 30;

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    _enabled = value;
    _isChanging = true;
    notifyListeners();

    await prefs.setBool(enabledKey, value);

    if (value) {
      await _scheduler.scheduleAllEnabledFromPrefs();
    } else {
      await _scheduler.cancelAllZekrNotifications();
    }

    _isChanging = false;
    notifyListeners();
  }

  Future<void> setMorningEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    _morningEnabled = value;
    notifyListeners();

    await prefs.setBool(ZekrNotificationScheduler.morningEnabledKey, value);

    await _reschedule();
  }

  Future<void> setEveningEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    _eveningEnabled = value;
    notifyListeners();

    await prefs.setBool(ZekrNotificationScheduler.eveningEnabledKey, value);

    await _reschedule();
  }

  Future<void> setSleepEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    _sleepEnabled = value;
    notifyListeners();

    await prefs.setBool(ZekrNotificationScheduler.sleepEnabledKey, value);

    await _reschedule();
  }

  Future<void> setReviewEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    _reviewEnabled = value;
    notifyListeners();

    await prefs.setBool(ZekrNotificationScheduler.reviewEnabledKey, value);

    await _reschedule();
  }

  Future<void> setMorningTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();

    _morningHour = time.hour;
    _morningMinute = time.minute;
    notifyListeners();

    await prefs.setInt(ZekrNotificationScheduler.morningHourKey, time.hour);
    await prefs.setInt(ZekrNotificationScheduler.morningMinuteKey, time.minute);

    await _reschedule();
  }

  Future<void> setEveningTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();

    _eveningHour = time.hour;
    _eveningMinute = time.minute;
    notifyListeners();

    await prefs.setInt(ZekrNotificationScheduler.eveningHourKey, time.hour);
    await prefs.setInt(ZekrNotificationScheduler.eveningMinuteKey, time.minute);

    await _reschedule();
  }

  Future<void> setSleepTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();

    _sleepHour = time.hour;
    _sleepMinute = time.minute;
    notifyListeners();

    await prefs.setInt(ZekrNotificationScheduler.sleepHourKey, time.hour);
    await prefs.setInt(ZekrNotificationScheduler.sleepMinuteKey, time.minute);

    await _reschedule();
  }

  Future<void> setReviewTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();

    _reviewHour = time.hour;
    _reviewMinute = time.minute;
    notifyListeners();

    await prefs.setInt(ZekrNotificationScheduler.reviewHourKey, time.hour);
    await prefs.setInt(ZekrNotificationScheduler.reviewMinuteKey, time.minute);

    await _reschedule();
  }

  Future<void> setSalawatEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    _salawatEnabled = value;
    notifyListeners();

    await prefs.setBool(salawatEnabledKey, value);

    await _reschedule();
  }

  Future<void> setDuaRotationEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    _duaRotationEnabled = value;
    notifyListeners();

    await prefs.setBool(duaRotationEnabledKey, value);

    await _reschedule();
  }

  Future<void> setZekrRotationEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    _zekrRotationEnabled = value;
    notifyListeners();

    await prefs.setBool(zekrRotationEnabledKey, value);

    await _reschedule();
  }

  Future<void> setSalawatIntervalMinutes(int value) async {
    final prefs = await SharedPreferences.getInstance();

    _salawatIntervalMinutes = value;
    notifyListeners();

    await prefs.setInt(salawatIntervalKey, value);

    await _reschedule();
  }

  Future<void> setDuaIntervalMinutes(int value) async {
    final prefs = await SharedPreferences.getInstance();

    _duaIntervalMinutes = value;
    notifyListeners();

    await prefs.setInt(duaIntervalKey, value);

    await _reschedule();
  }

  Future<void> setZekrIntervalMinutes(int value) async {
    final prefs = await SharedPreferences.getInstance();

    _zekrIntervalMinutes = value;
    notifyListeners();

    await prefs.setInt(zekrIntervalKey, value);

    await _reschedule();
  }

  Future<void> syncWithGlobalNotifications(bool globalEnabled) async {
    if (!globalEnabled || !_enabled) {
      await _scheduler.cancelAllZekrNotifications();
      return;
    }

    await _scheduler.scheduleAllEnabledFromPrefs();
  }

  Future<void> _reschedule() async {
    if (!_isLoaded) return;

    _isChanging = true;
    notifyListeners();

    try {
      if (_enabled) {
        await _scheduler.scheduleAllEnabledFromPrefs();
      } else {
        await _scheduler.cancelAllZekrNotifications();
      }
    } catch (error) {
      debugPrint('❌ Zekr notifications reschedule failed: $error');
    } finally {
      _isChanging = false;
      notifyListeners();
    }
  }

  String _formatTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
