import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PrayerBackgroundStyle {
  automatic('automatic', 'حسب الموقع'),
  global('global', 'النمط الافتراضي'),
  egypt('egypt', 'مصر'),
  syria('syria', 'سوريا');

  const PrayerBackgroundStyle(this.storageValue, this.arabicLabel);

  final String storageValue;
  final String arabicLabel;

  // Egypt and Syria remain internal styles for backwards compatibility and
  // location-based pack resolution, but are no longer user-facing choices.
  static const List<PrayerBackgroundStyle> userSelectableValues = [
    PrayerBackgroundStyle.global,
    PrayerBackgroundStyle.automatic,
  ];

  static PrayerBackgroundStyle normalizeUserSelection(
    PrayerBackgroundStyle style,
  ) {
    switch (style) {
      case PrayerBackgroundStyle.egypt:
      case PrayerBackgroundStyle.syria:
        return PrayerBackgroundStyle.global;
      case PrayerBackgroundStyle.automatic:
      case PrayerBackgroundStyle.global:
        return style;
    }
  }

  static PrayerBackgroundStyle fromStorage(String? value) {
    for (final PrayerBackgroundStyle style in values) {
      if (style.storageValue == value) {
        return normalizeUserSelection(style);
      }
    }

    return PrayerBackgroundStyle.automatic;
  }
}

class PrayerBackgroundStyleService {
  const PrayerBackgroundStyleService();

  static const String storageKey = 'prayer_background_visual_style';

  Future<PrayerBackgroundStyle> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? storedValue = prefs.getString(storageKey);
    final PrayerBackgroundStyle style = PrayerBackgroundStyle.fromStorage(
      storedValue,
    );

    // Rewrite retired manual regional choices so all future readers see a
    // supported user-facing value. Global is the safest permission-free
    // fallback; users can still opt back into automatic location selection.
    if ((storedValue == PrayerBackgroundStyle.egypt.storageValue ||
            storedValue == PrayerBackgroundStyle.syria.storageValue) &&
        storedValue != style.storageValue) {
      await prefs.setString(storageKey, style.storageValue);
    }

    return style;
  }

  Future<void> save(PrayerBackgroundStyle style) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final PrayerBackgroundStyle normalized =
        PrayerBackgroundStyle.normalizeUserSelection(style);
    await prefs.setString(storageKey, normalized.storageValue);
  }
}

class PrayerBackgroundStyleProvider extends ChangeNotifier {
  PrayerBackgroundStyleProvider() {
    load();
  }

  final PrayerBackgroundStyleService _service =
      const PrayerBackgroundStyleService();

  PrayerBackgroundStyle _style = PrayerBackgroundStyle.automatic;
  bool _isLoaded = false;

  PrayerBackgroundStyle get style => _style;
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    _style = await _service.load();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setStyle(PrayerBackgroundStyle style) async {
    final PrayerBackgroundStyle normalized =
        PrayerBackgroundStyle.normalizeUserSelection(style);
    if (_style == normalized && _isLoaded) return;

    _style = normalized;
    _isLoaded = true;
    notifyListeners();

    await _service.save(normalized);
  }
}
