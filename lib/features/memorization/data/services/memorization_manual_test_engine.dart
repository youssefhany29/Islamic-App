import 'dart:math' as math;

import 'package:islamic_app/features/memorization/data/models/memorization_today_task_model.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_plan_storage.dart';
import 'package:islamic_app/features/memorization/data/services/quran_memorization_hizb_boundaries.dart';
import 'package:islamic_app/features/memorization/data/services/quran_range_label_resolver.dart';
import 'package:islamic_app/features/memorization/results/services/memorization_test_result_storage.dart';
import 'package:islamic_app/features/memorization/test/models/standalone_test_settings.dart';
import 'package:islamic_app/features/quran/reader/quran_page_mapper.dart';
import 'package:islamic_app/features/quran/reader/quran_reader_helpers.dart';

class MemorizationManualTestRequest {
  const MemorizationManualTestRequest({
    required this.scopeType,
    required this.questionMode,
    required this.questionCount,
    required this.difficulty,
    required this.timerMode,
    this.surahNumber = 1,
    this.fromAyah = 1,
    this.toAyah = 7,
    this.juzNumber = 1,
    this.hizbNumber = 1,
    this.fromPage = 1,
    this.toPage = 1,
    this.customStartGlobalAyahIndex = 0,
    this.customEndGlobalAyahIndex = 0,
  });

  final StandaloneTestScopeType scopeType;
  final StandaloneQuestionMode questionMode;
  final int questionCount;
  final StandaloneDifficulty difficulty;
  final StandaloneTimerMode timerMode;
  final int surahNumber;
  final int fromAyah;
  final int toAyah;
  final int juzNumber;
  final int hizbNumber;
  final int fromPage;
  final int toPage;
  final int customStartGlobalAyahIndex;
  final int customEndGlobalAyahIndex;
}

class MemorizationManualTestEngine {
  const MemorizationManualTestEngine();

