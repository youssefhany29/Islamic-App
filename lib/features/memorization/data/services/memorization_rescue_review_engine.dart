import 'dart:math' as math;

import '../models/memorization_active_plan_model.dart';
import '../models/memorization_session_result_model.dart';
import '../models/memorization_today_task_model.dart';

class MemorizationRescueReviewEngine {
  const MemorizationRescueReviewEngine();

  MemorizationTodayTaskModel? getDueRescueTask({
    required List<MemorizationSessionResultModel> results,
    required MemorizationActivePlanModel? activePlan,
  }) {
    final today = _dateOnly(DateTime.now());

    final tasks = getUpcomingRescueTasks(
      results: results,
      activePlan: activePlan,
      daysAhead: 0,
    );

    for (final task in tasks) {
      if (_sameDay(task.effectiveScheduledDate, today)) {
        return task;
      }
    }

    return null;
  }

  List<MemorizationTodayTaskModel> getUpcomingRescueTasks({
    required List<MemorizationSessionResultModel> results,
    required MemorizationActivePlanModel? activePlan,
    int daysAhead = 180,
  }) {
    if (activePlan == null) return const [];

    final today = _dateOnly(DateTime.now());
    final lastAllowedDate = today.add(Duration(days: math.max(0, daysAhead)));

    final completedRescueKeys = _completedRescueKeys(results);

    final weakResults = results
        .where((result) => _shouldCreateRescueForResult(result))
        .where((result) => _belongsToActivePlan(result, activePlan))
        .toList()
      ..sort((a, b) {
        final ratingCompare = _ratingPriority(a.rating).compareTo(
          _ratingPriority(b.rating),
        );

        if (ratingCompare != 0) return ratingCompare;

        return a.completedAt.compareTo(b.completedAt);
      });

    if (weakResults.isEmpty) return const [];

    final planned = <_PlannedRescueTask>[];

    for (final result in weakResults) {
      final rescueSeries = _buildRescueSeriesForResult(
        result: result,
        activePlan: activePlan,
        completedRescueKeys: completedRescueKeys,
      );

      planned.addAll(rescueSeries);
    }

    if (planned.isEmpty) return const [];

    planned.sort((a, b) {
      final dateCompare = a.date.compareTo(b.date);
      if (dateCompare != 0) return dateCompare;

      final priorityCompare = a.priority.compareTo(b.priority);
      if (priorityCompare != 0) return priorityCompare;

      return a.result.completedAt.compareTo(b.result.completedAt);
    });

    final reservedDates = <String>{};
    final usedResultIntervalKeys = <String>{};
    final distributed = <MemorizationTodayTaskModel>[];

    for (final item in planned) {
      final resultIntervalKey = '${item.result.taskId}_${item.intervalDays}';

      if (usedResultIntervalKeys.contains(resultIntervalKey)) {
        continue;
      }

      var scheduledDate = _dateOnly(item.date);

      if (scheduledDate.isBefore(today)) {
        scheduledDate = today;
      }

      while (reservedDates.contains(_dateKey(scheduledDate))) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      if (scheduledDate.isAfter(lastAllowedDate)) {
        continue;
      }

      reservedDates.add(_dateKey(scheduledDate));
      usedResultIntervalKeys.add(resultIntervalKey);

      distributed.add(
        _taskFromRescueResult(
          result: item.result,
          activePlan: activePlan,
          scheduledDate: scheduledDate,
          intervalDays: item.intervalDays,
          priority: item.priority,
        ),
      );
    }

    return distributed;
  }

  List<_PlannedRescueTask> _buildRescueSeriesForResult({
    required MemorizationSessionResultModel result,
    required MemorizationActivePlanModel activePlan,
    required Set<String> completedRescueKeys,
  }) {
    final intervals = _intervalsForRating(result.rating);
    final items = <_PlannedRescueTask>[];

    for (final interval in intervals) {
      final rescueKey = _rescueCompletionKey(
        sourceTaskId: result.taskId,
        intervalDays: interval,
      );

      if (completedRescueKeys.contains(rescueKey)) {
        continue;
      }

      final baseDay = _dateOnly(result.completedAt);
      final date = baseDay.add(Duration(days: interval));

      items.add(
        _PlannedRescueTask(
          result: result,
          date: date,
          intervalDays: interval,
          priority: _rescuePriority(
            rating: result.rating,
            intervalDays: interval,
          ),
        ),
      );
    }

    return items;
  }

