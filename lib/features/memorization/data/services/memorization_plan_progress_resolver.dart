import '../models/memorization_active_plan_model.dart';
import '../models/memorization_session_result_model.dart';

class MemorizationPlanProgressSnapshot {
  final int completedNewCount;
  final int completedReviewCount;
  final int completedSelfTestCount;
  final bool completedNewToday;
  final bool completedReviewToday;
  final bool completedSelfTestToday;

  const MemorizationPlanProgressSnapshot({
    required this.completedNewCount,
    required this.completedReviewCount,
    required this.completedSelfTestCount,
    required this.completedNewToday,
    required this.completedReviewToday,
    required this.completedSelfTestToday,
  });
}

class MemorizationPlanProgressResolver {
  const MemorizationPlanProgressResolver();

  MemorizationPlanProgressSnapshot resolve({
    required MemorizationActivePlanModel plan,
    required List<MemorizationSessionResultModel> results,
    required DateTime today,
  }) {
    final normalizedToday = DateTime(today.year, today.month, today.day);

    final planResults = results.where((result) {
      if (result.completedAt.isBefore(plan.createdAt)) return false;

      final overlapsMainRange =
          result.endGlobalAyahIndex >= plan.scopeStartGlobalAyahIndex &&
              result.startGlobalAyahIndex <= plan.scopeEndGlobalAyahIndex;

      final overlapsReviewRange = plan.hasValidReviewRange &&
          result.endGlobalAyahIndex >= plan.reviewStartGlobalAyahIndex &&
          result.startGlobalAyahIndex <= plan.reviewEndGlobalAyahIndex;

      return overlapsMainRange || overlapsReviewRange;
    }).toList();

    bool doneToday(String type) {
      return planResults.any((result) {
        if (result.taskType != type) return false;

        final date = DateTime(
          result.completedAt.year,
          result.completedAt.month,
          result.completedAt.day,
        );

        return date == normalizedToday;
      });
    }

    return MemorizationPlanProgressSnapshot(
      completedNewCount:
      planResults.where((result) => result.taskType == 'dailyNew').length,
      completedReviewCount:
      planResults.where((result) => result.taskType == 'dailyReview').length,
      completedSelfTestCount:
      planResults.where((result) => result.taskType == 'selfTest').length,
      completedNewToday: doneToday('dailyNew'),
      completedReviewToday: doneToday('dailyReview'),
      completedSelfTestToday: doneToday('selfTest'),
    );
  }
}
