import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:islamic_app/core/notifications/notification_service.dart';
import 'quran_reminder_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:typed_data';

class QuranReminderScheduler {
  QuranReminderScheduler._internal();

  static final QuranReminderScheduler _instance =
  QuranReminderScheduler._internal();

  factory QuranReminderScheduler() {
    return _instance;
  }

  static const int dailyQuranReminderId = 1001;

  static const String _channelId = 'daily_quran_reminders_channel_v2';
  static const String _channelName = 'Daily Quran Reminders';
  static const String _channelDescription =
      'Daily reminders for Quran reading.';

  static const AndroidNotificationChannel _androidChannel =
  AndroidNotificationChannel(
    _channelId,
    _channelName,
    description: _channelDescription,
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  final List<String> _quranReminderBodies = const [
    'حان وقت وردك اليومي من القرآن الكريم 📖',
    'دقائق مع القرآن تغيّر يومك بإذن الله 🌙',
    'لا تنس وردك اليوم، افتح المصحف وابدأ الآن 🤍',
    'اجعل لك نصيبًا من كتاب الله اليوم ✨',
    'تذكير لطيف: ورد القرآن في انتظارك 📚',
    'ابدأ يومك بآيات من كتاب الله 🌿',
    'القرآن نور لقلبك، لا تنس وردك اليوم 💛',
    'خذ دقائق قليلة واملأ قلبك بالسكينة 📖',
    'وردك اليومي خطوة تقرّبك من الله 🤲',
    'افتح المصحف الآن، فرب آية تغيّر يومك 🌙',
    'لا تجعل يومك يمر دون تلاوة القرآن ✨',
    'موعدك مع القرآن قد حان 📚',
    'هدية لنفسك اليوم: دقائق مع كتاب الله 🤍',
    'اقترب من القرآن، تجد الراحة والطمأنينة 🌿',
    'ورد صغير اليوم خير من انقطاع طويل 📖',
    'اجعل القرآن صاحبك في يومك 💫',
    'تلاوة قليلة باستمرار خير من كثير منقطع 🌙',
    'قلبك يحتاج إلى القرآن، لا تؤخر وردك 🤍',
    'افتح المصحف وابدأ ولو بصفحة واحدة 📖',
    'تذكير جميل: لا تنس نصيبك من القرآن اليوم ✨',
    'آيات قليلة قد تكون سببًا في راحة قلبك 🌿',
    'استراحة قصيرة مع القرآن تصنع فرقًا كبيرًا 📚',
    'وردك اليوم ينتظرك، فابدأ الآن 🤲',
    'اجعل بينك وبين القرآن موعدًا لا ينقطع 💛',
    'دقائق مع كتاب الله تكفي لتجديد روحك 🌙',
    'لا تؤجل وردك، فالقرآن بركة يومك 📖',
    'افتح المصحف بنية القرب من الله 🤍',
    'القرآن حياة للقلوب، فاسقِ قلبك اليوم 🌿',
    'صفحة واحدة اليوم قد تفتح لك باب خير كبير ✨',
    'كن من أهل القرآن، وابدأ وردك الآن 📚',
  ];

  Future<void> _ensureQuranChannel() async {
    await NotificationService().createAndroidNotificationChannel(
      _androidChannel,
    );
  }

  NotificationDetails _notificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 600, 250, 600]),
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  String _randomQuranReminderBody() {
    final random = Random();

    return _quranReminderBodies[
    random.nextInt(_quranReminderBodies.length)];
  }

  Future<void> scheduleDailyQuranReminder({
    required int hour,
    required int minute,
  }) async {
    final reminderEnabled = await QuranReminderPreferences.isReminderEnabled();

    if (!reminderEnabled) {
      await cancelDailyQuranReminder();
      debugPrint('⚠️ Quran Wird Reminder Is Disabled');
      return;
    }

    await _ensureQuranChannel();

    await cancelDailyQuranReminder();

    final tz.TZDateTime scheduledTime = _nextInstanceOfTime(
      hour: hour,
      minute: minute,
    );

    final String reminderBody = _randomQuranReminderBody();

    debugPrint('📌 Daily Quran Reminder Scheduled At: $scheduledTime');

    await NotificationService().plugin.zonedSchedule(
      dailyQuranReminderId,
      'تذكير قراءة القرآن 📖',
      reminderBody,
      scheduledTime,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    await NotificationService().printPendingNotifications();
  }

  tz.TZDateTime _nextInstanceOfTime({
    required int hour,
    required int minute,
  }) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now) || scheduledDate.isAtSameMomentAs(now)) {
      scheduledDate = scheduledDate.add(
        const Duration(days: 1),
      );
    }

    return scheduledDate;
  }

  Future<void> cancelDailyQuranReminder() async {
    await NotificationService().cancelNotification(
      dailyQuranReminderId,
    );
  }
}