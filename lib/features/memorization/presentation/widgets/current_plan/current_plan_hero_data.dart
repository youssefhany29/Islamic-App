import 'dart:math' as math;

import 'package:islamic_app/features/memorization/data/models/memorization_active_plan_model.dart';
import 'package:islamic_app/features/memorization/results/models/memorization_course_certificate.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_session_result_model.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_test_preferences.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_today_task_model.dart';
import 'package:islamic_app/features/memorization/data/models/planning/memorization_plan_timeline_summary.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_plan_journey_engine.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_plan_completion_service.dart';
import 'package:islamic_app/features/memorization/data/services/planning/memorization_plan_timeline_resolver.dart';
import 'package:islamic_app/features/memorization/results/services/memorization_course_certificate_service.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_plan_storage.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_session_result_storage.dart';
import 'package:islamic_app/features/memorization/data/services/quran_memorization_range_resolver.dart';

class CurrentPlanHeroData {
  const CurrentPlanHeroData({
    required this.plan,
    required this.scopeTitle,
    required this.rangeLabel,
    required this.pagesLabel,
    required this.durationLabel,
    required this.dailyLoadLabel,
    required this.remainingDaysLabel,
    required this.testsLabel,
    required this.currentPlanDayLabel,
    required this.currentLessonLabel,
    required this.remainingPagesLabel,
    required this.progressPercent,
    required this.progressLabel,
    required this.isCompleted,
    required this.stageItems,
    required this.todayReviewPageLabels,
    this.timelineSummary,
    this.certificate,
    this.nextTask,
  });

  final MemorizationActivePlanModel plan;
  final String scopeTitle;
  final String rangeLabel;
  final String pagesLabel;
  final String durationLabel;
  final String dailyLoadLabel;
  final String remainingDaysLabel;
  final String testsLabel;
  final String currentPlanDayLabel;
  final String currentLessonLabel;
  final String remainingPagesLabel;
  final int progressPercent;
  final String progressLabel;
  final bool isCompleted;
  final List<CurrentPlanStageItem> stageItems;
  final List<String> todayReviewPageLabels;
  final MemorizationPlanTimelineSummary? timelineSummary;
  final MemorizationCourseCertificate? certificate;
  final MemorizationTodayTaskModel? nextTask;

  static Future<CurrentPlanHeroData?> load() async {
    final plan = await MemorizationPlanStorage.getActivePlan();
    if (plan == null) return null;

    final results = await MemorizationSessionResultStorage.getResults();
    final completionSnapshot = const MemorizationPlanCompletionService()
        .evaluate(plan: plan, results: results);

    if (completionSnapshot.isCompleted) {
      final certificate = await const MemorizationCourseCertificateService()
          .buildForPlan(plan: plan, results: results);
      final shouldPersistCompletion =
          !plan.isCompleted ||
          (plan.finalCourseScore == null && certificate != null);
      final completedPlan = shouldPersistCompletion
          ? (await MemorizationPlanStorage.markPlanCompleted(
                  planId: plan.id,
                  completedAt:
                      plan.completedAt ??
                      completionSnapshot.completedAt ??
                      DateTime.now(),
                  finalCourseScore: certificate?.finalScore,
                )) ??
                plan.copyWith(
                  planStatus: MemorizationActivePlanModel.statusCompleted,
                  completedAt:
                      plan.completedAt ??
                      completionSnapshot.completedAt ??
                      DateTime.now(),
                  finalCourseScore: certificate?.finalScore,
                )
          : plan;

      return CurrentPlanHeroData.fromPlan(
        plan: completedPlan,
        results: results,
        nextTask: null,
        todayReviewPageLabels: const [],
        certificate: certificate,
        completionSnapshot: completionSnapshot,
      );
    }

    final activeTask = await MemorizationPlanStorage.getTodayTaskForPlan(
      plan.id,
    );
    final journeyTasks = await _planJourneyTasks(
      plan: plan,
      activeTask: activeTask,
    );
    final todayJourneyTasks = _todayJourneyTasks(journeyTasks);
    final timeline = const MemorizationPlanTimelineResolver().resolve(
      plan: plan,
      journeyTasks: journeyTasks,
      results: results,
    );
    final certificate = await const MemorizationCourseCertificateService()
        .buildForPlan(plan: plan, results: results);
    final nextTask = _resolveTodayDisplayTask(
      activeTask: activeTask,
      results: results,
      todayJourneyTasks: todayJourneyTasks,
    );
    final todayReviewPageLabels = _todayReviewPageLabels(
      activeTask: activeTask,
      todayJourneyTasks: todayJourneyTasks,
    );

    return CurrentPlanHeroData.fromPlan(
      plan: plan,
      results: results,
      nextTask: nextTask,
      todayReviewPageLabels: todayReviewPageLabels,
      timelineSummary: timeline,
      certificate: certificate,
    );
  }

