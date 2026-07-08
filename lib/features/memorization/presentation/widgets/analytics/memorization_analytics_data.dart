import 'dart:math' as math;

import 'package:islamic_app/features/memorization/data/models/memorization_active_plan_model.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_session_result_model.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_today_task_model.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_journey_companion_service.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_plan_journey_engine.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_plan_storage.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_rescue_review_engine.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_session_result_storage.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_weak_spots_engine.dart';
import 'package:islamic_app/features/quran/reader/quran_page_mapper.dart';
import 'package:islamic_app/features/quran/reader/quran_reader_helpers.dart';
import 'package:islamic_app/features/memorization/results/models/memorization_test_result_model.dart';
import 'package:islamic_app/features/memorization/results/services/memorization_test_result_storage.dart';

class MemorizationAnalyticsData {
  const MemorizationAnalyticsData({
    required this.masteryPercent,
    required this.testsCount,
    required this.reviewPages,
    required this.memorizedPages,
    required this.strongGroups,
    required this.weakGroups,
    required this.trendPoints,
    required this.trendLabels,
    required this.smartSummary,
    required this.sessionQuality,
    required this.comparison,
    required this.commitment,
    required this.upcomingItems,
    required this.testResults,
  });

  MemorizationAnalyticsData.empty(MemorizationAnalyticsPeriod period)
    : masteryPercent = 0,
      testsCount = 0,
      reviewPages = 0,
      memorizedPages = 0,
      strongGroups = const [],
      weakGroups = const [],
      trendPoints = List<double>.filled(period.days, 0),
      trendLabels = buildTrendLabels(period.days),
      smartSummary = const AnalyticsSmartSummary(
        title: 'ابدأ رحلتك أولًا',
        subtitle: 'بعد إنشاء خطة وإكمال أول جلسة، ستظهر هنا قراءة ذكية لتقدمك.',
        tone: AnalyticsSummaryTone.neutral,
      ),
      sessionQuality = const AnalyticsSessionQuality.empty(),
      comparison = const AnalyticsComparison.empty(),
      commitment = AnalyticsCommitment.empty(period.days),
      upcomingItems = const [],
      testResults = const AnalyticsTestResults.empty();

  final int masteryPercent;
  final int testsCount;
  final int reviewPages;
  final int memorizedPages;
  final List<AnalyticsRangeGroup> strongGroups;
  final List<AnalyticsRangeGroup> weakGroups;
  final List<double> trendPoints;
  final List<String> trendLabels;
  final AnalyticsSmartSummary smartSummary;
  final AnalyticsSessionQuality sessionQuality;
  final AnalyticsComparison comparison;
  final AnalyticsCommitment commitment;
  final List<AnalyticsUpcomingItem> upcomingItems;
  final AnalyticsTestResults testResults;

  // Keep these getters for any old UI code that still reads labels only.
  List<String> get strongPoints =>
      strongGroups.map((group) => group.title).toList(growable: false);

  List<String> get weakPoints =>
      weakGroups.map((group) => group.title).toList(growable: false);

