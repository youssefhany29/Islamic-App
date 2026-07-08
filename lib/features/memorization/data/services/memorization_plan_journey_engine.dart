import 'dart:math' as math;

import '../models/memorization_active_plan_model.dart';
import '../models/planning/memorization_plan_intensity.dart';
import '../models/memorization_session_result_model.dart';
import '../models/memorization_today_task_model.dart';
import '../services/memorization_session_result_storage.dart';
import 'memorization_balanced_range_splitter.dart';
import 'planning/memorization_actual_range_summary.dart';
import 'memorization_plan_progress_resolver.dart';
import 'memorization_smart_memorization_brain.dart';
import 'memorization_smart_test_planner.dart';
import 'quran_memorization_range_resolver.dart';
part 'planning/journey/memorization_plan_journey_models.dart';
part 'planning/journey/memorization_plan_journey_schedule.dart';
part 'planning/journey/memorization_plan_journey_tasks.dart';
part 'planning/journey/memorization_plan_journey_helpers.dart';
part 'planning/journey/memorization_test_day_allocator.dart';
part 'planning/journey/memorization_visible_task_merger.dart';

class MemorizationJourneyTask {
  final MemorizationTodayTaskModel task;
  final DateTime date;
  final String timeLabel;
  final int priority;
  final bool isProjected;