  MemorizationTodayTaskModel _taskFromRescueResult({
    required MemorizationSessionResultModel result,
    required MemorizationActivePlanModel activePlan,
    required DateTime scheduledDate,
    required int intervalDays,
    required int priority,
  }) {
    final cleanDate = _dateOnly(scheduledDate);

    final safeStart = result.startGlobalAyahIndex
        .clamp(activePlan.scopeStartGlobalAyahIndex, activePlan.scopeEndGlobalAyahIndex)
        .toInt();

    final safeEnd = result.endGlobalAyahIndex
        .clamp(safeStart, activePlan.scopeEndGlobalAyahIndex)
        .toInt();

    final isForgot = result.rating == 'forgot';

    return MemorizationTodayTaskModel(
      id: _rescueCompletionKey(
        sourceTaskId: result.taskId,
        intervalDays: intervalDays,
      ),
      planId: activePlan.id,
      type: 'weakReview',
      title: intervalDays <= 1 ? 'مراجعة قريبة' : 'مراجعة إنقاذ',
      subtitle: isForgot
          ? 'ثبّت هذا الموضع بهدوء.'
          : 'راجع هذا الموضع قبل أن يضعف أكثر.',
      scopeTitle: _simpleRangeTitle(
        startGlobalAyahIndex: safeStart,
        endGlobalAyahIndex: safeEnd,
      ),
      startGlobalAyahIndex: safeStart,
      endGlobalAyahIndex: safeEnd,
      expectedMinutes: _estimateRescueMinutes(result),
      isCompleted: false,
      status: MemorizationTodayTaskModel.statusNotStarted,
      scheduledDate: cleanDate,
      createdAt: cleanDate,
      updatedAt: cleanDate,
    );
  }

  bool _shouldCreateRescueForResult(MemorizationSessionResultModel result) {
    if (result.taskType == 'weakReview') return false;

    return result.needsRescueReview ||
        result.rating == 'hard' ||
        result.rating == 'forgot';
  }

  bool _belongsToActivePlan(
      MemorizationSessionResultModel result,
      MemorizationActivePlanModel activePlan,
      ) {
    final overlapsMainRange =
        result.endGlobalAyahIndex >= activePlan.scopeStartGlobalAyahIndex &&
            result.startGlobalAyahIndex <= activePlan.scopeEndGlobalAyahIndex;

    final overlapsReviewRange = activePlan.hasValidReviewRange &&
        result.endGlobalAyahIndex >= activePlan.reviewStartGlobalAyahIndex &&
        result.startGlobalAyahIndex <= activePlan.reviewEndGlobalAyahIndex;

    return overlapsMainRange || overlapsReviewRange;
  }

  Set<String> _completedRescueKeys(
      List<MemorizationSessionResultModel> results,
      ) {
    return results
        .where((result) => result.taskType == 'weakReview')
        .map((result) => result.taskId)
        .where((taskId) => taskId.startsWith('rescue_'))
        .toSet();
  }

  List<int> _intervalsForRating(String rating) {
    if (rating == 'forgot') {
      return const [1, 3, 7, 15, 30];
    }

    if (rating == 'hard') {
      return const [1, 4, 10, 21];
    }

    return const [3, 10, 30];
  }

  int _rescuePriority({
    required String rating,
    required int intervalDays,
  }) {
    final ratingBase = rating == 'forgot' ? 0 : 10;
    return ratingBase + intervalDays;
  }

  int _ratingPriority(String rating) {
    if (rating == 'forgot') return 0;
    if (rating == 'hard') return 1;
    return 2;
  }

  int _estimateRescueMinutes(MemorizationSessionResultModel result) {
    final multiplier = result.rating == 'forgot' ? 1.25 : 0.95;
    final minutes = 5 + (result.ayahsCount * multiplier);
    return minutes.clamp(6, 45).round();
  }

  String _rescueCompletionKey({
    required String sourceTaskId,
    required int intervalDays,
  }) {
    return 'rescue_${sourceTaskId}_$intervalDays';
  }

  String _simpleRangeTitle({
    required int startGlobalAyahIndex,
    required int endGlobalAyahIndex,
  }) {
    final count = endGlobalAyahIndex - startGlobalAyahIndex + 1;

    if (count <= 1) {
      return 'موضع يحتاج تثبيت';
    }

    return '$count آية تحتاج تثبيت';
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  bool _sameDay(DateTime a, DateTime b) {
    final x = _dateOnly(a);
    final y = _dateOnly(b);

    return x.year == y.year && x.month == y.month && x.day == y.day;
  }

  String _dateKey(DateTime date) {
    final clean = _dateOnly(date);
    return '${clean.year}-${clean.month}-${clean.day}';
  }
}

class _PlannedRescueTask {
  final MemorizationSessionResultModel result;
  final DateTime date;
  final int intervalDays;
  final int priority;

  const _PlannedRescueTask({
    required this.result,
    required this.date,
    required this.intervalDays,
    required this.priority,
  });
}