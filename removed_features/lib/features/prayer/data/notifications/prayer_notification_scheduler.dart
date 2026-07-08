import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:islamic_app/core/notifications/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;

import 'prayer_notification_settings_provider.dart';

class PrayerNotificationScheduler {
  PrayerNotificationScheduler._internal();

  static final PrayerNotificationScheduler _instance =
  PrayerNotificationScheduler._internal();

  factory PrayerNotificationScheduler() {
    return _instance;
  }

  static const int _prayerNotificationBaseId = 2000;
  static const int _prayerBeforeNotificationBaseId = 3000;
  static const int _nightPrayReminderId = 3900;

  // مهم جدًا:
  // أندرويد لا يغير صوت القناة بعد إنشائها أول مرة.
  // لذلك غيرت أرقام القنوات إلى v4 حتى يتم إنشاء قنوات جديدة بالصوت الصحيح.
  static const String _defaultChannelId = 'prayer_reminders_channel_v4';
  static const String _defaultChannelName = 'Prayer Reminders';
  static const String _defaultChannelDescription =
      'Reminders for prayer times.';

  static const String _silentChannelId = 'prayer_silent_reminders_channel_v4';
  static const String _silentChannelName = 'Silent Prayer Reminders';
  static const String _silentChannelDescription =
      'Prayer reminders without sound.';

  static const String _beforeChannelId = 'prayer_before_reminders_channel_v4';
  static const String _beforeChannelName = 'Before Prayer Reminders';
  static const String _beforeChannelDescription =
      'Reminders before prayer times.';

  static const String _nightPrayChannelId = 'night_pray_reminder_channel_v4';
  static const String _nightPrayChannelName = 'Night Prayer Reminder';
  static const String _nightPrayChannelDescription =
      'Daily reminder for Qiyam Al-Layl.';

  static const AndroidNotificationChannel _defaultAndroidChannel =
  AndroidNotificationChannel(
    _defaultChannelId,
    _defaultChannelName,
    description: _defaultChannelDescription,
    importance: Importance.high,
    playSound: true,
  );

  static const AndroidNotificationChannel _silentAndroidChannel =
  AndroidNotificationChannel(
    _silentChannelId,
    _silentChannelName,
    description: _silentChannelDescription,
    importance: Importance.high,
    playSound: false,
  );

  static const AndroidNotificationChannel _beforeAndroidChannel =
  AndroidNotificationChannel(
    _beforeChannelId,
    _beforeChannelName,
    description: _beforeChannelDescription,
    importance: Importance.high,
    playSound: true,
  );

  static const AndroidNotificationChannel _nightPrayAndroidChannel =
  AndroidNotificationChannel(
    _nightPrayChannelId,
    _nightPrayChannelName,
    description: _nightPrayChannelDescription,
    importance: Importance.high,
    playSound: true,
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

  // أسماء الملفات داخل:
  // android/app/src/main/res/raw/
  // بدون .mp3 في الكود.
  static const List<String> _prayerVoiceSounds = [
    'prayer_fajr',
    'prayer_dhuhr',
    'prayer_asr',
    'prayer_maghrib',
    'prayer_isha',
  ];

  Future<void> _ensureBaseChannels() async {
    await NotificationService().createAndroidNotificationChannel(
      _defaultAndroidChannel,
    );

    await NotificationService().createAndroidNotificationChannel(
      _silentAndroidChannel,
    );

    await NotificationService().createAndroidNotificationChannel(
      _beforeAndroidChannel,
    );

    await NotificationService().createAndroidNotificationChannel(
      _nightPrayAndroidChannel,
    );
  }

  Future<void> _ensureSoundChannel({
    required String channelId,
    required String channelName,
    required String channelDescription,
    required String soundName,
  }) async {
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(soundName),
    );

    await NotificationService().createAndroidNotificationChannel(channel);
  }

  String _channelIdForPrayerVoice(String prayerKey) {
    // v4 مهم عشان أندرويد يعمل قناة جديدة بالصوت
    return 'prayer_voice_${prayerKey}_channel_v4';
  }

  String _channelNameForPrayerVoice(String prayerName) {
    return 'Prayer Voice $prayerName';
  }

  String _channelIdForAzan(String selectedAzanSound) {
    // v4 مهم عشان أندرويد يعمل قناة جديدة بالصوت
    return 'prayer_${selectedAzanSound}_channel_v4';
  }

  String _channelNameForAzan(String selectedAzanSound) {
    switch (selectedAzanSound) {
      case 'azan_1':
        return 'Prayer Azan 1';
      case 'azan_2':
        return 'Prayer Azan 2';
      case 'azan_3':
        return 'Prayer Azan 3';
      case 'azan_4':
        return 'Prayer Azan 4';
      case 'azan_5':
        return 'Prayer Azan 5';
      default:
        return 'Prayer Azan 1';
    }
  }