  factory CurrentPlanHeroData.fromPlan({
    required MemorizationActivePlanModel plan,
    required List<MemorizationSessionResultModel> results,
    MemorizationTodayTaskModel? nextTask,
    List<String> todayReviewPageLabels = const [],
    MemorizationPlanTimelineSummary? timelineSummary,
    MemorizationCourseCertificate? certificate,
    MemorizationPlanCompletionSnapshot? completionSnapshot,
  }) {
    final planResults = _resultsForPlan(plan, results);
    final completedNewAyahs = planResults
        .where((result) => result.taskType == 'dailyNew')
        .fold<int>(0, (sum, result) => sum + result.ayahsCount);

    final totalAyahs = math.max(1, plan.totalAyahs);
    final learnedPercent =
        (completionSnapshot?.completionPercent ??
                ((completedNewAyahs / totalAyahs) * 100).round())
            .round()
            .clamp(0, 100)
            .toInt();
    final bool isCompleted =
        plan.isCompleted || (completionSnapshot?.isCompleted ?? false);
    final int effectiveLearnedPercent = isCompleted ? 100 : learnedPercent;

    final timeline =
        timelineSummary ??
        const MemorizationPlanTimelineResolver().resolve(
          plan: plan,
          journeyTasks: const [],
          results: planResults,
        );
    final remainingPages = math.max(
      0,
      (plan.totalPages * (1 - effectiveLearnedPercent / 100)).ceil(),
    );

    return CurrentPlanHeroData(
      plan: plan,
      scopeTitle: _clean(plan.scopeTitle, fallback: plan.planName),
      rangeLabel: _rangeLabel(plan),
      pagesLabel: _pagesLabel(plan),
      durationLabel:
          timeline.effectiveCalendarDays > timeline.targetLearningDays
          ? '${plan.targetLearningDays} يوم حفظ • '
                '${timeline.effectiveCalendarDays} يوم للخطة الفعلية'
          : '${plan.targetLearningDays} يوم',
      dailyLoadLabel: _dailyLoadLabel(plan),
      remainingDaysLabel:
          'متبقي من الخطة: ${timeline.remainingCalendarDays} يوم',
      testsLabel: _testsLabel(plan),
      currentPlanDayLabel:
          'اليوم ${timeline.currentCalendarDay} من ${timeline.effectiveCalendarDays}',
      currentLessonLabel:
          'يوم الحفظ ${timeline.currentLearningDay} من ${timeline.targetLearningDays}',
      remainingPagesLabel: '$remainingPages صفحة',
      progressPercent: effectiveLearnedPercent,
      progressLabel: '$effectiveLearnedPercent%',
      isCompleted: isCompleted,
      nextTask: nextTask,
      todayReviewPageLabels: todayReviewPageLabels,
      stageItems: [
        const CurrentPlanStageItem(title: 'البداية', active: true),
        CurrentPlanStageItem(
          title: 'ربع الخطة',
          active: effectiveLearnedPercent >= 25,
        ),
        CurrentPlanStageItem(
          title: 'نصف الخطة',
          active: effectiveLearnedPercent >= 50,
        ),
        CurrentPlanStageItem(
          title: 'ثلاثة أرباع',
          active: effectiveLearnedPercent >= 75,
        ),
        CurrentPlanStageItem(
          title: 'نهاية الخطة',
          active: effectiveLearnedPercent >= 100,
        ),
      ],
      timelineSummary: timeline,
      certificate: certificate,
    );
  }

