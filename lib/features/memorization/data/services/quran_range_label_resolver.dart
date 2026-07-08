import 'package:islamic_app/features/quran/reader/quran_page_mapper.dart';
import 'package:islamic_app/features/quran/reader/quran_reader_helpers.dart';

class QuranRangeLabel {
  const QuranRangeLabel({
    required this.startGlobalAyahIndex,
    required this.endGlobalAyahIndex,
    required this.startSurahNumber,
    required this.startSurahName,
    required this.startAyahNumber,
    required this.endSurahNumber,
    required this.endSurahName,
    required this.endAyahNumber,
    required this.startPage,
    required this.endPage,
    required this.actualAyahCount,
    required this.displayLabel,
    required this.pagesLabel,
  });

  final int startGlobalAyahIndex;
  final int endGlobalAyahIndex;
  final int startSurahNumber;
  final String startSurahName;
  final int startAyahNumber;
  final int endSurahNumber;
  final String endSurahName;
  final int endAyahNumber;
  final int startPage;
  final int endPage;
  final int actualAyahCount;
  final String displayLabel;
  final String pagesLabel;

  String get feedbackLabel => '$displayLabel\n$pagesLabel';
}

class QuranRangeLabelResolver {
  const QuranRangeLabelResolver();

  Future<QuranRangeLabel> resolvePages({
    required int startPage,
    required int endPage,
  }) async {
    await QuranPageMapper.load();
    final safeStartPage = startPage.clamp(1, 604).toInt();
    final safeEndPage = endPage.clamp(safeStartPage, 604).toInt();
    final start = QuranPageMapper.getGlobalAyahIndexForPage(safeStartPage);
    final end = safeEndPage == 604
        ? QuranReaderHelpers.totalAyahs - 1
        : QuranPageMapper.getGlobalAyahIndexForPage(safeEndPage + 1) - 1;
    return resolveAyahs(startGlobalAyahIndex: start, endGlobalAyahIndex: end);
  }

  QuranRangeLabel resolveAyahs({
    required int startGlobalAyahIndex,
    required int endGlobalAyahIndex,
  }) {
    final max = QuranReaderHelpers.totalAyahs - 1;
    final start = startGlobalAyahIndex.clamp(0, max).toInt();
    final end = endGlobalAyahIndex.clamp(start, max).toInt();
    final startPosition = QuranReaderHelpers.getPositionFromGlobalIndex(start);
    final endPosition = QuranReaderHelpers.getPositionFromGlobalIndex(end);
    final startSurahName = QuranReaderHelpers.getSuraName(
      startPosition.suraIndex,
    );
    final endSurahName = QuranReaderHelpers.getSuraName(endPosition.suraIndex);
    final startAyah = startPosition.ayahIndex + 1;
    final endAyah = endPosition.ayahIndex + 1;
    final startPage = QuranPageMapper.getPageNumberForGlobalAyah(start);
    final endPage = QuranPageMapper.getPageNumberForGlobalAyah(end);

    final displayLabel = startPosition.suraIndex == endPosition.suraIndex
        ? startAyah == endAyah
              ? 'سورة $startSurahName، آية $startAyah'
              : 'سورة $startSurahName، الآيات $startAyah - $endAyah'
        : 'من سورة $startSurahName آية $startAyah '
              'إلى سورة $endSurahName آية $endAyah';

    return QuranRangeLabel(
      startGlobalAyahIndex: start,
      endGlobalAyahIndex: end,
      startSurahNumber: startPosition.suraIndex + 1,
      startSurahName: startSurahName,
      startAyahNumber: startAyah,
      endSurahNumber: endPosition.suraIndex + 1,
      endSurahName: endSurahName,
      endAyahNumber: endAyah,
      startPage: startPage,
      endPage: endPage,
      actualAyahCount: end - start + 1,
      displayLabel: displayLabel,
      pagesLabel: startPage == endPage
          ? 'الصفحة: $startPage'
          : 'الصفحات: $startPage - $endPage',
    );
  }
}
