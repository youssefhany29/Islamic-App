import 'package:shared_preferences/shared_preferences.dart';

import 'data/qpc_reader_perf.dart';

class QuranLastRead {
  final int suraIndex;
  final int ayahIndex;
  final String viewMode;
  final int mushafPageNumber;

  const QuranLastRead({
    required this.suraIndex,
    required this.ayahIndex,
    required this.viewMode,
    required this.mushafPageNumber,
  });
}

class QuranReaderStorage {
  static Future<SharedPreferences>? _prefsFuture;

  static const String _lastSuraKey = 'quran_last_sura_index';
  static const String _lastAyahKey = 'quran_last_ayah_index';
  static const String _lastViewModeKey = 'quran_last_view_mode';
  static const String _lastMushafPageKey = 'quran_last_mushaf_page_number';

  static const String _mushafOpenSuraKey = 'quran_mushaf_open_sura_index';
  static const String _mushafOpenAyahKey = 'quran_mushaf_open_ayah_index';
  static const String _mushafOpenViewModeKey = 'quran_mushaf_open_view_mode';
  static const String _mushafOpenPageKey = 'quran_mushaf_open_page_number';

  static Future<SharedPreferences> _prefs() {
    return _prefsFuture ??= SharedPreferences.getInstance();
  }

  static Future<void> saveLastRead({
    required int suraIndex,
    required int ayahIndex,
    required String viewMode,
    int? mushafPageNumber,
  }) async {
    await QpcReaderPerf.timeAsync(
      'save last read p$mushafPageNumber',
      () async {
        final prefs = await _prefs();

        await prefs.setInt(_lastSuraKey, suraIndex);
        await prefs.setInt(_lastAyahKey, ayahIndex);
        await prefs.setString(_lastViewModeKey, viewMode);

        if (mushafPageNumber != null) {
          await prefs.setInt(_lastMushafPageKey, mushafPageNumber);
        }
      },
    );
  }

  static Future<QuranLastRead?> getLastRead() async {
    final prefs = await _prefs();

    final suraIndex = prefs.getInt(_lastSuraKey);
    final ayahIndex = prefs.getInt(_lastAyahKey);
    final viewMode = prefs.getString(_lastViewModeKey) ?? 'continuous';
    final mushafPageNumber = prefs.getInt(_lastMushafPageKey) ?? 1;

    if (suraIndex == null || ayahIndex == null) {
      return null;
    }

    return QuranLastRead(
      suraIndex: suraIndex,
      ayahIndex: ayahIndex,
      viewMode: viewMode,
      mushafPageNumber: mushafPageNumber,
    );
  }

  static Future<void> saveMushafOpenProgress({
    required int suraIndex,
    required int ayahIndex,
    required String viewMode,
    int? mushafPageNumber,
  }) async {
    await QpcReaderPerf.timeAsync(
      'save mushaf open progress p$mushafPageNumber',
      () async {
        final prefs = await _prefs();

        await prefs.setInt(_mushafOpenSuraKey, suraIndex);
        await prefs.setInt(_mushafOpenAyahKey, ayahIndex);
        await prefs.setString(_mushafOpenViewModeKey, viewMode);

        if (mushafPageNumber != null) {
          await prefs.setInt(_mushafOpenPageKey, mushafPageNumber);
        }
      },
    );
  }

  static Future<QuranLastRead?> getMushafOpenProgress() async {
    final prefs = await _prefs();

    final suraIndex = prefs.getInt(_mushafOpenSuraKey);
    final ayahIndex = prefs.getInt(_mushafOpenAyahKey);
    final viewMode = prefs.getString(_mushafOpenViewModeKey) ?? 'pngMushaf';
    final mushafPageNumber = prefs.getInt(_mushafOpenPageKey) ?? 1;

    if (suraIndex == null || ayahIndex == null) {
      return null;
    }

    return QuranLastRead(
      suraIndex: suraIndex,
      ayahIndex: ayahIndex,
      viewMode: viewMode,
      mushafPageNumber: mushafPageNumber,
    );
  }

  static Future<void> clearMushafOpenProgress() async {
    final prefs = await _prefs();

    await prefs.remove(_mushafOpenSuraKey);
    await prefs.remove(_mushafOpenAyahKey);
    await prefs.remove(_mushafOpenViewModeKey);
    await prefs.remove(_mushafOpenPageKey);
  }

  static Future<void> clearLastRead() async {
    final prefs = await _prefs();

    await prefs.remove(_lastSuraKey);
    await prefs.remove(_lastAyahKey);
    await prefs.remove(_lastViewModeKey);
    await prefs.remove(_lastMushafPageKey);
  }
}
