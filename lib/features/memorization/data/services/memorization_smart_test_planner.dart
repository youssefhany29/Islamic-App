import 'dart:math' as math;

import '../models/memorization_active_plan_model.dart';
import '../models/memorization_scheduled_test_model.dart';
import '../models/memorization_session_result_model.dart';
import '../models/memorization_test_kind.dart';
import '../models/memorization_test_preferences.dart';
import '../models/memorization_today_task_model.dart';

class MemorizationTestSourceTask {
  final MemorizationTodayTaskModel task;
  final DateTime date;
  final int priority;

  const MemorizationTestSourceTask({
    required this.task,
    required this.date,
    required this.priority,
  });

  bool get isLearningTask {
    return task.type == 'dailyNew' || task.type == 'dailyReview';
  }
}

class MemorizationSmartTestPlanner {
  const MemorizationSmartTestPlanner();

  List<MemorizationScheduledTestModel> buildTests({
    required MemorizationActivePlanModel? plan,
    required List<MemorizationTestSourceTask> sourceTasks,
    required List<MemorizationSessionResultModel> results,
    int daysAhead = 180,
  }) {
    if (plan == null ||
        !plan.hasValidScopeRange ||
        plan.plannedTestsCount <= 0) {
      return const [];
    }

    final rawLearningTasks =
        sourceTasks
            .where((item) => item.isLearningTask && item.task.hasValidRange)
            .toList()
          ..sort((a, b) {
            final dateCompare = a.date.compareTo(b.date);
            if (dateCompare != 0) return dateCompare;
            return a.priority.compareTo(b.priority);
          });

    if (rawLearningTasks.isEmpty) return const [];
    final learningTasks = _mergeSourcesByLearningDay(rawLearningTasks);

    final planned = <MemorizationScheduledTestModel>[];

    if (_isStrongHafizPlan(plan)) {
      planned.addAll(
        _buildStrongHafizCadenceTests(
          plan: plan,
          learningTasks: learningTasks,
          results: results,
          daysAhead: daysAhead,
        ),
      );

      planned.add(
        _buildFinalCycleTest(
          plan: plan,
          learningTasks: learningTasks,
          results: results,
          orderIndex: 9999,
        ),
      );
    } else {
      planned.addAll(
        _buildMeaningfulCycleTests(
          plan: plan,
          learningTasks: learningTasks,
          results: results,
        ),
      );
    }
    final weakSpotTest = _buildWeakSpotRecoveryTest(
      plan: plan,
      learningTasks: learningTasks,
      results: results,
    );
    if (weakSpotTest != null) planned.add(weakSpotTest);

    final unique = _deduplicate(planned, results)
      ..sort((a, b) {
        final dateCompare = a.scheduledDate.compareTo(b.scheduledDate);
        if (dateCompare != 0) return dateCompare;
        if (a.isMandatory != b.isMandatory) return a.isMandatory ? -1 : 1;
        return a.orderIndex.compareTo(b.orderIndex);
      });

    return unique;
  }

