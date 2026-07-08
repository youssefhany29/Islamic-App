import 'dart:math' as math;

import '../../models/memorization_active_plan_model.dart';
import '../../models/memorization_session_result_model.dart';
import '../../models/planning/memorization_plan_timeline_summary.dart';
import '../memorization_plan_journey_engine.dart';

class MemorizationPlanTimelineResolver {
  const MemorizationPlanTimelineResolver();

  MemorizationPlanTimelineSummary resolve({
    required MemorizationActivePlanModel plan,
    required List<MemorizationJourneyTask> journeyTasks,
    required List<MemorizationSessionResultModel> results,
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());
    final planStart = _dateOnly(plan.createdAt);
    var lastScheduledDate = planStart.add(
      Duration(days: math.max(1, plan.effectiveCalendarDays) - 1),
    );

    for (final item in journeyTasks) {
      final date = _dateOnly(item.date);
      if (date.isAfter(lastScheduledDate)) lastScheduledDate = date;
    }

    final effectiveCalendarDays = math.max(
      1,
      lastScheduledDate.difference(planStart).inDays + 1,
    );
    final currentCalendarDay = (today.difference(planStart).inDays + 1)
        .clamp(1, effectiveCalendarDays)
        .toInt();

    final learningTasks = journeyTasks
        .where((item) => item.task.type == 'dailyNew')
        .toList(growable: false);
    final learningDates = learningTasks
        .map((item) => _dateKey(item.date))
        .toSet();
    final completedLearningDates = <String>{};
    for (final item in learningTasks) {
      if (_isTaskCompleted(item, results)) {
        completedLearningDates.add(_dateKey(item.date));
      }
    }

    final totalScheduledLearningDays = learningDates.isEmpty
        ? math.max(1, plan.targetLearningDays)
        : learningDates.length;
    final completedLearningDays = completedLearningDates.length;
    final hasLearningToday = learningTasks.any(
      (item) => _sameDay(item.date, today),
    );
    final currentLearningDay = math.max(
      1,
      math.min(
        totalScheduledLearningDays,
        completedLearningDays + (hasLearningToday ? 1 : 0),
      ),
    );
    final remainingLearningDays = math.max(
      0,
      totalScheduledLearningDays - completedLearningDays,
    );
    final reviewScheduleDays = journeyTasks
        .where(
          (item) =>
              item.task.type == 'dailyReview' || item.task.type == 'weakReview',
        )
        .map((item) => _dateKey(item.date))
        .toSet()
        .length;

    return MemorizationPlanTimelineSummary(
      targetLearningDays: plan.targetLearningDays,
      effectiveCalendarDays: effectiveCalendarDays,
      currentCalendarDay: currentCalendarDay,
      remainingCalendarDays: math.max(
        0,
        effectiveCalendarDays - currentCalendarDay,
      ),
      currentLearningDay: currentLearningDay,
      remainingLearningDays: remainingLearningDays,
      reviewScheduleDays: reviewScheduleDays,
      lastScheduledDate: lastScheduledDate,
    );
  }

  bool _isTaskCompleted(
    MemorizationJourneyTask item,
    List<MemorizationSessionResultModel> results,
  ) {
    if (item.task.isCompleted) return true;
    return results.any((result) {
      if (result.taskType != 'dailyNew') return false;
      if (result.taskId == item.task.id) return true;
      return result.startGlobalAyahIndex <= item.task.startGlobalAyahIndex &&
          result.endGlobalAyahIndex >= item.task.endGlobalAyahIndex;
    });
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _dateKey(DateTime value) {
    final date = _dateOnly(value);
    return '${date.year}-${date.month}-${date.day}';
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