  const MemorizationJourneyTask({
    required this.task,
    required this.date,
    required this.timeLabel,
    required this.priority,
    required this.isProjected,
  });

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class MemorizationPlanJourneyEngine {
  const MemorizationPlanJourneyEngine({
    this.splitter = const MemorizationBalancedRangeSplitter(),
    this.rangeResolver = const QuranMemorizationRangeResolver(),
    this.progressResolver = const MemorizationPlanProgressResolver(),
    this.smartTestPlanner = const MemorizationSmartTestPlanner(),
    this.smartBrain = const MemorizationSmartMemorizationBrain(),
    this.visibleTaskMerger = const MemorizationVisibleTaskMerger(),
  });

  final MemorizationBalancedRangeSplitter splitter;
  final QuranMemorizationRangeResolver rangeResolver;
  final MemorizationPlanProgressResolver progressResolver;
  final MemorizationSmartTestPlanner smartTestPlanner;
  final MemorizationSmartMemorizationBrain smartBrain;
  final MemorizationVisibleTaskMerger visibleTaskMerger;

  Future<List<MemorizationJourneyTask>> buildJourneyTasks({
    required MemorizationActivePlanModel? plan,
    required MemorizationTodayTaskModel? activeTask,
    int daysAhead = 7,
  }) async {
    await rangeResolver.ensureReady();

    if (plan == null || !plan.hasValidScopeRange) return const [];

    final today = _dateOnly(DateTime.now());
    final results = await MemorizationSessionResultStorage.getResults();

    final progress = progressResolver.resolve(
      plan: plan,
      results: results,
      today: today,
    );

    final action = plan.actionTypeName;
    final primaryType = _primaryTypeForAction(
      action,
      activeTask?.type ?? 'dailyNew',
    );

    final primaryChunks = await _buildPrimaryChunks(
      plan: plan,
      primaryType: primaryType,
    );

    final completedPrimaryCount = primaryType == 'dailyNew'
        ? _completedChunksCount(
            chunks: primaryChunks,
            results: results,
            plan: plan,
            taskType: primaryType,
          )
        : progress.completedReviewCount;

    final safeDaysAhead = math.max(0, daysAhead);

    final tasks = action == 'newWithReview'
        ? await _buildOneLearningTaskPerDay(
            plan: plan,
            action: action,
            primaryType: primaryType,
            primaryChunks: primaryChunks,
            progress: progress,
            completedPrimaryCount: completedPrimaryCount,
            safeDaysAhead: safeDaysAhead,
          )
        : _buildCapacityAwarePrimaryTasks(
            plan: plan,
            primaryType: primaryType,
            primaryChunks: primaryChunks,
            completedPrimaryCount: completedPrimaryCount,
            safeDaysAhead: safeDaysAhead,
            startTomorrow: progress.completedNewToday,
          );

    final dueWeakSpots = smartBrain.dueReviews(
      plan: plan,
      results: results,
      onDate: today,
    );
    if (dueWeakSpots.isNotEmpty) {
      final weak = dueWeakSpots.first;
      final weakReviewDate = progress.completedNewToday
          ? today.add(const Duration(days: 1))
          : today;
      tasks.add(
        MemorizationJourneyTask(
          task: _taskFromRange(
            plan: plan,
            type: 'weakReview',
            title: 'مراجعة موضع ضعيف',
            subtitle: 'مراجعة متباعدة حسب آخر تقييم وأخطاء الموضع',
            startGlobalAyahIndex: weak.startGlobalAyahIndex,
            endGlobalAyahIndex: weak.endGlobalAyahIndex,
            scheduledDate: weakReviewDate,
            timeCode:
                'spacedWeak_${weak.startGlobalAyahIndex}_${plan.planVersion}',
            expectedMinutes: _estimateMinutes(
              ayahsCount:
                  weak.endGlobalAyahIndex - weak.startGlobalAyahIndex + 1,
              type: 'dailyReview',
            ),
          ),
          date: weakReviewDate,
          timeLabel: 'موضع ضعيف',
          priority: 0,
          isProjected: !_sameDay(weakReviewDate, today),
        ),
      );
    }

    final plannedSmartTests = smartTestPlanner.buildTests(
      plan: plan,
      sourceTasks: tasks
          .where(
            (item) =>
                item.task.type == 'dailyNew' || item.task.type == 'dailyReview',
          )
          .map(
            (item) => MemorizationTestSourceTask(
              task: item.task,
              date: item.date,
              priority: item.priority,
            ),
          )
          .toList(),
      results: results,
      daysAhead: safeDaysAhead,
    );

    // نسمح بهامش بعد مدة الحفظ/المراجعة لأن أيام الاختبار تفصل المهام
    // وقد تزق ختام الدورة بعد آخر مهمة فعلية.
    final int testDaysBuffer = math.max(14, (safeDaysAhead / 4).ceil());
    final lastAllowedDate = today.add(
      Duration(days: safeDaysAhead + testDaysBuffer),
    );

    for (final test in plannedSmartTests) {
      final testDate = _dateOnly(test.scheduledDate);

      if (testDate.isBefore(today) || testDate.isAfter(lastAllowedDate)) {
        continue;
      }

      tasks.add(
        MemorizationJourneyTask(
          task: test.toTodayTask(),
          date: testDate,
          timeLabel: test.isMandatory ? 'اختبار إلزامي' : 'اختبار',
          priority: test.isMandatory ? 3 : 4,
          isProjected: !_sameDay(testDate, today),
        ),
      );
    }

    final rescheduledTasks = const MemorizationTestDayAllocator().allocate(
      tasks: tasks,
      intensity: plan.intensity,
      weeklyRestDays: plan.weeklyRestDays,
    );

    rescheduledTasks.sort((a, b) {
      final dateCompare = a.date.compareTo(b.date);
      if (dateCompare != 0) return dateCompare;
      return a.priority.compareTo(b.priority);
    });

    return visibleTaskMerger.mergeDailyLearningTasks(rescheduledTasks);
  }

  int _completedChunksCount({
    required List<MemorizationScheduleChunk> chunks,
    required List<MemorizationSessionResultModel> results,
    required MemorizationActivePlanModel plan,
    required String taskType,
  }) {
    final completedRanges = results.where((result) {
      if (result.completedAt.isBefore(plan.createdAt)) return false;
      return result.taskType == taskType &&
          result.endGlobalAyahIndex >= plan.scopeStartGlobalAyahIndex &&
          result.startGlobalAyahIndex <= plan.scopeEndGlobalAyahIndex;
    }).toList();

    int completed = 0;
    for (final chunk in chunks) {
      final covered = completedRanges.any(
        (result) =>
            result.startGlobalAyahIndex <= chunk.startGlobalAyahIndex &&
            result.endGlobalAyahIndex >= chunk.endGlobalAyahIndex,
      );
      if (!covered) break;
      completed++;
    }
    return completed;
  }

  List<MemorizationJourneyTask> _buildCapacityAwarePrimaryTasks({
    required MemorizationActivePlanModel plan,
    required String primaryType,
    required List<MemorizationScheduleChunk> primaryChunks,
    required int completedPrimaryCount,
    required int safeDaysAhead,
    required bool startTomorrow,
  }) {
    final startIndex = completedPrimaryCount
        .clamp(0, primaryChunks.length)
        .toInt();
    final remainingChunks = primaryChunks.skip(startIndex).toList();
    if (remainingChunks.isEmpty) return const [];

    final today = _dateOnly(DateTime.now());
    final elapsedPlanDays =
        today.difference(_dateOnly(plan.createdAt)).inDays + 1;
    final requestedRemainingDays = math.max(
      1,
      plan.targetLearningDays - elapsedPlanDays + 1,
    );
    final capacityDays =
        (remainingChunks.length / plan.intensity.maxLearningSessionsPerDay)
            .ceil();
    final scheduleDays = math.max(requestedRemainingDays, capacityDays);

    final eligibleDates = <DateTime>[];
    int offset = startTomorrow ? 1 : 0;
    while (eligibleDates.length < scheduleDays) {
      final date = today.add(Duration(days: offset));
      if (!_isWeeklyRestDay(date, plan.weeklyRestDays)) {
        eligibleDates.add(date);
      }
      offset++;
    }

    final tasks = <MemorizationJourneyTask>[];
    for (
      int localIndex = 0;
      localIndex < remainingChunks.length;
      localIndex++
    ) {
      final dateIndex =
          (localIndex * eligibleDates.length / remainingChunks.length)
              .floor()
              .clamp(0, eligibleDates.length - 1)
              .toInt();
      final date = eligibleDates[dateIndex];
      if (date.difference(today).inDays > safeDaysAhead) continue;

      final chunk = remainingChunks[localIndex];
      tasks.add(
        _primaryJourneyTaskFromChunk(
          plan: plan,
          chunk: chunk,
          index: startIndex + localIndex,
          type: primaryType,
          date: date,
          isProjected: !_sameDay(date, today),
        ),
      );
    }

    return tasks;
  }

  Future<List<MemorizationJourneyTask>> _buildOneLearningTaskPerDay({
    required MemorizationActivePlanModel plan,
    required String action,
    required String primaryType,
    required List<MemorizationScheduleChunk> primaryChunks,
    required MemorizationPlanProgressSnapshot progress,
    required int completedPrimaryCount,
    required int safeDaysAhead,
  }) async {
    if (primaryChunks.isEmpty) return const [];

    final today = _dateOnly(DateTime.now());
    final tasks = <MemorizationJourneyTask>[];

    final reviewChunks = await _buildIndependentReviewChunks(plan);
    final effectiveReviewEvery = _effectiveReviewEveryForPlan(
      plan: plan,
      primarySessionsCount: primaryChunks.length,
    );

    int primaryIndex = completedPrimaryCount
        .clamp(0, primaryChunks.length)
        .toInt();

    int reviewIndex = progress.completedReviewCount.clamp(0, 999999).toInt();
    int learnedReviewIndex = progress.completedReviewCount
        .clamp(0, 999999)
        .toInt();

    int dayOffset = progress.completedNewToday ? 1 : 0;
    int learningDaysUsed = 0;

    int lastIndependentReviewPrimaryCount = -1;
    int lastIndependentReviewDayOffset = -999;
    bool externalComprehensiveReviewDone = false;

    while (dayOffset <= safeDaysAhead) {
      final date = today.add(Duration(days: dayOffset));

      if (_isWeeklyRestDay(date, plan.weeklyRestDays)) {
        dayOffset++;
        continue;
      }

      MemorizationJourneyTask? nextTask;

      if (action == 'newWithReview') {
        if (plan.reviewFromLearnedOnly) {
          final learnedCount = primaryIndex;

          final shouldReviewLearned = _shouldScheduleLearnedReviewDay(
            learningDaysUsed: learningDaysUsed,
            learnedCount: learnedCount,
            reviewIndex: learnedReviewIndex,
            hasMoreNew: primaryIndex < primaryChunks.length,
            every: effectiveReviewEvery,
          );

          if (shouldReviewLearned) {
            nextTask = _learnedReviewTaskForDay(
              plan: plan,
              primaryChunks: primaryChunks,
              learnedCount: learnedCount,
              reviewIndex: learnedReviewIndex,
              date: date,
              isProjected: dayOffset != 0,
            );

            learnedReviewIndex++;
            reviewIndex++;
            lastIndependentReviewPrimaryCount = primaryIndex;
            lastIndependentReviewDayOffset = dayOffset;
          } else if (primaryIndex < primaryChunks.length) {
            final chunk = primaryChunks[primaryIndex];

            nextTask = _primaryJourneyTaskFromChunk(
              plan: plan,
              chunk: chunk,
              index: primaryIndex,
              type: primaryType,
              date: date,
              isProjected: dayOffset != 0,
            );

            primaryIndex++;
          } else if (_shouldAddFinalLearnedReview(
            learnedCount: learnedCount,
            reviewIndex: learnedReviewIndex,
          )) {
            nextTask = _learnedReviewTaskForDay(
              plan: plan,
              primaryChunks: primaryChunks,
              learnedCount: learnedCount,
              reviewIndex: learnedReviewIndex,
              date: date,
              isProjected: dayOffset != 0,
              forceCumulative: true,
            );

            learnedReviewIndex++;
            reviewIndex++;
          }
        } else {
          final shouldReviewExternal = _shouldScheduleIndependentReviewDay(
            primaryDaysDone: primaryIndex,
            reviewIndex: reviewIndex,
            reviewChunksCount: reviewChunks.length,
            every: effectiveReviewEvery,
            hasMoreNew: primaryIndex < primaryChunks.length,
            currentDayOffset: dayOffset,
            lastReviewPrimaryCount: lastIndependentReviewPrimaryCount,
            lastReviewDayOffset: lastIndependentReviewDayOffset,
          );

          if (shouldReviewExternal) {
            final chunk = reviewChunks[reviewIndex];

            nextTask = _reviewJourneyTaskFromChunk(
              plan: plan,
              chunk: chunk,
              index: reviewIndex,
              date: date,
              isProjected: dayOffset != 0,
              title: 'مراجعة اليوم',
              subtitle:
                  'مراجعة ${chunk.ayahsCount} آية من ${plan.reviewScopeTitle}',
              timeCode: 'reviewSeparate',
              minGlobalAyahIndex: plan.reviewStartGlobalAyahIndex,
              maxGlobalAyahIndex: plan.reviewEndGlobalAyahIndex,
            );

            reviewIndex++;
            lastIndependentReviewPrimaryCount = primaryIndex;
            lastIndependentReviewDayOffset = dayOffset;
          } else if (primaryIndex < primaryChunks.length) {
            final chunk = primaryChunks[primaryIndex];

            nextTask = _primaryJourneyTaskFromChunk(
              plan: plan,
              chunk: chunk,
              index: primaryIndex,
              type: primaryType,
              date: date,
              isProjected: dayOffset != 0,
            );

            primaryIndex++;
          } else if (reviewIndex < reviewChunks.length) {
            final chunk = reviewChunks[reviewIndex];

            nextTask = _reviewJourneyTaskFromChunk(
              plan: plan,
              chunk: chunk,
              index: reviewIndex,
              date: date,
              isProjected: dayOffset != 0,
              title: 'مراجعة اليوم',
              subtitle:
                  'مراجعة ${chunk.ayahsCount} آية من ${plan.reviewScopeTitle}',
              timeCode: 'reviewSeparate',
              minGlobalAyahIndex: plan.reviewStartGlobalAyahIndex,
              maxGlobalAyahIndex: plan.reviewEndGlobalAyahIndex,
            );

            reviewIndex++;
            lastIndependentReviewPrimaryCount = primaryIndex;
            lastIndependentReviewDayOffset = dayOffset;
          } else if (!externalComprehensiveReviewDone &&
              reviewChunks.isNotEmpty) {
            nextTask = _externalComprehensiveReviewTask(
              plan: plan,
              date: date,
              isProjected: dayOffset != 0,
            );

            externalComprehensiveReviewDone = true;
            lastIndependentReviewPrimaryCount = primaryIndex;
            lastIndependentReviewDayOffset = dayOffset;
          }
        }
      } else if (primaryIndex < primaryChunks.length) {
        final chunk = primaryChunks[primaryIndex];

        nextTask = _primaryJourneyTaskFromChunk(
          plan: plan,
          chunk: chunk,
          index: primaryIndex,
          type: primaryType,
          date: date,
          isProjected: dayOffset != 0,
        );

        primaryIndex++;
      }

      if (nextTask != null) {
        tasks.add(nextTask);
        learningDaysUsed++;
      }

      final primaryDone = primaryIndex >= primaryChunks.length;

      final reviewDone =
          action != 'newWithReview' ||
          (plan.reviewFromLearnedOnly
              ? primaryDone &&
                    !_shouldAddFinalLearnedReview(
                      learnedCount: primaryIndex,
                      reviewIndex: learnedReviewIndex,
                    )
              : reviewIndex >= reviewChunks.length &&
                    (reviewChunks.isEmpty || externalComprehensiveReviewDone));

      if (primaryDone && reviewDone) break;

      dayOffset++;
    }

    return tasks;
  }

  /// يوم الاختبار = اختبار فقط.
  /// الحفظ/المراجعة لا يختفوا من الخطة، بل ينتقلوا لأول يوم مناسب بعد الاختبار.
  /// اختبار ختام الدورة يُنقل تلقائيًا بعد آخر مهمة حفظ/مراجعة فعلية بعد إعادة الجدولة.

  DateTime _dateAfterLastLearningTask(
    List<MemorizationJourneyTask> learningTasks, {
    required DateTime fallback,
  }) {
    if (learningTasks.isEmpty) {
      return _journeyDateOnly(fallback);
    }

    var last = _journeyDateOnly(learningTasks.first.date);

    for (final item in learningTasks) {
      final day = _journeyDateOnly(item.date);
      if (day.isAfter(last)) last = day;
    }

    return last.add(const Duration(days: 1));
  }

  _Range _testRangeFromChunk({
    required MemorizationScheduleChunk chunk,
    required int testIndex,
  }) {
    final total = chunk.ayahsCount;

    if (total <= 12) {
      return _Range(
        start: chunk.startGlobalAyahIndex,
        end: chunk.endGlobalAyahIndex,
      );
    }

    final wanted = total <= 40 ? math.min(total, 18) : math.min(total, 35);

    if (testIndex % 3 == 0) {
      return _Range(
        start: chunk.startGlobalAyahIndex,
        end: (chunk.startGlobalAyahIndex + wanted - 1)
            .clamp(chunk.startGlobalAyahIndex, chunk.endGlobalAyahIndex)
            .toInt(),
      );
    }

    return _Range(
      start: math.max(
        chunk.startGlobalAyahIndex,
        chunk.endGlobalAyahIndex - wanted + 1,
      ),
      end: chunk.endGlobalAyahIndex,
    );
  }
}
