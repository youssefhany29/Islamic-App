part of '../../memorization_plan_journey_engine.dart';

extension _MemorizationPlanJourneySchedule on MemorizationPlanJourneyEngine {
  Future<List<MemorizationScheduleChunk>> _buildIndependentReviewChunks(
    MemorizationActivePlanModel plan,
  ) async {
    if (!plan.hasValidReviewRange || plan.reviewFromLearnedOnly) {
      return const [];
    }

    return splitter.split(
      startGlobalAyahIndex: plan.reviewStartGlobalAyahIndex,
      endGlobalAyahIndex: plan.reviewEndGlobalAyahIndex,
      targetSessions: _reviewSessionsCountForPlan(plan),
      pagesPerSession: plan.dailyReviewPages > 0 ? plan.dailyReviewPages : null,
    );
  }

  bool _shouldScheduleLearnedReviewDay({
    required int learningDaysUsed,
    required int learnedCount,
    required int reviewIndex,
    required bool hasMoreNew,
    required int every,
  }) {
    if (learnedCount <= 0) return false;
    if (learningDaysUsed <= 0) return false;

    final safeEvery = every.clamp(1, 7).toInt();

    // مراجعة قريبة بعد عدد من جلسات الحفظ، وليس بعد عدد أيام خام.
    final bool closeReview =
        learnedCount >= safeEvery &&
        learningDaysUsed % (safeEvery + 1) == safeEvery;

    // مراجعة شاملة كل فترة على كل ما سبق.
    final int widerEvery = math.max(7, safeEvery * 4);
    final bool widerReview =
        learnedCount >= 7 && learningDaysUsed % (widerEvery + 1) == widerEvery;

    if (widerReview) return true;
    if (closeReview) return true;

    return false;
  }

  bool _shouldAddFinalLearnedReview({
    required int learnedCount,
    required int reviewIndex,
  }) {
    if (learnedCount <= 0) return false;

    // لو الحفظ قليل، نضيف مراجعة نهائية واحدة.
    if (learnedCount < 4) return reviewIndex == 0;

    // نضمن وجود مراجعة ختامية لو آخر مراجعة لم تكن شاملة.
    return reviewIndex == 0 || reviewIndex % 4 != 0;
  }

  bool _shouldScheduleIndependentReviewDay({
    required int primaryDaysDone,
    required int reviewIndex,
    required int reviewChunksCount,
    required int every,
    required bool hasMoreNew,
    required int currentDayOffset,
    required int lastReviewPrimaryCount,
    required int lastReviewDayOffset,
  }) {
    if (reviewIndex >= reviewChunksCount) return false;

    final safeEvery = every.clamp(1, 7).toInt();

    if (hasMoreNew) {
      if (primaryDaysDone <= 0) return false;
      if (primaryDaysDone == lastReviewPrimaryCount) return false;
      return primaryDaysDone % safeEvery == 0;
    }

    // بعد انتهاء الحفظ لا نرمي كل المراجعات وراء بعض.
    // نكملها بنفس الإيقاع الذي اختاره المستخدم: كل يوم / كل 3 أيام / ...
    if (lastReviewDayOffset < 0) return true;
    return currentDayOffset - lastReviewDayOffset >= safeEvery;
  }

