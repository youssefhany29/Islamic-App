import 'package:shared_preferences/shared_preferences.dart';

import '../Notifications/prayer_tracking_notification_scheduler.dart';
import 'prayer_tracking_storage.dart';

class PrayerTrackingServiceResult {
  final List<bool> checked;
  final int streak;
  final int bestStreak;
  final bool completedToday;
  final List<PrayerWeeklyDay> weeklyHistory;
  final PrayerMonthlyStats monthlyStats;

  const PrayerTrackingServiceResult({
    required this.checked,
    required this.streak,
    required this.bestStreak,
    required this.completedToday,
    required this.weeklyHistory,
    required this.monthlyStats,
  });
}

class PrayerTrackingService {
  static const String _prayerNotificationsEnabledKey =
      'prayer_notifications_enabled';
  static const String _afterPrayerAzkarReminderEnabledKey =
      'after_prayer_azkar_reminder_enabled';

  static const int _onTimeGraceMinutes = 60;

  static const List<String> _defaultPrayerKeys = [
    'fajr',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
  ];

  const PrayerTrackingService();

  Future<PrayerTrackingServiceResult> changePrayerStatus({
    required List<String> prayers,
    required List<bool> currentChecked,
    required int prayerIndex,
    required bool newValue,
    required int currentStreak,
    required bool completedToday,
    required List<Map<String, String>> prayerWeek,
  }) async {
    if (prayerIndex < 0 || prayerIndex >= currentChecked.length) {
      throw RangeError.index(prayerIndex, currentChecked, 'prayerIndex');
    }

    final List<bool> updatedChecked = List<bool>.from(currentChecked);

    updatedChecked[prayerIndex] = newValue;

    int updatedStreak = currentStreak;
    bool updatedCompletedToday = completedToday;

    final bool allCompleted = updatedChecked.every((value) => value);

    if (allCompleted && !updatedCompletedToday) {
      updatedCompletedToday = true;
      updatedStreak++;
    }

    if (!allCompleted && updatedCompletedToday) {
      updatedCompletedToday = false;

      if (updatedStreak > 0) {
        updatedStreak--;
      }
    }

    await PrayerTrackingStorage.saveTrackingData(
      checked: updatedChecked,
      streak: updatedStreak,
      completedToday: updatedCompletedToday,
    );

    await _handleNotificationsAfterPrayerChange(
      prayers: prayers,
      prayerWeek: prayerWeek,
      prayerIndex: prayerIndex,
      newValue: newValue,
    );

    final List<PrayerWeeklyDay> weeklyHistory =
        await PrayerTrackingStorage.getWeeklyHistory();
    final PrayerMonthlyStats monthlyStats =
        await PrayerTrackingStorage.getMonthlyStats();
    final int bestStreak = await PrayerTrackingStorage.getBestStreak();

    return PrayerTrackingServiceResult(
      checked: updatedChecked,
      streak: updatedStreak,
      bestStreak: bestStreak,
      completedToday: updatedCompletedToday,
      weeklyHistory: weeklyHistory,
      monthlyStats: monthlyStats,
    );
  }

  Future<void> _handleNotificationsAfterPrayerChange({
    required List<String> prayers,
    required List<Map<String, String>> prayerWeek,
    required int prayerIndex,
    required bool newValue,
  }) async {
    final bool notificationsEnabled = await _arePrayerNotificationsEnabled();

    if (!notificationsEnabled) {
      return;
    }

    final int todayIndex = _getTodayPrayerRowIndex(prayerWeek);

    if (newValue) {
      await PrayerTrackingNotificationScheduler()
          .cancelTrackingRemindersForPrayer(
            dayIndex: todayIndex == -1 ? 0 : todayIndex,
            prayerIndex: prayerIndex,
          );

      final bool checkedOnTime = _canCountAsOnTime(
        prayerWeek: prayerWeek,
        prayerIndex: prayerIndex,
      );

      if (checkedOnTime) {
        if (await _isAfterPrayerAzkarReminderEnabled()) {
          await PrayerTrackingNotificationScheduler()
              .scheduleAfterPrayerAzkarReminder(
                prayerName: prayers[prayerIndex],
                afterMinutes: 2,
              );
        }
      } else {
        await PrayerTrackingNotificationScheduler()
            .cancelAfterPrayerAzkarReminder();
      }
    } else {
      await PrayerTrackingNotificationScheduler()
          .cancelAfterPrayerAzkarReminder();
    }
  }

  Future<bool> _arePrayerNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prayerNotificationsEnabledKey) ?? false;
  }

  Future<bool> _isAfterPrayerAzkarReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_afterPrayerAzkarReminderEnabledKey) ?? true;
  }

  bool _canCountAsOnTime({
    required List<Map<String, String>> prayerWeek,
    required int prayerIndex,
  }) {
    final DateTime now = DateTime.now();
    final DateTime? prayerTime = _getPrayerTimeToday(
      prayerWeek: prayerWeek,
      prayerIndex: prayerIndex,
    );

    if (prayerTime == null) return true;

    final DateTime graceEnd = prayerTime.add(
      const Duration(minutes: _onTimeGraceMinutes),
    );

    return !now.isBefore(prayerTime) && !now.isAfter(graceEnd);
  }

  DateTime? _getPrayerTimeToday({
    required List<Map<String, String>> prayerWeek,
    required int prayerIndex,
  }) {
    final int todayIndex = _getTodayPrayerRowIndex(prayerWeek);
    if (todayIndex == -1) return null;

    final String? prayerKey = _prayerKeyAt(prayerIndex);
    if (prayerKey == null) return null;

    return _parsePrayerDateTime(
      day: prayerWeek[todayIndex],
      fallbackDayOffset: 0,
      timeText: prayerWeek[todayIndex][prayerKey],
    );
  }

  int _getTodayPrayerRowIndex(List<Map<String, String>> prayerWeek) {
    final String today = _todayStorageKey();

    for (int i = 0; i < prayerWeek.length; i++) {
      if (prayerWeek[i]['date'] == today) {
        return i;
      }
    }

    final String todayName = _todayArabicName();

    for (int i = 0; i < prayerWeek.length; i++) {
      if (prayerWeek[i]['day'] == todayName) {
        return i;
      }
    }

    return -1;
  }

  String? _prayerKeyAt(int prayerIndex) {
    if (prayerIndex < 0 || prayerIndex >= _defaultPrayerKeys.length) {
      return null;
    }

    return _defaultPrayerKeys[prayerIndex];
  }

  DateTime? _parsePrayerDateTime({
    required Map<String, String> day,
    required int fallbackDayOffset,
    required String? timeText,
  }) {
    if (timeText == null || !timeText.contains(':')) {
      return null;
    }

    final List<String> timeParts = timeText.split(':');

    if (timeParts.length != 2) {
      return null;
    }

    final int? hour = int.tryParse(timeParts[0]);
    final int? minute = int.tryParse(timeParts[1]);

    if (hour == null || minute == null) {
      return null;
    }

    final DateTime fallbackDay = DateTime.now().add(
      Duration(days: fallbackDayOffset),
    );

    final DateTime date = _parseDateKey(day['date']) ?? fallbackDay;

    return DateTime(date.year, date.month, date.day, hour, minute);
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

  String _todayStorageKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    return '${now.year}-$month-$day';
  }

  String _todayArabicName() {
    const days = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];

    return days[DateTime.now().weekday - 1];
  }
}