  List<MemorizationScheduledTestModel> _buildMeaningfulCycleTests({
    required MemorizationActivePlanModel plan,
    required List<MemorizationTestSourceTask> learningTasks,
    required List<MemorizationSessionResultModel> results,
  }) {
    final totalLearningDays = learningTasks.length;
    final tests = <MemorizationScheduledTestModel>[];
    int order = 0;

    if (_isWholeQuranPlan(plan) && totalLearningDays <= 30) {
      return _buildWholeQuranTests(
        plan: plan,
        learningTasks: learningTasks,
        results: results,
      );
    }

    // الخطط من 20 يوم فأكثر:
    // اختبار أسبوعي على آخر أسبوع، واختبار شهري تراكمي عند نهاية كل شهر بعيد عن نهاية الدورة،
    // ثم اختبار ختام الدورة بعد آخر مهمة حفظ/مراجعة.
    if (totalLearningDays >= 20) {
      final lastSafeCheckpointDay = math.max(1, totalLearningDays - 4);

      for (int day = 7; day <= lastSafeCheckpointDay; day += 7) {
        // لو اليوم قريب جدًا من اختبار شهري، نترك الشهري لأنه أوسع معنى.
        final nearMonthly = day % 30 >= 27 || day % 30 <= 2 && day > 7;
        if (nearMonthly && day >= 28) continue;

        final range = _rangeForLastDays(
          learningTasks: learningTasks,
          endDayNumber: day,
          daysCount: 7,
        );

        tests.add(
          _buildTest(
            plan: plan,
            source: _sourceAtDayNumber(learningTasks, day),
            results: results,
            trigger: MemorizationTestTrigger.weeklyCheckpoint,
            orderIndex: order++,
            cycleProgress: (day / totalLearningDays).clamp(0.0, 1.0),
            isMandatory: false,
            startOverride: range.start,
            endOverride: range.end,
          ),
        );
      }

      for (int day = 30; day <= lastSafeCheckpointDay; day += 30) {
        final range = _rangeFromStartToDay(
          learningTasks: learningTasks,
          dayNumber: day,
        );

        tests.add(
          _buildTest(
            plan: plan,
            source: _sourceAtDayNumber(learningTasks, day),
            results: results,
            trigger: MemorizationTestTrigger.monthlyCheckpoint,
            orderIndex: order++,
            cycleProgress: (day / totalLearningDays).clamp(0.0, 1.0),
            isMandatory: true,
            startOverride: range.start,
            endOverride: range.end,
          ),
        );
      }

      tests.add(
        _buildFinalCycleTest(
          plan: plan,
          learningTasks: learningTasks,
          results: results,
          orderIndex: 9999,
        ),
      );

      return tests;
    }

    // الخطط القصيرة: مراجعة منتصف الخطة ثم الختام، بلا monthly حرفي.
    if (totalLearningDays >= 5) {
      final middleDay = (totalLearningDays / 2).floor().clamp(
        3,
        totalLearningDays - 2,
      );
      final range = _rangeFromStartToDay(
        learningTasks: learningTasks,
        dayNumber: middleDay,
      );

      tests.add(
        _buildTest(
          plan: plan,
          source: _sourceAtDayNumber(learningTasks, middleDay),
          results: results,
          trigger: MemorizationTestTrigger.halfCycle,
          orderIndex: order++,
          cycleProgress: 0.5,
          isMandatory: false,
          startOverride: range.start,
          endOverride: range.end,
        ),
      );
    }

    tests.add(
      _buildFinalCycleTest(
        plan: plan,
        learningTasks: learningTasks,
        results: results,
        orderIndex: 9999,
      ),
    );

    return tests;
  }

  MemorizationScheduledTestModel _buildFinalCycleTest({
    required MemorizationActivePlanModel plan,
    required List<MemorizationTestSourceTask> learningTasks,
    required List<MemorizationSessionResultModel> results,
    required int orderIndex,
  }) {
    final source = learningTasks.last;
    final fullRange = _rangeFromStartToDay(
      learningTasks: learningTasks,
      dayNumber: learningTasks.length,
    );

    return _buildTest(
      plan: plan,
      source: source,
      results: results,
      trigger: MemorizationTestTrigger.endOfCycle,
      orderIndex: orderIndex,
      cycleProgress: 1.0,
      isMandatory: true,
      dateOverride: _dateOnly(source.date).add(const Duration(days: 1)),
      startOverride: fullRange.start,
      endOverride: fullRange.end,
    );
  }

