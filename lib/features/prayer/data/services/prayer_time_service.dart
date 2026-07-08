import 'dart:convert';

import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrayerTimeService {
  const PrayerTimeService();

  static const String _cachedPrayerWeekKey = 'cached_prayer_week';
  static const String _cachedPrayerWeekDateKey = 'cached_prayer_week_date';
  static const String _cachedPrayerCountryIsoKey = 'cached_prayer_country_iso';
  static const String _cachedPrayerLatitudeKey = 'cached_prayer_latitude';
  static const String _cachedPrayerLongitudeKey = 'cached_prayer_longitude';

  /// حساب مواقيت الأسبوع وحفظ آخر نتيجة ناجحة.
  ///
  /// مهم:
  /// كل يوم يتم حفظه مع date حقيقي بصيغة yyyy-MM-dd
  /// حتى لا نعتمد على اسم اليوم فقط في الجدولة أو العرض.
  Future<List<Map<String, String>>> getWeekPrayerTimes(
      Position position,
      ) async {
    final String? countryIso = await _detectCountryIso(position);
    final CalculationParameters params = _getCalculationParameters(countryIso);
    final Coordinates coords = Coordinates(
      position.latitude,
      position.longitude,
    );

    const List<String> arabicDays = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];

    final List<Map<String, String>> weekPrayers = [];
    final DateTime today = DateTime.now();

    for (int i = 0; i < 7; i++) {
      final DateTime date = DateTime(
        today.year,
        today.month,
        today.day,
      ).add(Duration(days: i));

      final String dayName = arabicDays[date.weekday - 1];
      final DateComponents dateComponents = DateComponents.from(date);
      final PrayerTimes times = PrayerTimes(coords, dateComponents, params);

      weekPrayers.add({
        'day': dayName,
        'date': _dateKey(date),
        'countryIso': countryIso ?? '',
        'fajr': _formatTime(times.fajr),
        'sunrise': _formatTime(times.sunrise),
        'dhuhr': _formatTime(times.dhuhr),
        'asr': _formatTime(times.asr),
        'maghrib': _formatTime(times.maghrib),
        'isha': _formatTime(times.isha),
      });
    }

    await saveCachedPrayerWeek(
      weekPrayers,
      countryIso: countryIso,
      latitude: position.latitude,
      longitude: position.longitude,
    );

    return weekPrayers;
  }

  Future<void> saveCachedPrayerWeek(
      List<Map<String, String>> prayerWeek, {
        String? countryIso,
        double? latitude,
        double? longitude,
      }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final String encodedData = jsonEncode(prayerWeek);

    await prefs.setString(_cachedPrayerWeekKey, encodedData);
    await prefs.setString(_cachedPrayerWeekDateKey, _todayKey());

    if (countryIso != null && countryIso.trim().isNotEmpty) {
      await prefs.setString(
        _cachedPrayerCountryIsoKey,
        countryIso.trim().toUpperCase(),
      );
    }

    if (latitude != null) {
      await prefs.setDouble(_cachedPrayerLatitudeKey, latitude);
    }

    if (longitude != null) {
      await prefs.setDouble(_cachedPrayerLongitudeKey, longitude);
    }
  }

  Future<List<Map<String, String>>> getCachedPrayerWeek() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final String? cachedData = prefs.getString(_cachedPrayerWeekKey);

    if (cachedData == null || cachedData.isEmpty) {
      return [];
    }

    try {
      final dynamic decodedData = jsonDecode(cachedData);

      if (decodedData is! List) {
        await prefs.remove(_cachedPrayerWeekKey);
        return [];
      }

      final List<Map<String, String>> result = decodedData
          .whereType<Map>()
          .map<Map<String, String>>((item) {
        final Map<String, dynamic> mapItem = Map<String, dynamic>.from(
          item,
        );

        return mapItem.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
        );
      })
          .toList();

      if (result.isEmpty) {
        return [];
      }

      final List<Map<String, String>> ensuredWeek = _ensureDatesInCachedWeek(
        result,
        cachedWeekDate: prefs.getString(_cachedPrayerWeekDateKey),
      );

      final bool hasSunrise = ensuredWeek.every((day) {
        final String? sunrise = day['sunrise'];
        return sunrise != null && sunrise.trim().isNotEmpty;
      });

      if (!hasSunrise) {
        return [];
      }

      return ensuredWeek;
    } catch (error) {
      debugPrint('⚠️ Failed to decode cached prayer week: $error');
      await prefs.remove(_cachedPrayerWeekKey);
      return [];
    }
  }

  Future<String?> getCachedPrayerWeekDate() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cachedPrayerWeekDateKey);
  }

  Future<String?> getCachedPrayerCountryIso() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? iso = prefs.getString(_cachedPrayerCountryIsoKey);
    return iso == null || iso.trim().isEmpty ? null : iso.trim().toUpperCase();
  }

  Future<String?> getCountryIsoForPosition(Position position) {
    return _detectCountryIso(position);
  }

  Future<({double latitude, double longitude})?>
  getCachedPrayerCoordinates() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final double? latitude = prefs.getDouble(_cachedPrayerLatitudeKey);
    final double? longitude = prefs.getDouble(_cachedPrayerLongitudeKey);

    if (latitude == null || longitude == null) {
      return null;
    }

    return (latitude: latitude, longitude: longitude);
  }

  Future<bool> hasFreshPrayerCacheForToday() async {
    final List<Map<String, String>> cachedWeek = await getCachedPrayerWeek();
    final String? cachedDate = await getCachedPrayerWeekDate();
    return cachedWeek.isNotEmpty && cachedDate == _todayKey();
  }

  List<Map<String, String>> _ensureDatesInCachedWeek(
      List<Map<String, String>> prayerWeek, {
        required String? cachedWeekDate,
      }) {
    final bool allDaysHaveDate = prayerWeek.every((day) {
      final String? dateText = day['date'];
      return dateText != null && dateText.trim().isNotEmpty;
    });

    if (allDaysHaveDate) {
      return prayerWeek;
    }

    final DateTime baseDate = _parseDateKey(cachedWeekDate) ?? DateTime.now();

    return List<Map<String, String>>.generate(prayerWeek.length, (index) {
      final Map<String, String> day = Map<String, String>.from(
        prayerWeek[index],
      );
      day['date'] = _dateKey(baseDate.add(Duration(days: index)));
      return day;
    });
  }

  Future<String?> _detectCountryIso(Position position) async {
    final String? fastIso = _countryIsoFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (fastIso != null) {
      return fastIso;
    }

    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final String? iso = placemarks.first.isoCountryCode;
        if (iso != null && iso.trim().isNotEmpty) {
          return iso.trim().toUpperCase();
        }
      }
    } catch (error) {
      debugPrint(
        '⚠️ Failed to detect country for prayer calculation method: $error',
      );
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? cachedIso = prefs.getString(_cachedPrayerCountryIsoKey);
    return cachedIso == null || cachedIso.trim().isEmpty
        ? null
        : cachedIso.trim().toUpperCase();
  }

  /// Bounding boxes سريعة للدول اللي ظهرت عندك فيها مشاكل/اختلافات.
  /// ده يمنع إن reverse geocoding يفشل ويرجعنا لطريقة حساب عامة غلط.
  String? _countryIsoFromCoordinates(double latitude, double longitude) {
    if (_inside(
      latitude: latitude,
      longitude: longitude,
      minLat: 22.0,
      maxLat: 31.9,
      minLng: 24.5,
      maxLng: 36.9,
    )) {
      return 'EG';
    }

    if (_inside(
      latitude: latitude,
      longitude: longitude,
      minLat: 32.0,
      maxLat: 37.5,
      minLng: 35.6,
      maxLng: 42.4,
    )) {
      return 'SY';
    }

    if (_inside(
      latitude: latitude,
      longitude: longitude,
      minLat: 35.7,
      maxLat: 42.2,
      minLng: 25.5,
      maxLng: 44.9,
    )) {
      return 'TR';
    }

    return null;
  }

  bool _inside({
    required double latitude,
    required double longitude,
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  }) {
    return latitude >= minLat &&
        latitude <= maxLat &&
        longitude >= minLng &&
        longitude <= maxLng;
  }

  CalculationParameters _getCalculationParameters(String? countryIso) {
    final String iso = countryIso?.trim().toUpperCase() ?? '';
    late final CalculationParameters params;

    switch (iso) {
      case 'EG':
        params = CalculationMethod.egyptian.getParameters();
        params.madhab = Madhab.shafi;
        params.fajrAngle = 19.5;
        params.ishaAngle = 17.5;
        break;

      case 'TR':
        params = CalculationMethod.turkey.getParameters();
        params.madhab = Madhab.shafi;
        params.fajrAngle = 18.0;
        params.ishaAngle = 17.0;
        break;

      case 'SY':
        params = CalculationMethod.muslim_world_league.getParameters();
        params.madhab = Madhab.shafi;
        params.fajrAngle = 18.0;
        params.ishaAngle = 17.0;
        break;

      case 'IR':
        params = CalculationMethod.tehran.getParameters();
        params.madhab = Madhab.shafi;
        params.fajrAngle = 17.7;
        params.ishaAngle = 14.0;
        break;

      case 'SA':
      case 'OM':
      case 'BH':
        params = CalculationMethod.umm_al_qura.getParameters();
        params.madhab = Madhab.shafi;
        params.fajrAngle = 18.5;
        params.ishaInterval = 90;
        break;

      case 'AE':
        params = CalculationMethod.dubai.getParameters();
        params.madhab = Madhab.shafi;
        params.fajrAngle = 18.2;
        params.ishaAngle = 18.2;
        break;

      case 'QA':
        params = CalculationMethod.qatar.getParameters();
        params.madhab = Madhab.shafi;
        params.fajrAngle = 18.0;
        params.ishaInterval = 90;
        break;

      case 'KW':
        params = CalculationMethod.kuwait.getParameters();
        params.madhab = Madhab.shafi;
        params.fajrAngle = 18.0;
        params.ishaAngle = 17.5;
        break;

      case 'PK':
      case 'IN':
      case 'BD':
        params = CalculationMethod.karachi.getParameters();
        params.madhab = Madhab.hanafi;
        params.fajrAngle = 18.0;
        params.ishaAngle = 18.0;
        break;

      case 'SG':
        params = CalculationMethod.singapore.getParameters();
        params.madhab = Madhab.shafi;
        params.fajrAngle = 20.0;
        params.ishaAngle = 18.0;
        break;

      case 'US':
      case 'CA':
      case 'AU':
        params = CalculationMethod.north_america.getParameters();
        params.madhab = Madhab.shafi;
        params.fajrAngle = 15.0;
        params.ishaAngle = 15.0;
        break;

      case 'GB':
      case 'FR':
      case 'DE':
      case 'NL':
      case 'ES':
      case 'IT':
        params = CalculationMethod.muslim_world_league.getParameters();
        params.madhab = Madhab.shafi;
        params.fajrAngle = 18.0;
        params.ishaAngle = 17.0;
        break;

      default:
        params = CalculationMethod.muslim_world_league.getParameters();
        params.madhab = Madhab.shafi;
        params.fajrAngle = 18.0;
        params.ishaAngle = 17.0;
        break;
    }

    return params;
  }

  String _formatTime(DateTime dateTime) {
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String _todayKey() {
    return _dateKey(DateTime.now());
  }

  String _dateKey(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  DateTime? _parseDateKey(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    try {
      final DateTime parsed = DateTime.parse(value);
      return DateTime(parsed.year, parsed.month, parsed.day);
    } catch (_) {
      return null;
    }
  }
}
