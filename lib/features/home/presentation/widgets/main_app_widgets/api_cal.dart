import 'dart:convert';

import 'package:http/http.dart' as http;

class IslamicCalendarDay {
  final DateTime gregorianDate;
  final int hijriDay;
  final int hijriMonth;
  final int hijriYear;
  final String hijriDateText;
  final List<String> holidays;

  const IslamicCalendarDay({
    required this.gregorianDate,
    required this.hijriDay,
    required this.hijriMonth,
    required this.hijriYear,
    required this.hijriDateText,
    this.holidays = const [],
  });
}

class IslamicCalendarApiService {
  static const String _baseUrl = 'https://api.aladhan.com/v1';

  Future<List<IslamicCalendarDay>> getGregorianMonthCalendar({
    required int month,
    required int year,
  }) async {
    final uri = Uri.parse('$_baseUrl/gToHCalendar/$month/$year');

    final response = await http.get(uri).timeout(
      const Duration(seconds: 8),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load Islamic calendar');
    }

    final Map<String, dynamic> decoded = jsonDecode(response.body);

    if (decoded['code'] != 200 || decoded['data'] == null) {
      throw Exception('Invalid Islamic calendar response');
    }

    final List<dynamic> data = decoded['data'];

    return data.map((item) {
      final Map<String, dynamic> gregorian = item['gregorian'];
      final Map<String, dynamic> hijri = item['hijri'];

      final String gregorianDateText = gregorian['date'].toString();
      final List<String> gregorianParts = gregorianDateText.split('-');

      final DateTime gregorianDate = DateTime(
        int.parse(gregorianParts[2]),
        int.parse(gregorianParts[1]),
        int.parse(gregorianParts[0]),
      );

      final int hijriDay = int.parse(hijri['day'].toString());
      final int hijriMonth = int.parse(hijri['month']['number'].toString());
      final int hijriYear = int.parse(hijri['year'].toString());

      final String hijriMonthName =
      hijri['month']['ar']?.toString().trim().isNotEmpty == true
          ? hijri['month']['ar'].toString()
          : hijri['month']['en'].toString();

      final List<String> holidays = _parseHolidays(hijri['holidays']);

      return IslamicCalendarDay(
        gregorianDate: gregorianDate,
        hijriDay: hijriDay,
        hijriMonth: hijriMonth,
        hijriYear: hijriYear,
        hijriDateText: '$hijriDay $hijriMonthName $hijriYear',
        holidays: holidays,
      );
    }).toList();
  }

  List<String> _parseHolidays(dynamic rawHolidays) {
    if (rawHolidays == null) return [];

    if (rawHolidays is List) {
      return rawHolidays
          .map((item) => _translateHolidayToArabic(item.toString()))
          .where((item) => item.trim().isNotEmpty)
          .toSet()
          .toList();
    }

    final text = _translateHolidayToArabic(rawHolidays.toString());
    if (text.trim().isEmpty) return [];

    return [text];
  }

  String _translateHolidayToArabic(String value) {
    final clean = _cleanHolidayText(value);

    if (clean.isEmpty) return '';

    if (_containsArabic(clean)) return clean;

    final normalized = clean
        .toLowerCase()
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (normalized.contains('islamic new year') ||
        normalized.contains('hijri new year')) {
      return 'رأس السنة الهجرية';
    }

    if (normalized.contains('ashura') || normalized.contains('ashoora')) {
      return 'عاشوراء';
    }

    if (normalized.contains('tasu') || normalized.contains('tasua')) {
      return 'تاسوعاء';
    }

    if (normalized.contains('mawlid') ||
        normalized.contains('milad') ||
        normalized.contains('prophet')) {
      return 'المولد النبوي';
    }

    if (normalized.contains('isra') || normalized.contains('miraj')) {
      return 'الإسراء والمعراج';
    }

    if (normalized.contains('nisf') ||
        normalized.contains('bara') ||
        normalized.contains('shaban')) {
      return 'ليلة النصف من شعبان';
    }

    if (normalized.contains('start of ramadan') ||
        normalized.contains('1st ramadan') ||
        normalized == 'ramadan') {
      return 'بداية شهر رمضان';
    }

    if ((normalized.contains('lailat') || normalized.contains('laylat')) &&
        normalized.contains('qadr')) {
      return 'ليلة القدر';
    }

    if (normalized.contains('eid') && normalized.contains('fitr')) {
      return 'عيد الفطر';
    }

    if (normalized.contains('arafat') || normalized.contains('arafah')) {
      return 'يوم عرفة';
    }

    if (normalized.contains('eid') && normalized.contains('adha')) {
      return 'عيد الأضحى';
    }

    return '';
  }

  String _cleanHolidayText(String value) {
    return value
        .replaceAll(' - ', ' ')
        .replaceAll('Holiday', '')
        .replaceAll('holiday', '')
        .replaceAll('Observed', '')
        .replaceAll('observed', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _containsArabic(String value) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(value);
  }
}