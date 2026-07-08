import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum HomeCardId {
  greeting,
  nextPrayer,
  smartZekr,
  worship,
  dailyBoost,
  video,
}

enum HomeCardSize {
  compact,
  normal,
  large,
}

enum WorshipShortcutId {
  prayer,
  quran,
  nightPray,
  azkar,
  ahadeth,
  events,
}

extension HomeCardIdX on HomeCardId {
  String get storageKey => name;

  String get title {
    switch (this) {
      case HomeCardId.greeting:
        return 'كارت الترحيب';
      case HomeCardId.nextPrayer:
        return 'موعد الصلاة القادمة';
      case HomeCardId.smartZekr:
        return 'أذكار الوقت';
      case HomeCardId.worship:
        return 'ثبت عبادتك';
      case HomeCardId.dailyBoost:
        return 'زاد يومك';
      case HomeCardId.video:
        return 'فيديو اليوم';
    }
  }

  String get subtitle {
    switch (this) {
      case HomeCardId.greeting:
        return 'رسالة ترحيب يومية باسم المستخدم.';
      case HomeCardId.nextPrayer:
        return 'الصلاة القادمة والوقت المتبقي واتجاه القبلة.';
      case HomeCardId.smartZekr:
        return 'يفتح أذكار الصباح أو المساء حسب الوقت.';
      case HomeCardId.worship:
        return 'الأقسام الأساسية داخل التطبيق، ولا يمكن حذفها.';
      case HomeCardId.dailyBoost:
        return 'دعاء أو فكرة يومية خفيفة.';
      case HomeCardId.video:
        return 'كارت الفيديوهات/الدروس.';
    }
  }

  bool get isRequired {
    switch (this) {
      case HomeCardId.worship:
        return true;
      case HomeCardId.greeting:
      case HomeCardId.nextPrayer:
      case HomeCardId.smartZekr:
      case HomeCardId.dailyBoost:
      case HomeCardId.video:
        return false;
    }
  }
}

extension HomeCardSizeX on HomeCardSize {
  String get storageKey => name;

  String get title {
    switch (this) {
      case HomeCardSize.compact:
        return 'صغير';
      case HomeCardSize.normal:
        return 'عادي';
      case HomeCardSize.large:
        return 'واسع';
    }
  }

  double get widthFactor {
    switch (this) {
      case HomeCardSize.compact:
        return 0.94;
      case HomeCardSize.normal:
      case HomeCardSize.large:
        return 1.0;
    }
  }

  EdgeInsets get outerPadding {
    switch (this) {
      case HomeCardSize.compact:
        return EdgeInsets.zero;
      case HomeCardSize.normal:
        return EdgeInsets.zero;
      case HomeCardSize.large:
        return const EdgeInsets.symmetric(horizontal: 0);
    }
  }
}

extension WorshipShortcutIdX on WorshipShortcutId {
  String get storageKey => name;

  String get title {
    switch (this) {
      case WorshipShortcutId.prayer:
        return 'الصلاة';
      case WorshipShortcutId.quran:
        return 'قرآن';
      case WorshipShortcutId.nightPray:
        return 'قيام الليل';
      case WorshipShortcutId.azkar:
        return 'أذكار';
      case WorshipShortcutId.ahadeth:
        return 'أحاديث';
      case WorshipShortcutId.events:
        return 'مناسبات';
    }
  }
}

@immutable
class HomeCardPreference {
  const HomeCardPreference({
    required this.id,
    required this.visible,
    required this.size,
  });

  final HomeCardId id;
  final bool visible;
  final HomeCardSize size;

  HomeCardPreference copyWith({
    bool? visible,
    HomeCardSize? size,
  }) {
    return HomeCardPreference(
      id: id,
      visible: visible ?? this.visible,
      size: size ?? this.size,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id.storageKey,
      'visible': id.isRequired ? true : visible,
      'size': size.storageKey,
    };
  }