  List<MemorizationScheduledTestModel> _buildWholeQuranTests({
    required MemorizationActivePlanModel plan,
    required List<MemorizationTestSourceTask> learningTasks,
    required List<MemorizationSessionResultModel> results,
  }) {
    final tests = <MemorizationScheduledTestModel>[];
    int order = 0;

    final learningDays = learningTasks
        .map((item) => _dateKey(item.date))
        .toSet()
        .length;

    if (learningDays <= 30) {
      final checkpoints = learningDays <= 10
          ? const <double>[0.50]
          : learningDays <= 20
          ? const <double>[0.35, 0.50]
          : const <double>[0.25, 0.50, 0.75];

      for (final progress in checkpoints) {
        final source = _sourceAtProgress(learningTasks, progress);
        final trigger = progress < 0.4
            ? MemorizationTestTrigger.quarterCycle
            : progress < 0.7
            ? MemorizationTestTrigger.halfCycle
            : MemorizationTestTrigger.threeQuarterCycle;
        final range = _rangeFromStartToSource(
          learningTasks: learningTasks,
          source: source,
        );

        tests.add(
          _buildTest(
            plan: plan,
            source: source,
            results: results,
            trigger: trigger,
            orderIndex: order++,
            cycleProgress: progress,
            isMandatory: false,
            startOverride: range.start,
            endOverride: range.end,
          ),
        );
      }

      tests.add(
        _buildFinalCycleTest(
          plan: plan,
          learningTasks: learningTasks,
          results: results,
          orderIndex: 9999,
        ),
      );
      return tests;
    }

    const milestones = <int>[5, 10, 15, 20, 25];
    for (final juz in milestones) {
      final progress = juz / 30.0;
      final source = _sourceAtProgress(learningTasks, progress);

      final trigger = juz % 10 == 0
          ? MemorizationTestTrigger.tenJuzCheckpoint
          : MemorizationTestTrigger.fiveJuzCheckpoint;

      final range = _rangeFromStartToSource(
        learningTasks: learningTasks,
        source: source,
      );

      tests.add(
        _buildTest(
          plan: plan,
          source: source,
          results: results,
          trigger: trigger,
          orderIndex: order++,
          cycleProgress: progress,
          isMandatory: true,
          startOverride: range.start,
          endOverride: range.end,
        ),
      );
    }

    tests.add(
      _buildFinalCycleTest(
        plan: plan,
        learningTasks: learningTasks,
        results: results,
        orderIndex: 9999,
      ),
    );

    return tests;
  }

  List<MemorizationScheduledTestModel> _buildStrongHafizCadenceTests({
    required MemorizationActivePlanModel plan,
    required List<MemorizationTestSourceTask> learningTasks,
    required List<MemorizationSessionResultModel> results,
    required int daysAhead,
  }) {
    final firstDate = _dateOnly(learningTasks.first.date);
    final lastLearningDate = _dateOnly(learningTasks.last.date);
    final requestedEndDate = firstDate.add(
      Duration(days: math.max(14, daysAhead)),
    );
    final endDate = requestedEndDate.isBefore(lastLearningDate)
        ? requestedEndDate
        : lastLearningDate;

    final tests = <MemorizationScheduledTestModel>[];

    int order = 0;
    int dayOffset = 2;
    int previousCheckpointDay = 0;
    bool addThreeDays = true;

    while (true) {
      final date = firstDate.add(Duration(days: dayOffset));

      if (date.isAfter(endDate)) break;
      if (_sameDay(date, lastLearningDate)) break;

      final currentDayNumber = dayOffset + 1;
      final source = _nearestSourceForDate(learningTasks, date);

      if (source != null) {
        final range = _rangeBetweenDays(
          learningTasks: learningTasks,
          startDayNumber: previousCheckpointDay + 1,
          endDayNumber: currentDayNumber,
        );

        tests.add(
          _buildTest(
            plan: plan,
            source: source,
            results: results,
            trigger: MemorizationTestTrigger.strongHafizCadence,
            orderIndex: 1000 + order,
            cycleProgress: _progressForSource(learningTasks, source),
            isMandatory: false,
            startOverride: range.start,
            endOverride: range.end,
          ),
        );

        previousCheckpointDay = currentDayNumber;
      }

      order++;
      dayOffset += addThreeDays ? 3 : 2;
      addThreeDays = !addThreeDays;
    }

    return tests;
  }

  MemorizationTestSourceTask _sourceAtDayNumber(
    List<MemorizationTestSourceTask> tasks,
    int dayNumber,
  ) {
    final index = (dayNumber - 1).clamp(0, tasks.length - 1).toInt();
    return tasks[index];
  }

  MemorizationTestSourceTask _sourceAtProgress(
    List<MemorizationTestSourceTask> tasks,
    double progress,
  ) {
    final safeProgress = progress.clamp(0.01, 1.0).toDouble();
    final index = ((tasks.length * safeProgress).ceil() - 1)
        .clamp(0, tasks.length - 1)
        .toInt();

    return tasks[index];
  }

