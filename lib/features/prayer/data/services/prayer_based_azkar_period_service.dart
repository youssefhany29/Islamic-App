import 'prayer_time_service.dart';

enum AzkarPrayerPeriod {
  morning,
  evening,
}

extension AzkarPrayerPeriodX on AzkarPrayerPeriod {
  bool get isMorning => this == AzkarPrayerPeriod.morning;
  bool get isEvening => this == AzkarPrayerPeriod.evening;

  String get arabicTitle {
    switch (this) {
      case AzkarPrayerPeriod.morning:
        return 'أذكار الصباح';
      case AzkarPrayerPeriod.evening:
        return 'أذكار المساء';
    }
  }

  String get arabicSubtitle {
    switch (this) {
      case AzkarPrayerPeriod.morning:
        return 'من الفجر إلى قبل العصر';
      case AzkarPrayerPeriod.evening:
        return 'من العصر إلى قبل الفجر';
    }
  }
}

class PrayerBasedAzkarPeriodService {
  const PrayerBasedAzkarPeriodService({
    PrayerTimeService? prayerTimeService,
  }) : _prayerTimeService = prayerTimeService ?? const PrayerTimeService();

  final PrayerTimeService _prayerTimeService;

  Future<AzkarPrayerPeriod> getCurrentPeriod() async {
    final List<Map<String, String>> prayerWeek =
    await _prayerTimeService.getCachedPrayerWeek();

    return getCurrentPeriodFromPrayerWeek(
      prayerWeek: prayerWeek,
      now: DateTime.now(),
    );
  }

  AzkarPrayerPeriod getCurrentPeriodFromPrayerWeek({
    required List<Map<String, String>> prayerWeek,
    required DateTime now,
  }) {
    final Map<String, String>? todayPrayerTimes = _findPrayerDay(
      prayerWeek: prayerWeek,
      date: now,
    );

    if (todayPrayerTimes == null) {
      return _fallbackPeriod(now);
    }

    final DateTime? fajr = _parsePrayerDateTime(
      day: todayPrayerTimes,
      prayerKey: 'fajr',
      fallbackDate: now,
    );

    final DateTime? asr = _parsePrayerDateTime(
      day: todayPrayerTimes,
      prayerKey: 'asr',
      fallbackDate: now,
    );

    if (fajr == null || asr == null) {
      return _fallbackPeriod(now);
    }

    // أذكار الصباح: من الفجر إلى قبل العصر.
    if (!now.isBefore(fajr) && now.isBefore(asr)) {
      return AzkarPrayerPeriod.morning;
    }

    // أذكار المساء: من العصر إلى قبل فجر اليوم التالي.
    // قبل فجر اليوم الحالي يعتبر امتدادًا لمساء اليوم السابق.
    return AzkarPrayerPeriod.evening;
  }

  Map<String, String>? _findPrayerDay({
    required List<Map<String, String>> prayerWeek,
    required DateTime date,
  }) {
    final String key = _dateKey(date);

    for (final Map<String, String> day in prayerWeek) {
      if (day['date'] == key) {
        return day;
      }
    }

    return null;
  }

  DateTime? _parsePrayerDateTime({
    required Map<String, String> day,
    required String prayerKey,
    required DateTime fallbackDate,
  }) {
    final String? timeValue = day[prayerKey];
    if (timeValue == null || timeValue.trim().isEmpty) return null;

    final List<String> parts = timeValue.trim().split(':');
    if (parts.length < 2) return null;

    final int? hour = int.tryParse(parts[0]);
    final int? minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

    final DateTime date = _parseDateKey(day['date']) ??
        DateTime(
          fallbackDate.year,
          fallbackDate.month,
          fallbackDate.day,
        );

    return DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
  }

  AzkarPrayerPeriod _fallbackPeriod(DateTime now) {
    // احتياطي فقط لو مفيش مواقيت محفوظة.
    // اخترنا الفجر التقريبي 05:00 والعصر التقريبي 15:00 بدل 06:00/18:00
    // لأن المطلوب الأساسي هو: الصباح من الفجر للعصر، والمساء من العصر للفجر.
    if (now.hour >= 5 && now.hour < 15) {
      return AzkarPrayerPeriod.morning;
    }

    return AzkarPrayerPeriod.evening;
  }

  String _dateKey(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  DateTime? _parseDateKey(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    try {
      final DateTime parsed = DateTime.parse(value);
      return DateTime(parsed.year, parsed.month, parsed.day);
    } catch (_) {
      return null;
    }
  }
}