  Future<void> _ensureRequiredSoundChannels({
    required PrayerSoundMode soundMode,
    required String selectedAzanSound,
    required bool azanSoundEnabled,
    required bool prayerSoundEnabled,
  }) async {
    if (!prayerSoundEnabled) {
      return;
    }

    if (soundMode == PrayerSoundMode.prayerVoice) {
      for (int i = 0; i < _prayerKeys.length; i++) {
        await _ensureSoundChannel(
          channelId: _channelIdForPrayerVoice(_prayerKeys[i]),
          channelName: _channelNameForPrayerVoice(_prayerNames[i]),
          channelDescription: 'Prayer voice reminder for ${_prayerNames[i]}.',
          soundName: _prayerVoiceSounds[i],
        );
      }

      return;
    }

    if (soundMode == PrayerSoundMode.azan && azanSoundEnabled) {
      await _ensureSoundChannel(
        channelId: _channelIdForAzan(selectedAzanSound),
        channelName: _channelNameForAzan(selectedAzanSound),
        channelDescription: 'Prayer reminders with selected azan sound.',
        soundName: selectedAzanSound,
      );
    }
  }

  NotificationDetails _beforePrayerNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _beforeChannelId,
        _beforeChannelName,
        channelDescription: _beforeChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentSound: true,
      ),
    );
  }

  NotificationDetails _nightPrayNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _nightPrayChannelId,
        _nightPrayChannelName,
        channelDescription: _nightPrayChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentSound: true,
      ),
    );
  }

  NotificationDetails _silentPrayerNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _silentChannelId,
        _silentChannelName,
        channelDescription: _silentChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: false,
      ),
      iOS: DarwinNotificationDetails(
        presentSound: false,
      ),
    );
  }

  NotificationDetails _defaultPrayerNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _defaultChannelId,
        _defaultChannelName,
        channelDescription: _defaultChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentSound: true,
      ),
    );
  }

  NotificationDetails _prayerTimeNotificationDetails({
    required PrayerSoundMode soundMode,
    required String selectedAzanSound,
    required int prayerIndex,
    required bool azanSoundEnabled,
    required bool prayerSoundEnabled,
  }) {
    if (!prayerSoundEnabled) {
      return _silentPrayerNotificationDetails();
    }

    if (soundMode == PrayerSoundMode.prayerVoice) {
      final String prayerKey = _prayerKeys[prayerIndex];
      final String prayerName = _prayerNames[prayerIndex];
      final String soundName = _prayerVoiceSounds[prayerIndex];

      return NotificationDetails(
        android: AndroidNotificationDetails(
          _channelIdForPrayerVoice(prayerKey),
          _channelNameForPrayerVoice(prayerName),
          channelDescription: 'Prayer voice reminder for $prayerName.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          sound: RawResourceAndroidNotificationSound(soundName),
        ),
        iOS: const DarwinNotificationDetails(
          presentSound: true,
        ),
      );
    }

    if (soundMode == PrayerSoundMode.azan) {
      if (!azanSoundEnabled) {
        return _silentPrayerNotificationDetails();
      }

      return NotificationDetails(
        android: AndroidNotificationDetails(
          _channelIdForAzan(selectedAzanSound),
          _channelNameForAzan(selectedAzanSound),
          channelDescription: 'Prayer reminders with selected azan sound.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          sound: RawResourceAndroidNotificationSound(selectedAzanSound),
        ),
        iOS: const DarwinNotificationDetails(
          presentSound: true,
        ),
      );
    }

    return _defaultPrayerNotificationDetails();
  }

  Future<void> schedulePrayerNotifications({
    required List<Map<String, String>> prayerWeek,
    required List<String> selectedPrayers,
    required bool notifyAtPrayerTime,
    required bool notifyBeforePrayer,
    required int notifyBeforeMinutes,
    required PrayerSoundMode soundMode,
    required String selectedAzanSound,
    required bool azanSoundEnabled,
    required bool prayerSoundEnabled,
  }) async {
    await _ensureBaseChannels();

    await _ensureRequiredSoundChannels(
      soundMode: soundMode,
      selectedAzanSound: selectedAzanSound,
      azanSoundEnabled: azanSoundEnabled,
      prayerSoundEnabled: prayerSoundEnabled,
    );

    await cancelPrayerNotifications();

    if (prayerWeek.isEmpty) {
      debugPrint('⚠️ No prayer week data available for scheduling.');
      return;
    }

    if (selectedPrayers.isEmpty) {
      debugPrint('⚠️ No selected prayers for scheduling.');
      return;
    }

    if (!notifyAtPrayerTime && !notifyBeforePrayer) {
      debugPrint(
        '⚠️ Prayer notifications are enabled but no reminder type selected.',
      );
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

        if (notifyAtPrayerTime && prayerDateTime.isAfter(now)) {
          final int notificationId =
              _prayerNotificationBaseId + (dayIndex * 10) + prayerIndex;

          await NotificationService().plugin.zonedSchedule(
            notificationId,
            'حان الآن موعد صلاة $prayerName 🕌',
            'تقبّل الله صلاتك، قم إلى الصلاة واطمئن بقربك من الله.',
            prayerDateTime,
            _prayerTimeNotificationDetails(
              soundMode: soundMode,
              selectedAzanSound: selectedAzanSound,
              prayerIndex: prayerIndex,
              azanSoundEnabled: azanSoundEnabled,
              prayerSoundEnabled: prayerSoundEnabled,
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: NotificationService.openPrayerPayload,
          );

          debugPrint(
            '📌 Prayer notification scheduled: $prayerName at $prayerDateTime',
          );
        }

        if (notifyBeforePrayer) {
          final tz.TZDateTime beforePrayerDateTime = prayerDateTime.subtract(
            Duration(minutes: notifyBeforeMinutes),
          );

          if (beforePrayerDateTime.isAfter(now)) {
            final int notificationId =
                _prayerBeforeNotificationBaseId + (dayIndex * 10) + prayerIndex;

            await NotificationService().plugin.zonedSchedule(
              notificationId,
              'اقترب موعد صلاة $prayerName ⏰',
              'باقي $notifyBeforeMinutes دقائق على صلاة $prayerName.',
              beforePrayerDateTime,
              _beforePrayerNotificationDetails(),
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              payload: NotificationService.openPrayerPayload,
            );

            debugPrint(
              '📌 Before prayer notification scheduled: $prayerName at $beforePrayerDateTime',
            );
          }
        }
      }
    }

    await NotificationService().printPendingNotifications();
  }

  Future<void> scheduleNightPrayReminder({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    await _ensureBaseChannels();
    await cancelNightPrayReminder();

    if (!enabled) {
      debugPrint('🧹 Night prayer reminder is disabled.');
      return;
    }

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (!scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await NotificationService().plugin.zonedSchedule(
      _nightPrayReminderId,
      'تذكير قيام الليل 🌙',
      'حان وقت قيام الليل، ركعتان خفيفتان وذكرٌ طيب يكفيان لبداية جميلة.',
      scheduledDate,
      _nightPrayNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: NotificationService.openPrayerPayload,
    );

    debugPrint('📌 Night prayer reminder scheduled daily at $scheduledDate');
  }

  Future<void> cancelNightPrayReminder() async {
    await NotificationService().cancelNotification(_nightPrayReminderId);
    debugPrint('🧹 Night prayer reminder cancelled.');
  }

  Future<void> showPrayerSoundTestNotification({
    required PrayerSoundMode soundMode,
    required String selectedAzanSound,
    required bool azanSoundEnabled,
    required bool prayerSoundEnabled,
  }) async {
    await _ensureBaseChannels();

    await _ensureRequiredSoundChannels(
      soundMode: soundMode,
      selectedAzanSound: selectedAzanSound,
      azanSoundEnabled: azanSoundEnabled,
      prayerSoundEnabled: prayerSoundEnabled,
    );

    await NotificationService().plugin.show(
      2999,
      'اختبار تنبيه الصلاة ✅',
      prayerSoundEnabled
          ? 'هذا اختبار لصوت تنبيه الصلاة الحالي.'
          : 'هذا اختبار لإشعار الصلاة بدون صوت.',
      _prayerTimeNotificationDetails(
        soundMode: soundMode,
        selectedAzanSound: selectedAzanSound,
        prayerIndex: 0,
        azanSoundEnabled: azanSoundEnabled,
        prayerSoundEnabled: prayerSoundEnabled,
      ),
      payload: NotificationService.openPrayerPayload,
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

    final DateTime? realDate = _parsePrayerDate(day['date']);
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    if (realDate != null) {
      return tz.TZDateTime(
        tz.local,
        realDate.year,
        realDate.month,
        realDate.day,
        hour,
        minute,
      );
    }

    // Fallback للكاش القديم فقط:
    // لو day['date'] غير موجود، نستخدم ترتيب الأيام القديم.
    final tz.TZDateTime targetDay = now.add(
      Duration(days: fallbackDayOffset),
    );

    return tz.TZDateTime(
      tz.local,
      targetDay.year,
      targetDay.month,
      targetDay.day,
      hour,
      minute,
    );
  }

  DateTime? _parsePrayerDate(String? dateText) {
    if (dateText == null || dateText.trim().isEmpty) {
      return null;
    }

    try {
      final DateTime parsed = DateTime.parse(dateText);
      return DateTime(parsed.year, parsed.month, parsed.day);
    } catch (_) {
      return null;
    }
  }

  Future<void> cancelPrayerNotifications() async {
    for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
      for (int prayerIndex = 0; prayerIndex < _prayerNames.length; prayerIndex++) {
        await NotificationService().cancelNotification(
          _prayerNotificationBaseId + (dayIndex * 10) + prayerIndex,
        );

        await NotificationService().cancelNotification(
          _prayerBeforeNotificationBaseId + (dayIndex * 10) + prayerIndex,
        );
      }
    }

    debugPrint('🧹 Prayer notifications cancelled.');
  }
}
