import 'package:hijri_calendar/hijri_calendar.dart';
import 'package:islamic_app/features/settings/prayer_background_style_provider.dart';

enum PrayerBackgroundPack { global, egypt, syria, gulf, ramadan, eid }

class PrayerHeroBackgroundChoice {
  const PrayerHeroBackgroundChoice({
    required this.asset,
    required this.pack,
    required this.period,
    required this.availableAssets,
  });

  final String asset;
  final PrayerBackgroundPack pack;
  final String period;
  final List<String> availableAssets;
}

class PrayerHeroBackgroundResolver {
  const PrayerHeroBackgroundResolver._();

  static const String fallbackAsset =
      'assets/prayerTimeChangeable/default/maghrib/maghrib_01.webp';

  static const String _ramadanNightAsset =
      'assets/prayerTimeChangeable/default/isha/RamadanNight.webp';

  static const String _laylatAlQadrAsset =
      'assets/prayerTimeChangeable/default/isha/LaylatAl-Qadr.webp';

  static const Map<PrayerBackgroundPack, Map<String, List<String>>> packs = {
    PrayerBackgroundPack.global: {
      'fajr': [
        'assets/prayerTimeChangeable/default/fajr/Fajr.webp',
        'assets/prayerTimeChangeable/default/fajr/MountainMosque.webp',
      ],
      'sunrise': [
        'assets/prayerTimeChangeable/default/sunrise/FridaySunrise - Copy.webp',
        'assets/prayerTimeChangeable/default/sunrise/FridaySunrise.webp',
        'assets/prayerTimeChangeable/default/sunrise/PinkSunrise.webp',
        'assets/prayerTimeChangeable/default/sunrise/sunrise_01.webp',
      ],
      'dhuhr': [
        'assets/prayerTimeChangeable/default/dhuhr/CoastalDhuhr.webp',
        'assets/prayerTimeChangeable/default/dhuhr/dhuhr_01.webp',
      ],
      'asr': [
        'assets/prayerTimeChangeable/default/asr/asr_01.webp',
        'assets/prayerTimeChangeable/default/asr/PeacefulAsr.webp',
      ],
      'maghrib': [
        'assets/prayerTimeChangeable/default/maghrib/maghrib_01.webp',
        'assets/prayerTimeChangeable/default/maghrib/SummerMaghrib.webp',
      ],
      'isha': ['assets/prayerTimeChangeable/default/isha/Isha.webp'],
    },
    PrayerBackgroundPack.egypt: {
      'fajr': [
        'assets/prayerTimeChangeable/egypt/fajr/fajr_1.webp',
        'assets/prayerTimeChangeable/egypt/fajr/fajr_nile.webp',
      ],
      'sunrise': [
        'assets/prayerTimeChangeable/egypt/sunrise/sunrise_1 (1).webp',
        'assets/prayerTimeChangeable/egypt/sunrise/sunrise_1 (2).webp',
      ],
      'dhuhr': [
        'assets/prayerTimeChangeable/egypt/dhuhur/dhuhur_1.webp',
        'assets/prayerTimeChangeable/egypt/dhuhur/dhuhur_2.webp',
      ],
      'asr': [
        'assets/prayerTimeChangeable/egypt/asr/asr_2.webp',
        'assets/prayerTimeChangeable/egypt/asr/asr_3.webp',
      ],
      'maghrib': [
        'assets/prayerTimeChangeable/egypt/maghrip/maghrib_2.webp',
        'assets/prayerTimeChangeable/egypt/maghrip/maghrib_nile.webp',
      ],
      'isha': [
        'assets/prayerTimeChangeable/egypt/isha/isha_4.webp',
        'assets/prayerTimeChangeable/egypt/isha/isha_nile.webp',
      ],
    },
    PrayerBackgroundPack.syria: {
      'fajr': [
        'assets/prayerTimeChangeable/syria/fajr/fajr_sy.webp',
        'assets/prayerTimeChangeable/syria/fajr/fajr_sy_2.webp',
      ],
      'sunrise': [
        'assets/prayerTimeChangeable/syria/sunrise/sunrise_sy.webp',
        'assets/prayerTimeChangeable/syria/sunrise/sunrise_sy_2.webp',
      ],
      'dhuhr': [
        'assets/prayerTimeChangeable/syria/dhuhur/dhuhur_1.webp',
        'assets/prayerTimeChangeable/syria/dhuhur/syr_1.webp',
        'assets/prayerTimeChangeable/syria/dhuhur/syr_2.webp',
      ],
      'asr': [
        'assets/prayerTimeChangeable/syria/asr/asr_sy.webp',
        'assets/prayerTimeChangeable/syria/asr/sunrrise_sy.webp',
      ],
      'maghrib': [
        'assets/prayerTimeChangeable/syria/maghrib/maghrib_1 (1).webp',
        'assets/prayerTimeChangeable/syria/maghrib/maghrib_3.webp',
      ],
      'isha': [
        'assets/prayerTimeChangeable/syria/isha/isha_2.webp',
        'assets/prayerTimeChangeable/syria/isha/isha_3.webp',
      ],
    },
    PrayerBackgroundPack.gulf: {},
    PrayerBackgroundPack.ramadan: {
      'fajr': ['assets/prayerTimeChangeable/default/ramadan/fajr/r_4.webp'],
      'sunrise': ['assets/prayerTimeChangeable/default/ramadan/sunrise/3.webp'],
      'dhuhr': ['assets/prayerTimeChangeable/default/ramadan/dhuhur/1.webp'],
      'asr': [
        'assets/prayerTimeChangeable/default/ramadan/asr/3.webp',
        'assets/prayerTimeChangeable/default/ramadan/asr/4.webp',
      ],
      'maghrib': ['assets/prayerTimeChangeable/default/ramadan/maghrib/3.webp'],
      'isha': [
        'assets/prayerTimeChangeable/default/ramadan/isha/2.webp',
        'assets/prayerTimeChangeable/default/ramadan/isha/3.webp',
        _ramadanNightAsset,
      ],
    },
    PrayerBackgroundPack.eid: {
      'fajr': ['assets/prayerTimeChangeable/default/eid/fajr/3.webp'],
      'sunrise': [
        'assets/prayerTimeChangeable/default/eid/sunrise/EidMorning.webp',
      ],
      'dhuhr': [
        'assets/prayerTimeChangeable/default/eid/dhuhur/1.webp',
        'assets/prayerTimeChangeable/default/eid/dhuhur/2.webp',
      ],
      'asr': [],
      'maghrib': [],
      'isha': ['assets/prayerTimeChangeable/default/eid/isha/EidNight.webp'],
    },
  };

