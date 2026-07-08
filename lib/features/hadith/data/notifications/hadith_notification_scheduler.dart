import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:islamic_app/core/notifications/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../services/hadith_memory_progress_service.dart';

class HadithNotificationScheduler {
  const HadithNotificationScheduler();

  static const int learnReminderId = 8101;
  static const int reviewReminderId = 8102;
  static const int reviewReminderRange = 14;

  static const String learnEnabledKey = 'hadith_learn_notifications_enabled';
  static const String reviewEnabledKey = 'hadith_review_notifications_enabled';

  static const String learnHourKey = 'hadith_learn_notification_hour';
  static const String learnMinuteKey = 'hadith_learn_notification_minute';
  static const String reviewHourKey = 'hadith_review_notification_hour';
  static const String reviewMinuteKey = 'hadith_review_notification_minute';

  static const String _channelId = 'hadith_reminders_channel';
  static const String _channelName = 'Hadith Reminders';
  static const String _channelDescription =
      'Reminders for learning and reviewing Hadith.';

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

  Future<void> ensureChannelCreated() async {
    const hadithChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );

    await NotificationService().createAndroidNotificationChannel(hadithChannel);
  }

  Future<void> scheduleAllEnabledFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    await ensureChannelCreated();
    await cancelAllHadithNotifications();

    final bool learnEnabled = prefs.getBool(learnEnabledKey) ?? true;
    final bool reviewEnabled = prefs.getBool(reviewEnabledKey) ?? true;

    if (learnEnabled) {
      await scheduleLearnHadithReminder(
        hour: prefs.getInt(learnHourKey) ?? 9,
        minute: prefs.getInt(learnMinuteKey) ?? 0,
      );
    }

    if (reviewEnabled) {
      await scheduleMemoryReviewReminder(
        hour: prefs.getInt(reviewHourKey) ?? 20,
        minute: prefs.getInt(reviewMinuteKey) ?? 30,
      );
    }
  }

  Future<void> scheduleLearnHadithReminder({
    required int hour,
    required int minute,
  }) async {
    await _scheduleDailyReminder(
      id: learnReminderId,
      title: 'تعلّم حديث اليوم 📘',
      body: 'اختار حديثًا جديدًا واقرأ فائدته وطبّق منه معنى واحد اليوم.',
      hour: hour,
      minute: minute,
    );
  }

  Future<void> scheduleMemoryReviewReminder({
    required int hour,
    required int minute,
  }) async {
    await ensureChannelCreated();
    await cancelMemoryReviewReminder();

    final bool planEnabled = await _isMemoryPlanEnabled();
    if (!planEnabled) {
      debugPrint('🔕 Hadith review skipped: memory plan disabled');
      return;
    }

    final states = await const HadithMemoryProgressService().getItemStates();
    if (states.isEmpty) {
      debugPrint('🔕 Hadith review skipped: no tracked items');
      return;
    }

    final today = _dateOnly(DateTime.now());
    int scheduledCount = 0;

    for (int dayOffset = 0; dayOffset < reviewReminderRange; dayOffset++) {
      final targetDate = today.add(Duration(days: dayOffset));
      final dueCount = _reviewCountForDate(
        states: states,
        targetDate: targetDate,
        includeOverdue: dayOffset == 0,
      );

      if (dueCount <= 0) continue;

      final scheduledTime = _reviewTimeForDate(
        targetDate: targetDate,
        hour: hour,
        minute: minute,
      );

      await NotificationService().plugin.zonedSchedule(
        reviewReminderId + dayOffset,
        'مراجعة حديث اليوم',
        dueCount == 1
            ? 'عندك حديث واحد مستحق للمراجعة اليوم.'
            : 'عندك $dueCount أحاديث مستحقة للمراجعة اليوم.',
        scheduledTime,
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: NotificationService.openHadithPayload,
      );

      scheduledCount++;
    }

    debugPrint(
      '🔔 Scheduled Hadith review notifications for $scheduledCount days at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
    );
  }

  Future<bool> _isMemoryPlanEnabled() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool('hadith_memory_plan_enabled') ?? true;
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  int _reviewCountForDate({
    required List<dynamic> states,
    required DateTime targetDate,
    required bool includeOverdue,
  }) {
    final targetOnly = _dateOnly(targetDate);

    return states.where((state) {
      final dueOnly = _dateOnly(state.nextReviewAt as DateTime);

      if (includeOverdue) {
        return !dueOnly.isAfter(targetOnly);
      }

      return dueOnly == targetOnly;
    }).length;
  }

  tz.TZDateTime _reviewTimeForDate({
    required DateTime targetDate,
    required int hour,
    required int minute,
  }) {
    final now = tz.TZDateTime.now(tz.local);

    var scheduledDate = tz.TZDateTime(
      tz.local,
      targetDate.year,
      targetDate.month,
      targetDate.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now) || scheduledDate.isAtSameMomentAs(now)) {
      scheduledDate = now.add(const Duration(minutes: 1));
    }

    return scheduledDate;
  }

  Future<void> refreshMemoryReviewReminderFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final bool globalEnabled = prefs.getBool('notifications_enabled') ?? false;
    final bool hadithEnabled =
        prefs.getBool(HadithNotificationSettingsKeys.enabledKey) ?? true;
    final bool reviewEnabled = prefs.getBool(reviewEnabledKey) ?? true;

    if (!globalEnabled || !hadithEnabled || !reviewEnabled) {
      await cancelMemoryReviewReminder();
      return;
    }

    await scheduleMemoryReviewReminder(
      hour: prefs.getInt(reviewHourKey) ?? 20,
      minute: prefs.getInt(reviewMinuteKey) ?? 30,
    );
  }

  Future<void> _scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await ensureChannelCreated();
    await NotificationService().cancelNotification(id);

    await NotificationService().plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour: hour, minute: minute),
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: NotificationService.openHadithPayload,
    );

    debugPrint(
      '🔔 Scheduled Hadith notification $id at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
    );
  }

  tz.TZDateTime _nextInstanceOfTime({required int hour, required int minute}) {
    final now = tz.TZDateTime.now(tz.local);

    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now) || scheduledDate.isAtSameMomentAs(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  Future<void> cancelLearnHadithReminder() async {
    await NotificationService().cancelNotification(learnReminderId);
  }

  Future<void> cancelMemoryReviewReminder() async {
    await _cancelRange(startId: reviewReminderId, count: reviewReminderRange);
  }

  Future<void> _cancelRange({required int startId, required int count}) async {
    for (int offset = 0; offset < count; offset++) {
      await NotificationService().plugin.cancel(startId + offset);
    }
  }

  Future<void> cancelAllHadithNotifications() async {
    await Future.wait([
      cancelLearnHadithReminder(),
      cancelMemoryReviewReminder(),
    ]);
  }
}

class HadithNotificationSettingsKeys {
  const HadithNotificationSettingsKeys._();

  static const String enabledKey = 'hadith_notifications_enabled';
}