  static Future<MemorizationAnalyticsData> load(
    MemorizationAnalyticsPeriod period,
  ) async {
    final activePlan = await MemorizationPlanStorage.getActivePlan();

    if (activePlan == null) {
      return MemorizationAnalyticsData.empty(period);
    }

    await QuranPageMapper.load();

    final results = await MemorizationSessionResultStorage.getResults();
    final detailedTestResults = await const MemorizationTestResultStorage()
        .getResults(planId: activePlan.id);
    final weakSpots = await const MemorizationWeakSpotsEngine().getWeakSpots();
    final companionReport = await const MemorizationJourneyCompanionService()
        .buildReport();

    final planResults = results.where((result) {
      return _belongsToActivePlan(plan: activePlan, result: result);
    }).toList()..sort((a, b) => a.completedAt.compareTo(b.completedAt));

    final currentPeriodResults = _resultsInLastDays(
      results: planResults,
      days: period.days,
      offsetDays: 0,
    );

    final previousPeriodResults = _resultsInLastDays(
      results: planResults,
      days: period.days,
      offsetDays: period.days,
    );
    final currentPeriodTestResults = _testResultsInLastDays(
      results: detailedTestResults,
      days: period.days,
    );

    if (planResults.isEmpty && currentPeriodTestResults.isEmpty) {
      final weakGroups = _weakPointGroups(weakSpots);

      return MemorizationAnalyticsData(
        masteryPercent: 0,
        testsCount: 0,
        reviewPages: 0,
        memorizedPages: 0,
        strongGroups: const [],
        weakGroups: weakGroups,
        trendPoints: List<double>.filled(period.days, 0),
        trendLabels: buildTrendLabels(period.days),
        smartSummary: _buildSmartSummary(
          activePlan: activePlan,
          planResults: const [],
          periodResults: const [],
          weakGroups: weakGroups,
          companionReport: companionReport,
        ),
        sessionQuality: const AnalyticsSessionQuality.empty(),
        comparison: const AnalyticsComparison.empty(),
        commitment: AnalyticsCommitment.empty(period.days),
        upcomingItems: await _upcomingItems(
          activePlan: activePlan,
          allResults: results,
        ),
        testResults: const AnalyticsTestResults.empty(),
      );
    }

    final memorizedPages = _uniquePagesCount(
      planResults.where((result) => result.taskType == 'dailyNew'),
    );

    final reviewPages = _totalPagesCount(
      planResults.where(
        (result) =>
            result.taskType == 'dailyReview' || result.taskType == 'weakReview',
      ),
    );

    final testsCount = currentPeriodTestResults.isNotEmpty
        ? currentPeriodTestResults.length
        : planResults.where((result) {
            return result.taskType == 'selfTest';
          }).length;

    final weakGroups = _weakPointGroups(weakSpots);

    return MemorizationAnalyticsData(
      masteryPercent: _overallMasteryPercent(planResults),
      testsCount: testsCount,
      reviewPages: reviewPages,
      memorizedPages: memorizedPages,
      strongGroups: _strongPointGroups(planResults),
      weakGroups: weakGroups,
      trendPoints: _masteryTrendPoints(results: planResults, days: period.days),
      trendLabels: buildTrendLabels(period.days),
      smartSummary: _buildSmartSummary(
        activePlan: activePlan,
        planResults: planResults,
        periodResults: currentPeriodResults,
        weakGroups: weakGroups,
        companionReport: companionReport,
      ),
      sessionQuality: AnalyticsSessionQuality.fromResults(currentPeriodResults),
      comparison: AnalyticsComparison.fromResults(
        currentResults: currentPeriodResults,
        previousResults: previousPeriodResults,
      ),
      commitment: AnalyticsCommitment.fromResults(
        results: currentPeriodResults,
        periodDays: period.days,
      ),
      upcomingItems: await _upcomingItems(
        activePlan: activePlan,
        allResults: results,
      ),
      testResults: currentPeriodTestResults.isNotEmpty
          ? AnalyticsTestResults.fromTestResults(currentPeriodTestResults)
          : AnalyticsTestResults.fromResults(currentPeriodResults),
    );
  }

  static bool _belongsToActivePlan({
    required MemorizationActivePlanModel plan,
    required MemorizationSessionResultModel result,
  }) {
    if (result.completedAt.isBefore(plan.createdAt)) return false;

    final overlapsMainRange =
        result.endGlobalAyahIndex >= plan.scopeStartGlobalAyahIndex &&
        result.startGlobalAyahIndex <= plan.scopeEndGlobalAyahIndex;

    final overlapsReviewRange =
        plan.hasValidReviewRange &&
        result.endGlobalAyahIndex >= plan.reviewStartGlobalAyahIndex &&
        result.startGlobalAyahIndex <= plan.reviewEndGlobalAyahIndex;

    return overlapsMainRange || overlapsReviewRange;
  }