  factory HomeCardPreference.fromJson(Map<String, dynamic> json) {
    final id = HomeInterfaceSettingsService.cardIdFromString(
      json['id']?.toString(),
    );

    return HomeCardPreference(
      id: id,
      visible: id.isRequired ? true : (json['visible'] as bool? ?? true),
      size: HomeInterfaceSettingsService.cardSizeFromString(
        json['size']?.toString(),
      ),
    );
  }
}

@immutable
class HomeInterfaceSettings {
  const HomeInterfaceSettings({
    required this.cards,
    required this.worshipShortcutsOrder,
  });

  final List<HomeCardPreference> cards;
  final List<WorshipShortcutId> worshipShortcutsOrder;

  factory HomeInterfaceSettings.defaults() {
    return HomeInterfaceSettings(
      cards: HomeCardId.values
          .map(
            (id) => HomeCardPreference(
              id: id,
              visible: true,
              size: HomeCardSize.normal,
            ),
          )
          .toList(),
      worshipShortcutsOrder: WorshipShortcutId.values.toList(),
    );
  }

  HomeInterfaceSettings copyWith({
    List<HomeCardPreference>? cards,
    List<WorshipShortcutId>? worshipShortcutsOrder,
  }) {
    return HomeInterfaceSettings(
      cards: cards ?? this.cards,
      worshipShortcutsOrder:
          worshipShortcutsOrder ?? this.worshipShortcutsOrder,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cards': cards.map((card) => card.toJson()).toList(),
      'worshipShortcutsOrder':
          worshipShortcutsOrder.map((item) => item.storageKey).toList(),
    };
  }

  factory HomeInterfaceSettings.fromJson(Map<String, dynamic> json) {
    final defaults = HomeInterfaceSettings.defaults();

    final rawCards = json['cards'];
    final parsedCards = rawCards is List
        ? rawCards
            .whereType<Map>()
            .map(
              (item) => HomeCardPreference.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
        : <HomeCardPreference>[];

    final cards = <HomeCardPreference>[];

    for (final defaultCard in defaults.cards) {
      final saved = parsedCards.where((card) => card.id == defaultCard.id);

      cards.add(saved.isEmpty ? defaultCard : saved.first);
    }

    final rawShortcuts = json['worshipShortcutsOrder'];
    final parsedShortcuts = rawShortcuts is List
        ? rawShortcuts
            .map((item) => HomeInterfaceSettingsService.shortcutIdFromString(
                  item?.toString(),
                ))
            .toList()
        : <WorshipShortcutId>[];

    final uniqueShortcuts = <WorshipShortcutId>[];

    for (final shortcut in parsedShortcuts) {
      if (!uniqueShortcuts.contains(shortcut)) {
        uniqueShortcuts.add(shortcut);
      }
    }

    for (final shortcut in WorshipShortcutId.values) {
      if (!uniqueShortcuts.contains(shortcut)) {
        uniqueShortcuts.add(shortcut);
      }
    }

    return HomeInterfaceSettings(
      cards: cards,
      worshipShortcutsOrder: uniqueShortcuts,
    );
  }
}

class HomeInterfaceSettingsService {
  const HomeInterfaceSettingsService();

  static const String _storageKey = 'home_interface_settings_v1';

  Future<HomeInterfaceSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.trim().isEmpty) {
      return HomeInterfaceSettings.defaults();
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! Map) {
        return HomeInterfaceSettings.defaults();
      }

      return HomeInterfaceSettings.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      return HomeInterfaceSettings.defaults();
    }
  }

  Future<void> save(HomeInterfaceSettings settings) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _storageKey,
      jsonEncode(settings.toJson()),
    );
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  static HomeCardId cardIdFromString(String? value) {
    for (final id in HomeCardId.values) {
      if (id.storageKey == value) return id;
    }

    return HomeCardId.greeting;
  }

  static HomeCardSize cardSizeFromString(String? value) {
    for (final size in HomeCardSize.values) {
      if (size.storageKey == value) return size;
    }

    return HomeCardSize.normal;
  }

  static WorshipShortcutId shortcutIdFromString(String? value) {
    for (final id in WorshipShortcutId.values) {
      if (id.storageKey == value) return id;
    }

    return WorshipShortcutId.prayer;
  }
}