  static List<MemorizationSessionResultModel> _resultsForPlan(
    MemorizationActivePlanModel plan,
    List<MemorizationSessionResultModel> results,
  ) {
    return results.where((result) {
      if (result.completedAt.isBefore(plan.createdAt)) return false;

      final overlapsMainRange =
          result.endGlobalAyahIndex >= plan.scopeStartGlobalAyahIndex &&
          result.startGlobalAyahIndex <= plan.scopeEndGlobalAyahIndex;

      final overlapsReviewRange =
          plan.hasValidReviewRange &&
          result.endGlobalAyahIndex >= plan.reviewStartGlobalAyahIndex &&
          result.startGlobalAyahIndex <= plan.reviewEndGlobalAyahIndex;

      return overlapsMainRange || overlapsReviewRange;
    }).toList();
  }

  static Future<List<MemorizationJourneyTask>> _planJourneyTasks({
    required MemorizationActivePlanModel plan,
    required MemorizationTodayTaskModel? activeTask,
  }) async {
    return const MemorizationPlanJourneyEngine().buildJourneyTasks(
      plan: plan,
      activeTask: activeTask,
      daysAhead: (_totalPlanDays(plan) + 45).clamp(30, 2200).toInt(),
    );
  }

  static List<MemorizationJourneyTask> _todayJourneyTasks(
    List<MemorizationJourneyTask> journeyTasks,
  ) {
    final today = _dateOnly(DateTime.now());
    return journeyTasks.where((item) {
      if (!_sameDay(_dateOnly(item.date), today)) return false;
      if (!item.task.hasValidRange) return false;

      final taskDay = _dateOnly(item.task.effectiveScheduledDate);

      if (item.task.type == 'selfTest') {
        return _sameDay(taskDay, today) && !item.task.isFutureTask;
      }

      return !item.task.isFutureTask;
    }).toList()..sort((a, b) {
      final priority = a.priority.compareTo(b.priority);
      if (priority != 0) return priority;
      return a.date.compareTo(b.date);
    });
  }

  static MemorizationTodayTaskModel? _resolveTodayDisplayTask({
    required MemorizationTodayTaskModel? activeTask,
    required List<MemorizationSessionResultModel> results,
    required List<MemorizationJourneyTask> todayJourneyTasks,
  }) {
    final today = _dateOnly(DateTime.now());

    final candidates = _normalizeTodayTasks(
      todayJourneyTasks,
    ).map((item) => item.task).toList(growable: true);

    if (candidates.isEmpty &&
        activeTask != null &&
        activeTask.hasValidRange &&
        !activeTask.isFutureTask &&
        _sameDay(_dateOnly(activeTask.effectiveScheduledDate), today)) {
      candidates.add(activeTask);
    }

    if (candidates.isEmpty) return null;

    for (final task in candidates) {
      if (!_isCompleted(results, task)) return task;
    }

    return candidates.first;
  }

  static List<String> _todayReviewPageLabels({
    required MemorizationTodayTaskModel? activeTask,
    required List<MemorizationJourneyTask> todayJourneyTasks,
  }) {
    final today = _dateOnly(DateTime.now());
    final reviewTasks = todayJourneyTasks
        .map((item) => item.task)
        .where(_isReviewTask)
        .toList(growable: true);

    if (reviewTasks.isEmpty &&
        activeTask != null &&
        activeTask.hasValidRange &&
        _isReviewTask(activeTask) &&
        !activeTask.isFutureTask &&
        _sameDay(_dateOnly(activeTask.effectiveScheduledDate), today)) {
      reviewTasks.add(activeTask);
    }

    if (reviewTasks.isEmpty) return const [];

    final pages = <int>{};
    const resolver = QuranMemorizationRangeResolver();

    for (final task in reviewTasks) {
      final startPage = resolver.pageForGlobalAyah(task.startGlobalAyahIndex);
      final endPage = resolver.pageForGlobalAyah(task.endGlobalAyahIndex);

      for (int page = startPage; page <= endPage; page++) {
        pages.add(page);
      }
    }

    final sortedPages = pages.toList()..sort();
    return sortedPages.map((page) => 'صفحة $page').toList(growable: false);
  }