  static List<MemorizationSessionResultModel> _resultsInLastDays({
    required List<MemorizationSessionResultModel> results,
    required int days,
    required int offsetDays,
  }) {
    final today = _dateOnly(DateTime.now());
    final end = today.subtract(Duration(days: offsetDays));
    final start = end.subtract(Duration(days: days - 1));

    return results
        .where((result) {
          final day = _dateOnly(result.completedAt);
          return !day.isBefore(start) && !day.isAfter(end);
        })
        .toList(growable: false);
  }

  static List<MemorizationTestResultModel> _testResultsInLastDays({
    required List<MemorizationTestResultModel> results,
    required int days,
  }) {
    final today = _dateOnly(DateTime.now());
    final start = today.subtract(Duration(days: days - 1));
    return results
        .where((result) {
          final day = _dateOnly(result.completedAt);
          return !day.isBefore(start) && !day.isAfter(today);
        })
        .toList(growable: false);
  }

  static int _overallMasteryPercent(
    List<MemorizationSessionResultModel> results,
  ) {
    if (results.isEmpty) return 0;

    final score = results.fold<int>(0, (sum, result) {
      return sum + ratingScore(result.rating);
    });

    return (score / results.length).round().clamp(0, 100).toInt();
  }

  static int ratingScore(String rating) {
    switch (rating) {
      case 'easy':
        return 100;
      case 'good':
        return 75;
      case 'hard':
        return 40;
      case 'forgot':
        return 15;
      default:
        return 70;
    }
  }

  static AnalyticsSmartSummary _buildSmartSummary({
    required MemorizationActivePlanModel activePlan,
    required List<MemorizationSessionResultModel> planResults,
    required List<MemorizationSessionResultModel> periodResults,
    required List<AnalyticsRangeGroup> weakGroups,
    required MemorizationJourneyCompanionReport companionReport,
  }) {
    if (planResults.isEmpty) {
      return AnalyticsSmartSummary(
        title: 'الخطة جاهزة للانطلاق',
        subtitle:
            'ابدأ أول جلسة في ${activePlan.planName}، وبعدها سنعرض لك تحليلات حقيقية.',
        tone: AnalyticsSummaryTone.neutral,
      );
    }

    final periodQuality = AnalyticsSessionQuality.fromResults(periodResults);
    final mastery = _overallMasteryPercent(planResults);

    if (periodQuality.forgot > 0 || weakGroups.isNotEmpty) {
      return AnalyticsSmartSummary(
        title: 'محتاج تثبيت قريب',
        subtitle: weakGroups.isEmpty
            ? 'ظهر نسيان في الفترة الأخيرة؛ راجع موضعًا قصيرًا قبل إضافة حفظ جديد.'
            : 'عندك ${weakGroups.length} موضع يحتاج تركيز. ابدأ بالمراجعة قبل الجلسة الجديدة.',
        tone: AnalyticsSummaryTone.warning,
      );
    }

    if (mastery >= 82 && companionReport.commitmentPercent >= 70) {
      return const AnalyticsSmartSummary(
        title: 'الخطة مستقرة جدًا',
        subtitle: 'إتقانك جيد والتزامك واضح. استمر بنفس الهدوء بدون زيادة ضغط.',
        tone: AnalyticsSummaryTone.success,
      );
    }

    if (companionReport.commitmentPercent < 45) {
      return const AnalyticsSmartSummary(
        title: 'الاستمرارية أهم من السرعة',
        subtitle: 'حاول تثبيت جلسة قصيرة يوميًا حتى لو كانت مراجعة فقط.',
        tone: AnalyticsSummaryTone.warning,
      );
    }

    return AnalyticsSmartSummary(
      title: companionReport.title.isEmpty
          ? 'تقدمك ماشي كويس'
          : companionReport.title,
      subtitle: companionReport.message.isEmpty
          ? 'استمر على نفس الوتيرة وراجع المواضع الصعبة أولًا بأول.'
          : companionReport.message,
      tone: AnalyticsSummaryTone.neutral,
    );
  }

