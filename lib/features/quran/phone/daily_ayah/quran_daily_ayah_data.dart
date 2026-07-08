import 'package:islamic_app/features/quran/main_quraan_components/constant.dart';
import 'package:islamic_app/features/quran/reader/quran_reader_helpers.dart';

class QuranDailyAyahInfo {
  const QuranDailyAyahInfo({
    required this.text,
    required this.reference,
    required this.surahNumber,
    required this.ayahNumber,
  });

  final String text;
  final String reference;
  final int surahNumber;
  final int ayahNumber;
}

class QuranDailyAyahReference {
  const QuranDailyAyahReference({
    required this.surahNumber,
    required this.ayahNumber,
  });

  final int surahNumber;
  final int ayahNumber;
}

class QuranDailyAyahData {
  const QuranDailyAyahData._();

  // References only. The ayah text is loaded from assets/hafs_smart_v8.json.
  // Keep these ayahs short enough for the card and meaningful for daily display.
  static const List<QuranDailyAyahReference> _meaningfulReferences = [
    QuranDailyAyahReference(surahNumber: 2, ayahNumber: 152),
    QuranDailyAyahReference(surahNumber: 2, ayahNumber: 153),
    QuranDailyAyahReference(surahNumber: 2, ayahNumber: 186),
    QuranDailyAyahReference(surahNumber: 3, ayahNumber: 8),
    QuranDailyAyahReference(surahNumber: 3, ayahNumber: 9),
    QuranDailyAyahReference(surahNumber: 3, ayahNumber: 26),
    QuranDailyAyahReference(surahNumber: 3, ayahNumber: 53),
    QuranDailyAyahReference(surahNumber: 3, ayahNumber: 139),
    QuranDailyAyahReference(surahNumber: 3, ayahNumber: 173),
    QuranDailyAyahReference(surahNumber: 4, ayahNumber: 40),
    QuranDailyAyahReference(surahNumber: 5, ayahNumber: 100),
    QuranDailyAyahReference(surahNumber: 6, ayahNumber: 54),
    QuranDailyAyahReference(surahNumber: 7, ayahNumber: 23),
    QuranDailyAyahReference(surahNumber: 7, ayahNumber: 56),
    QuranDailyAyahReference(surahNumber: 8, ayahNumber: 2),
    QuranDailyAyahReference(surahNumber: 9, ayahNumber: 51),
    QuranDailyAyahReference(surahNumber: 10, ayahNumber: 57),
    QuranDailyAyahReference(surahNumber: 10, ayahNumber: 62),
    QuranDailyAyahReference(surahNumber: 11, ayahNumber: 56),
    QuranDailyAyahReference(surahNumber: 11, ayahNumber: 61),
    QuranDailyAyahReference(surahNumber: 12, ayahNumber: 18),
    QuranDailyAyahReference(surahNumber: 12, ayahNumber: 64),
    QuranDailyAyahReference(surahNumber: 12, ayahNumber: 87),
    QuranDailyAyahReference(surahNumber: 13, ayahNumber: 28),
    QuranDailyAyahReference(surahNumber: 14, ayahNumber: 7),
    QuranDailyAyahReference(surahNumber: 15, ayahNumber: 49),
    QuranDailyAyahReference(surahNumber: 16, ayahNumber: 128),
    QuranDailyAyahReference(surahNumber: 17, ayahNumber: 80),
    QuranDailyAyahReference(surahNumber: 18, ayahNumber: 10),
    QuranDailyAyahReference(surahNumber: 20, ayahNumber: 25),
    QuranDailyAyahReference(surahNumber: 20, ayahNumber: 114),
    QuranDailyAyahReference(surahNumber: 21, ayahNumber: 87),
    QuranDailyAyahReference(surahNumber: 23, ayahNumber: 118),
    QuranDailyAyahReference(surahNumber: 25, ayahNumber: 58),
    QuranDailyAyahReference(surahNumber: 26, ayahNumber: 89),
    QuranDailyAyahReference(surahNumber: 27, ayahNumber: 19),
    QuranDailyAyahReference(surahNumber: 28, ayahNumber: 24),
    QuranDailyAyahReference(surahNumber: 29, ayahNumber: 69),
    QuranDailyAyahReference(surahNumber: 33, ayahNumber: 3),
    QuranDailyAyahReference(surahNumber: 33, ayahNumber: 41),
    QuranDailyAyahReference(surahNumber: 39, ayahNumber: 53),
    QuranDailyAyahReference(surahNumber: 40, ayahNumber: 44),
    QuranDailyAyahReference(surahNumber: 40, ayahNumber: 60),
    QuranDailyAyahReference(surahNumber: 42, ayahNumber: 19),
    QuranDailyAyahReference(surahNumber: 47, ayahNumber: 7),
    QuranDailyAyahReference(surahNumber: 50, ayahNumber: 16),
    QuranDailyAyahReference(surahNumber: 51, ayahNumber: 56),
    QuranDailyAyahReference(surahNumber: 57, ayahNumber: 4),
    QuranDailyAyahReference(surahNumber: 59, ayahNumber: 19),
    QuranDailyAyahReference(surahNumber: 65, ayahNumber: 2),
    QuranDailyAyahReference(surahNumber: 65, ayahNumber: 3),
    QuranDailyAyahReference(surahNumber: 65, ayahNumber: 7),
    QuranDailyAyahReference(surahNumber: 94, ayahNumber: 5),
    QuranDailyAyahReference(surahNumber: 94, ayahNumber: 6),
  ];