  static const Map<String, Map<String, List<String>>> _ramadanCountryPacks = {
    'EG': {},
  };

  static String resolve({
    required List<Map<String, String>> prayerWeek,
    String? countryIso,
    DateTime? now,
    PrayerBackgroundStyle backgroundStyle = PrayerBackgroundStyle.automatic,
  }) {
    return resolveChoice(
      prayerWeek: prayerWeek,
      countryIso: countryIso,
      now: now,
      backgroundStyle: backgroundStyle,
    ).asset;
  }

  static PrayerHeroBackgroundChoice resolveChoice({
    required List<Map<String, String>> prayerWeek,
    String? countryIso,
    DateTime? now,
    PrayerBackgroundStyle backgroundStyle = PrayerBackgroundStyle.automatic,
  }) {
    final DateTime currentTime = now ?? DateTime.now();
    final String period = resolvePeriod(
      prayerWeek: prayerWeek,
      now: currentTime,
    );
    final String? detectedCountryIso =
        _countryIsoFromPrayerWeek(prayerWeek) ?? countryIso;
    final String? effectiveCountryIso = _countryIsoForStyle(
      backgroundStyle: backgroundStyle,
      detectedCountryIso: detectedCountryIso,
    );
    final PrayerBackgroundPack preferredPack = _packFor(
      date: currentTime,
      countryIso: effectiveCountryIso,
    );
    final List<String> assets = _assetsForContext(
      pack: preferredPack,
      period: period,
      date: currentTime,
      countryIso: effectiveCountryIso,
    );
    final PrayerBackgroundPack effectivePack = assets.isEmpty
        ? PrayerBackgroundPack.global
        : preferredPack;
    final List<String> effectiveAssets = assets.isEmpty
        ? _assetsForContext(
            pack: PrayerBackgroundPack.global,
            period: period,
            date: currentTime,
            countryIso: effectiveCountryIso,
          )
        : assets;

    if (effectiveAssets.isEmpty) {
      return PrayerHeroBackgroundChoice(
        asset: fallbackAsset,
        pack: PrayerBackgroundPack.global,
        period: period,
        availableAssets: const [fallbackAsset],
      );
    }

    final String selectedAsset = _stableRotatedAsset(
      date: currentTime,
      period: period,
      countryIso: effectiveCountryIso,
      pack: effectivePack,
      assets: effectiveAssets,
      backgroundStyle: backgroundStyle,
    );

    return PrayerHeroBackgroundChoice(
      asset: selectedAsset,
      pack: effectivePack,
      period: period,
      availableAssets: effectiveAssets,
    );
  }

