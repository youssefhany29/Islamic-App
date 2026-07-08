import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:islamic_app/core/notifications/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;

class PrayerTrackingNotificationScheduler {
  PrayerTrackingNotificationScheduler._internal();

  static final PrayerTrackingNotificationScheduler _instance =
  PrayerTrackingNotificationScheduler._internal();

  factory PrayerTrackingNotificationScheduler() {
    return _instance;
  }

  static const int _onTimeReminderBaseId = 4000;
  static const int _lastChanceBaseId = 5000;
  static const int _lockWarningBaseId = 5500;
  static const int _dailySummaryBaseId = 6000;
  static const int _achievementBaseId = 7000;

  static const String _trackingChannelId = 'prayer_tracking_channel_v1';
  static const String _trackingChannelName = 'Prayer Tracking Reminders';
  static const String _trackingChannelDescription =
      'Smart reminders for prayer progress and achievements.';

  static const AndroidNotificationChannel _trackingAndroidChannel =
  AndroidNotificationChannel(
    _trackingChannelId,
    _trackingChannelName,
    description: _trackingChannelDescription,
    importance: Importance.high,
  );

  static const List<String> _prayerNames = [
    'الفجر',
    'الظهر',
    'العصر',
    'المغرب',
    'العشاء',
  ];

  static const List<String> _prayerKeys = [
    'fajr',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
  ];

  Future<void> _ensureTrackingChannel() async {
    await NotificationService().createAndroidNotificationChannel(
      _trackingAndroidChannel,
    );
  }

  NotificationDetails _trackingNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _trackingChannelId,
        _trackingChannelName,
        channelDescription: _trackingChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  Future<void> scheduleTrackingReminders({
    required List<Map<String, String>> prayerWeek,
    required List<String> selectedPrayers,
    int onTimeGraceMinutes = 60,
    int lastChanceBeforeNextPrayerMinutes = 30,
    int lockWarningBeforeMinutes = 5,
  }) async {
    await _ensureTrackingChannel();

    await cancelAllTrackingReminders();

    if (prayerWeek.isEmpty) {
      debugPrint('⚠️ Tracking reminders not scheduled: prayerWeek is empty.');
      return;
    }

    if (selectedPrayers.isEmpty) {
      debugPrint('⚠️ Tracking reminders not scheduled: no selected prayers.');
      return;
    }

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    for (int dayIndex = 0; dayIndex < prayerWeek.length; dayIndex++) {
      final Map<String, String> day = prayerWeek[dayIndex];

      for (int prayerIndex = 0; prayerIndex < _prayerNames.length; prayerIndex++) {
        final String prayerName = _prayerNames[prayerIndex];
        final String prayerKey = _prayerKeys[prayerIndex];

        if (!selectedPrayers.contains(prayerName)) {
          continue;
        }

        final tz.TZDateTime? prayerDateTime = _buildPrayerDateTime(
          day: day,
          fallbackDayOffset: dayIndex,
          timeText: day[prayerKey],
        );

        if (prayerDateTime == null) {
          continue;
        }

        final tz.TZDateTime onTimeReminderTime = prayerDateTime.add(
          Duration(minutes: onTimeGraceMinutes),
        );

        if (onTimeReminderTime.isAfter(now)) {
          await NotificationService().plugin.zonedSchedule(
            _onTimeReminderNotificationId(dayIndex, prayerIndex),
            'حافظ على صلاة $prayerName في وقتها 🤍',
            'مرّت ساعة على دخول وقت $prayerName. حاول أن تجعلها في أول وقتها قدر الإمكان.',
            onTimeReminderTime,
            _trackingNotificationDetails(),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: NotificationService.openPrayerPayload,
          );
        }

        final tz.TZDateTime? nextPrayerDateTime = _getNextPrayerDateTime(
          prayerWeek: prayerWeek,
          dayIndex: dayIndex,
          prayerIndex: prayerIndex,
        );

        if (nextPrayerDateTime != null) {
          final tz.TZDateTime lastChanceTime = nextPrayerDateTime.subtract(
            Duration(minutes: lastChanceBeforeNextPrayerMinutes),
          );

          if (lastChanceTime.isAfter(now) &&
              lastChanceTime.isAfter(prayerDateTime)) {
            final tz.TZDateTime lockWarningTime = lastChanceTime.subtract(
              Duration(minutes: lockWarningBeforeMinutes),
            );

            if (lockWarningTime.isAfter(now) &&
                lockWarningTime.isAfter(prayerDateTime)) {
              await NotificationService().plugin.zonedSchedule(
                _lockWarningNotificationId(dayIndex, prayerIndex),
                'باقي ٥ دقائق على قفل تسجيل $prayerName ⏳',
                'قم للصلاة وسجّلها الآن حتى لا تفقد سلسلة تقدمك.',
                lockWarningTime,
                _trackingNotificationDetails(),
                androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
                payload: NotificationService.openPrayerPayload,
              );
            }

            await NotificationService().plugin.zonedSchedule(
              _lastChanceNotificationId(dayIndex, prayerIndex),
              'تم قفل تسجيل $prayerName لهذا الوقت',
              'لو لم تصلِّها بعد فهي فائتة، وحاول المحافظة على الصلاة في وقتها القادم.',
              lastChanceTime,
              _trackingNotificationDetails(),
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              payload: NotificationService.openPrayerPayload,
            );
          }
        }
      }
    }

    debugPrint('✅ Prayer tracking reminders scheduled.');
  }

