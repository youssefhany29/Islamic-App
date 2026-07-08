class PrayerTimeHighlightHelper {
  static const List<String> arabicDays = [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  static String todayArabicName() {
    return arabicDays[DateTime.now().weekday - 1];
  }

  static bool isTodayRow(Map<String, String> day) {
    final String? dateText = day['date'];

    if (dateText != null && dateText.trim().isNotEmpty) {
      final DateTime? parsedDate = _parseDateKey(dateText.trim());
      final DateTime now = DateTime.now();

      if (parsedDate != null) {
        return parsedDate.year == now.year &&
            parsedDate.month == now.month &&
            parsedDate.day == now.day;
      }
    }

    return day['day'] == todayArabicName();
  }

  static Map<String, String>? getTodayPrayerTimes(
      List<Map<String, String>> prayerWeek,
      ) {
    for (final Map<String, String> day in prayerWeek) {
      if (isTodayRow(day)) {
        return day;
      }
    }

    return prayerWeek.isEmpty ? null : prayerWeek.first;
  }

  static String? getNextPrayerKey(Map<String, String> todayPrayerTimes) {
    final DateTime now = DateTime.now();
    final DateTime baseDate = _parseDateKey(todayPrayerTimes['date']) ??
        DateTime(now.year, now.month, now.day);

    final List<({String key, DateTime? time})> prayers = [
      (key: 'fajr', time: _parseTime(todayPrayerTimes['fajr'], baseDate)),
      (
      key: 'sunrise',
      time: _parseTime(todayPrayerTimes['sunrise'], baseDate),
      ),
      (key: 'dhuhr', time: _parseTime(todayPrayerTimes['dhuhr'], baseDate)),
      (key: 'asr', time: _parseTime(todayPrayerTimes['asr'], baseDate)),
      (
      key: 'maghrib',
      time: _parseTime(todayPrayerTimes['maghrib'], baseDate),
      ),
      (key: 'isha', time: _parseTime(todayPrayerTimes['isha'], baseDate)),
    ];

    for (final prayer in prayers) {
      final DateTime? prayerTime = prayer.time;

      if (prayerTime == null) {
        continue;
      }

      if (now.isBefore(prayerTime) || now.isAtSameMomentAs(prayerTime)) {
        return prayer.key;
      }
    }

    return null;
  }

  static DateTime? _parseTime(String? time, DateTime baseDate) {
    if (time == null || !time.contains(':')) return null;

    final List<String> parts = time.split(':');

    if (parts.length < 2) return null;

    final int? hour = int.tryParse(parts[0]);
    final int? minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return null;

    return DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      hour,
      minute,
    );
  }

  static DateTime? _parseDateKey(String? dateKey) {
    if (dateKey == null || dateKey.trim().isEmpty) return null;

    try {
      final DateTime parsed = DateTime.parse(dateKey.trim());
      return DateTime(parsed.year, parsed.month, parsed.day);
    } catch (_) {
      return null;
    }
  }
}