  MemorizationTestSourceTask? _nearestSourceForDate(
    List<MemorizationTestSourceTask> tasks,
    DateTime date,
  ) {
    MemorizationTestSourceTask? previousOrSame;

    for (final task in tasks) {
      final taskDate = _dateOnly(task.date);

      if (taskDate.isAfter(date)) break;
      previousOrSame = task;
    }

    return previousOrSame ?? (tasks.isNotEmpty ? tasks.first : null);
  }

  _TestRange _rangeForLastDays({
    required List<MemorizationTestSourceTask> learningTasks,
    required int endDayNumber,
    required int daysCount,
  }) {
    final startDay = math.max(1, endDayNumber - daysCount + 1);
    return _rangeBetweenDays(
      learningTasks: learningTasks,
      startDayNumber: startDay,
      endDayNumber: endDayNumber,
    );
  }

  _TestRange _rangeFromStartToDay({
    required List<MemorizationTestSourceTask> learningTasks,
    required int dayNumber,
  }) {
    return _rangeBetweenDays(
      learningTasks: learningTasks,
      startDayNumber: 1,
      endDayNumber: dayNumber,
    );
  }

  _TestRange _rangeFromStartToSource({
    required List<MemorizationTestSourceTask> learningTasks,
    required MemorizationTestSourceTask source,
  }) {
    final index = learningTasks.indexOf(source);
    return _rangeFromStartToDay(
      learningTasks: learningTasks,
      dayNumber: index < 0 ? 1 : index + 1,
    );
  }

  _TestRange _rangeBetweenDays({
    required List<MemorizationTestSourceTask> learningTasks,
    required int startDayNumber,
    required int endDayNumber,
  }) {
    final startIndex = (startDayNumber - 1)
        .clamp(0, learningTasks.length - 1)
        .toInt();
    final endIndex = (endDayNumber - 1)
        .clamp(startIndex, learningTasks.length - 1)
        .toInt();

    int start = learningTasks[startIndex].task.startGlobalAyahIndex;
    int end = learningTasks[startIndex].task.endGlobalAyahIndex;

    for (int i = startIndex; i <= endIndex; i++) {
      start = math.min(start, learningTasks[i].task.startGlobalAyahIndex);
      end = math.max(end, learningTasks[i].task.endGlobalAyahIndex);
    }

    return _TestRange(start: start, end: end);
  }

  double _progressForSource(
    List<MemorizationTestSourceTask> tasks,
    MemorizationTestSourceTask source,
  ) {
    final index = tasks.indexOf(source);
    if (index < 0 || tasks.isEmpty) return 0;

    return ((index + 1) / tasks.length).clamp(0.0, 1.0).toDouble();
  }

  MemorizationScheduledTestModel _buildTest({
    required MemorizationActivePlanModel plan,
    required MemorizationTestSourceTask source,
    required List<MemorizationSessionResultModel> results,
    required MemorizationTestTrigger trigger,
    required int orderIndex,
    required double cycleProgress,
    required bool isMandatory,
    DateTime? dateOverride,
    int? startOverride,
    int? endOverride,
  }) {
    final difficulty = _difficultyForNextTest(
      plan: plan,
      results: results,
      orderIndex: orderIndex,
      trigger: trigger,
    );

    final kind = _kindForNextTest(
      orderIndex: orderIndex,
      difficulty: difficulty,
      trigger: trigger,
      plan: plan,
    );

    final cleanDate = _dateOnly(
      dateOverride ?? source.date.add(const Duration(days: 1)),
    );

    final range = startOverride != null && endOverride != null
        ? _TestRange(start: startOverride, end: endOverride)
        : _safeTestRange(source: source, difficulty: difficulty);

    return MemorizationScheduledTestModel(
      id:
          'smart_test_${plan.id}_v${plan.planVersion}_'
          '${trigger.code}_${orderIndex}_${cleanDate.millisecondsSinceEpoch}',
      planId: plan.id,
      kind: kind,
      difficulty: difficulty,
      trigger: trigger,
      startGlobalAyahIndex: range.start,
      endGlobalAyahIndex: range.end,
      scheduledDate: cleanDate,
      orderIndex: orderIndex,
      cycleProgress: cycleProgress,
      isMandatory: isMandatory,
      planVersion: plan.planVersion,
      preferences: plan.testPreferences,
    );
  }

