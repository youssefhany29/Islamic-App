import 'dart:math' as math;

import '../../../quran/reader/quran_page_mapper.dart';
import '../../../quran/reader/quran_reader_helpers.dart';
import 'quran_range_label_resolver.dart';
import 'quran_memorization_hizb_boundaries.dart';

class MemorizationGlobalRange {
  final int start;
  final int end;

  const MemorizationGlobalRange({required this.start, required this.end});

  const MemorizationGlobalRange.invalid() : start = -1, end = -1;

  bool get isValid {
    return start >= 0 && end >= start;
  }

  int get ayahsCount {
    if (!isValid) return 0;
    return end - start + 1;
  }

  MemorizationGlobalRange normalized() {
    if (!isValid) return this;

    final maxIndex = QuranReaderHelpers.totalAyahs - 1;

    final safeStart = start.clamp(0, maxIndex).toInt();
    final safeEnd = end.clamp(safeStart, maxIndex).toInt();

    return MemorizationGlobalRange(start: safeStart, end: safeEnd);
  }
}

class QuranMemorizationRangeResolver {
  const QuranMemorizationRangeResolver();

  Future<void> ensureReady() async {
    await QuranPageMapper.load();
  }

  int pageForGlobalAyah(int globalAyahIndex) {
    return QuranPageMapper.getPageNumberForGlobalAyah(
      globalAyahIndex.clamp(0, QuranReaderHelpers.totalAyahs - 1).toInt(),
    );
  }

  int pageStartGlobalAyah(int pageNumber) {
    return QuranPageMapper.getGlobalAyahIndexForPage(
      pageNumber.clamp(1, 604).toInt(),
    );
  }

  int pageEndGlobalAyah(int pageNumber) {
    final safePage = pageNumber.clamp(1, 604).toInt();

    if (safePage >= 604) {
      return QuranReaderHelpers.totalAyahs - 1;
    }

    return QuranPageMapper.getGlobalAyahIndexForPage(safePage + 1) - 1;
  }

  MemorizationGlobalRange clampRange({
    required int start,
    required int end,
    required int min,
    required int max,
  }) {
    final safeMin = min.clamp(0, QuranReaderHelpers.totalAyahs - 1).toInt();
    final safeMax = max
        .clamp(safeMin, QuranReaderHelpers.totalAyahs - 1)
        .toInt();
    final safeStart = start.clamp(safeMin, safeMax).toInt();
    final safeEnd = end.clamp(safeStart, safeMax).toInt();

    return MemorizationGlobalRange(start: safeStart, end: safeEnd);
  }

  int pagesCountForRange({
    required int startGlobalAyahIndex,
    required int endGlobalAyahIndex,
  }) {
    final range = clampRange(
      start: startGlobalAyahIndex,
      end: endGlobalAyahIndex,
      min: 0,
      max: QuranReaderHelpers.totalAyahs - 1,
    );

    if (!range.isValid) return 0;

    final startPage = pageForGlobalAyah(range.start);
    final endPage = pageForGlobalAyah(range.end);

    return math.max(1, endPage - startPage + 1);
  }

  MemorizationGlobalRange surahRange({
    required int surahNumber,
    int? fromAyah,
    int? toAyah,
  }) {
    final safeSurah = surahNumber.clamp(1, 114).toInt();
    final suraIndex = safeSurah - 1;
    final maxAyah =
        QuranReaderHelpers.getPositionFromGlobalIndex(
              QuranReaderHelpers.getGlobalAyahIndex(
                suraIndex: suraIndex,
                ayahIndex: 0,
              ),
            ).suraIndex ==
            suraIndex
        ? _surahAyahCount(suraIndex)
        : 1;

    final startAyah = (fromAyah ?? 1).clamp(1, maxAyah).toInt();
    final endAyah = (toAyah ?? maxAyah).clamp(startAyah, maxAyah).toInt();

    return MemorizationGlobalRange(
      start: QuranReaderHelpers.getGlobalAyahIndex(
        suraIndex: suraIndex,
        ayahIndex: startAyah - 1,
      ),
      end: QuranReaderHelpers.getGlobalAyahIndex(
        suraIndex: suraIndex,
        ayahIndex: endAyah - 1,
      ),
    ).normalized();
  }

  int _surahAyahCount(int suraIndex) {
    final safeIndex = suraIndex.clamp(0, 113).toInt();

    if (safeIndex == 113) {
      return QuranReaderHelpers.totalAyahs -
          QuranReaderHelpers.getGlobalAyahIndex(
            suraIndex: safeIndex,
            ayahIndex: 0,
          );
    }

    final currentStart = QuranReaderHelpers.getGlobalAyahIndex(
      suraIndex: safeIndex,
      ayahIndex: 0,
    );

    final nextStart = QuranReaderHelpers.getGlobalAyahIndex(
      suraIndex: safeIndex + 1,
      ayahIndex: 0,
    );

    return math.max(1, nextStart - currentStart);
  }

  MemorizationGlobalRange hizbRange(int hizbNumber) {
    final range = QuranMemorizationHizbBoundaries.rangeForHizb(hizbNumber);
    if (!range.isValid) return const MemorizationGlobalRange.invalid();

    return MemorizationGlobalRange(
      start: range.startGlobalAyahIndex,
      end: range.endGlobalAyahIndex,
    ).normalized();
  }

  int endFromPages({
    required int startGlobalAyahIndex,
    required int maxEndGlobalAyahIndex,
    required double pages,
  }) {
    final safePages = pages <= 0 ? 0.5 : pages;
    final startPage = pageForGlobalAyah(startGlobalAyahIndex);

    if (safePages <= 0.5) {
      return halfPageEnd(
        startGlobalAyahIndex: startGlobalAyahIndex,
        maxEndGlobalAyahIndex: maxEndGlobalAyahIndex,
      );
    }

    final wholePages = safePages.floor();
    final hasHalfPage = safePages - wholePages >= 0.5;

    int endPage = startPage + wholePages - 1;
    if (endPage < startPage) endPage = startPage;
    if (endPage > 604) endPage = 604;

    int endGlobalAyahIndex = pageEndGlobalAyah(endPage);

    if (hasHalfPage && endGlobalAyahIndex < maxEndGlobalAyahIndex) {
      endGlobalAyahIndex = halfPageEnd(
        startGlobalAyahIndex: endGlobalAyahIndex + 1,
        maxEndGlobalAyahIndex: maxEndGlobalAyahIndex,
      );
    }

    return endGlobalAyahIndex
        .clamp(startGlobalAyahIndex, maxEndGlobalAyahIndex)
        .toInt();
  }

  int halfPageEnd({
    required int startGlobalAyahIndex,
    required int maxEndGlobalAyahIndex,
  }) {
    final page = pageForGlobalAyah(startGlobalAyahIndex);
    final pageEnd = pageEndGlobalAyah(
      page,
    ).clamp(startGlobalAyahIndex, maxEndGlobalAyahIndex).toInt();

    final availableAyahs = pageEnd - startGlobalAyahIndex + 1;
    final halfAyahs = math.max(1, (availableAyahs / 2).ceil());

    return (startGlobalAyahIndex + halfAyahs - 1)
        .clamp(startGlobalAyahIndex, maxEndGlobalAyahIndex)
        .toInt();
  }

  String titleForRange(int startGlobalAyahIndex, int endGlobalAyahIndex) {
    return const QuranRangeLabelResolver()
        .resolveAyahs(
          startGlobalAyahIndex: startGlobalAyahIndex,
          endGlobalAyahIndex: endGlobalAyahIndex,
        )
        .displayLabel;
  }
}
