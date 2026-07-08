import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:islamic_app/core/notifications/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../services/zekr_memory_progress_service.dart';

class ZekrNotificationScheduler {
  const ZekrNotificationScheduler();

  static const int morningReminderId = 7101;
  static const int eveningReminderId = 7102;
  static const int sleepReminderId = 7103;
  static const int reviewReminderId = 7104;
  static const int reviewReminderRange = 14;

  static const int salawatBaseId = 7200;
  static const int duaRotationBaseId = 7300;
  static const int zekrRotationBaseId = 7400;

  static const int _rotatingNotificationsRange = 80;

  static const String morningEnabledKey = 'zekr_morning_notifications_enabled';
  static const String eveningEnabledKey = 'zekr_evening_notifications_enabled';
  static const String sleepEnabledKey = 'zekr_sleep_notifications_enabled';
  static const String reviewEnabledKey = 'zekr_review_notifications_enabled';

  static const String morningHourKey = 'zekr_morning_notification_hour';
  static const String morningMinuteKey = 'zekr_morning_notification_minute';
  static const String eveningHourKey = 'zekr_evening_notification_hour';
  static const String eveningMinuteKey = 'zekr_evening_notification_minute';
  static const String sleepHourKey = 'zekr_sleep_notification_hour';
  static const String sleepMinuteKey = 'zekr_sleep_notification_minute';
  static const String reviewHourKey = 'zekr_review_notification_hour';
  static const String reviewMinuteKey = 'zekr_review_notification_minute';

  static const String salawatEnabledKey = 'zekr_salawat_enabled';
  static const String duaRotationEnabledKey = 'zekr_dua_rotation_enabled';
  static const String zekrRotationEnabledKey = 'zekr_rotation_enabled';

  static const String salawatIntervalKey = 'zekr_salawat_interval';
  static const String duaIntervalKey = 'zekr_dua_interval';
  static const String zekrIntervalKey = 'zekr_interval';

  static const String _channelId = 'zekr_reminders_channel';
  static const String _channelName = 'Zekr Reminders';
  static const String _channelDescription =
      'Azkar and memory review reminders.';

  static const String _rotatingChannelId = 'zekr_rotating_channel';
  static const String _rotatingChannelName = 'إشعارات الأذكار المتغيرة';
  static const String _rotatingChannelDescription =
      'إشعارات متكررة للصلاة على النبي والأدعية والأذكار.';

  static const List<String> _salawatMessages = [
    'اللهم صل وسلم وبارك على نبينا محمد ﷺ',
    'صلِّ على النبي ﷺ، فالصلاة عليه نور وطمأنينة.',
    'اللهم صل على محمد وعلى آل محمد.',
    'أكثر من الصلاة على النبي ﷺ في يومك.',
  ];

  static const List<String> _duaMessages = [
    'اللهم إني أسألك العفو والعافية في الدنيا والآخرة.',
    'يا حي يا قيوم برحمتك أستغيث، أصلح لي شأني كله.',
    'ربنا آتنا في الدنيا حسنة وفي الآخرة حسنة وقنا عذاب النار.',
    'اللهم أعني على ذكرك وشكرك وحسن عبادتك.',
    'اللهم اجعل قلبي مطمئنًا بذكرك.',
  ];

  static const List<String> _zekrMessages = [
    'سبحان الله وبحمده.',
    'لا حول ولا قوة إلا بالله.',
    'أستغفر الله العظيم وأتوب إليه.',
    'سبحان الله، والحمد لله، ولا إله إلا الله، والله أكبر.',
    'لا إله إلا الله وحده لا شريك له.',
  ];

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

  NotificationDetails _rotatingNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _rotatingChannelId,
        _rotatingChannelName,
        channelDescription: _rotatingChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  Future<void> ensureChannelCreated() async {
    const zekrChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );

    const rotatingChannel = AndroidNotificationChannel(
      _rotatingChannelId,
      _rotatingChannelName,
      description: _rotatingChannelDescription,
      importance: Importance.high,
    );