  _TestRange _safeTestRange({
    required MemorizationTestSourceTask source,
    required MemorizationTestDifficulty difficulty,
  }) {
    final start = source.task.startGlobalAyahIndex;
    final end = source.task.endGlobalAyahIndex;
    final total = end - start + 1;

    if (total <= 0) return _TestRange(start: start, end: start);

    if (difficulty == MemorizationTestDifficulty.easy || total <= 12) {
      return _TestRange(start: start, end: end);
    }

    final wanted = difficulty == MemorizationTestDifficulty.medium
        ? math.min(total, 24)
        : math.min(total, 40);

    return _TestRange(start: math.max(start, end - wanted + 1), end: end);
  }

  MemorizationTestDifficulty _difficultyForNextTest({
    required MemorizationActivePlanModel plan,
    required List<MemorizationSessionResultModel> results,
    required int orderIndex,
    required MemorizationTestTrigger trigger,
  }) {
    switch (plan.testPreferences.difficulty) {
      case MemorizationTestDifficultyPreference.easy:
        return MemorizationTestDifficulty.easy;
      case MemorizationTestDifficultyPreference.medium:
        return MemorizationTestDifficulty.medium;
      case MemorizationTestDifficultyPreference.hard:
        return MemorizationTestDifficulty.hard;
      case MemorizationTestDifficultyPreference.smart:
        break;
    }

    if (trigger == MemorizationTestTrigger.endOfCycle ||
        trigger == MemorizationTestTrigger.monthlyCheckpoint ||
        trigger == MemorizationTestTrigger.tenJuzCheckpoint) {
      return MemorizationTestDifficulty.hard;
    }

    if (trigger == MemorizationTestTrigger.strongHafizCadence) {
      return orderIndex.isEven
          ? MemorizationTestDifficulty.medium
          : MemorizationTestDifficulty.hard;
    }

    if (trigger == MemorizationTestTrigger.weeklyCheckpoint) {
      if (plan.actionTypeName == 'reviewOnly') {
        return MemorizationTestDifficulty.hard;
      }
      return MemorizationTestDifficulty.medium;
    }

    final recentTests = results
        .where((item) => item.taskType == 'selfTest')
        .take(6)
        .toList();

    final easyOrGoodCount = recentTests
        .where((item) => item.rating == 'easy' || item.rating == 'good')
        .length;

    final hardOrForgotCount = recentTests
        .where((item) => item.rating == 'hard' || item.rating == 'forgot')
        .length;

    if (hardOrForgotCount >= 2) return MemorizationTestDifficulty.easy;
    if (easyOrGoodCount >= 3) return MemorizationTestDifficulty.hard;

    return orderIndex <= 1
        ? MemorizationTestDifficulty.easy
        : MemorizationTestDifficulty.medium;
  }

