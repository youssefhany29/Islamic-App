import 'dart:convert';

import 'package:flutter/services.dart';

import 'quran_reader_helpers.dart';

class QuranPageStart {
  final int pageNumber;
  final int suraIndex;
  final int ayahIndex;

  const QuranPageStart({
    required this.pageNumber,
    required this.suraIndex,
    required this.ayahIndex,
  });

  factory QuranPageStart.fromMap(Map<String, dynamic> map) {
    return QuranPageStart(
      pageNumber: int.parse(map['page'].toString()),
      // JSON should use 1-based surah/ayah numbers.
      suraIndex: int.parse(map['sura'].toString()) - 1,
      ayahIndex: int.parse(map['ayah'].toString()) - 1,
    );
  }
}

class QuranPageMapper {
  static const String mapAssetPath = 'assets/quraan/page_ayah_map.json';
  static const int totalMushafPages = 604;

  static List<QuranPageStart> _pageStarts = [];
  static bool _isLoaded = false;

  static bool get isLoaded => _isLoaded && _pageStarts.isNotEmpty;

  static Future<void> load() async {
    if (_isLoaded) return;

    try {
      final jsonText = await rootBundle.loadString(mapAssetPath);
      final decoded = jsonDecode(jsonText) as List<dynamic>;

      _pageStarts = decoded.map((item) {
        return QuranPageStart.fromMap(item as Map<String, dynamic>);
      }).toList()
        ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));

      _isLoaded = true;
    } catch (_) {
      // Fallback mode: app still works, but page linking will be approximate.
      _pageStarts = [];
      _isLoaded = false;
    }
  }

  static int getGlobalAyahIndexForPage(int pageNumber) {
    final safePage = pageNumber.clamp(1, totalMushafPages);

    if (!isLoaded) {
      return _getApproxGlobalAyahIndexFromPage(safePage);
    }

    QuranPageStart? selectedStart;

    for (final pageStart in _pageStarts) {
      if (pageStart.pageNumber <= safePage) {
        selectedStart = pageStart;
      } else {
        break;
      }
    }

    if (selectedStart == null) {
      return 0;
    }

    return QuranReaderHelpers.getGlobalAyahIndex(
      suraIndex: selectedStart.suraIndex,
      ayahIndex: selectedStart.ayahIndex,
    );
  }

  static int getPageNumberForGlobalAyah(int globalAyahIndex) {
    if (!isLoaded) {
      return QuranReaderHelpers.getApproxPageNumber(globalAyahIndex);
    }

    int selectedPage = 1;

    for (final pageStart in _pageStarts) {
      final startGlobalAyahIndex = QuranReaderHelpers.getGlobalAyahIndex(
        suraIndex: pageStart.suraIndex,
        ayahIndex: pageStart.ayahIndex,
      );

      if (globalAyahIndex >= startGlobalAyahIndex) {
        selectedPage = pageStart.pageNumber;
      } else {
        break;
      }
    }

    return selectedPage.clamp(1, totalMushafPages);
  }

  static int _getApproxGlobalAyahIndexFromPage(int pageNumber) {
    final safePage = pageNumber.clamp(1, totalMushafPages);
    final ratio = (safePage - 1) / totalMushafPages;
    final approximateIndex = (ratio * QuranReaderHelpers.totalAyahs).floor();

    if (approximateIndex < 0) return 0;

    if (approximateIndex >= QuranReaderHelpers.totalAyahs) {
      return QuranReaderHelpers.totalAyahs - 1;
    }

    return approximateIndex;
  }
}