  static List<AnalyticsRangeGroup> _strongPointGroups(
    List<MemorizationSessionResultModel> results,
  ) {
    final grouped = <String, _RangeGroupStats>{};

    for (final result in results) {
      if (result.rating != 'easy' && result.rating != 'good') continue;

      final info = _rangeInfo(
        result.startGlobalAyahIndex,
        result.endGlobalAyahIndex,
      );

      final stats = grouped.putIfAbsent(
        info.groupTitle,
        () => _RangeGroupStats(title: info.groupTitle),
      );

      stats.count++;
      stats.score += ratingScore(result.rating);
      stats.addRange(info.rangeText);

      if (result.completedAt.isAfter(stats.latest)) {
        stats.latest = result.completedAt;
      }
    }

    final entries = grouped.values.toList()
      ..sort((a, b) {
        final averageCompare = b.average.compareTo(a.average);
        if (averageCompare != 0) return averageCompare;

        final countCompare = b.count.compareTo(a.count);
        if (countCompare != 0) return countCompare;

        return b.latest.compareTo(a.latest);
      });

    return entries
        .take(4)
        .map((stats) {
          return AnalyticsRangeGroup(
            title: stats.title,
            subtitle: '${stats.count} جلسة قوية',
            ranges: stats.ranges.take(8).toList(growable: false),
          );
        })
        .toList(growable: false);
  }

  static List<AnalyticsRangeGroup> _weakPointGroups(
    List<MemorizationWeakSpotModel> weakSpots,
  ) {
    final grouped = <String, _RangeGroupStats>{};

    for (final weakSpot in weakSpots) {
      final info = _rangeInfo(
        weakSpot.startGlobalAyahIndex,
        weakSpot.endGlobalAyahIndex,
      );

      final stats = grouped.putIfAbsent(
        info.groupTitle,
        () => _RangeGroupStats(title: info.groupTitle),
      );

      stats.count += weakSpot.attemptsCount.clamp(1, 999).toInt();
      stats.score += weakSpot.latestRating == 'forgot' ? 0 : 40;
      stats.addRange(info.rangeText);

      if (weakSpot.lastSeenAt.isAfter(stats.latest)) {
        stats.latest = weakSpot.lastSeenAt;
      }
    }

    final entries = grouped.values.toList()
      ..sort((a, b) {
        final countCompare = b.count.compareTo(a.count);
        if (countCompare != 0) return countCompare;
        return b.latest.compareTo(a.latest);
      });

    return entries
        .take(4)
        .map((stats) {
          return AnalyticsRangeGroup(
            title: stats.title,
            subtitle: '${stats.ranges.length} موضع يحتاج تركيز',
            ranges: stats.ranges.take(8).toList(growable: false),
          );
        })
        .toList(growable: false);
  }