  static bool _isReviewTask(MemorizationTodayTaskModel task) {
    return task.type == 'dailyReview' || task.type == 'weakReview';
  }

  static List<MemorizationJourneyTask> _normalizeTodayTasks(
    List<MemorizationJourneyTask> tasks,
  ) {
    if (tasks.isEmpty) return const [];

    final normalTasks = tasks
        .where((item) => item.task.type != 'selfTest')
        .toList(growable: true);

    final testTasks =
        tasks
            .where((item) => item.task.type == 'selfTest')
            .toList(growable: true)
          ..sort((a, b) {
            final priorityCompare = a.priority.compareTo(b.priority);
            if (priorityCompare != 0) return priorityCompare;

            final mandatoryA = a.timeLabel.contains('إلزامي') ? 0 : 1;
            final mandatoryB = b.timeLabel.contains('إلزامي') ? 0 : 1;
            return mandatoryA.compareTo(mandatoryB);
          });

    if (testTasks.isNotEmpty) {
      normalTasks.add(testTasks.first);
    }

    normalTasks.sort((a, b) {
      final priorityCompare = a.priority.compareTo(b.priority);
      if (priorityCompare != 0) return priorityCompare;
      return a.date.compareTo(b.date);
    });

    return normalTasks;
  }

  static bool _isCompleted(
    List<MemorizationSessionResultModel> results,
    MemorizationTodayTaskModel task,
  ) {
    return results.any((result) {
      final exactTask = result.taskId == task.id;
      final sameRange =
          result.startGlobalAyahIndex == task.startGlobalAyahIndex &&
          result.endGlobalAyahIndex == task.endGlobalAyahIndex;
      final compatibleType =
          result.taskType == task.type ||
          (task.type == 'dailyNew' && result.taskType == 'dailyReview') ||
          (task.type == 'dailyReview' && result.taskType == 'dailyNew');

      return exactTask || (sameRange && compatibleType);
    });
  }

  static int _totalPlanDays(MemorizationActivePlanModel plan) {
    return math.max(1, plan.effectiveCalendarDays);
  }

  static String _rangeLabel(MemorizationActivePlanModel plan) {
    if (!plan.hasValidScopeRange) {
      return _clean(plan.scopeSizeText, fallback: 'نطاق الخطة');
    }

    return const QuranMemorizationRangeResolver().titleForRange(
      plan.scopeStartGlobalAyahIndex,
      plan.scopeEndGlobalAyahIndex,
    );
  }

  static String _pagesLabel(MemorizationActivePlanModel plan) {
    final pages = plan.totalPages <= 0 ? 1 : plan.totalPages;
    return '$pages صفحة';
  }

  static String _dailyLoadLabel(MemorizationActivePlanModel plan) {
    final dailyPages = plan.dailyNewPages;
    if (dailyPages <= 0) return 'مراجعة فقط';

    if (dailyPages == dailyPages.roundToDouble()) {
      return '${dailyPages.round()} صفحة';
    }

    return '${dailyPages.toStringAsFixed(1)} صفحة';
  }

  static String _testsLabel(MemorizationActivePlanModel plan) {
    return '${plan.testPreferences.style.title} • '
        '${plan.testPreferences.questionsPerTest} أسئلة';
  }

  static String _clean(String value, {required String fallback}) {
    final text = value.trim();
    return text.isEmpty ? fallback : text;
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class CurrentPlanStageItem {
  const CurrentPlanStageItem({required this.title, required this.active});

  final String title;
  final bool active;
}
