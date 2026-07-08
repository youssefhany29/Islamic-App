import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'quran_reader_theme.dart';

class QuranReaderThemeController extends ChangeNotifier {
  QuranReaderThemeController._();

  static final QuranReaderThemeController instance =
  QuranReaderThemeController._();

  static const String _storageKey = 'quran_reader_theme_id';

  QuranReaderThemeId _themeId = QuranReaderThemeId.classicCream;
  bool _initialized = false;

  QuranReaderThemeId get themeId => _themeId;

  QuranReaderTheme get theme => QuranReaderTheme.byId(_themeId);

  bool get initialized => _initialized;

  Future<void> init() async {
    if (_initialized) {
      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _themeId = QuranReaderThemeIdX.fromStorageValue(
      prefs.getString(_storageKey),
    );

    _initialized = true;
    notifyListeners();
  }

  Future<void> setTheme(QuranReaderThemeId id) async {
    if (_themeId == id) {
      return;
    }

    _themeId = id;
    notifyListeners();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, id.storageValue);
  }
}