  List<MemorizationJourneyTask> _moveLearningTasksAwayFromTestDays(
    List<MemorizationJourneyTask> tasks, {
    required int weeklyRestDays,
  }) {
    if (tasks.isEmpty) return const [];

    final sorted = List<MemorizationJourneyTask>.from(tasks)
      ..sort((a, b) {
        final dateCompare = a.date.compareTo(b.date);
        if (dateCompare != 0) return dateCompare;
        return a.priority.compareTo(b.priority);
      });

    final chosenTestByDate = <String, MemorizationJourneyTask>{};
    final learningTasks = <MemorizationJourneyTask>[];
    final otherTasks = <MemorizationJourneyTask>[];

    for (final item in sorted) {
      if (item.task.type == 'selfTest') {
        final key = _journeyDateKey(item.date);
        final existing = chosenTestByDate[key];

        if (existing == null || _shouldReplaceSameDayTest(existing, item)) {
          chosenTestByDate[key] = item;
        }

        continue;
      }

      if (_isLearningTask(item)) {
        learningTasks.add(item);
      } else {
        otherTasks.add(item);
      }
    }

    final reservedDates = <String>{
      ...chosenTestByDate.keys,
      ...otherTasks.map((item) => _journeyDateKey(item.date)),
    };

    final movedLearningTasks = <MemorizationJourneyTask>[];

    for (final item in learningTasks) {
      var newDate = _journeyDateOnly(item.date);

      while (reservedDates.contains(_journeyDateKey(newDate)) ||
          _isWeeklyRestDay(newDate, weeklyRestDays)) {
        newDate = newDate.add(const Duration(days: 1));
      }

      reservedDates.add(_journeyDateKey(newDate));

      movedLearningTasks.add(
        _copyJourneyTaskWithDate(item: item, date: newDate),
      );
    }

    final adjustedTests = <MemorizationJourneyTask>[];

    for (final test in chosenTestByDate.values) {
      if (!_isFinalTest(test)) {
        adjustedTests.add(test);
        continue;
      }

      var finalDate = _dateAfterLastLearningTask(
        movedLearningTasks,
        fallback: test.date,
      );

      while (reservedDates.contains(_journeyDateKey(finalDate)) ||
          _isWeeklyRestDay(finalDate, weeklyRestDays)) {
        finalDate = finalDate.add(const Duration(days: 1));
      }

      reservedDates.add(_journeyDateKey(finalDate));

      adjustedTests.add(_copyJourneyTaskWithDate(item: test, date: finalDate));
    }

    return <MemorizationJourneyTask>[
      ...otherTasks,
      ...movedLearningTasks,
      ...adjustedTests,
    ];
  }

  Future<List<MemorizationScheduleChunk>> _buildPrimaryChunks({
    required MemorizationActivePlanModel plan,
    required String primaryType,
  }) {
    final isNew = primaryType == 'dailyNew';

    final desiredSessionPages = isNew
        ? math.min(
            plan.dailyNewPages <= 0 ? 0.5 : plan.dailyNewPages,
            plan.intensity.maxPagesPerLearningSession,
          )
        : plan.dailyReviewPages;

    return splitter.split(
      startGlobalAyahIndex: plan.scopeStartGlobalAyahIndex,
      endGlobalAyahIndex: plan.scopeEndGlobalAyahIndex,
      targetSessions: _targetSessionsForPrimary(plan: plan, isNew: isNew),
      pagesPerSession: desiredSessionPages > 0 ? desiredSessionPages : null,
    );
  }

  int _targetSessionsForPrimary({
    required MemorizationActivePlanModel plan,
    required bool isNew,
  }) {
    if (isNew) {
      if (plan.learningSessionsCount > 0) {
        return plan.learningSessionsCount;
      }

      if (plan.totalPages > 0 && plan.dailyNewPages > 0) {
        return (plan.totalPages / plan.dailyNewPages).ceil();
      }

      return 1;
    }

    final reviewSessions = _reviewSessionsCountForPlan(plan);
    if (reviewSessions > 0) return reviewSessions;

    if (plan.totalDays > 0) return plan.totalDays;

    if (plan.totalPages > 0 && plan.dailyReviewPages > 0) {
      return (plan.totalPages / plan.dailyReviewPages).ceil();
    }

    return 1;
  }

  int _plannedTestsForPlan({required MemorizationActivePlanModel plan}) {
    if (plan.plannedTestsCount > 0) return plan.plannedTestsCount;

    final totalAyahs =
        plan.scopeEndGlobalAyahIndex - plan.scopeStartGlobalAyahIndex + 1;
    final totalPages = plan.totalPages;

    if (totalAyahs <= 10 || totalPages <= 3) return 1;
    if (totalPages <= 10) return 2;
    if (totalPages <= 30) return 3;
    if (totalPages <= 100) return 5;

    return 8;
  }

  int _reviewSessionsCountForPlan(MemorizationActivePlanModel plan) {
    if (plan.reviewSessionsCount > 0) return plan.reviewSessionsCount;

    if (plan.dailyReviewPages > 0) {
      final reviewStartPage = rangeResolver.pageForGlobalAyah(
        plan.reviewStartGlobalAyahIndex,
      );
      final reviewEndPage = rangeResolver.pageForGlobalAyah(
        plan.reviewEndGlobalAyahIndex,
      );
      final pages = math.max(1, reviewEndPage - reviewStartPage + 1);

      return (pages / plan.dailyReviewPages).ceil().clamp(1, 999).toInt();
    }

    if (plan.totalDays > 0) return plan.totalDays;

    return 1;
  }
}
