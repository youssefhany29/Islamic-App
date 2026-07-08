import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:islamic_app/core/notifications/notification_service.dart';

class RecitationAchievementNotificationScheduler {
  RecitationAchievementNotificationScheduler._internal();

  static final RecitationAchievementNotificationScheduler _instance =
  RecitationAchievementNotificationScheduler._internal();

  factory RecitationAchievementNotificationScheduler() {
    return _instance;
  }

  static const int _baseNotificationId = 8200;
  static const int _notificationsCount = 300;

  static const String _channelId = 'recitation_achievements_channel_v1';
  static const String _channelName = 'Recitation Achievements';
  static const String _channelDescription =
      'Notifications for Quran recitation listening achievements and goals.';

  static const AndroidNotificationChannel _androidChannel =
  AndroidNotificationChannel(
    _channelId,
    _channelName,
    description: _channelDescription,
    importance: Importance.high,
  );

  Future<void> _ensureChannel() async {
    await NotificationService().createAndroidNotificationChannel(
      _androidChannel,
    );
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  int _stableNotificationId(String id) {
    return _baseNotificationId + id.hashCode.abs().remainder(_notificationsCount);
  }

  Future<void> showAchievementNotification({
    required String achievementId,
    required String title,
    required String message,
  }) async {
    try {
      await _ensureChannel();

      await NotificationService().plugin.show(
        _stableNotificationId('achievement_$achievementId'),
        title,
        message,
        _notificationDetails(),
        payload: NotificationService.openHomePayload,
      );
    } catch (error) {
      debugPrint('⚠️ Recitation achievement notification failed: $error');
    }
  }

  Future<void> showGoalNotification({
    required String goalId,
    required String title,
    required String message,
  }) async {
    try {
      await _ensureChannel();

      await NotificationService().plugin.show(
        _stableNotificationId('goal_$goalId'),
        title,
        message,
        _notificationDetails(),
        payload: NotificationService.openHomePayload,
      );
    } catch (error) {
      debugPrint('⚠️ Recitation goal notification failed: $error');
    }
  }

  Future<void> showTestNotification() async {
    try {
      await _ensureChannel();

      await NotificationService().plugin.show(
        _baseNotificationId,
        'إشعارات التلاوة 🎧',
        'تم تفعيل إشعارات جوائز وأهداف الاستماع بنجاح',
        _notificationDetails(),
        payload: NotificationService.openHomePayload,
      );
    } catch (error) {
      debugPrint('⚠️ Recitation test notification failed: $error');
    }
  }

  Future<void> cancelRecitationNotifications() async {
    debugPrint('🎧 Cancelling Recitation Notifications...');

    for (int id = _baseNotificationId;
    id < _baseNotificationId + _notificationsCount;
    id++) {
      await NotificationService().cancelNotification(id);
    }

    await NotificationService().printPendingNotifications(
      detailed: true,
    );
  }
}