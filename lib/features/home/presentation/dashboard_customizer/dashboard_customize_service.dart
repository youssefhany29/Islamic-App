import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class DashboardCustomizeService {
  const DashboardCustomizeService();

  static const String _mainOrderKey = 'home_dashboard_main_order_v4';
  static const String _hiddenKey = 'home_dashboard_hidden_v4';
  static const String _videoSizeKey = 'home_dashboard_video_sizes_v4';
  static const String _worshipOrderKey = 'home_dashboard_worship_order_v4';

  static const List<String> defaultMainOrder = [
    DashboardTileIds.greeting,
    DashboardTileIds.nextPrayer,
    DashboardTileIds.azkar,
    DashboardTileIds.worship,
    DashboardTileIds.dailyChange,
    DashboardTileIds.recitations,
    DashboardTileIds.podcasts,
    DashboardTileIds.lessons,
  ];

  static const List<String> defaultWorshipOrder = [
    WorshipTileIds.prayer,
    WorshipTileIds.quran,
    WorshipTileIds.azkar,
    WorshipTileIds.hadith,
    WorshipTileIds.events,
  ];

  static const Map<String, bool> defaultVideoWideMap = {
    DashboardTileIds.recitations: false,
    DashboardTileIds.podcasts: false,
    DashboardTileIds.lessons: true,
  };

  Future<DashboardCustomizeState> load() async {
    final prefs = await SharedPreferences.getInstance();

    final mainOrder = _safeStringList(
      prefs.getStringList(_mainOrderKey),
      defaultMainOrder,
    );

    final hidden = prefs.getStringList(_hiddenKey) ?? <String>[];

    final worshipOrder = _safeStringList(
      prefs.getStringList(_worshipOrderKey),
      defaultWorshipOrder,
    );

    final videoWideMap = _decodeVideoWideMap(prefs.getString(_videoSizeKey));

    return DashboardCustomizeState(
      mainOrder: mainOrder,
      hiddenTileIds: hidden.where(_isHideable).toSet(),
      worshipOrder: worshipOrder,
      videoWideMap: videoWideMap,
    );
  }

  Future<void> save(DashboardCustomizeState state) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      _mainOrderKey,
      _safeStringList(state.mainOrder, defaultMainOrder),
    );

    await prefs.setStringList(
      _hiddenKey,
      state.hiddenTileIds.where(_isHideable).toList(growable: false),
    );

    await prefs.setStringList(
      _worshipOrderKey,
      _safeStringList(state.worshipOrder, defaultWorshipOrder),
    );

    await prefs.setString(_videoSizeKey, jsonEncode(state.videoWideMap));
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_mainOrderKey);
    await prefs.remove(_hiddenKey);
    await prefs.remove(_videoSizeKey);
    await prefs.remove(_worshipOrderKey);
  }

  static bool canHide(String id) {
    return _isHideable(id);
  }

  static bool isVideoTile(String id) {
    return id == DashboardTileIds.recitations ||
        id == DashboardTileIds.podcasts ||
        id == DashboardTileIds.lessons;
  }

  static String tileTitle(String id) {
    switch (id) {
      case DashboardTileIds.greeting:
        return 'أهلًا ضيفنا';
      case DashboardTileIds.nextPrayer:
        return 'الصلاة القادمة';
      case DashboardTileIds.azkar:
        return 'أذكار اليوم';
      case DashboardTileIds.worship:
        return 'ثبت عبادتك';
      case DashboardTileIds.dailyChange:
        return 'زاد يومك';
      case DashboardTileIds.tabletStats:
        return 'لوحة المتابعة';
      case DashboardTileIds.recitations:
        return 'تلاوة';
      case DashboardTileIds.podcasts:
        return 'بودكاست';
      case DashboardTileIds.lessons:
        return 'حلقة الحفظ';
      default:
        return id;
    }
  }

  static String worshipTitle(String id) {
    switch (id) {
      case WorshipTileIds.prayer:
        return 'الصلاة';
      case WorshipTileIds.quran:
        return 'قرآن';
      case WorshipTileIds.azkar:
        return 'أذكار';
      case WorshipTileIds.hadith:
        return 'أحاديث';
      case WorshipTileIds.events:
        return 'مناسبات';
      default:
        return id;
    }
  }

  static bool _isHideable(String id) {
    return id != DashboardTileIds.worship && id != DashboardTileIds.tabletStats;
  }

  static List<String> _safeStringList(
    List<String>? saved,
    List<String> defaults,
  ) {
    final safe = <String>[];
    final input = saved ?? defaults;

    for (final id in input) {
      if (defaults.contains(id) && !safe.contains(id)) {
        safe.add(id);
      }
    }

    for (final id in defaults) {
      if (!safe.contains(id)) {
        safe.add(id);
      }
    }

    return safe;
  }

  static Map<String, bool> _decodeVideoWideMap(String? raw) {
    final result = Map<String, bool>.from(defaultVideoWideMap);

    if (raw == null || raw.trim().isEmpty) return result;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        for (final entry in decoded.entries) {
          if (isVideoTile(entry.key) && entry.value is bool) {
            result[entry.key] = entry.value as bool;
          }
        }
      }
    } catch (_) {
      return result;
    }

    return result;
  }
}

class DashboardCustomizeState {
  const DashboardCustomizeState({
    required this.mainOrder,
    required this.hiddenTileIds,
    required this.worshipOrder,
    required this.videoWideMap,
  });

  final List<String> mainOrder;
  final Set<String> hiddenTileIds;
  final List<String> worshipOrder;
  final Map<String, bool> videoWideMap;

  DashboardCustomizeState copyWith({
    List<String>? mainOrder,
    Set<String>? hiddenTileIds,
    List<String>? worshipOrder,
    Map<String, bool>? videoWideMap,
  }) {
    return DashboardCustomizeState(
      mainOrder: mainOrder ?? this.mainOrder,
      hiddenTileIds: hiddenTileIds ?? this.hiddenTileIds,
      worshipOrder: worshipOrder ?? this.worshipOrder,
      videoWideMap: videoWideMap ?? this.videoWideMap,
    );
  }
}

class DashboardTileIds {
  const DashboardTileIds._();

  static const String greeting = 'greeting';
  static const String nextPrayer = 'next_prayer';
  static const String azkar = 'azkar';
  static const String worship = 'worship';
  static const String dailyChange = 'daily_change';
  static const String tabletStats = 'tablet_stats';
  static const String recitations = 'video_recitations';
  static const String podcasts = 'video_podcasts';
  static const String lessons = 'video_lessons';
}

class WorshipTileIds {
  const WorshipTileIds._();

  static const String prayer = 'worship_prayer';
  static const String quran = 'worship_quran';
  static const String azkar = 'worship_azkar';
  static const String hadith = 'worship_hadith';
  static const String events = 'worship_events';
}
