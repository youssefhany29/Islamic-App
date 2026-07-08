import 'dart:math' as math;

import '../../../quran/reader/quran_reader_helpers.dart';
import 'quran_memorization_range_resolver.dart';

class MemorizationScheduleChunk {
  final int index;
  final int startGlobalAyahIndex;
  final int endGlobalAyahIndex;

  const MemorizationScheduleChunk({
    required this.index,
    required this.startGlobalAyahIndex,
    required this.endGlobalAyahIndex,
  });

  int get ayahsCount {
    return endGlobalAyahIndex - startGlobalAyahIndex + 1;
  }

  bool get isValid {
    return startGlobalAyahIndex >= 0 &&
        endGlobalAyahIndex >= startGlobalAyahIndex;
  }
}

class MemorizationBalancedRangeSplitter {
  const MemorizationBalancedRangeSplitter({
    this.resolver = const QuranMemorizationRangeResolver(),
  });

  final QuranMemorizationRangeResolver resolver;

  Future<List<MemorizationScheduleChunk>> split({
    required int startGlobalAyahIndex,
    required int endGlobalAyahIndex,
    int? targetSessions,
    int? fixedAyahsPerSession,
    double? pagesPerSession,
  }) async {
    await resolver.ensureReady();

    final safeRange = resolver
        .clampRange(
      start: startGlobalAyahIndex,
      end: endGlobalAyahIndex,
      min: 0,
      max: QuranReaderHelpers.totalAyahs - 1,
    )
        .normalized();

    if (!safeRange.isValid) return const [];

    // اختيار شخصي واضح: المستخدم قال عدد آيات في الجلسة.
    // هنا نحترم اختياره ولا ندخل التقسيم الذكي.
    if (fixedAyahsPerSession != null && fixedAyahsPerSession > 0) {
      return _splitByAyahs(
        startGlobalAyahIndex: safeRange.start,
        endGlobalAyahIndex: safeRange.end,
        ayahsPerSession: fixedAyahsPerSession,
      );
    }

    // اختيار شخصي واضح: المستخدم قال عدد صفحات في الجلسة.
    // هنا نحترم اختياره قدر الإمكان على حدود الآيات.
    if (pagesPerSession != null && pagesPerSession > 0) {
      return _splitByPages(
        startGlobalAyahIndex: safeRange.start,
        endGlobalAyahIndex: safeRange.end,
        pagesPerSession: pagesPerSession,
      );
    }

    // تقسيم ذكي: المستخدم اختار مدة/عدد جلسات، ولم يحدد مقدارًا حرفيًا.
    // هنا نقسم حسب وزن الآيات التقريبي داخل الصفحات؛ لأن الآية الطويلة
    // في صفحة قليلة الآيات أثقل من آية قصيرة في صفحة كثيرة الآيات.
    final sessions = math.max(1, targetSessions ?? 1);

    return _splitSmartByWeightedAyahs(
      startGlobalAyahIndex: safeRange.start,
      endGlobalAyahIndex: safeRange.end,
      targetSessions: sessions,
    );
  }

  List<MemorizationScheduleChunk> _splitByAyahs({
    required int startGlobalAyahIndex,
    required int endGlobalAyahIndex,
    required int ayahsPerSession,
  }) {
    final chunks = <MemorizationScheduleChunk>[];
    int start = startGlobalAyahIndex;
    int index = 0;

    while (start <= endGlobalAyahIndex) {
      final end = (start + ayahsPerSession - 1)
          .clamp(start, endGlobalAyahIndex)
          .toInt();

      chunks.add(
        MemorizationScheduleChunk(
          index: index,
          startGlobalAyahIndex: start,
          endGlobalAyahIndex: end,
        ),
      );

      start = end + 1;
      index++;
    }

    return chunks;
  }