  static PrayerBackgroundPack _packFor({
    required DateTime date,
    required String? countryIso,
  }) {
    if (_isEidDay(date)) return PrayerBackgroundPack.eid;
    if (_isRamadan(date)) return PrayerBackgroundPack.ramadan;

    final String iso = countryIso?.trim().toUpperCase() ?? '';
    if (iso == 'EG') return PrayerBackgroundPack.egypt;
    if (iso == 'SY') return PrayerBackgroundPack.syria;

    return PrayerBackgroundPack.global;
  }

  static String? _countryIsoForStyle({
    required PrayerBackgroundStyle backgroundStyle,
    required String? detectedCountryIso,
  }) {
    switch (backgroundStyle) {
      case PrayerBackgroundStyle.automatic:
        final String iso = detectedCountryIso?.trim().toUpperCase() ?? '';
        return iso.isEmpty ? null : iso;
      case PrayerBackgroundStyle.global:
        return null;
      case PrayerBackgroundStyle.egypt:
        return 'EG';
      case PrayerBackgroundStyle.syria:
        return 'SY';
    }
  }

  static List<String> _assetsForPack(PrayerBackgroundPack pack, String period) {
    return List<String>.of(packs[pack]?[period] ?? const <String>[]);
  }

  static List<String> _assetsForContext({
    required PrayerBackgroundPack pack,
    required String period,
    required DateTime date,
    required String? countryIso,
  }) {
    if (pack == PrayerBackgroundPack.ramadan) {
      final List<String> countryAssets =
          _ramadanCountryPacks[countryIso?.trim().toUpperCase()]?[period] ??
          const <String>[];

      if (countryAssets.isNotEmpty) {
        return List<String>.of(countryAssets);
      }
    }

    final List<String> assets = _assetsForPack(pack, period);

    if (pack == PrayerBackgroundPack.ramadan &&
        period == 'isha' &&
        _isLastTenRamadanNights(date)) {
      return <String>[...assets, _laylatAlQadrAsset];
    }

    return assets;
  }

  static String resolvePeriod({
    required List<Map<String, String>> prayerWeek,
    required DateTime now,
  }) {
    if (prayerWeek.isEmpty) return 'maghrib';

    final Map<String, String> today =
        _findDay(prayerWeek, now) ?? prayerWeek.first;
    final DateTime todayDate =
        _parseDate(today['date']) ?? DateTime(now.year, now.month, now.day);

    final Map<String, String>? tomorrow =
        _findDay(prayerWeek, todayDate.add(const Duration(days: 1))) ??
        (prayerWeek.length > 1 ? prayerWeek[1] : null);

    final DateTime? fajr = _parseTime(today['fajr'], todayDate);
    final DateTime? sunrise = _parseTime(today['sunrise'], todayDate);
    final DateTime? asr = _parseTime(today['asr'], todayDate);
    final DateTime? maghrib = _parseTime(today['maghrib'], todayDate);

    final DateTime tenAm = DateTime(
      todayDate.year,
      todayDate.month,
      todayDate.day,
      10,
    );

    final DateTime? tomorrowDate = tomorrow == null
        ? null
        : (_parseDate(tomorrow['date']) ??
              todayDate.add(const Duration(days: 1)));

    final DateTime? nextFajr = tomorrow == null
        ? fajr?.add(const Duration(days: 1))
        : _parseTime(tomorrow['fajr'], tomorrowDate!);

    final List<_PeriodStart> starts = [
      if (fajr != null)
        _PeriodStart('fajr', fajr.subtract(const Duration(minutes: 60))),
      if (sunrise != null)
        _PeriodStart('sunrise', sunrise.subtract(const Duration(minutes: 20))),
      _PeriodStart('dhuhr', tenAm),
      if (asr != null)
        _PeriodStart('asr', asr.subtract(const Duration(minutes: 45))),
      if (maghrib != null)
        _PeriodStart('maghrib', maghrib.subtract(const Duration(minutes: 45))),
      if (maghrib != null)
        _PeriodStart('isha', maghrib.add(const Duration(minutes: 60))),
      if (nextFajr != null)
        _PeriodStart('fajr', nextFajr.subtract(const Duration(minutes: 60))),
    ]..sort((a, b) => a.start.compareTo(b.start));

    String period = 'isha';

    for (final _PeriodStart item in starts) {
      if (now.isBefore(item.start)) {
        break;
      }

      period = item.period;
    }

    return period;
  }

  static Map<String, String>? _findDay(
    List<Map<String, String>> prayerWeek,
    DateTime date,
  ) {
    for (final Map<String, String> day in prayerWeek) {
      final DateTime? parsed = _parseDate(day['date']);
      if (parsed == null) continue;

      if (parsed.year == date.year &&
          parsed.month == date.month &&
          parsed.day == date.day) {
        return day;
      }
    }

    return null;
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    try {
      final DateTime parsed = DateTime.parse(value.trim());
      return DateTime(parsed.year, parsed.month, parsed.day);
    } catch (_) {
      return null;
    }
  }

