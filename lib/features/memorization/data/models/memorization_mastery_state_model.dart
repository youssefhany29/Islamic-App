class MemorizationMasteryStateModel {
  final String planId;
  final int startGlobalAyahIndex;
  final int endGlobalAyahIndex;
  final double masteryScore;
  final DateTime? lastReviewedAt;
  final int mistakesCount;
  final double hesitationScore;
  final double testScore;
  final int timesReviewed;
  final DateTime nextReviewDueDate;

  const MemorizationMasteryStateModel({
    required this.planId,
    required this.startGlobalAyahIndex,
    required this.endGlobalAyahIndex,
    required this.masteryScore,
    required this.lastReviewedAt,
    required this.mistakesCount,
    required this.hesitationScore,
    required this.testScore,
    required this.timesReviewed,
    required this.nextReviewDueDate,
  });

  bool get isWeakSpot => masteryScore < 0.65 || mistakesCount >= 2;

  bool isDueOn(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final due = DateTime(
      nextReviewDueDate.year,
      nextReviewDueDate.month,
      nextReviewDueDate.day,
    );
    return !due.isAfter(day);
  }
}