  List<MemorizationScheduleChunk> _splitByPages({
    required int startGlobalAyahIndex,
    required int endGlobalAyahIndex,
    required double pagesPerSession,
  }) {
    final chunks = <MemorizationScheduleChunk>[];
    int start = startGlobalAyahIndex;
    int index = 0;

    while (start <= endGlobalAyahIndex) {
      final end = resolver.endFromPages(
        startGlobalAyahIndex: start,
        maxEndGlobalAyahIndex: endGlobalAyahIndex,
        pages: pagesPerSession,
      );

      chunks.add(
        MemorizationScheduleChunk(
          index: index,
          startGlobalAyahIndex: start,
          endGlobalAyahIndex: end,
        ),
      );

      start = end + 1;
      index++;
    }

    return _removeInvalidOrOverlapping(chunks);
  }

  List<MemorizationScheduleChunk> _splitSmartByWeightedAyahs({
    required int startGlobalAyahIndex,
    required int endGlobalAyahIndex,
    required int targetSessions,
  }) {
    final totalAyahs = endGlobalAyahIndex - startGlobalAyahIndex + 1;

    if (totalAyahs <= 0) return const [];

    final sessions = targetSessions.clamp(1, totalAyahs).toInt();

    if (sessions <= 1) {
      return [
        MemorizationScheduleChunk(
          index: 0,
          startGlobalAyahIndex: startGlobalAyahIndex,
          endGlobalAyahIndex: endGlobalAyahIndex,
        ),
      ];
    }

    final weights = _buildAyahWeights(
      startGlobalAyahIndex: startGlobalAyahIndex,
      endGlobalAyahIndex: endGlobalAyahIndex,
    );

    final totalWeight = weights.fold<double>(
      0,
          (sum, value) => sum + value,
    );

    if (totalWeight <= 0) {
      return _splitByAyahCountIntoSessions(
        startGlobalAyahIndex: startGlobalAyahIndex,
        endGlobalAyahIndex: endGlobalAyahIndex,
        targetSessions: sessions,
      );
    }

    final targetWeight = totalWeight / sessions;
    final chunks = <MemorizationScheduleChunk>[];

    int currentStart = startGlobalAyahIndex;
    double currentWeight = 0;

    for (int global = startGlobalAyahIndex; global <= endGlobalAyahIndex; global++) {
      final localIndex = global - startGlobalAyahIndex;
      currentWeight += weights[localIndex];

      final remainingAyahs = endGlobalAyahIndex - global;
      final remainingSessions = sessions - chunks.length - 1;

      final canCloseHere = remainingSessions > 0 &&
          remainingAyahs >= remainingSessions &&
          currentWeight >= targetWeight;

      final mustLeaveAyahsForRest = remainingSessions > 0 &&
          remainingAyahs == remainingSessions;

      if (canCloseHere || mustLeaveAyahsForRest) {
        chunks.add(
          MemorizationScheduleChunk(
            index: chunks.length,
            startGlobalAyahIndex: currentStart,
            endGlobalAyahIndex: global,
          ),
        );

        currentStart = global + 1;
        currentWeight = 0;
      }
    }

    if (currentStart <= endGlobalAyahIndex) {
      chunks.add(
        MemorizationScheduleChunk(
          index: chunks.length,
          startGlobalAyahIndex: currentStart,
          endGlobalAyahIndex: endGlobalAyahIndex,
        ),
      );
    }

    return _rebalanceTinyLastChunk(
      _removeInvalidOrOverlapping(chunks),
    );
  }