  MemorizationTestKind _kindForNextTest({
    required int orderIndex,
    required MemorizationTestDifficulty difficulty,
    required MemorizationTestTrigger trigger,
    required MemorizationActivePlanModel plan,
  }) {
    switch (plan.testPreferences.style) {
      case MemorizationTestStyle.hiddenMushaf:
        return MemorizationTestKind.hiddenMushafRecitation;
      case MemorizationTestStyle.ordering:
        return MemorizationTestKind.orderAyahs;
      case MemorizationTestStyle.completionAndRecitation:
        return orderIndex.isEven
            ? MemorizationTestKind.completeAyah
            : MemorizationTestKind.noTextRecitation;
      case MemorizationTestStyle.multipleChoice:
        return MemorizationTestKind.completeAyah;
      case MemorizationTestStyle.system:
      case MemorizationTestStyle.smartMixed:
      case MemorizationTestStyle.custom:
        break;
    }

    if (trigger == MemorizationTestTrigger.endOfCycle) {
      return MemorizationTestKind.noTextRecitation;
    }

    if (trigger == MemorizationTestTrigger.monthlyCheckpoint) {
      return MemorizationTestKind.randomPassage;
    }

    if (trigger == MemorizationTestTrigger.weeklyCheckpoint) {
      final weeklyKinds = const [
        MemorizationTestKind.completeAyah,
        MemorizationTestKind.orderAyahs,
        MemorizationTestKind.hiddenAyahs,
      ];

      final seed = plan.id.hashCode.abs() + orderIndex + trigger.code.length;
      return weeklyKinds[seed % weeklyKinds.length];
    }

    if (trigger == MemorizationTestTrigger.strongHafizCadence) {
      final strongKinds = difficulty == MemorizationTestDifficulty.hard
          ? const [
              MemorizationTestKind.noTextRecitation,
              MemorizationTestKind.orderAyahs,
              MemorizationTestKind.randomPassage,
              MemorizationTestKind.fullPage,
            ]
          : const [
              MemorizationTestKind.completeAyah,
              MemorizationTestKind.orderAyahs,
              MemorizationTestKind.hiddenAyahs,
              MemorizationTestKind.randomPassage,
            ];

      final seed = plan.id.hashCode.abs() + orderIndex + trigger.code.length;
      return strongKinds[seed % strongKinds.length];
    }

    final easyKinds = const [
      MemorizationTestKind.ayahStarts,
      MemorizationTestKind.completeAyah,
      MemorizationTestKind.hiddenAyahs,
    ];

    final mediumKinds = const [
      MemorizationTestKind.completeAyah,
      MemorizationTestKind.orderAyahs,
      MemorizationTestKind.hiddenAyahs,
      MemorizationTestKind.randomPassage,
    ];

    final hardKinds = const [
      MemorizationTestKind.noTextRecitation,
      MemorizationTestKind.fullPage,
      MemorizationTestKind.orderAyahs,
      MemorizationTestKind.randomPassage,
    ];

    final list = difficulty == MemorizationTestDifficulty.easy
        ? easyKinds
        : difficulty == MemorizationTestDifficulty.medium
        ? mediumKinds
        : hardKinds;

    final seed = plan.id.hashCode.abs() + orderIndex + trigger.code.length;
    return list[seed % list.length];
  }

  List<MemorizationScheduledTestModel> _deduplicate(
    List<MemorizationScheduledTestModel> input,
    List<MemorizationSessionResultModel> results,
  ) {
    final completedTaskIds = results.map((item) => item.taskId).toSet();
    final byDate = <String, MemorizationScheduledTestModel>{};

    for (final test in input) {
      if (completedTaskIds.contains(test.id)) continue;

      final dateKey = _dateKey(test.scheduledDate);
      final existing = byDate[dateKey];

      if (existing == null) {
        byDate[dateKey] = test;
        continue;
      }

      if (_shouldReplaceTest(existing: existing, candidate: test)) {
        byDate[dateKey] = test;
      }
    }

    return byDate.values.toList();
  }

  bool _shouldReplaceTest({
    required MemorizationScheduledTestModel existing,
    required MemorizationScheduledTestModel candidate,
  }) {
    final existingRank = _testPriorityRank(existing);
    final candidateRank = _testPriorityRank(candidate);

    if (candidateRank != existingRank) return candidateRank < existingRank;

    if (candidate.isMandatory != existing.isMandatory) {
      return candidate.isMandatory;
    }

    return candidate.ayahsCount > existing.ayahsCount;
  }

  int _testPriorityRank(MemorizationScheduledTestModel test) {
    switch (test.trigger) {
      case MemorizationTestTrigger.endOfCycle:
        return 0;
      case MemorizationTestTrigger.monthlyCheckpoint:
        return 1;
      case MemorizationTestTrigger.tenJuzCheckpoint:
        return 2;
      case MemorizationTestTrigger.fiveJuzCheckpoint:
        return 3;
      case MemorizationTestTrigger.juzCheckpoint:
        return 4;
      case MemorizationTestTrigger.strongHafizCadence:
        return 5;
      case MemorizationTestTrigger.weeklyCheckpoint:
        return 6;
      case MemorizationTestTrigger.threeQuarterCycle:
        return 7;
      case MemorizationTestTrigger.halfCycle:
        return 8;
      case MemorizationTestTrigger.quarterCycle:
        return 9;
      case MemorizationTestTrigger.weakSpotRecovery:
        return 10;
      case MemorizationTestTrigger.manual:
        return 11;
    }
  }

