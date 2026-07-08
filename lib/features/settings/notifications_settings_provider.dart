import 'package:flutter/material.dart';
import 'package:islamic_app/core/notifications/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:islamic_app/features/quran/Notification/quran_reminder_scheduler.dart';
import 'package:islamic_app/features/azkar/data/notifications/zekr_notification_scheduler.dart';
import 'package:islamic_app/features/hadith/data/notifications/hadith_notification_scheduler.dart';

class NotificationsSettingsProvider extends ChangeNotifier {
  static const String _notificationsKey = 'notifications_enabled';
  static const String _reminderHourKey = 'reminder_hour';
  static const String _reminderMinuteKey = 'reminder_minute';
  static const String _hapticFeedbackKey = 'haptic_feedback_enabled';

  bool _notificationsEnabled = false;
  bool _hapticFeedbackEnabled = false;
  bool _isLoaded = false;
  bool _isChanging = false;

  int _reminderHour = 20;
  int _reminderMinute = 0;

  bool get notificationsEnabled => _notificationsEnabled;
  bool get hapticFeedbackEnabled => _hapticFeedbackEnabled;
  bool get isLoaded => _isLoaded;
  bool get isChanging => _isChanging;

  int get reminderHour => _reminderHour;
  int get reminderMinute => _reminderMinute;

  String get reminderTimeText {
    final String hour = _reminderHour.toString().padLeft(2, '0');
    final String minute = _reminderMinute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  NotificationsSettingsProvider() {
    loadNotificationSetting();
  }

  Future<void> loadNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();

    _notificationsEnabled = prefs.getBool(_notificationsKey) ?? false;
    _hapticFeedbackEnabled = prefs.getBool(_hapticFeedbackKey) ?? false;
    _reminderHour = prefs.getInt(_reminderHourKey) ?? 20;
    _reminderMinute = prefs.getInt(_reminderMinuteKey) ?? 0;

    _isLoaded = true;
    notifyListeners();

    if (_notificationsEnabled) {
      await QuranReminderScheduler().scheduleDailyQuranReminder(
        hour: _reminderHour,
        minute: _reminderMinute,
      );

      await const ZekrNotificationScheduler().scheduleAllEnabledFromPrefs();
      await const HadithNotificationScheduler().scheduleAllEnabledFromPrefs();
    }
  }

  Future<void> setNotificationsEnabled(bool value) async {
    if (_isChanging) return;

    _isChanging = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    if (value) {
      final bool isAllowed =
      await NotificationService().requestNotificationPermission();

      if (isAllowed) {
        _notificationsEnabled = true;
        await prefs.setBool(_notificationsKey, true);

        await QuranReminderScheduler().scheduleDailyQuranReminder(
          hour: _reminderHour,
          minute: _reminderMinute,
        );

        await const ZekrNotificationScheduler().scheduleAllEnabledFromPrefs();
        await const HadithNotificationScheduler().scheduleAllEnabledFromPrefs();

        await NotificationService().showTestNotification();
      } else {
        _notificationsEnabled = false;
        await prefs.setBool(_notificationsKey, false);
      }
    } else {
      _notificationsEnabled = false;
      await prefs.setBool(_notificationsKey, false);

      await QuranReminderScheduler().cancelDailyQuranReminder();
      await const ZekrNotificationScheduler().cancelAllZekrNotifications();
      await const HadithNotificationScheduler().cancelAllHadithNotifications();
    }

    _isChanging = false;
    notifyListeners();
  }

  Future<void> setReminderTime({
    required int hour,
    required int minute,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    _reminderHour = hour;
    _reminderMinute = minute;

    await prefs.setInt(_reminderHourKey, hour);
    await prefs.setInt(_reminderMinuteKey, minute);

    if (_notificationsEnabled) {
      await QuranReminderScheduler().scheduleDailyQuranReminder(
        hour: _reminderHour,
        minute: _reminderMinute,
      );
    }

    notifyListeners();
  }

  Future<void> setHapticFeedbackEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    _hapticFeedbackEnabled = value;
    await prefs.setBool(_hapticFeedbackKey, value);

    notifyListeners();
  }
}