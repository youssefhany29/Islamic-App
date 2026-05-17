// lib/utils/hijri_date_utils.dart
import 'package:hijri_calendar/hijri_calendar.dart';

class HijriiDate {
  /// Returns today’s Hijri date in Arabic, formatted by [pattern].
  static String getTodayHijri({String pattern = "dd MMMM yyyy"}) {
    // 1) set locale to Arabic
    HijriCalendarConfig.language = 'ar';
    // 2) get current Hijri date
    final hijri = HijriCalendarConfig.now();
    // 3) format it
    return hijri.toFormat(pattern);
  }

  /// Converts a Gregorian [date] to Hijri (Arabic) and formats it.
  static String fromGregorianHijri({
    required DateTime date,
    String pattern = "dd MMMM yyyy",
  }) {
    HijriCalendarConfig.language = 'ar';
    final hijri = HijriCalendarConfig.fromGregorian(date);
    return hijri.toFormat(pattern);
  }

  /// Converts a Hijri date (year, month, day) to a Gregorian [DateTime].
  static DateTime toGregorian({
    required int year,
    required int month,
    required int day,
  }) {
    // 1) create an instance from your Hijri components
    final hijri = HijriCalendarConfig.fromHijri(year, month, day);
    // 2) call the instance method hijriToGregorian
    return hijri.hijriToGregorian(year, month, day);
  }
}
