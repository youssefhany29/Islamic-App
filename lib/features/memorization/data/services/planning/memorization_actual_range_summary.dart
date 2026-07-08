import '../quran_memorization_range_resolver.dart';
import '../quran_range_label_resolver.dart';

class MemorizationActualRangeSummary {
  const MemorizationActualRangeSummary({
    required this.actualAyahCount,
    required this.pageRangeLabel,
    required this.surahRangeLabel,
  });

  final int actualAyahCount;
  final String pageRangeLabel;
  final String surahRangeLabel;
}

class MemorizationActualRangeSummaryResolver {
  const MemorizationActualRangeSummaryResolver();

  MemorizationActualRangeSummary calculateActualAyahCount(
    Iterable<MemorizationGlobalRange> ranges,
  ) {
    final uniqueAyahs = <int>{};
    for (final rawRange in ranges) {
      if (!rawRange.isValid) continue;
      final range = rawRange.normalized();
      for (int index = range.start; index <= range.end; index++) {
        uniqueAyahs.add(index);
      }
    }

    if (uniqueAyahs.isEmpty) {
      return const MemorizationActualRangeSummary(
        actualAyahCount: 0,
        pageRangeLabel: '',
        surahRangeLabel: '',
      );
    }

    final sorted = uniqueAyahs.toList()..sort();
    final first = sorted.first;
    final last = sorted.last;
    final range = const QuranRangeLabelResolver().resolveAyahs(
      startGlobalAyahIndex: first,
      endGlobalAyahIndex: last,
    );

    return MemorizationActualRangeSummary(
      actualAyahCount: uniqueAyahs.length,
      pageRangeLabel: range.pagesLabel,
      surahRangeLabel: range.displayLabel,
    );
  }
}