    await NotificationService().createAndroidNotificationChannel(zekrChannel);
    await NotificationService().createAndroidNotificationChannel(
      rotatingChannel,
    );
  }

  Future<void> scheduleAllEnabledFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    await ensureChannelCreated();
    await cancelAllZekrNotifications();

    final bool morningEnabled = prefs.getBool(morningEnabledKey) ?? true;
    final bool eveningEnabled = prefs.getBool(eveningEnabledKey) ?? true;
    final bool sleepEnabled = prefs.getBool(sleepEnabledKey) ?? false;
    final bool reviewEnabled = prefs.getBool(reviewEnabledKey) ?? true;

    final bool salawatEnabled = prefs.getBool(salawatEnabledKey) ?? false;
    final bool duaRotationEnabled =
        prefs.getBool(duaRotationEnabledKey) ?? false;
    final bool zekrRotationEnabled =
        prefs.getBool(zekrRotationEnabledKey) ?? false;

    if (morningEnabled) {
      await scheduleMorningReminder(
        hour: prefs.getInt(morningHourKey) ?? 7,
        minute: prefs.getInt(morningMinuteKey) ?? 0,
      );
    }

    if (eveningEnabled) {
      await scheduleEveningReminder(
        hour: prefs.getInt(eveningHourKey) ?? 18,
        minute: prefs.getInt(eveningMinuteKey) ?? 0,
      );
    }

    if (sleepEnabled) {
      await scheduleSleepReminder(
        hour: prefs.getInt(sleepHourKey) ?? 22,
        minute: prefs.getInt(sleepMinuteKey) ?? 30,
      );
    }

    if (reviewEnabled) {
      await scheduleMemoryReviewReminder(
        hour: prefs.getInt(reviewHourKey) ?? 20,
        minute: prefs.getInt(reviewMinuteKey) ?? 30,
      );
    }

    if (salawatEnabled) {
      await scheduleSalawatRotation(
        intervalMinutes: prefs.getInt(salawatIntervalKey) ?? 60,
      );
    }

    if (duaRotationEnabled) {
      await scheduleDuaRotation(
        intervalMinutes: prefs.getInt(duaIntervalKey) ?? 120,
      );
    }

    if (zekrRotationEnabled) {
      await scheduleZekrRotation(
        intervalMinutes: prefs.getInt(zekrIntervalKey) ?? 180,
      );
    }
  }

  Future<void> scheduleMorningReminder({
    required int hour,
    required int minute,
  }) async {
    await _scheduleDailyReminder(
      id: morningReminderId,
      title: 'أذكار الصباح 🌿',
      body: 'ابدأ يومك بذكر الله وطمأنينة القلب.',
      hour: hour,
      minute: minute,
    );
  }

  Future<void> scheduleEveningReminder({
    required int hour,
    required int minute,
  }) async {
    await _scheduleDailyReminder(
      id: eveningReminderId,
      title: 'أذكار المساء 🌙',
      body: 'اختم يومك بذكر وسكينة وحفظ بإذن الله.',
      hour: hour,
      minute: minute,
    );
  }

  Future<void> scheduleSleepReminder({
    required int hour,
    required int minute,
  }) async {
    await _scheduleDailyReminder(
      id: sleepReminderId,
      title: 'أذكار النوم 🤍',
      body: 'نم على ذكر وطمأنينة.',
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
      debugPrint(
        '🔕 Memory review notifications skipped: memory plan disabled',
      );
      return;
    }

    final states = await const ZekrMemoryProgressService().getItemStates();
    if (states.isEmpty) {
      debugPrint('🔕 Memory review notifications skipped: no tracked items');
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
        'مراجعة حفظ الأذكار',
        dueCount == 1
            ? 'عندك ذكر واحد مستحق للمراجعة اليوم.'
            : 'عندك $dueCount أذكار مستحقة للمراجعة اليوم.',
        scheduledTime,
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: NotificationService.openZekrPayload,
      );

      scheduledCount++;
    }

    debugPrint(
      '🔔 Scheduled memory review notifications for $scheduledCount days at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
    );
  }

  Future<void> scheduleSalawatRotation({required int intervalMinutes}) async {
    await cancelSalawatRotation();

    await _scheduleRotatingNotifications(
      baseId: salawatBaseId,
      title: 'الصلاة على النبي ﷺ',
      messages: _salawatMessages,
      intervalMinutes: intervalMinutes,
    );
  }

  Future<void> scheduleDuaRotation({required int intervalMinutes}) async {
    await cancelDuaRotation();

    await _scheduleRotatingNotifications(
      baseId: duaRotationBaseId,
      title: 'دعاء اليوم',
      messages: _duaMessages,
      intervalMinutes: intervalMinutes,
    );
  }

  Future<void> scheduleZekrRotation({required int intervalMinutes}) async {
    await cancelZekrRotation();

    await _scheduleRotatingNotifications(
      baseId: zekrRotationBaseId,
      title: 'ذكر اليوم',
      messages: _zekrMessages,
      intervalMinutes: intervalMinutes,
    );
  }

  Future<void> _scheduleRotatingNotifications({
    required int baseId,
    required String title,
    required List<String> messages,
    required int intervalMinutes,
  }) async {
    await ensureChannelCreated();

    final int safeInterval = intervalMinutes < 1 ? 60 : intervalMinutes;

    // We do not schedule an unlimited number of notifications.
    // Short intervals get more queued notifications; longer intervals need fewer.
    final int count = safeInterval <= 5 ? 60 : 24;

    for (int index = 0; index < count; index++) {
      final scheduledTime = tz.TZDateTime.now(
        tz.local,
      ).add(Duration(minutes: safeInterval * (index + 1)));

      final message = messages[index % messages.length];

      await NotificationService().plugin.zonedSchedule(
        baseId + index,
        title,
        message,
        scheduledTime,
        _rotatingNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: NotificationService.openZekrPayload,
      );
    }

    debugPrint(
      '🔔 Scheduled rotating Zekr notifications: $title every $safeInterval minutes',
    );
  }

  Future<bool> _isMemoryPlanEnabled() async {
    final prefs = await SharedPreferences.getInstance();

    // نفس المفتاح المستخدم في خدمة خطة الحفظ.
    // لو المفتاح غير موجود عند مستخدم قديم، نخليها true حتى لا نعطل إشعاراته فجأة.
    return prefs.getBool('zekr_memory_plan_enabled') ?? true;
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

    // لو مراجعة اليوم ووقت التنبيه عدى، ابعته بعد دقيقة بدل ما نسيبه لبكرة.
    if (scheduledDate.isBefore(now) || scheduledDate.isAtSameMomentAs(now)) {
      scheduledDate = now.add(const Duration(minutes: 1));
    }

    return scheduledDate;
  }

  Future<void> refreshMemoryReviewReminderFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final bool globalEnabled =
        prefs.getBool('zekr_notifications_enabled') ?? true;
    final bool reviewEnabled = prefs.getBool(reviewEnabledKey) ?? true;

    if (!globalEnabled || !reviewEnabled) {
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
      payload: NotificationService.openZekrPayload,
    );

    debugPrint(
      '🔔 Scheduled Zekr notification $id at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
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

  Future<void> cancelMorningReminder() async {
    await NotificationService().cancelNotification(morningReminderId);
  }

  Future<void> cancelEveningReminder() async {
    await NotificationService().cancelNotification(eveningReminderId);
  }

  Future<void> cancelSleepReminder() async {
    await NotificationService().cancelNotification(sleepReminderId);
  }

  Future<void> cancelMemoryReviewReminder() async {
    await _cancelRange(startId: reviewReminderId, count: reviewReminderRange);
  }

  Future<void> cancelSalawatRotation() async {
    await _cancelRange(
      startId: salawatBaseId,
      count: _rotatingNotificationsRange,
    );
  }

  Future<void> cancelDuaRotation() async {
    await _cancelRange(
      startId: duaRotationBaseId,
      count: _rotatingNotificationsRange,
    );
  }

  Future<void> cancelZekrRotation() async {
    await _cancelRange(
      startId: zekrRotationBaseId,
      count: _rotatingNotificationsRange,
    );
  }

  Future<void> _cancelRange({required int startId, required int count}) async {
    for (int offset = 0; offset < count; offset++) {
      await NotificationService().plugin.cancel(startId + offset);
    }
  }

  Future<void> cancelAllZekrNotifications() async {
    await Future.wait([
      cancelMorningReminder(),
      cancelEveningReminder(),
      cancelSleepReminder(),
      cancelMemoryReviewReminder(),
      cancelSalawatRotation(),
      cancelDuaRotation(),
      cancelZekrRotation(),
    ]);
  }
}