  Future<void> scheduleDailyProgressSummary({
    required int completedCount,
    required int totalCount,
    int hour = 22,
    int minute = 0,
  }) async {
    await _ensureTrackingChannel();

    await NotificationService().cancelNotification(_dailySummaryBaseId);

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime targetTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (targetTime.isBefore(now)) {
      targetTime = targetTime.add(const Duration(days: 1));
    }

    final String message = completedCount >= totalCount
        ? 'ما شاء الله، أكملت صلوات اليوم كلها. ربنا يثبتك 🤍'
        : 'أكملت $completedCount من $totalCount صلوات. استمر، تقدمك مهم.';

    await NotificationService().plugin.zonedSchedule(
      _dailySummaryBaseId,
      'ملخص صلواتك اليوم 🌙',
      message,
      targetTime,
      _trackingNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: NotificationService.openPrayerPayload,
    );

    debugPrint('📌 Daily prayer summary scheduled at $targetTime');
  }

  Future<void> showAchievementNotification({
    required String title,
    required String message,
  }) async {
    await _ensureTrackingChannel();

    await NotificationService().plugin.show(
      _achievementBaseId + DateTime.now().millisecondsSinceEpoch.remainder(999),
      title,
      message,
      _trackingNotificationDetails(),
      payload: NotificationService.openPrayerPayload,
    );
  }

  Future<void> showLatePrayerNotification({
    required String prayerName,
  }) async {
    await _ensureTrackingChannel();

    await NotificationService().plugin.show(
      _achievementBaseId + 1501,
      'تم قضاؤها 🤍',
      'تم تسجيل صلاة $prayerName كقضاء لأنها صُلّيت في غير موعدها. ربنا يعينك على أدائها في وقتها.',
      _trackingNotificationDetails(),
      payload: NotificationService.openPrayerPayload,
    );
  }

  Future<void> showOnePrayerRemainingNotification() async {
    await _ensureTrackingChannel();

    await NotificationService().plugin.show(
      _achievementBaseId + 1001,
      'باقي صلاة واحدة وتكمل يومك 🌿',
      'أنت قريب جدًا من إكمال صلوات اليوم. ربنا يثبتك ويعينك 🤍',
      _trackingNotificationDetails(),
      payload: NotificationService.openPrayerPayload,
    );
  }

  Future<void> showTestNotification() async {
    await _ensureTrackingChannel();

    await NotificationService().plugin.show(
      _achievementBaseId + 2001,
      'اختبار الإشعار ✅',
      'الإشعارات تعمل بنجاح. ربنا يثبتك على الصلاة 🤍',
      _trackingNotificationDetails(),
      payload: NotificationService.openPrayerPayload,
    );
  }

  Future<void> scheduleAfterPrayerAzkarReminder({
    required String prayerName,
    int afterMinutes = 2,
  }) async {
    await _ensureTrackingChannel();

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    final tz.TZDateTime targetTime = now.add(
      Duration(minutes: afterMinutes),
    );

    await NotificationService().plugin.zonedSchedule(
      _afterPrayerAzkarNotificationId(),
      'لا تنسَ أذكار بعد الصلاة 🌿',
      'بعد صلاة $prayerName، خذ دقيقة لذكر الله وطمأنينة قلبك.',
      targetTime,
      _trackingNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: NotificationService.openPrayerPayload,
    );
  }

  Future<void> cancelAfterPrayerAzkarReminder() async {
    await NotificationService().cancelNotification(
      _afterPrayerAzkarNotificationId(),
    );
  }

