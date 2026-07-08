import 'dart:convert';

import 'package:flutter/services.dart';

class QuranAyahSheetText {
  const QuranAyahSheetText({required this.hafsText, required this.plainText});

  final String hafsText;
  final String plainText;

  bool get hasHafsText => hafsText.trim().isNotEmpty;
  bool get hasPlainText => plainText.trim().isNotEmpty;

  // The current bundled text file has Hafs/uthmani glyphs, not tajweed
  // rule spans or per-token colors.
  bool get hasTajweedColorMetadata => false;
}

class QuranAyahSheetTextRepository {
  QuranAyahSheetTextRepository._();

  static final QuranAyahSheetTextRepository instance =
      QuranAyahSheetTextRepository._();

  Map<String, QuranAyahSheetText>? _cache;

  Future<QuranAyahSheetText?> getAyahText({
    required int surah,
    required int ayah,
  }) async {
    final Map<String, QuranAyahSheetText> data = await _load();
    return data['$surah:$ayah'];
  }

  Future<Map<String, QuranAyahSheetText>> _load() async {
    final Map<String, QuranAyahSheetText>? cached = _cache;
    if (cached != null) {
      return cached;
    }

    final String rawJson = await rootBundle.loadString(
      'assets/hafs_smart_v8.json',
    );
    final Map<String, dynamic> decoded =
        jsonDecode(rawJson) as Map<String, dynamic>;
    final List<dynamic> verses = decoded['quran'] as List<dynamic>;
    final Map<String, QuranAyahSheetText> result =
        <String, QuranAyahSheetText>{};

    for (final dynamic item in verses) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final int? surahNumber = _asInt(item['sura_no']);
      final int? ayahNumber = _asInt(item['aya_no']);
      if (surahNumber == null || ayahNumber == null) {
        continue;
      }

      result['$surahNumber:$ayahNumber'] = QuranAyahSheetText(
        hafsText: item['aya_text']?.toString() ?? '',
        plainText: item['aya_text_emlaey']?.toString() ?? '',
      );
    }

    _cache = result;
    return result;
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