  static List<double> _masteryTrendPoints({
    required List<MemorizationSessionResultModel> results,
    required int days,
  }) {
    final now = DateTime.now();
    final startDay = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));

    final points = <double>[];
    double previousValue = 0;

    for (int dayOffset = 0; dayOffset < days; dayOffset++) {
      final day = startDay.add(Duration(days: dayOffset));
      final dayResults = results.where((result) {
        final completedAt = result.completedAt;
        return completedAt.year == day.year &&
            completedAt.month == day.month &&
            completedAt.day == day.day;
      }).toList();

      if (dayResults.isEmpty) {
        points.add(previousValue);
        continue;
      }

      final dayScore = dayResults.fold<int>(0, (sum, result) {
        return sum + ratingScore(result.rating);
      });

      previousValue = (dayScore / dayResults.length).clamp(0, 100).toDouble();
      points.add(previousValue);
    }

    return points;
  }

  static Future<List<AnalyticsUpcomingItem>> _upcomingItems({
    required MemorizationActivePlanModel activePlan,
    required List<MemorizationSessionResultModel> allResults,
  }) async {
    final today = _dateOnly(DateTime.now());
    final items = <AnalyticsUpcomingItem>[];

    final rescueTasks =
        const MemorizationRescueReviewEngine()
            .getUpcomingRescueTasks(
              results: allResults,
              activePlan: activePlan,
              daysAhead: 21,
            )
            .where(
              (task) => !_dateOnly(task.effectiveScheduledDate).isBefore(today),
            )
            .toList()
          ..sort(
            (a, b) =>
                a.effectiveScheduledDate.compareTo(b.effectiveScheduledDate),
          );

    for (final task in rescueTasks.take(2)) {
      items.add(
        AnalyticsUpcomingItem.fromTask(
          task: task,
          type: AnalyticsUpcomingType.rescue,
        ),
      );
    }

    final journeyTasks = await const MemorizationPlanJourneyEngine()
        .buildJourneyTasks(
          plan: activePlan,
          activeTask: await MemorizationPlanStorage.getTodayTask(),
          daysAhead: math.max(45, activePlan.totalDays.clamp(30, 365).toInt()),
        );

    final tests =
        journeyTasks
            .where((item) => item.task.type == 'selfTest')
            .where((item) => !_dateOnly(item.date).isBefore(today))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    for (final item in tests.take(1)) {
      items.add(
        AnalyticsUpcomingItem.fromTask(
          task: item.task,
          type: AnalyticsUpcomingType.test,
          overrideDate: item.date,
        ),
      );
    }

    items.sort((a, b) => a.date.compareTo(b.date));
    return items.take(3).toList(growable: false);
  }

  static int _uniquePagesCount(
    Iterable<MemorizationSessionResultModel> results,
  ) {
    final pages = <int>{};

    for (final result in results) {
      final range = _safeResultPageRange(result);

      for (int page = range.startPage; page <= range.endPage; page++) {
        pages.add(page);
      }
    }

    return pages.length;
  }

  static int _totalPagesCount(
    Iterable<MemorizationSessionResultModel> results,
  ) {
    int total = 0;

    for (final result in results) {
      final range = _safeResultPageRange(result);
      total += math.max(1, range.endPage - range.startPage + 1);
    }

    return total;
  }

  static _PageRange _safeResultPageRange(
    MemorizationSessionResultModel result,
  ) {
    final int maxAyahIndex = QuranReaderHelpers.totalAyahs - 1;
    final int startIndex = result.startGlobalAyahIndex
        .clamp(0, maxAyahIndex)
        .toInt();
    final int endIndex = result.endGlobalAyahIndex
        .clamp(startIndex, maxAyahIndex)
        .toInt();

    final int startPage = QuranPageMapper.getPageNumberForGlobalAyah(
      startIndex,
    ).clamp(1, 604).toInt();
    final int endPage = QuranPageMapper.getPageNumberForGlobalAyah(
      endIndex,
    ).clamp(startPage, 604).toInt();

    return _PageRange(startPage: startPage, endPage: endPage);
  }
}

class AnalyticsSmartSummary {
  const AnalyticsSmartSummary({
    required this.title,
    required this.subtitle,
    required this.tone,
  });

  final String title;
  final String subtitle;
  final AnalyticsSummaryTone tone;
}

enum AnalyticsSummaryTone { success, warning, neutral }

class AnalyticsSessionQuality {
  const AnalyticsSessionQuality({
    required this.easy,
    required this.good,
    required this.hard,
    required this.forgot,
  });

  const AnalyticsSessionQuality.empty()
    : easy = 0,
      good = 0,
      hard = 0,
      forgot = 0;

  final int easy;
  final int good;
  final int hard;
  final int forgot;

  int get total => easy + good + hard + forgot;

  static AnalyticsSessionQuality fromResults(
    List<MemorizationSessionResultModel> results,
  ) {
    int easy = 0;
    int good = 0;
    int hard = 0;
    int forgot = 0;

    for (final result in results) {
      switch (result.rating) {
        case 'easy':
          easy++;
          break;
        case 'good':
          good++;
          break;
        case 'hard':
          hard++;
          break;
        case 'forgot':
          forgot++;
          break;
      }
    }

    return AnalyticsSessionQuality(
      easy: easy,
      good: good,
      hard: hard,
      forgot: forgot,
    );
  }
}

class AnalyticsTestResults {
  const AnalyticsTestResults({
    required this.totalTests,
    required this.averageScore,
    required this.strongTests,
    required this.needsReviewTests,
    required this.latestItems,
  });