  static Future<QuranDailyAyahInfo> today() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final int seedIndex = today.difference(DateTime(2024)).inDays.abs();

    final List<dynamic> quranData = await readJson();
    final dynamic arabicSource = quranData.isNotEmpty ? quranData.first : null;

    for (int offset = 0; offset < _meaningfulReferences.length; offset++) {
      final reference = _meaningfulReferences[
      (seedIndex + offset) % _meaningfulReferences.length
      ];

      final info = _loadAyahFromSmartHafs(
        arabicSource: arabicSource,
        reference: reference,
      );

      if (_isGoodCardLength(info.text)) {
        return info;
      }
    }

    return _loadAyahFromSmartHafs(
      arabicSource: arabicSource,
      reference: _meaningfulReferences[seedIndex % _meaningfulReferences.length],
    );
  }

  static QuranDailyAyahInfo _loadAyahFromSmartHafs({
    required dynamic arabicSource,
    required QuranDailyAyahReference reference,
  }) {
    final int suraIndex = reference.surahNumber - 1;
    final int ayahIndex = reference.ayahNumber - 1;

    final String text = _SmartHafsAyahTextReader.readAyahText(
      source: arabicSource,
      suraIndex: suraIndex,
      ayahIndex: ayahIndex,
    );

    return QuranDailyAyahInfo(
      text: text,
      reference: _buildReferenceText(reference),
      surahNumber: reference.surahNumber,
      ayahNumber: reference.ayahNumber,
    );
  }

  static String _buildReferenceText(QuranDailyAyahReference reference) {
    final String surahName = QuranReaderHelpers.getSuraName(
      reference.surahNumber - 1,
    );

    return '$surahName - ${reference.ayahNumber}';
  }

  static bool _isGoodCardLength(String text) {
    final String cleanText = text.trim();

    if (cleanText.isEmpty) return false;
    if (cleanText.contains('تعذر') || cleanText.contains('تحميل')) return false;

    final int wordsCount = cleanText
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .length;

    return cleanText.length <= 95 && wordsCount <= 16;
  }
}

class _SmartHafsAyahTextReader {
  const _SmartHafsAyahTextReader._();

  static String readAyahText({
    required dynamic source,
    required int suraIndex,
    required int ayahIndex,
  }) {
    final dynamic value = _readAyahValue(
      source: source,
      suraIndex: suraIndex,
      ayahIndex: ayahIndex,
    );

    final String text = _cleanText(value?.toString() ?? '');
    return text.isEmpty ? 'تعذر تحميل نص الآية' : text;
  }

  static dynamic _readAyahValue({
    required dynamic source,
    required int suraIndex,
    required int ayahIndex,
  }) {
    if (source == null) return null;

    if (source is List) {
      final int globalIndex = QuranReaderHelpers.getGlobalAyahIndex(
        suraIndex: suraIndex,
        ayahIndex: ayahIndex,
      );

      if (source.length > 114 &&
          globalIndex >= 0 &&
          globalIndex < source.length) {
        final dynamic flatText = _extractText(source[globalIndex]);
        if (flatText != null) return flatText;
      }

      if (suraIndex >= 0 && suraIndex < source.length) {
        final dynamic surahText = _readFromSurahSource(
          surahSource: source[suraIndex],
          ayahIndex: ayahIndex,
        );
        if (surahText != null) return surahText;
      }

      if (globalIndex >= 0 && globalIndex < source.length) {
        return _extractText(source[globalIndex]);
      }
    }

    if (source is Map) {
      final dynamic quran = source['quran'];
      if (quran != null) {
        return _readAyahValue(
          source: quran,
          suraIndex: suraIndex,
          ayahIndex: ayahIndex,
        );
      }

      final dynamic surahSource = source['${suraIndex + 1}'] ??
          source[suraIndex + 1] ??
          source[suraIndex];

      final dynamic fromSurah = _readFromSurahSource(
        surahSource: surahSource,
        ayahIndex: ayahIndex,
      );

      if (fromSurah != null) return fromSurah;
    }

    return null;
  }

  static dynamic _readFromSurahSource({
    required dynamic surahSource,
    required int ayahIndex,
  }) {
    if (surahSource == null) return null;

    if (surahSource is List) {
      if (ayahIndex >= 0 && ayahIndex < surahSource.length) {
        return _extractText(surahSource[ayahIndex]);
      }
      return null;
    }

    if (surahSource is Map) {
      final dynamic ayahs = surahSource['ayahs'] ??
          surahSource['ayas'] ??
          surahSource['verses'] ??
          surahSource['data'];

      if (ayahs != null) {
        return _readFromSurahSource(
          surahSource: ayahs,
          ayahIndex: ayahIndex,
        );
      }

      final dynamic directValue = surahSource['${ayahIndex + 1}'] ??
          surahSource[ayahIndex + 1] ??
          surahSource[ayahIndex];

      return _extractText(directValue);
    }

    return _extractText(surahSource);
  }

  static dynamic _extractText(dynamic value) {
    if (value == null) return null;

    if (value is String) return value;

    if (value is Map) {
      return value['aya_text'] ??
          value['ayah_text'] ??
          value['arabic_text'] ??
          value['uthmani'] ??
          value['text_uthmani'] ??
          value['text'] ??
          value['simple'] ??
          value['clean'] ??
          value['verse'] ??
          value['ayah'] ??
          value['aya'];
    }

    return value;
  }

  static String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[۝۞﴿﴾]+'), '')
        .replaceAll('ـ', '')
        .trim();
  }
}
