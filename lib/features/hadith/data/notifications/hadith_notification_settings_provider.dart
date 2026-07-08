import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hadith_notification_scheduler.dart';

class HadithNotificationSettingsProvider extends ChangeNotifier {
  final HadithNotificationScheduler _scheduler =
      const HadithNotificationScheduler();

  static const String enabledKey = HadithNotificationSettingsKeys.enabledKey;

  bool _isLoaded = false;
  bool _isChanging = false;

  bool _enabled = true;
  bool _learnEnabled = true;
  bool _reviewEnabled = true;

  int _learnHour = 9;
  int _learnMinute = 0;

  int _reviewHour = 20;
  int _reviewMinute = 30;

  bool get isLoaded => _isLoaded;
  bool get isChanging => _isChanging;

  bool get enabled => _enabled;
  bool get learnEnabled => _learnEnabled;
  bool get reviewEnabled => _reviewEnabled;

  TimeOfDay get learnTime => TimeOfDay(hour: _learnHour, minute: _learnMinute);

  TimeOfDay get reviewTime =>
      TimeOfDay(hour: _reviewHour, minute: _reviewMinute);

  String get learnTimeText => _formatTime(_learnHour, _learnMinute);
  String get reviewTimeText => _formatTime(_reviewHour, _reviewMinute);

  HadithNotificationSettingsProvider() {
    load();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    _enabled = prefs.getBool(enabledKey) ?? true;

    _learnEnabled =
        prefs.getBool(HadithNotificationScheduler.learnEnabledKey) ?? true;
    _reviewEnabled =
        prefs.getBool(HadithNotificationScheduler.reviewEnabledKey) ?? true;

    _learnHour = prefs.getInt(HadithNotificationScheduler.learnHourKey) ?? 9;
    _learnMinute =
        prefs.getInt(HadithNotificationScheduler.learnMinuteKey) ?? 0;

    _reviewHour = prefs.getInt(HadithNotificationScheduler.reviewHourKey) ?? 20;
    _reviewMinute =
        prefs.getInt(HadithNotificationScheduler.reviewMinuteKey) ?? 30;

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    if (_isChanging) return;

    final prefs = await SharedPreferences.getInstance();

    _enabled = value;
    _isChanging = true;
    notifyListeners();

    await prefs.setBool(enabledKey, value);

    if (value) {
      await _scheduler.scheduleAllEnabledFromPrefs();
    } else {
      await _scheduler.cancelAllHadithNotifications();
    }

    _isChanging = false;
    notifyListeners();
  }

  Future<void> setLearnEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    _learnEnabled = value;
    notifyListeners();

    await prefs.setBool(HadithNotificationScheduler.learnEnabledKey, value);

    await _reschedule();
  }

  Future<void> setReviewEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    _reviewEnabled = value;
    notifyListeners();

    await prefs.setBool(HadithNotificationScheduler.reviewEnabledKey, value);

    await _reschedule();
  }

  Future<void> setLearnTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();

    _learnHour = time.hour;
    _learnMinute = time.minute;
    notifyListeners();

    await prefs.setInt(HadithNotificationScheduler.learnHourKey, time.hour);
    await prefs.setInt(HadithNotificationScheduler.learnMinuteKey, time.minute);

    await _reschedule();
  }

  Future<void> setReviewTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();

    _reviewHour = time.hour;
    _reviewMinute = time.minute;
    notifyListeners();

    await prefs.setInt(HadithNotificationScheduler.reviewHourKey, time.hour);
    await prefs.setInt(
      HadithNotificationScheduler.reviewMinuteKey,
      time.minute,
    );

    await _reschedule();
  }

  Future<void> syncWithGlobalNotifications(bool globalEnabled) async {
    if (!globalEnabled || !_enabled) {
      await _scheduler.cancelAllHadithNotifications();
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
        await _scheduler.cancelAllHadithNotifications();
      }
    } catch (error) {
      debugPrint('❌ Hadith notifications reschedule failed: $error');
    } finally {
      _isChanging = false;
      notifyListeners();
    }
  }

  String _formatTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
