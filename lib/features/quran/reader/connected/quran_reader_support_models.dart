part of '../qpc_connected_mushaf_page.dart';

class _QpcBottomBarSnapshot {
  const _QpcBottomBarSnapshot({
    required this.pageNumber,
    required this.surahName,
    required this.ayahNumber,
    required this.juzNumber,
  });

  final int pageNumber;
  final String surahName;
  final int ayahNumber;
  final int juzNumber;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _QpcBottomBarSnapshot &&
            runtimeType == other.runtimeType &&
            pageNumber == other.pageNumber &&
            surahName == other.surahName &&
            ayahNumber == other.ayahNumber &&
            juzNumber == other.juzNumber;
  }

  @override
  int get hashCode {
    return Object.hash(pageNumber, surahName, ayahNumber, juzNumber);
  }
}

class _QpcPendingReadingPersistence {
  const _QpcPendingReadingPersistence({
    required this.ayahKey,
    required this.mushafPageNumber,
    required this.wordCount,
    required this.recordStats,
    required this.reason,
  });

  final QpcAyahKey ayahKey;
  final int mushafPageNumber;
  final int? wordCount;
  final bool recordStats;
  final String reason;
}

class _AyahSearchResult {
  const _AyahSearchResult({
    required this.ayahKey,
    required this.displayText,
    this.ayahText,
  });

  final QpcAyahKey ayahKey;
  final String displayText;
  final String? ayahText;
}