  const AnalyticsTestResults.empty()
    : totalTests = 0,
      averageScore = 0,
      strongTests = 0,
      needsReviewTests = 0,
      latestItems = const [];

  final int totalTests;
  final int averageScore;
  final int strongTests;
  final int needsReviewTests;
  final List<AnalyticsTestResultItem> latestItems;

  bool get hasResults => totalTests > 0;

  static AnalyticsTestResults fromResults(
    List<MemorizationSessionResultModel> results,
  ) {
    final tests = results.where((result) {
      return result.taskType == 'selfTest';
    }).toList()..sort((a, b) => b.completedAt.compareTo(a.completedAt));

    if (tests.isEmpty) return const AnalyticsTestResults.empty();

    final totalScore = tests.fold<int>(0, (sum, result) {
      return sum + MemorizationAnalyticsData.ratingScore(result.rating);
    });

    final strongTests = tests.where((result) {
      return result.rating == 'easy' || result.rating == 'good';
    }).length;

    final needsReviewTests = tests.where((result) {
      return result.rating == 'hard' || result.rating == 'forgot';
    }).length;

    return AnalyticsTestResults(
      totalTests: tests.length,
      averageScore: (totalScore / tests.length).round().clamp(0, 100).toInt(),
      strongTests: strongTests,
      needsReviewTests: needsReviewTests,
      latestItems: tests
          .take(3)
          .map(AnalyticsTestResultItem.fromResult)
          .toList(growable: false),
    );
  }

  static AnalyticsTestResults fromTestResults(
    List<MemorizationTestResultModel> results,
  ) {
    final tests = List<MemorizationTestResultModel>.from(results)
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    if (tests.isEmpty) return const AnalyticsTestResults.empty();

    final average =
        tests.fold<double>(0, (sum, result) => sum + result.scorePercent) /
        tests.length;
    return AnalyticsTestResults(
      totalTests: tests.length,
      averageScore: average.round().clamp(0, 100).toInt(),
      strongTests: tests.where((result) => result.scorePercent >= 70).length,
      needsReviewTests: tests
          .where((result) => result.scorePercent < 70)
          .length,
      latestItems: tests
          .take(3)
          .map(AnalyticsTestResultItem.fromTestResult)
          .toList(growable: false),
    );
  }
}

class AnalyticsTestResultItem {
  const AnalyticsTestResultItem({
    required this.title,
    required this.subtitle,
    required this.scoreLabel,
    required this.ratingLabel,
    required this.dateLabel,
    required this.rating,
  });

  final String title;
  final String subtitle;
  final String scoreLabel;
  final String ratingLabel;
  final String dateLabel;
  final String rating;

  factory AnalyticsTestResultItem.fromResult(
    MemorizationSessionResultModel result,
  ) {
    final range = _rangeInfo(
      result.startGlobalAyahIndex,
      result.endGlobalAyahIndex,
    );

    return AnalyticsTestResultItem(
      title: range.groupTitle,
      subtitle: range.rangeText,
      scoreLabel: '${MemorizationAnalyticsData.ratingScore(result.rating)}%',
      ratingLabel: _ratingArabicLabel(result.rating),
      dateLabel: _relativeDayLabel(result.completedAt),
      rating: result.rating,
    );
  }

  factory AnalyticsTestResultItem.fromTestResult(
    MemorizationTestResultModel result,
  ) {
    final range = _rangeInfo(
      result.startGlobalAyahIndex,
      result.endGlobalAyahIndex,
    );
    final rating = result.scorePercent >= 90
        ? 'easy'
        : result.scorePercent >= 70
        ? 'good'
        : result.scorePercent >= 45
        ? 'hard'
        : 'forgot';
    return AnalyticsTestResultItem(
      title: range.groupTitle,
      subtitle: '${range.rangeText} • ${result.questionCount} سؤال',
      scoreLabel: '${result.scorePercent.round()}%',
      ratingLabel: _ratingArabicLabel(rating),
      dateLabel: _relativeDayLabel(result.completedAt),
      rating: rating,
    );
  }
}

