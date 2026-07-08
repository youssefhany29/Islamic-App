import 'package:flutter/material.dart';
import 'package:islamic_app/features/recitations/notifications/recitation_achievement_notification_scheduler.dart';
import 'package:islamic_app/core/notifications/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecitationNotificationSettingsProvider extends ChangeNotifier {
  static const String enabledKey = 'recitation_notifications_enabled';
  static const String achievementNotificationsEnabledKey =
      'recitation_achievement_notifications_enabled';
  static const String personalGoalNotificationsEnabledKey =
      'recitation_personal_goal_notifications_enabled';

  bool _isLoaded = false;
  bool _isChanging = false;

  bool _enabled = false;
  bool _achievementNotificationsEnabled = true;
  bool _personalGoalNotificationsEnabled = true;

  bool get isLoaded => _isLoaded;
  bool get isChanging => _isChanging;

  bool get enabled => _enabled;
  bool get achievementNotificationsEnabled => _achievementNotificationsEnabled;
  bool get personalGoalNotificationsEnabled => _personalGoalNotificationsEnabled;

  RecitationNotificationSettingsProvider() {
    loadSettings();
  }

  static Future<bool> canShowAchievementNotifications() async {
    final prefs = await SharedPreferences.getInstance();

    final enabled = prefs.getBool(enabledKey) ?? false;
    final achievementsEnabled =
        prefs.getBool(achievementNotificationsEnabledKey) ?? true;

    return enabled && achievementsEnabled;
  }

  static Future<bool> canShowPersonalGoalNotifications() async {
    final prefs = await SharedPreferences.getInstance();

    final enabled = prefs.getBool(enabledKey) ?? false;
    final goalsEnabled =
        prefs.getBool(personalGoalNotificationsEnabledKey) ?? true;

    return enabled && goalsEnabled;
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _enabled = prefs.getBool(enabledKey) ?? false;
    _achievementNotificationsEnabled =
        prefs.getBool(achievementNotificationsEnabledKey) ?? true;
    _personalGoalNotificationsEnabled =
        prefs.getBool(personalGoalNotificationsEnabledKey) ?? true;

    _isLoaded = true;
    notifyListeners();
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
        await prefs.setBool(enabledKey, true);
      } else {
        _enabled = false;
        await prefs.setBool(enabledKey, false);
      }
    } else {
      _enabled = false;
      await prefs.setBool(enabledKey, false);

      await RecitationAchievementNotificationScheduler()
          .cancelRecitationNotifications();
    }

    _isChanging = false;
    notifyListeners();
  }

  Future<void> setAchievementNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    _achievementNotificationsEnabled = value;
    await prefs.setBool(achievementNotificationsEnabledKey, value);

    notifyListeners();

    if (!_enabled || !value) {
      await RecitationAchievementNotificationScheduler()
          .cancelRecitationNotifications();
    }
  }

  Future<void> setPersonalGoalNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    _personalGoalNotificationsEnabled = value;
    await prefs.setBool(personalGoalNotificationsEnabledKey, value);

    notifyListeners();

    if (!_enabled || !value) {
      await RecitationAchievementNotificationScheduler()
          .cancelRecitationNotifications();
    }
  }

  Future<void> showTestNotification() async {
    final bool isAllowed =
    await NotificationService().requestNotificationPermission();

    if (!isAllowed) return;

    await RecitationAchievementNotificationScheduler().showTestNotification();
  }
}