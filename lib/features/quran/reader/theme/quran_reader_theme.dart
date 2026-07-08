import 'package:flutter/material.dart';

enum QuranReaderThemeId {
  appBlue,
  lightIvory,
  classicCream,
  warmBeige,
  softGreen,
}

extension QuranReaderThemeIdX on QuranReaderThemeId {
  String get storageValue {
    switch (this) {
      case QuranReaderThemeId.appBlue:
        return 'app_blue';
      case QuranReaderThemeId.lightIvory:
        return 'light_ivory';
      case QuranReaderThemeId.classicCream:
        return 'classic_cream';
      case QuranReaderThemeId.warmBeige:
        return 'warm_beige';
      case QuranReaderThemeId.softGreen:
        return 'soft_green';
    }
  }

  String get label {
    switch (this) {
      case QuranReaderThemeId.appBlue:
        return 'لون التطبيق';
      case QuranReaderThemeId.lightIvory:
        return 'عاجي فاتح';
      case QuranReaderThemeId.classicCream:
        return 'سمني فاتح';
      case QuranReaderThemeId.warmBeige:
        return 'بيج فاتح';
      case QuranReaderThemeId.softGreen:
        return 'كريمي دافئ';
    }
  }

  static QuranReaderThemeId fromStorageValue(String? value) {
    switch (value) {
      case 'light_ivory':
        return QuranReaderThemeId.lightIvory;
      case 'classic_cream':
        return QuranReaderThemeId.classicCream;
      case 'warm_beige':
        return QuranReaderThemeId.warmBeige;
      case 'soft_green':
        return QuranReaderThemeId.softGreen;
      case 'night_black':
      case 'deep_navy':
        return QuranReaderThemeId.lightIvory;
      case 'app_blue':
      default:
        return QuranReaderThemeId.appBlue;
    }
  }
}

class QuranReaderTheme {
  const QuranReaderTheme({
    required this.id,
    required this.label,
    required this.pageBackground,
    required this.textColor,
    required this.secondaryTextColor,
    required this.ayahHighlightColor,
    required this.wordHighlightColor,
    required this.selectedWordTextColor,
    required this.controlsBackgroundColor,
    required this.controlsTextColor,
    required this.dividerColor,
    required this.pageBadgeBackground,
    required this.pageBadgeBorder,
    required this.pageBadgeText,
  });

  final QuranReaderThemeId id;
  final String label;

  final Color pageBackground;
  final Color textColor;
  final Color secondaryTextColor;

  final Color ayahHighlightColor;
  final Color wordHighlightColor;
  final Color selectedWordTextColor;

  final Color controlsBackgroundColor;
  final Color controlsTextColor;
  final Color dividerColor;

  final Color pageBadgeBackground;
  final Color pageBadgeBorder;
  final Color pageBadgeText;

  bool get isDarkLike => false;

  Color get ayahSeparatorColor {
    return isDarkLike ? const Color(0x99FFFFFF) : const Color(0x66000000);
  }

  static QuranReaderTheme byId(QuranReaderThemeId id) {
    switch (id) {
      case QuranReaderThemeId.appBlue:
        return appBlue;
      case QuranReaderThemeId.lightIvory:
        return lightIvory;
      case QuranReaderThemeId.classicCream:
        return classicCream;
      case QuranReaderThemeId.warmBeige:
        return warmBeige;
      case QuranReaderThemeId.softGreen:
        return softGreen;
    }
  }

  static const List<QuranReaderTheme> all = <QuranReaderTheme>[
    appBlue,
    lightIvory,
    classicCream,
    warmBeige,
    softGreen,
  ];

  static const QuranReaderTheme appBlue = QuranReaderTheme(
    id: QuranReaderThemeId.appBlue,
    label: 'لون التطبيق',
    pageBackground: Color(0xffF7FBFD),
    textColor: Color(0xff111827),
    secondaryTextColor: Color(0xff5F6F82),
    ayahHighlightColor: Color(0x26224368),
    wordHighlightColor: Color(0x44224368),
    selectedWordTextColor: Color(0xff224368),
    controlsBackgroundColor: Color(0xf2DEE9EF),
    controlsTextColor: Color(0xff224368),
    dividerColor: Color(0x33224368),
    pageBadgeBackground: Color(0xf2DEE9EF),
    pageBadgeBorder: Color(0xffB8C9D5),
    pageBadgeText: Color(0xff224368),
  );

  static const QuranReaderTheme lightIvory = QuranReaderTheme(
    id: QuranReaderThemeId.lightIvory,
    label: 'عاجي فاتح',
    pageBackground: Color(0xffFFFDF6),
    textColor: Color(0xff17120C),
    secondaryTextColor: Color(0xff776B58),
    ayahHighlightColor: Color(0x2A224368),
    wordHighlightColor: Color(0x48224368),
    selectedWordTextColor: Color(0xff224368),
    controlsBackgroundColor: Color(0xeeFFF9EA),
    controlsTextColor: Color(0xff1F2118),
    dividerColor: Color(0x2E000000),
    pageBadgeBackground: Color(0xeeFFFDF6),
    pageBadgeBorder: Color(0xffE1D7BF),
    pageBadgeText: Color(0xff224368),
  );

  static const QuranReaderTheme classicCream = QuranReaderTheme(
    id: QuranReaderThemeId.classicCream,
    label: 'سمني فاتح',
    pageBackground: Color(0xffFFF8E8),
    textColor: Color(0xff17120C),
    secondaryTextColor: Color(0xff6F6250),
    ayahHighlightColor: Color(0x30224368),
    wordHighlightColor: Color(0x55224368),
    selectedWordTextColor: Color(0xff224368),
    controlsBackgroundColor: Color(0xeeFFF4D8),
    controlsTextColor: Color(0xff1F2118),
    dividerColor: Color(0x33000000),
    pageBadgeBackground: Color(0xeeFFF8E8),
    pageBadgeBorder: Color(0xffD8C9A8),
    pageBadgeText: Color(0xff224368),
  );

  static const QuranReaderTheme warmBeige = QuranReaderTheme(
    id: QuranReaderThemeId.warmBeige,
    label: 'بيج فاتح',
    pageBackground: Color(0xffF8EEDC),
    textColor: Color(0xff17120C),
    secondaryTextColor: Color(0xff6B5A45),
    ayahHighlightColor: Color(0x33224368),
    wordHighlightColor: Color(0x55224368),
    selectedWordTextColor: Color(0xff224368),
    controlsBackgroundColor: Color(0xeeF2E3CA),
    controlsTextColor: Color(0xff1F2118),
    dividerColor: Color(0x44000000),
    pageBadgeBackground: Color(0xeeF8EEDC),
    pageBadgeBorder: Color(0xffB9AA91),
    pageBadgeText: Color(0xff224368),
  );

  static const QuranReaderTheme softGreen = QuranReaderTheme(
    id: QuranReaderThemeId.softGreen,
    label: 'كريمي دافئ',
    pageBackground: Color(0xffFCF5E6),
    textColor: Color(0xff17120C),
    secondaryTextColor: Color(0xff6F6250),
    ayahHighlightColor: Color(0x30224368),
    wordHighlightColor: Color(0x55224368),
    selectedWordTextColor: Color(0xff224368),
    controlsBackgroundColor: Color(0xeeF3E7D3),
    controlsTextColor: Color(0xff1F2118),
    dividerColor: Color(0x44000000),
    pageBadgeBackground: Color(0xeeFCF5E6),
    pageBadgeBorder: Color(0xffB9AA91),
    pageBadgeText: Color(0xff224368),
  );
}