  Future<MemorizationTodayTaskModel> buildManualTestTask(
    MemorizationManualTestRequest request,
  ) async {
    await QuranPageMapper.load();

    final scope = await _scopeRange(request);
    final selectedRange = _shouldUseFullScope(request.scopeType)
        ? scope
        : _selectRangeInsideScope(scope: scope, difficulty: request.difficulty);
    final label = const QuranRangeLabelResolver().resolveAyahs(
      startGlobalAyahIndex: selectedRange.startGlobalAyahIndex,
      endGlobalAyahIndex: selectedRange.endGlobalAyahIndex,
    );

    final now = DateTime.now();
    final ayahsCount =
        selectedRange.endGlobalAyahIndex -
        selectedRange.startGlobalAyahIndex +
        1;
    final questionCount = request.questionCount.clamp(1, 30).toInt();
    final mode = request.questionMode;

    return MemorizationTodayTaskModel(
      id: 'standalone_test_${now.microsecondsSinceEpoch}',
      planId: 'standalone_test',
      type: 'standaloneTest',
      title: 'اختبرني',
      subtitle:
          '${mode.questionModeLabel} • ${request.difficulty.difficultyLabel} • '
          '$questionCount سؤال • ${request.timerMode.timerTitle(request)}',
      scopeTitle: label.displayLabel,
      startGlobalAyahIndex: selectedRange.startGlobalAyahIndex,
      endGlobalAyahIndex: selectedRange.endGlobalAyahIndex,
      expectedMinutes: _estimateMinutes(
        ayahsCount: ayahsCount,
        difficulty: request.difficulty,
        questionCount: questionCount,
      ),
      testKindCode: 'standalone',
      testTriggerCode: 'standalone',
      testStyleCode: mode.questionModeCode,
      testDifficultyPreferenceCode: request.difficulty.difficultyCode,
      questionsCount: questionCount,
      allowedQuestionTypeCodes: mode.allowedQuestionTypeCodes,
      attemptNumber: 1,
      planVersion: 1,
      isCompleted: false,
      status: MemorizationTodayTaskModel.statusReadyForTest,
      scheduledDate: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<_AyahRange> _scopeRange(MemorizationManualTestRequest request) async {
    switch (request.scopeType) {
      case StandaloneTestScopeType.wholeSurah:
        return _rangeForSurah(request.surahNumber.clamp(1, 114).toInt());

      case StandaloneTestScopeType.surahRange:
        return _rangeForSurahAyahs(
          request.surahNumber.clamp(1, 114).toInt(),
          request.fromAyah,
          request.toAyah,
        );

      case StandaloneTestScopeType.juz:
        return _rangeForJuz(request.juzNumber.clamp(1, 30).toInt());

      case StandaloneTestScopeType.hizb:
        final hizb = QuranMemorizationHizbBoundaries.rangeForHizb(
          request.hizbNumber.clamp(1, 60).toInt(),
        );
        if (hizb.isValid) {
          return _AyahRange(
            startGlobalAyahIndex: hizb.startGlobalAyahIndex,
            endGlobalAyahIndex: hizb.endGlobalAyahIndex,
          );
        }
        return _rangeForJuz(1);

      case StandaloneTestScopeType.pages:
        return _rangeForPages(request.fromPage, request.toPage);

      case StandaloneTestScopeType.customRange:
        if (request.customEndGlobalAyahIndex <= 0) {
          return _rangeForPages(request.fromPage, request.toPage);
        }
        final start = request.customStartGlobalAyahIndex
            .clamp(0, QuranReaderHelpers.totalAyahs - 1)
            .toInt();
        final end = request.customEndGlobalAyahIndex
            .clamp(start, QuranReaderHelpers.totalAyahs - 1)
            .toInt();
        return _AyahRange(startGlobalAyahIndex: start, endGlobalAyahIndex: end);

      case StandaloneTestScopeType.lastMemorized:
        final activePlan = await MemorizationPlanStorage.getActivePlan();
        if (activePlan != null && activePlan.scopeStartGlobalAyahIndex >= 0) {
          final end = activePlan.scopeEndGlobalAyahIndex
              .clamp(
                activePlan.scopeStartGlobalAyahIndex,
                QuranReaderHelpers.totalAyahs - 1,
              )
              .toInt();
          final pageEnd = QuranPageMapper.getPageNumberForGlobalAyah(end);
          final pageStart = math.max(1, pageEnd - 1);
          return _rangeForPages(pageStart, pageEnd);
        }
        return _rangeForPages(1, 2);

      case StandaloneTestScopeType.weakSpots:
      case StandaloneTestScopeType.previousMistakes:
        final weakRange = await _rangeFromPreviousWeakSpots();
        if (weakRange != null) return weakRange;
        return _rangeForPages(1, 2);

      case StandaloneTestScopeType.randomWholeQuran:
        return _AyahRange(
          startGlobalAyahIndex: 0,
          endGlobalAyahIndex: QuranReaderHelpers.totalAyahs - 1,
        );
    }
  }

  bool _shouldUseFullScope(StandaloneTestScopeType scopeType) {
    return scopeType == StandaloneTestScopeType.wholeSurah ||
        scopeType == StandaloneTestScopeType.surahRange ||
        scopeType == StandaloneTestScopeType.hizb ||
        scopeType == StandaloneTestScopeType.pages ||
        scopeType == StandaloneTestScopeType.customRange ||
        scopeType == StandaloneTestScopeType.lastMemorized ||
        scopeType == StandaloneTestScopeType.weakSpots ||
        scopeType == StandaloneTestScopeType.previousMistakes;
  }

  _AyahRange _rangeForSurah(int surahNumber) {
    return _rangeForSurahAyahs(surahNumber, 1, _surahAyahCount(surahNumber));
  }

  _AyahRange _rangeForSurahAyahs(int surahNumber, int fromAyah, int toAyah) {
    final total = _surahAyahCount(surahNumber);
    final startAyah = fromAyah.clamp(1, total).toInt();
    final endAyah = toAyah.clamp(startAyah, total).toInt();
    final targetSuraIndex = surahNumber - 1;

    int? start;
    int? end;
    for (int index = 0; index < QuranReaderHelpers.totalAyahs; index++) {
      final position = QuranReaderHelpers.getPositionFromGlobalIndex(index);
      if (position.suraIndex != targetSuraIndex) {
        if (start != null && position.suraIndex > targetSuraIndex) break;
        continue;
      }
      final ayah = position.ayahIndex + 1;
      if (ayah >= startAyah && ayah <= endAyah) {
        start ??= index;
        end = index;
      }
    }

    return _AyahRange(
      startGlobalAyahIndex: start ?? 0,
      endGlobalAyahIndex: end ?? start ?? 0,
    );
  }

  int _surahAyahCount(int surahNumber) {
    final safe = surahNumber.clamp(1, 114).toInt();
    int count = 0;
    for (int index = 0; index < QuranReaderHelpers.totalAyahs; index++) {
      final position = QuranReaderHelpers.getPositionFromGlobalIndex(index);
      if (position.suraIndex == safe - 1) count++;
      if (count > 0 && position.suraIndex > safe - 1) break;
    }
    return count.clamp(1, 286).toInt();
  }

  _AyahRange _rangeForJuz(int juzNumber) {
    int? start;
    int? end;

    for (int index = 0; index < QuranReaderHelpers.totalAyahs; index++) {
      final position = QuranReaderHelpers.getPositionFromGlobalIndex(index);
      final juz = QuranReaderHelpers.getJuzNumber(
        suraIndex: position.suraIndex,
        ayahIndex: position.ayahIndex,
      );

      if (juz == juzNumber) {
        start ??= index;
        end = index;
      }

      if (start != null && juz > juzNumber) break;
    }

    return _AyahRange(
      startGlobalAyahIndex: start ?? 0,
      endGlobalAyahIndex: end ?? start ?? 0,
    );
  }

  _AyahRange _rangeForPages(int fromPage, int toPage) {
    final startPage = fromPage.clamp(1, 604).toInt();
    final endPage = toPage.clamp(startPage, 604).toInt();
    final start = QuranPageMapper.getGlobalAyahIndexForPage(startPage);
    final end = endPage >= 604
        ? QuranReaderHelpers.totalAyahs - 1
        : QuranPageMapper.getGlobalAyahIndexForPage(endPage + 1) - 1;
    return _AyahRange(startGlobalAyahIndex: start, endGlobalAyahIndex: end);
  }

  Future<_AyahRange?> _rangeFromPreviousWeakSpots() async {
    final results = await const MemorizationTestResultStorage().getResults();
    final ranges = <_AyahRange>[];

    for (final result in results.take(20)) {
      for (final weakSpot in result.weakSpots) {
        final parsed = _parseWeakSpotRange(weakSpot);
        if (parsed != null) ranges.add(parsed);
      }
      for (final question in result.questionResults) {
        if (!question.isCorrect) {
          ranges.add(
            _AyahRange(
              startGlobalAyahIndex: question.startGlobalAyahIndex,
              endGlobalAyahIndex: question.endGlobalAyahIndex,
            ),
          );
        }
      }
      if (ranges.length >= 8) break;
    }

    if (ranges.isEmpty) return null;
    final start = ranges
        .map((item) => item.startGlobalAyahIndex)
        .reduce(math.min);
    final end = ranges.map((item) => item.endGlobalAyahIndex).reduce(math.max);
    return _AyahRange(
      startGlobalAyahIndex: start
          .clamp(0, QuranReaderHelpers.totalAyahs - 1)
          .toInt(),
      endGlobalAyahIndex: end
          .clamp(start, QuranReaderHelpers.totalAyahs - 1)
          .toInt(),
    );
  }

  _AyahRange? _parseWeakSpotRange(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final start = int.tryParse(parts[0]);
    final end = int.tryParse(parts[1]);
    if (start == null || end == null || end < start) return null;
    return _AyahRange(startGlobalAyahIndex: start, endGlobalAyahIndex: end);
  }

  _AyahRange _selectRangeInsideScope({
    required _AyahRange scope,
    required StandaloneDifficulty difficulty,
  }) {
    final scopeStartPage = QuranPageMapper.getPageNumberForGlobalAyah(
      scope.startGlobalAyahIndex,
    );
    final scopeEndPage = QuranPageMapper.getPageNumberForGlobalAyah(
      scope.endGlobalAyahIndex,
    );

    final scopePages = math.max(1, scopeEndPage - scopeStartPage + 1);
    final wantedPages = math.min(scopePages, _pagesForDifficulty(difficulty));
    if (scopePages <= wantedPages) return scope;

    final now = DateTime.now();
    final seed = _stableSeed(
      '${scope.startGlobalAyahIndex}|${scope.endGlobalAyahIndex}|'
      '${difficulty.name}|${now.year}-${now.month}-${now.day}',
    );
    final random = math.Random(seed);
    final selectedStartPage =
        scopeStartPage +
        random.nextInt(math.max(1, scopePages - wantedPages + 1));
    final selectedEndPage = math.min(
      selectedStartPage + wantedPages - 1,
      scopeEndPage,
    );

    final pageStartGlobalAyahIndex = QuranPageMapper.getGlobalAyahIndexForPage(
      selectedStartPage,
    );
    final pageEndGlobalAyahIndex = selectedEndPage >= 604
        ? QuranReaderHelpers.totalAyahs - 1
        : QuranPageMapper.getGlobalAyahIndexForPage(selectedEndPage + 1) - 1;

    final safeStart = pageStartGlobalAyahIndex
        .clamp(scope.startGlobalAyahIndex, scope.endGlobalAyahIndex)
        .toInt();
    final safeEnd = pageEndGlobalAyahIndex
        .clamp(safeStart, scope.endGlobalAyahIndex)
        .toInt();

    return _AyahRange(
      startGlobalAyahIndex: safeStart,
      endGlobalAyahIndex: safeEnd,
    );
  }

  int _pagesForDifficulty(StandaloneDifficulty difficulty) {
    switch (difficulty) {
      case StandaloneDifficulty.easy:
        return 1;
      case StandaloneDifficulty.medium:
        return 2;
      case StandaloneDifficulty.hard:
        return 3;
      case StandaloneDifficulty.comprehensive:
        return 5;
    }
  }

  int _estimateMinutes({
    required int ayahsCount,
    required StandaloneDifficulty difficulty,
    required int questionCount,
  }) {
    final multiplier = switch (difficulty) {
      StandaloneDifficulty.easy => 0.28,
      StandaloneDifficulty.medium => 0.38,
      StandaloneDifficulty.hard => 0.50,
      StandaloneDifficulty.comprehensive => 0.62,
    };
    final minutes = 4 + (questionCount * 0.7) + (ayahsCount * multiplier);
    return minutes.clamp(5, 60).round();
  }

  int _stableSeed(String source) {
    int hash = 0x811C9DC5;
    for (final codeUnit in source.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}

extension _StandaloneTimerEngineLabels on StandaloneTimerMode {
  String timerTitle(MemorizationManualTestRequest request) {
    switch (this) {
      case StandaloneTimerMode.none:
        return 'بدون وقت';
      case StandaloneTimerMode.perQuestion:
        return 'وقت لكل سؤال';
      case StandaloneTimerMode.fullTest:
        return 'وقت للاختبار';
      case StandaloneTimerMode.customMinutes:
        return 'وقت مخصص';
    }
  }
}

class _AyahRange {
  const _AyahRange({
    required this.startGlobalAyahIndex,
    required this.endGlobalAyahIndex,
  });

  final int startGlobalAyahIndex;
  final int endGlobalAyahIndex;
}