  Future<void> cancelTrackingRemindersForPrayer({
    required int dayIndex,
    required int prayerIndex,
  }) async {
    await NotificationService().cancelNotification(
      _onTimeReminderNotificationId(dayIndex, prayerIndex),
    );

    await NotificationService().cancelNotification(
      _lastChanceNotificationId(dayIndex, prayerIndex),
    );

    await NotificationService().cancelNotification(
      _lockWarningNotificationId(dayIndex, prayerIndex),
    );

    debugPrint(
      '🧹 Cancelled tracking reminders for dayIndex=$dayIndex prayerIndex=$prayerIndex',
    );
  }

  Future<void> cancelDailySummaryReminder() async {
    await NotificationService().cancelNotification(_dailySummaryBaseId);
  }

  Future<void> cancelAllTrackingReminders() async {
    for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
      for (int prayerIndex = 0; prayerIndex < _prayerNames.length; prayerIndex++) {
        await NotificationService().cancelNotification(
          _onTimeReminderNotificationId(dayIndex, prayerIndex),
        );

        await NotificationService().cancelNotification(
          _lastChanceNotificationId(dayIndex, prayerIndex),
        );

        await NotificationService().cancelNotification(
          _lockWarningNotificationId(dayIndex, prayerIndex),
        );
      }
    }

    await NotificationService().cancelNotification(_dailySummaryBaseId);
    await cancelAfterPrayerAzkarReminder();

    debugPrint('🧹 All prayer tracking reminders cancelled.');
  }

  int _afterPrayerAzkarNotificationId() {
    return _achievementBaseId + 3001;
  }

  int _onTimeReminderNotificationId(int dayIndex, int prayerIndex) {
    return _onTimeReminderBaseId + (dayIndex * 10) + prayerIndex;
  }

  int _lastChanceNotificationId(int dayIndex, int prayerIndex) {
    return _lastChanceBaseId + (dayIndex * 10) + prayerIndex;
  }

  int _lockWarningNotificationId(int dayIndex, int prayerIndex) {
    return _lockWarningBaseId + (dayIndex * 10) + prayerIndex;
  }

  String _nextPrayerName(int prayerIndex) {
    final int nextIndex = prayerIndex + 1 >= _prayerNames.length
        ? 0
        : prayerIndex + 1;

    return _prayerNames[nextIndex];
  }

  tz.TZDateTime? _getNextPrayerDateTime({
    required List<Map<String, String>> prayerWeek,
    required int dayIndex,
    required int prayerIndex,
  }) {
    int nextDayIndex = dayIndex;
    int nextPrayerIndex = prayerIndex + 1;

    if (nextPrayerIndex >= _prayerKeys.length) {
      nextPrayerIndex = 0;
      nextDayIndex = dayIndex + 1;
    }

    if (nextDayIndex >= prayerWeek.length) {
      return null;
    }

    return _buildPrayerDateTime(
      day: prayerWeek[nextDayIndex],
      fallbackDayOffset: nextDayIndex,
      timeText: prayerWeek[nextDayIndex][_prayerKeys[nextPrayerIndex]],
    );
  }

  tz.TZDateTime? _buildPrayerDateTime({
    required Map<String, String> day,
    required int fallbackDayOffset,
    required String? timeText,
  }) {
    if (timeText == null || !timeText.contains(':')) {
      return null;
    }

    final List<String> parts = timeText.split(':');

    if (parts.length != 2) {
      return null;
    }

    final int? hour = int.tryParse(parts[0]);
    final int? minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) {
      return null;
    }

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    final tz.TZDateTime fallbackDay = now.add(
      Duration(days: fallbackDayOffset),
    );

    final DateTime? parsedDate = _parseDateKey(day['date']);

    return tz.TZDateTime(
      tz.local,
      parsedDate?.year ?? fallbackDay.year,
      parsedDate?.month ?? fallbackDay.month,
      parsedDate?.day ?? fallbackDay.day,
      hour,
      minute,
    );
  }

  DateTime? _parseDateKey(String? dateKey) {
    if (dateKey == null || dateKey.isEmpty) {
      return null;
    }

    final List<String> parts = dateKey.split('-');

    if (parts.length != 3) {
      return null;
    }

    final int? year = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    final int? day = int.tryParse(parts[2]);

    if (year == null || month == null || day == null) {
      return null;
    }

    return DateTime(year, month, day);
  }
}
