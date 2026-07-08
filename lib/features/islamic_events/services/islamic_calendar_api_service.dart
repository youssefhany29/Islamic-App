import 'dart:convert';

import 'package:http/http.dart' as http;

class IslamicCalendarDay {
  final DateTime gregorianDate;
  final int hijriDay;
  final int hijriMonth;
  final int hijriYear;
  final String hijriDateText;

  const IslamicCalendarDay({
    required this.gregorianDate,
    required this.hijriDay,
    required this.hijriMonth,
    required this.hijriYear,
    required this.hijriDateText,
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
      const Duration(seconds: 12),
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

      return IslamicCalendarDay(
        gregorianDate: gregorianDate,
        hijriDay: hijriDay,
        hijriMonth: hijriMonth,
        hijriYear: hijriYear,
        hijriDateText: '$hijriDay $hijriMonthName $hijriYear',
      );
    }).toList();
  }
}