class AnalyticsComparison {
  const AnalyticsComparison({
    required this.masteryDelta,
    required this.sessionsDelta,
    required this.forgotDelta,
  });

  const AnalyticsComparison.empty()
    : masteryDelta = 0,
      sessionsDelta = 0,
      forgotDelta = 0;

  final int masteryDelta;
  final int sessionsDelta;
  final int forgotDelta;

  bool get hasAnyChange =>
      masteryDelta != 0 || sessionsDelta != 0 || forgotDelta != 0;

  static AnalyticsComparison fromResults({
    required List<MemorizationSessionResultModel> currentResults,
    required List<MemorizationSessionResultModel> previousResults,
  }) {
    final currentMastery = MemorizationAnalyticsData._overallMasteryPercent(
      currentResults,
    );
    final previousMastery = MemorizationAnalyticsData._overallMasteryPercent(
      previousResults,
    );

    final currentForgot = currentResults.where((result) {
      return result.rating == 'forgot';
    }).length;

    final previousForgot = previousResults.where((result) {
      return result.rating == 'forgot';
    }).length;

    return AnalyticsComparison(
      masteryDelta: currentMastery - previousMastery,
      sessionsDelta: currentResults.length - previousResults.length,
      forgotDelta: currentForgot - previousForgot,
    );
  }
}

class AnalyticsCommitment {
  const AnalyticsCommitment({
    required this.activeDays,
    required this.periodDays,
    required this.averageMinutes,
    required this.lastSessionLabel,
  });

  AnalyticsCommitment.empty(int periodDays)
    : activeDays = 0,
      periodDays = periodDays,
      averageMinutes = 0,
      lastSessionLabel = 'لا توجد جلسات بعد';

  final int activeDays;
  final int periodDays;
  final int averageMinutes;
  final String lastSessionLabel;

  static AnalyticsCommitment fromResults({
    required List<MemorizationSessionResultModel> results,
    required int periodDays,
  }) {
    if (results.isEmpty) return AnalyticsCommitment.empty(periodDays);

    final activeDays = <String>{};
    int totalMinutes = 0;
    int minutesCount = 0;
    DateTime latest = results.first.completedAt;

    for (final result in results) {
      final day = _dateOnly(result.completedAt);
      activeDays.add(_dateKey(day));

      final minutes = result.actualMinutes > 0
          ? result.actualMinutes
          : result.estimatedMinutes;

      if (minutes > 0) {
        totalMinutes += minutes;
        minutesCount++;
      }

      if (result.completedAt.isAfter(latest)) latest = result.completedAt;
    }

    return AnalyticsCommitment(
      activeDays: activeDays.length,
      periodDays: periodDays,
      averageMinutes: minutesCount == 0
          ? 0
          : (totalMinutes / minutesCount).round(),
      lastSessionLabel: _relativeDayLabel(latest),
    );
  }
}

class AnalyticsUpcomingItem {
  const AnalyticsUpcomingItem({
    required this.title,
    required this.subtitle,
    required this.dateLabel,
    required this.type,
    required this.date,
  });

  final String title;
  final String subtitle;
  final String dateLabel;
  final AnalyticsUpcomingType type;
  final DateTime date;

  factory AnalyticsUpcomingItem.fromTask({
    required MemorizationTodayTaskModel task,
    required AnalyticsUpcomingType type,
    DateTime? overrideDate,
  }) {
    final date = _dateOnly(overrideDate ?? task.effectiveScheduledDate);
    final range = _rangeInfo(
      task.startGlobalAyahIndex,
      task.endGlobalAyahIndex,
    );

    return AnalyticsUpcomingItem(
      title: type == AnalyticsUpcomingType.test
          ? 'الاختبار القادم'
          : 'مراجعة إنقاذ قادمة',
      subtitle: range.rangeText,
      dateLabel: _dueDateLabel(date),
      type: type,
      date: date,
    );
  }
}

enum AnalyticsUpcomingType { rescue, test }

class AnalyticsRangeGroup {
  const AnalyticsRangeGroup({
    required this.title,
    required this.subtitle,
    required this.ranges,
  });

