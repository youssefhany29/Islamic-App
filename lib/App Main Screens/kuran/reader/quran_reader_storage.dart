import 'package:shared_preferences/shared_preferences.dart';

class QuranLastRead {
  final int suraIndex;
  final int ayahIndex;
  final String viewMode;

  const QuranLastRead({
    required this.suraIndex,
    required this.ayahIndex,
    required this.viewMode,
  });
}

class QuranReaderStorage {
  static const String _lastSuraKey = 'quran_last_sura_index';
  static const String _lastAyahKey = 'quran_last_ayah_index';
  static const String _lastViewModeKey = 'quran_last_view_mode';

  static Future<void> saveLastRead({
    required int suraIndex,
    required int ayahIndex,
    required String viewMode,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_lastSuraKey, suraIndex);
    await prefs.setInt(_lastAyahKey, ayahIndex);
    await prefs.setString(_lastViewModeKey, viewMode);
  }

  static Future<QuranLastRead?> getLastRead() async {
    final prefs = await SharedPreferences.getInstance();

    final suraIndex = prefs.getInt(_lastSuraKey);
    final ayahIndex = prefs.getInt(_lastAyahKey);
    final viewMode = prefs.getString(_lastViewModeKey) ?? 'continuous';

    if (suraIndex == null || ayahIndex == null) {
      return null;
    }

    return QuranLastRead(
      suraIndex: suraIndex,
      ayahIndex: ayahIndex,
      viewMode: viewMode,
    );
  }
}