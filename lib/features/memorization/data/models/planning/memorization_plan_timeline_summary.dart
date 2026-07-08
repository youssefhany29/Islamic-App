class MemorizationPlanTimelineSummary {
  const MemorizationPlanTimelineSummary({
    required this.targetLearningDays,
    required this.effectiveCalendarDays,
    required this.currentCalendarDay,
    required this.remainingCalendarDays,
    required this.currentLearningDay,
    required this.remainingLearningDays,
    required this.reviewScheduleDays,
    required this.lastScheduledDate,
  });

  final int targetLearningDays;
  final int effectiveCalendarDays;
  final int currentCalendarDay;
  final int remainingCalendarDays;
  final int currentLearningDay;
  final int remainingLearningDays;
  final int reviewScheduleDays;
  final DateTime lastScheduledDate;
}