  List<double> _buildAyahWeights({
    required int startGlobalAyahIndex,
    required int endGlobalAyahIndex,
  }) {
    final pageAyahsCountCache = <int, int>{};
    final weights = <double>[];

    for (int global = startGlobalAyahIndex; global <= endGlobalAyahIndex; global++) {
      final page = resolver.pageForGlobalAyah(global);

      final ayahsInPage = pageAyahsCountCache.putIfAbsent(page, () {
        final pageStart = resolver.pageStartGlobalAyah(page);
        final pageEnd = resolver.pageEndGlobalAyah(page);

        final from = math.max(pageStart, startGlobalAyahIndex);
        final to = math.min(pageEnd, endGlobalAyahIndex);

        return math.max(1, to - from + 1);
      });

      // وزن تقريبي:
      // الصفحة كلها تعتبر وحدة مجهود تقريبًا.
      // لو الصفحة فيها آيات قليلة، فالآية الواحدة غالبًا أطول وأثقل.
      // لو الصفحة فيها آيات كثيرة، فالآية الواحدة أخف.
      final pageShareWeight = 1.0 / ayahsInPage;

      // عامل تهدئة بسيط يمنع الآيات الكثيرة جدًا في الصفحة من أن تصبح خفيفة زيادة.
      final densityAdjustment = ayahsInPage <= 5
          ? 1.45
          : ayahsInPage <= 9
          ? 1.20
          : ayahsInPage >= 18
          ? 0.82
          : 1.0;

      weights.add(pageShareWeight * densityAdjustment);
    }

    return weights;
  }

  List<MemorizationScheduleChunk> _rebalanceTinyLastChunk(
      List<MemorizationScheduleChunk> chunks,
      ) {
    if (chunks.length < 2) return chunks;

    final last = chunks.last;
    final previous = chunks[chunks.length - 2];

    // لو آخر جلسة آية واحدة فقط والجلسة السابقة كبيرة نسبيًا،
    // ننقل آية من السابقة للأخيرة حتى لا تظهر جلسة ضعيفة جدًا بلا داعي.
    if (last.ayahsCount == 1 && previous.ayahsCount >= 4) {
      final updatedPrevious = MemorizationScheduleChunk(
        index: previous.index,
        startGlobalAyahIndex: previous.startGlobalAyahIndex,
        endGlobalAyahIndex: previous.endGlobalAyahIndex - 1,
      );

      final updatedLast = MemorizationScheduleChunk(
        index: last.index,
        startGlobalAyahIndex: previous.endGlobalAyahIndex,
        endGlobalAyahIndex: last.endGlobalAyahIndex,
      );

      final updated = <MemorizationScheduleChunk>[
        ...chunks.take(chunks.length - 2),
        updatedPrevious,
        updatedLast,
      ];

      return _removeInvalidOrOverlapping(updated);
    }

    return chunks;
  }

  List<MemorizationScheduleChunk> _splitByAyahCountIntoSessions({
    required int startGlobalAyahIndex,
    required int endGlobalAyahIndex,
    required int targetSessions,
  }) {
    final totalAyahs = endGlobalAyahIndex - startGlobalAyahIndex + 1;
    final sessions = targetSessions.clamp(1, totalAyahs).toInt();
    final ayahsPerSession = (totalAyahs / sessions).ceil();

    return _splitByAyahs(
      startGlobalAyahIndex: startGlobalAyahIndex,
      endGlobalAyahIndex: endGlobalAyahIndex,
      ayahsPerSession: ayahsPerSession,
    );
  }

  List<MemorizationScheduleChunk> _removeInvalidOrOverlapping(
      List<MemorizationScheduleChunk> input,
      ) {
    final chunks = <MemorizationScheduleChunk>[];
    int? lastEnd;

    for (final chunk in input) {
      if (!chunk.isValid) continue;

      final start = lastEnd == null
          ? chunk.startGlobalAyahIndex
          : math.max(chunk.startGlobalAyahIndex, lastEnd + 1);

      if (start > chunk.endGlobalAyahIndex) continue;

      chunks.add(
        MemorizationScheduleChunk(
          index: chunks.length,
          startGlobalAyahIndex: start,
          endGlobalAyahIndex: chunk.endGlobalAyahIndex,
        ),
      );

      lastEnd = chunk.endGlobalAyahIndex;
    }

    return chunks;
  }
}
