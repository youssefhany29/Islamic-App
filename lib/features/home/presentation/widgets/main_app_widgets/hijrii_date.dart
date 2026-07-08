// lib/utils/hijri_date_utils.dart
import 'package:hijri_calendar/hijri_calendar.dart';

class HijriiDate {
  static String getTodayHijri({String pattern = "dd MMMM yyyy"}) {
    HijriCalendarConfig.language = 'ar';
    final hijri = HijriCalendarConfig.now();
    return hijri.toFormat(pattern);
  }

  static HijriCalendarConfig now() {
    HijriCalendarConfig.language = 'ar';
    return HijriCalendarConfig.now();
  }

  static HijriCalendarConfig fromGregorianObject(DateTime date) {
    HijriCalendarConfig.language = 'ar';
    return HijriCalendarConfig.fromGregorian(date);
  }

  static String fromGregorianHijri({
    required DateTime date,
    String pattern = "dd MMMM yyyy",
  }) {
    HijriCalendarConfig.language = 'ar';
    final hijri = HijriCalendarConfig.fromGregorian(date);
    return hijri.toFormat(pattern);
  }

  static DateTime toGregorian({
    required int year,
    required int month,
    required int day,
  }) {
    final hijri = HijriCalendarConfig.fromHijri(year, month, day);
    return hijri.hijriToGregorian(year, month, day);
  }

  static DateTime safeToGregorian({
    required int year,
    required int month,
    required int day,
  }) {
    try {
      return toGregorian(
        year: year,
        month: month,
        day: day,
      );
    } catch (_) {
      final safeDay = day.clamp(1, 29);
      return toGregorian(
        year: year,
        month: month,
        day: safeDay,
      );
    }
  }

  static String monthName(int month) {
    const months = [
      'محرم',
      'صفر',
      'ربيع الأول',
      'ربيع الآخر',
      'جمادى الأولى',
      'جمادى الآخرة',
      'رجب',
      'شعبان',
      'رمضان',
      'شوال',
      'ذو القعدة',
      'ذو الحجة',
    ];

    if (month < 1 || month > 12) return '';
    return months[month - 1];
  }

  static String gregorianMonthName(int month) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];

    if (month < 1 || month > 12) return '';
    return months[month - 1];
  }

  static int monthLength({
    required int year,
    required int month,
  }) {
    try {
      toGregorian(
        year: year,
        month: month,
        day: 30,
      );
      return 30;
    } catch (_) {
      return 29;
    }
  }

  static int firstWeekdayOfMonth({
    required int year,
    required int month,
  }) {
    final gregorianFirstDay = toGregorian(
      year: year,
      month: month,
      day: 1,
    );

    return gregorianFirstDay.weekday;
  }

  static String formatHijriDate({
    required int year,
    required int month,
    required int day,
  }) {
    return '$day ${monthName(month)} $year هـ';
  }

  static String gregorianMonthYearForHijriMonth({
    required int hijriYear,
    required int hijriMonth,
  }) {
    final length = monthLength(
      year: hijriYear,
      month: hijriMonth,
    );

    final firstGregorian = toGregorian(
      year: hijriYear,
      month: hijriMonth,
      day: 1,
    );

    final lastGregorian = firstGregorian.add(
      Duration(days: length - 1),
    );

    final firstMonthName = gregorianMonthName(firstGregorian.month);
    final lastMonthName = gregorianMonthName(lastGregorian.month);

    if (firstGregorian.month == lastGregorian.month &&
        firstGregorian.year == lastGregorian.year) {
      return '$firstMonthName ${firstGregorian.year}';
    }

    if (firstGregorian.year == lastGregorian.year) {
      return '$firstMonthName - $lastMonthName ${firstGregorian.year}';
    }

    return '$firstMonthName ${firstGregorian.year} - $lastMonthName ${lastGregorian.year}';
  }

  static String? islamicEventName({
    required int hijriDay,
    required int hijriMonth,
  }) {
    if (hijriMonth == 1 && hijriDay == 1) return 'رأس السنة الهجرية';
    if (hijriMonth == 1 && hijriDay == 9) return 'تاسوعاء';
    if (hijriMonth == 1 && hijriDay == 10) return 'عاشوراء';

    if (hijriMonth == 3 && hijriDay == 12) return 'المولد النبوي';

    if (hijriMonth == 7 && hijriDay == 27) return 'الإسراء والمعراج';

    if (hijriMonth == 8 && hijriDay == 15) {
      return 'ليلة النصف من شعبان';
    }

    if (hijriMonth == 9 && hijriDay == 1) {
      return 'بداية شهر رمضان';
    }

    if (hijriMonth == 9 && hijriDay == 17) {
      return 'غزوة بدر';
    }

    if (hijriMonth == 9 && hijriDay >= 21 && hijriDay <= 29) {
      return 'العشر الأواخر من رمضان';
    }

    if (hijriMonth == 9 && hijriDay == 27) {
      return 'ليلة القدر';
    }

    if (hijriMonth == 10 && hijriDay == 1) return 'عيد الفطر';

    if (hijriMonth == 12 && hijriDay == 8) return 'يوم التروية';
    if (hijriMonth == 12 && hijriDay == 9) return 'يوم عرفة';
    if (hijriMonth == 12 && hijriDay == 10) return 'عيد الأضحى';

    if (hijriMonth == 12 && hijriDay >= 11 && hijriDay <= 13) {
      return 'أيام التشريق';
    }

    if (hijriDay == 13 || hijriDay == 14 || hijriDay == 15) {
      return 'الأيام البيض';
    }

    return null;
  }
}