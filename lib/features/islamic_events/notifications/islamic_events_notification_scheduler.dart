import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:islamic_app/features/islamic_events/models/islamic_event_model.dart';
import 'package:islamic_app/features/islamic_events/services/islamic_events_service.dart';
import 'package:islamic_app/core/notifications/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;

class IslamicEventsNotificationScheduler {
  IslamicEventsNotificationScheduler._internal();

  static final IslamicEventsNotificationScheduler _instance =
  IslamicEventsNotificationScheduler._internal();

  factory IslamicEventsNotificationScheduler() {
    return _instance;
  }

  static const int _baseNotificationId = 7000;
  static const int _notificationsCount = 120;

  static const String _channelId = 'islamic_events_channel';
  static const String _channelName = 'Islamic Events Reminders';
  static const String _channelDescription =
      'Reminders for fasting days, Ramadan, Eid, Arafah and Islamic events.';

  static const AndroidNotificationChannel _androidChannel =
  AndroidNotificationChannel(
    _channelId,
    _channelName,
    description: _channelDescription,
    importance: Importance.high,
  );

  Future<void> _ensureChannelCreated() async {
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

  Future<void> scheduleIslamicEventsNotifications({
    required bool notifyBeforeEvent,
    required int notifyBeforeDays,

    // موجود عشان ما نكسرش استدعاء الـ Provider الحالي،
    // لكن مش هنستخدمه دلوقتي لأننا اتفقنا التذكير يكون قبل المناسبة فقط.
    required bool notifyOnEventMorning,

    required bool fastingRemindersEnabled,
    required bool ramadanRemindersEnabled,
    required bool eidGreetingsEnabled,
    required bool specialDaysEnabled,
  }) async {
    debugPrint('🌙 Scheduling Islamic Events Notifications...');

    await _ensureChannelCreated();

    await cancelIslamicEventsNotifications();

    if (!notifyBeforeEvent) {
      debugPrint(
        '⚠️ Islamic events notifications enabled but before-event reminder is disabled.',
      );
      return;
    }

    final IslamicEventsResult result =
    await IslamicEventsService().getUpcomingEventsSmart();

    final List<IslamicEventModel> events = result.events
        .where(
          (event) => _shouldScheduleEvent(
        event: event,
        fastingRemindersEnabled: fastingRemindersEnabled,
        ramadanRemindersEnabled: ramadanRemindersEnabled,
        eidGreetingsEnabled: eidGreetingsEnabled,
        specialDaysEnabled: specialDaysEnabled,
      ),
    )
        .where(_shouldScheduleBeforeReminder)
        .toList();

    if (events.isEmpty) {
      debugPrint('⚠️ No Islamic events available for scheduling.');
      return;
    }

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    int scheduledCount = 0;

    for (final IslamicEventModel event in events) {
      if (scheduledCount >= _notificationsCount) {
        debugPrint('⚠️ Reached Islamic events notification limit.');
        break;
      }

      final tz.TZDateTime beforeEventTime = _buildScheduledDateTime(
        date: event.gregorianDate.subtract(
          Duration(days: notifyBeforeDays),
        ),
        hour: 20,
        minute: 0,
      );

      if (!beforeEventTime.isAfter(now)) {
        continue;
      }

      final int notificationId = _baseNotificationId + scheduledCount;

      await NotificationService().plugin.zonedSchedule(
        notificationId,
        _beforeTitle(event),
        _beforeBody(event, notifyBeforeDays),
        beforeEventTime,
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: NotificationService.openHomePayload,
      );

      scheduledCount++;

      debugPrint(
        '📌 Islamic event before reminder scheduled: ${event.title} at $beforeEventTime',
      );
    }

    debugPrint('✅ Islamic Events scheduled count: $scheduledCount');

    await NotificationService().printPendingNotifications(
      detailed: false,
    );
  }

  bool _shouldScheduleEvent({
    required IslamicEventModel event,
    required bool fastingRemindersEnabled,
    required bool ramadanRemindersEnabled,
    required bool eidGreetingsEnabled,
    required bool specialDaysEnabled,
  }) {
    if (_isFastingEvent(event)) {
      return fastingRemindersEnabled;
    }

    if (_isRamadanEvent(event)) {
      return ramadanRemindersEnabled;
    }

    if (_isEidEvent(event)) {
      return eidGreetingsEnabled;
    }

    if (_isSpecialEvent(event)) {
      return specialDaysEnabled;
    }

    return false;
  }

  bool _shouldScheduleBeforeReminder(IslamicEventModel event) {
    // الأيام البيض 13 و14 و15.
    // نخلي إشعار قبل الأيام البيض مرة واحدة فقط قبل أول يوم.
    if (event.title.contains('الأيام البيض')) {
      return event.subtitle.contains('13') ||
          event.hijriDateText.startsWith('13');
    }

    // العشر الأوائل من ذي الحجة تظهر كل يوم.
    // التذكير قبل كل يوم ممكن يبقى مزعج، فنخليها أول يوم فقط.
    if (event.title.contains('العشر الأوائل من ذي الحجة')) {
      return event.subtitle.contains('1') ||
          event.hijriDateText.startsWith('1');
    }

    // هذا حدث تذكيري بعنوان "غدًا يوم عرفة".
    // لا نحتاج نعمل له "غدًا على غدًا يوم عرفة".
    // سنعتمد على حدث "يوم عرفة" نفسه.
    if (event.title.contains('غدًا يوم عرفة')) {
      return false;
    }

    return true;
  }

  bool _isFastingEvent(IslamicEventModel event) {
    return event.type == IslamicEventType.fasting ||
        event.title.contains('صيام') ||
        event.title.contains('الأيام البيض') ||
        event.title.contains('عرفة') ||
        event.title.contains('عاشوراء') ||
        event.title.contains('ذي الحجة');
  }

  bool _isRamadanEvent(IslamicEventModel event) {
    return event.title.contains('رمضان') ||
        event.title.contains('العشر الأواخر');
  }

  bool _isEidEvent(IslamicEventModel event) {
    return event.title.contains('عيد') ||
        event.title.contains('الفطر') ||
        event.title.contains('الأضحى');
  }

  bool _isSpecialEvent(IslamicEventModel event) {
    return event.type == IslamicEventType.specialDay ||
        event.type == IslamicEventType.reminder ||
        event.type == IslamicEventType.greeting ||
        event.title.contains('عرفة') ||
        event.title.contains('عاشوراء') ||
        event.title.contains('تاسوعاء');
  }

  tz.TZDateTime _buildScheduledDateTime({
    required DateTime date,
    required int hour,
    required int minute,
  }) {
    return tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
  }

  String _beforeTitle(IslamicEventModel event) {
    if (_isEidEvent(event)) {
      return 'اقترب العيد 🎉';
    }

    if (_isRamadanEvent(event)) {
      return 'اقترب رمضان 🌙';
    }

    if (_isFastingEvent(event)) {
      return 'تذكير بصيام قريب 🌙';
    }

    return 'اقتربت مناسبة إسلامية 🌙';
  }

  String _beforeBody(IslamicEventModel event, int days) {
    final String daysText = _beforeDaysText(days);
    final String title = _cleanEventTitle(event.title);

    if (_isEidEvent(event)) {
      return '$daysText $title، كل عام وأنتم بخير.';
    }

    if (_isRamadanEvent(event)) {
      return '$daysText $title، اللهم بلغنا رمضان وبارك لنا فيه.';
    }

    if (_isFastingEvent(event)) {
      return '$daysText $title، لا تنس نية الصيام والعمل الصالح.';
    }

    return '$daysText $title.';
  }

  String _cleanEventTitle(String title) {
    return title
        .replaceAll('غدًا ', '')
        .replaceAll('اقترب ', '')
        .trim();
  }

  String _beforeDaysText(int days) {
    if (days == 1) return 'غدًا';
    if (days == 2) return 'بعد يومين';
    return 'بعد $days أيام';
  }

  Future<void> showTestNotification() async {
    await _ensureChannelCreated();

    await NotificationService().plugin.show(
      _baseNotificationId,
      'تذكيرات المناسبات 🌙',
      'تم تفعيل إشعارات المناسبات الإسلامية بنجاح',
      _notificationDetails(),
      payload: NotificationService.openHomePayload,
    );
  }

  Future<void> cancelIslamicEventsNotifications() async {
    debugPrint('🌙 Cancelling Islamic Events Notifications...');

    for (int id = _baseNotificationId;
    id < _baseNotificationId + _notificationsCount;
    id++) {
      await NotificationService().cancelNotification(id);
    }

    await NotificationService().printPendingNotifications(
      detailed: false,
    );
  }
}