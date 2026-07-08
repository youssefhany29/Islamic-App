import 'package:characters/characters.dart';

import 'quran_hide_mode.dart';

class QuranTextMasker {
  const QuranTextMasker._();

  static const String hiddenGlyph = 'ـ';

  static String maskWord({
    required String text,
    required QuranHideMode hideMode,
    required int wordIndexInAyah,
    int partialVisibleEvery = 3,
  }) {
    if (hideMode == QuranHideMode.visible) {
      return text;
    }

    if (_isAyahMarkerLike(text)) {
      return text;
    }

    if (hideMode == QuranHideMode.partial) {
      final bool keepVisible = wordIndexInAyah % partialVisibleEvery == 0;

      if (keepVisible) {
        return text;
      }
    }

    return _maskArabicWordKeepingShape(text);
  }

  static List<String> splitAyahWords(String text, {required int ayahNumber}) {
    final String textOnly = stripEmbeddedAyahMarker(
      text,
      ayahNumber: ayahNumber,
    );

    if (textOnly.trim().isEmpty) {
      return const <String>[];
    }

    return textOnly
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .split(' ')
        .where((word) => word.trim().isNotEmpty)
        .toList(growable: false);
  }

  static String stripEmbeddedAyahMarker(
    String text, {
    required int ayahNumber,
  }) {
    final List<String> tokens = text
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .split(' ')
        .where((word) => word.trim().isNotEmpty)
        .toList();

    while (tokens.isNotEmpty &&
        isStandaloneAyahMarker(tokens.last, ayahNumber: ayahNumber)) {
      tokens.removeLast();
    }

    return tokens.join(' ');
  }

  static bool isStandaloneAyahMarker(String text, {required int ayahNumber}) {
    final String compact = text
        .replaceAll(RegExp(r'[\u061C\u200E\u200F\s]'), '')
        .trim();

    if (compact.isEmpty) {
      return false;
    }

    final bool plainMarker = RegExp(
      r'^[\u06DD\u06DE\u06E9۝۞۩٠-٩۰-۹0-9]+$',
    ).hasMatch(compact);
    if (plainMarker) {
      return true;
    }

    final Characters graphemes = compact.characters;
    if (graphemes.length != 1) {
      return false;
    }

    final int markerCodeUnit = compact.codeUnitAt(0);
    return markerCodeUnit == 0xE959 + ayahNumber;
  }

  static String maskWordShape(String text) {
    return _maskArabicWordKeepingShape(text);
  }

  static bool shouldHideWord({
    required QuranHideMode hideMode,
    required int wordIndexInAyah,
    int partialVisibleEvery = 3,
  }) {
    if (hideMode == QuranHideMode.visible) {
      return false;
    }

    if (hideMode == QuranHideMode.full) {
      return true;
    }

    return wordIndexInAyah % partialVisibleEvery != 0;
  }

  static String _maskArabicWordKeepingShape(String text) {
    final int length = _countVisibleCharacters(text);

    if (length <= 0) {
      return hiddenGlyph;
    }

    if (length <= 2) {
      return hiddenGlyph * 2;
    }

    return hiddenGlyph * length.clamp(3, 14);
  }

  static int _countVisibleCharacters(String text) {
    final String cleaned = text
        .replaceAll(RegExp(r'[\u061C\u200E\u200F]'), '')
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '')
        .replaceAll(RegExp(r'\s+'), '');

    return cleaned.characters.length;
  }

  static bool _isAyahMarkerLike(String text) {
    final String compact = text
        .replaceAll(RegExp(r'[\u061C\u200E\u200F\s]'), '')
        .trim();

    if (compact.isEmpty) {
      return false;
    }

    if (RegExp(r'^[\u06DD\u06DE\u06E9۝۞۩٠-٩۰-۹0-9]+$').hasMatch(compact)) {
      return true;
    }

    if (compact.characters.length != 1) {
      return false;
    }

    final int codeUnit = compact.codeUnitAt(0);
    return codeUnit >= 0xE95A && codeUnit <= 0xEA77;
  }
}