  static DateTime? _parseTime(String? time, DateTime baseDate) {
    if (time == null || !time.contains(':')) return null;

    final List<String> parts = time.split(':');
    if (parts.length < 2) return null;

    final int? hour = int.tryParse(parts[0]);
    final int? minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return null;

    return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
  }

  static String _stableRotatedAsset({
    required DateTime date,
    required String period,
    required PrayerBackgroundPack pack,
    required List<String> assets,
    required PrayerBackgroundStyle backgroundStyle,
    String? countryIso,
  }) {
    final List<String> validAssets = assets
        .where((asset) => asset.trim().isNotEmpty)
        .toList(growable: false);

    if (validAssets.isEmpty) {
      return fallbackAsset;
    }

    if (validAssets.length == 1) {
      return validAssets.first;
    }

    final int index = _stableBackgroundRotationIndex(
      date: date,
      period: period,
      countryIso: countryIso,
      pack: pack,
      length: validAssets.length,
      backgroundStyle: backgroundStyle,
    );

    return validAssets[index];
  }

  // Keeps background choice stable for one prayer period/day/country context,
  // while still cycling through all images over time when a pack has variety.
  static int _stableBackgroundRotationIndex({
    required DateTime date,
    required String period,
    required PrayerBackgroundPack pack,
    required int length,
    required PrayerBackgroundStyle backgroundStyle,
    String? countryIso,
  }) {
    if (length <= 1) return 0;

    final DateTime cleanDate = DateTime(date.year, date.month, date.day);
    final int dayNumber = cleanDate.difference(DateTime(cleanDate.year)).inDays;
    final int absoluteDay = cleanDate.difference(DateTime(2000, 1, 1)).inDays;
    final HijriCalendarConfig? hijri = _hijriDate(cleanDate);
    final int hijriMonth = hijri?.hMonth ?? 0;
    final int hijriDay = hijri?.hDay ?? 0;
    final int daySeed = absoluteDay + (hijriMonth * 32) + hijriDay;
    final String countrySegment =
        backgroundStyle == PrayerBackgroundStyle.automatic
        ? countryIso ?? ''
        : '';
    final String key =
        '${cleanDate.year}-$dayNumber-$period-${pack.name}-${backgroundStyle.storageValue}-$countrySegment-$hijriMonth';
    final int start = _hash('$key-start') % length;
    final int step = _coprimeRotationStep(
      hash: _hash('$key-step'),
      length: length,
    );

    return (start + daySeed * step) % length;
  }

  static int _coprimeRotationStep({required int hash, required int length}) {
    if (length <= 1) return 0;

    int step = (hash % (length - 1)) + 1;
    while (_greatestCommonDivisor(step, length) != 1) {
      step = (step % (length - 1)) + 1;
    }

    return step;
  }

  static int _greatestCommonDivisor(int a, int b) {
    int x = a.abs();
    int y = b.abs();

    while (y != 0) {
      final int next = x % y;
      x = y;
      y = next;
    }

    return x == 0 ? 1 : x;
  }

  static int _hash(String key) {
    int hash = 0;

    for (final int codeUnit in key.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }

    return hash;
  }

  static String? _countryIsoFromPrayerWeek(
    List<Map<String, String>> prayerWeek,
  ) {
    for (final Map<String, String> day in prayerWeek) {
      final String? iso = day['countryIso'];
      if (iso != null && iso.trim().isNotEmpty) {
        return iso.trim().toUpperCase();
      }
    }

    return null;
  }

  static bool _isRamadan(DateTime date) {
    final HijriCalendarConfig? hijri = _hijriDate(date);
    return hijri?.hMonth == 9;
  }

  static bool _isLastTenRamadanNights(DateTime date) {
    final HijriCalendarConfig? hijri = _hijriDate(date);
    return hijri?.hMonth == 9 && (hijri?.hDay ?? 0) >= 20;
  }

  static bool _isEidDay(DateTime date) {
    final HijriCalendarConfig? hijri = _hijriDate(date);
    if (hijri == null) return false;

    return (hijri.hMonth == 10 && hijri.hDay >= 1 && hijri.hDay <= 3) ||
        (hijri.hMonth == 12 && hijri.hDay >= 10 && hijri.hDay <= 13);
  }

  static HijriCalendarConfig? _hijriDate(DateTime date) {
    try {
      return HijriCalendarConfig.fromGregorian(date);
    } catch (_) {
      return null;
    }
  }
}

class _PeriodStart {
  const _PeriodStart(this.period, this.start);

  final String period;
  final DateTime start;
}
