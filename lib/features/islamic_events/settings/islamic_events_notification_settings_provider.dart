import 'package:flutter/material.dart';
import 'package:islamic_app/features/islamic_events/notifications/islamic_events_notification_scheduler.dart';
import 'package:islamic_app/core/notifications/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IslamicEventsNotificationSettingsProvider extends ChangeNotifier {
  static const String _enabledKey = 'islamic_events_notifications_enabled';
  static const String _notifyBeforeEventKey =
      'islamic_events_notify_before_event';
  static const String _notifyBeforeDaysKey =
      'islamic_events_notify_before_days';
  static const String _fastingRemindersEnabledKey =
      'islamic_events_fasting_reminders_enabled';
  static const String _ramadanRemindersEnabledKey =
      'islamic_events_ramadan_reminders_enabled';
  static const String _eidGreetingsEnabledKey =
      'islamic_events_eid_greetings_enabled';
  static const String _specialDaysEnabledKey =
      'islamic_events_special_days_enabled';

  bool _isLoaded = false;
  bool _isChanging = false;

  bool _enabled = false;
  bool _notifyBeforeEvent = true;
  bool _fastingRemindersEnabled = true;
  bool _ramadanRemindersEnabled = true;
  bool _eidGreetingsEnabled = true;
  bool _specialDaysEnabled = true;

  int _notifyBeforeDays = 1;

  bool get isLoaded => _isLoaded;
  bool get isChanging => _isChanging;

  bool get enabled => _enabled;
  bool get notifyBeforeEvent => _notifyBeforeEvent;
  bool get fastingRemindersEnabled => _fastingRemindersEnabled;
  bool get ramadanRemindersEnabled => _ramadanRemindersEnabled;
  bool get eidGreetingsEnabled => _eidGreetingsEnabled;
  bool get specialDaysEnabled => _specialDaysEnabled;

  int get notifyBeforeDays => _notifyBeforeDays;

  String get notifyBeforeDaysText {
    if (_notifyBeforeDays == 1) return 'قبلها بيوم';
    if (_notifyBeforeDays == 2) return 'قبلها بيومين';
    return 'قبلها بـ $_notifyBeforeDays أيام';
  }

  IslamicEventsNotificationSettingsProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _enabled = prefs.getBool(_enabledKey) ?? false;
    _notifyBeforeEvent = prefs.getBool(_notifyBeforeEventKey) ?? true;
    _notifyBeforeDays = prefs.getInt(_notifyBeforeDaysKey) ?? 1;
    _fastingRemindersEnabled =
        prefs.getBool(_fastingRemindersEnabledKey) ?? true;
    _ramadanRemindersEnabled =
        prefs.getBool(_ramadanRemindersEnabledKey) ?? true;
    _eidGreetingsEnabled = prefs.getBool(_eidGreetingsEnabledKey) ?? true;
    _specialDaysEnabled = prefs.getBool(_specialDaysEnabledKey) ?? true;

    if (_notifyBeforeDays != 1 &&
        _notifyBeforeDays != 2 &&
        _notifyBeforeDays != 3) {
      _notifyBeforeDays = 1;
    }

    _isLoaded = true;
    notifyListeners();

    if (_enabled) {
      await _scheduleNotifications();
    }
  }

  Future<void> setEnabled(bool value) async {
    if (_isChanging) return;

    _isChanging = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    if (value) {
      final bool isAllowed =
      await NotificationService().requestNotificationPermission();

      if (isAllowed) {
        _enabled = true;
        await prefs.setBool(_enabledKey, true);

        await _scheduleNotifications();
      } else {
        _enabled = false;
        await prefs.setBool(_enabledKey, false);
      }
    } else {
      _enabled = false;
      await prefs.setBool(_enabledKey, false);

      await IslamicEventsNotificationScheduler()
          .cancelIslamicEventsNotifications();
    }

    _isChanging = false;
    notifyListeners();
  }

  Future<void> setNotifyBeforeEvent(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    _notifyBeforeEvent = value;
    await prefs.setBool(_notifyBeforeEventKey, value);

    notifyListeners();

    if (_enabled) {
      await _scheduleNotifications();
    }
  }

  Future<void> setNotifyBeforeDays(int days) async {
    if (days != 1 && days != 2 && days != 3) return;

    final prefs = await SharedPreferences.getInstance();

    _notifyBeforeDays = days;
    await prefs.setInt(_notifyBeforeDaysKey, days);

    notifyListeners();

    if (_enabled) {
      await _scheduleNotifications();
    }
  }

  Future<void> setFastingRemindersEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    _fastingRemindersEnabled = value;
    await prefs.setBool(_fastingRemindersEnabledKey, value);

    notifyListeners();

    if (_enabled) {
      await _scheduleNotifications();
    }
  }

  Future<void> setRamadanRemindersEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    _ramadanRemindersEnabled = value;
    await prefs.setBool(_ramadanRemindersEnabledKey, value);

    notifyListeners();

    if (_enabled) {
      await _scheduleNotifications();
    }
  }

  Future<void> setEidGreetingsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    _eidGreetingsEnabled = value;
    await prefs.setBool(_eidGreetingsEnabledKey, value);

    notifyListeners();

    if (_enabled) {
      await _scheduleNotifications();
    }
  }

  Future<void> setSpecialDaysEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    _specialDaysEnabled = value;
    await prefs.setBool(_specialDaysEnabledKey, value);

    notifyListeners();

    if (_enabled) {
      await _scheduleNotifications();
    }
  }

  Future<void> showTestNotification() async {
    final bool isAllowed =
    await NotificationService().requestNotificationPermission();

    if (!isAllowed) return;

    await IslamicEventsNotificationScheduler().showTestNotification();
  }

  Future<void> _scheduleNotifications() async {
    await IslamicEventsNotificationScheduler()
        .scheduleIslamicEventsNotifications(
      notifyBeforeEvent: _notifyBeforeEvent,
      notifyBeforeDays: _notifyBeforeDays,

      // بقيت false لأننا اتفقنا إن إشعارات المناسبات تكون قبلها فقط.
      notifyOnEventMorning: false,

      fastingRemindersEnabled: _fastingRemindersEnabled,
      ramadanRemindersEnabled: _ramadanRemindersEnabled,
      eidGreetingsEnabled: _eidGreetingsEnabled,
      specialDaysEnabled: _specialDaysEnabled,
    );
  }
}