  final String title;
  final String subtitle;
  final List<String> ranges;
}

enum MemorizationAnalyticsPeriod {
  last7Days('آخر 7 أيام', 7),
  last14Days('آخر 14 يوم', 14),
  last30Days('آخر 30 يوم', 30);

  const MemorizationAnalyticsPeriod(this.label, this.days);

  final String label;
  final int days;
}

List<String> buildTrendLabels(int days) {
  final now = DateTime.now();
  final startDay = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: days - 1));

  final indexes = <int>{0, (days / 2).floor(), days - 1}.toList()..sort();

  return List<String>.generate(days, (index) {
    if (!indexes.contains(index)) return '';

    final day = startDay.add(Duration(days: index));
    return '${day.day} ${_arabicMonthName(day.month)}';
  });
}

String _arabicMonthName(int month) {
  const months = <String>[
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  if (month < 1 || month > 12) return '';
  return months[month - 1];
}

class _PageRange {
  const _PageRange({required this.startPage, required this.endPage});

  final int startPage;
  final int endPage;
}

class _RangeInfo {
  const _RangeInfo({required this.groupTitle, required this.rangeText});

  final String groupTitle;
  final String rangeText;
}

class _RangeGroupStats {
  _RangeGroupStats({required this.title});

  final String title;
  final List<String> ranges = [];
  int count = 0;
  int score = 0;
  DateTime latest = DateTime.fromMillisecondsSinceEpoch(0);

  double get average => count == 0 ? 0 : score / count;

  void addRange(String value) {
    if (!ranges.contains(value)) ranges.add(value);
  }
}

_RangeInfo _rangeInfo(int startIndex, int endIndex) {
  final int maxAyahIndex = QuranReaderHelpers.totalAyahs - 1;
  final int safeStart = startIndex.clamp(0, maxAyahIndex).toInt();
  final int safeEnd = endIndex.clamp(safeStart, maxAyahIndex).toInt();

  final start = QuranReaderHelpers.getPositionFromGlobalIndex(safeStart);
  final end = QuranReaderHelpers.getPositionFromGlobalIndex(safeEnd);

  final startSurahName = QuranReaderHelpers.getSuraName(start.suraIndex);
  final endSurahName = QuranReaderHelpers.getSuraName(end.suraIndex);

  final startAyah = start.ayahIndex + 1;
  final endAyah = end.ayahIndex + 1;

  if (start.suraIndex == end.suraIndex) {
    final title = 'سورة $startSurahName';

    return _RangeInfo(
      groupTitle: title,
      rangeText: startAyah == endAyah
          ? '$title • آية $startAyah'
          : '$title • من آية $startAyah إلى $endAyah',
    );
  }

  return _RangeInfo(
    groupTitle: '$startSurahName - $endSurahName',
    rangeText:
        'من سورة $startSurahName آية $startAyah إلى سورة $endSurahName آية $endAyah',
  );
}

String _ratingArabicLabel(String rating) {
  switch (rating) {
    case 'easy':
      return 'ممتاز';
    case 'good':
      return 'جيد';
    case 'hard':
      return 'يحتاج تثبيت';
    case 'forgot':
      return 'نسيان';
    default:
      return 'جيد';
  }
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

String _dateKey(DateTime value) {
  final day = _dateOnly(value);
  return '${day.year}-${day.month}-${day.day}';
}

String _relativeDayLabel(DateTime value) {
  final today = _dateOnly(DateTime.now());
  final day = _dateOnly(value);
  final diff = today.difference(day).inDays;

  if (diff <= 0) return 'اليوم';
  if (diff == 1) return 'أمس';
  if (diff == 2) return 'منذ يومين';
  return 'منذ $diff أيام';
}

String _dueDateLabel(DateTime value) {
  final today = _dateOnly(DateTime.now());
  final diff = _dateOnly(value).difference(today).inDays;

  if (diff <= 0) return 'اليوم';
  if (diff == 1) return 'غدًا';
  if (diff == 2) return 'بعد غد';
  return 'بعد $diff أيام';
}