  bool _isStrongHafizPlan(MemorizationActivePlanModel plan) {
    // كادنس الحافظ القوي لا يشتغل لمجرد أن المستخدم نوعه strong.
    // يشتغل فقط لو اختار مسار "اختبار وتقوية".
    return plan.actionTypeName == 'strengthenAndTest';
  }

  bool _isWholeQuranPlan(MemorizationActivePlanModel plan) {
    return plan.totalPages >= 580 ||
        plan.scopeTitle.contains('القرآن كامل') ||
        plan.scopeTypeName == 'wholeQuran';
  }

  List<MemorizationTestSourceTask> _mergeSourcesByLearningDay(
    List<MemorizationTestSourceTask> source,
  ) {
    final byDate = <String, List<MemorizationTestSourceTask>>{};
    for (final item in source) {
      byDate.putIfAbsent(_dateKey(item.date), () => []).add(item);
    }

    final merged = <MemorizationTestSourceTask>[];
    for (final items in byDate.values) {
      items.sort((a, b) => a.priority.compareTo(b.priority));
      final first = items.first;
      int start = first.task.startGlobalAyahIndex;
      int end = first.task.endGlobalAyahIndex;
      int minutes = 0;
      for (final item in items) {
        start = math.min(start, item.task.startGlobalAyahIndex);
        end = math.max(end, item.task.endGlobalAyahIndex);
        minutes += item.task.expectedMinutes;
      }
      final date = _dateOnly(first.date);
      merged.add(
        MemorizationTestSourceTask(
          task: first.task.copyWith(
            id: 'test_source_${first.task.planId}_${_dateKey(date)}',
            startGlobalAyahIndex: start,
            endGlobalAyahIndex: end,
            expectedMinutes: minutes,
            scheduledDate: date,
          ),
          date: date,
          priority: items.map((item) => item.priority).reduce(math.min),
        ),
      );
    }
    merged.sort((a, b) => a.date.compareTo(b.date));
    return merged;
  }

  MemorizationScheduledTestModel? _buildWeakSpotRecoveryTest({
    required MemorizationActivePlanModel plan,
    required List<MemorizationTestSourceTask> learningTasks,
    required List<MemorizationSessionResultModel> results,
  }) {
    final weak =
        results
            .where(
              (item) =>
                  item.needsRescueReview ||
                  item.rating == 'hard' ||
                  item.rating == 'forgot',
            )
            .where(
              (item) =>
                  item.endGlobalAyahIndex >= plan.scopeStartGlobalAyahIndex &&
                  item.startGlobalAyahIndex <= plan.scopeEndGlobalAyahIndex,
            )
            .toList()
          ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    if (weak.isEmpty) return null;

    final recent = weak.first;
    final source = learningTasks.firstWhere(
      (item) => !_dateOnly(item.date).isBefore(_dateOnly(recent.completedAt)),
      orElse: () => learningTasks.first,
    );
    return _buildTest(
      plan: plan,
      source: source,
      results: results,
      trigger: MemorizationTestTrigger.weakSpotRecovery,
      orderIndex: 8000,
      cycleProgress: _progressForSource(learningTasks, source),
      isMandatory: false,
      dateOverride: _dateOnly(recent.completedAt).add(const Duration(days: 2)),
      startOverride: math.max(
        plan.scopeStartGlobalAyahIndex,
        recent.startGlobalAyahIndex,
      ),
      endOverride: math.min(
        plan.scopeEndGlobalAyahIndex,
        recent.endGlobalAyahIndex,
      ),
    );
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _dateKey(DateTime date) {
    final clean = _dateOnly(date);
    return '${clean.year}-${clean.month}-${clean.day}';
  }
}

class _TestRange {
  final int start;
  final int end;

  const _TestRange({required this.start, required this.end});
}
