import 'dart:math' as math;

import 'package:islamic_app/features/memorization/data/models/memorization_active_plan_model.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_session_result_model.dart';

class MemorizationPlanCompletionSnapshot {
  const MemorizationPlanCompletionSnapshot({
    required this.isCompleted,
    required this.completionPercent,
    required this.completedLearningSessions,
    required this.completedAt,
  });

  final bool isCompleted;
  final int completionPercent;
  final int completedLearningSessions;
  final DateTime? completedAt;
}

class MemorizationPlanCompletionService {
  const MemorizationPlanCompletionService();

  MemorizationPlanCompletionSnapshot evaluate({
    required MemorizationActivePlanModel plan,
    required List<MemorizationSessionResultModel> results,
  }) {
    final planResults = _planResults(plan, results);
    final DateTime? latestCompletion = _latestCompletion(planResults);

    if (plan.isCompleted) {
      return MemorizationPlanCompletionSnapshot(
        isCompleted: true,
        completionPercent: 100,
        completedLearningSessions: _learningResults(planResults).length,
        completedAt: plan.completedAt ?? latestCompletion ?? plan.updatedAt,
      );
    }

    if (_hasNewMemorization(plan)) {
      final memorizedAyahs = <int>{};

      for (final result in planResults.where(
        (item) => item.taskType == 'dailyNew',
      )) {
        final start = math.max(
          plan.scopeStartGlobalAyahIndex,
          result.startGlobalAyahIndex,
        );
        final end = math.min(
          plan.scopeEndGlobalAyahIndex,
          result.endGlobalAyahIndex,
        );

        for (int index = start; index <= end; index++) {
          memorizedAyahs.add(index);
        }
      }

      final totalAyahs = math.max(1, plan.totalAyahs);
      final percent = ((memorizedAyahs.length / totalAyahs) * 100)
          .round()
          .clamp(0, 100)
          .toInt();

      return MemorizationPlanCompletionSnapshot(
        isCompleted: percent >= 100,
        completionPercent: percent,
        completedLearningSessions: _learningResults(planResults).length,
        completedAt: percent >= 100 ? latestCompletion : null,
      );
    }

    final completedSessions = _learningResults(planResults).length;
    final requiredSessions = plan.learningSessionsCount.clamp(1, 99999).toInt();
    final percent = ((completedSessions / requiredSessions) * 100)
        .round()
        .clamp(0, 100)
        .toInt();

    return MemorizationPlanCompletionSnapshot(
      isCompleted: percent >= 100,
      completionPercent: percent,
      completedLearningSessions: completedSessions,
      completedAt: percent >= 100 ? latestCompletion : null,
    );
  }

  static bool _hasNewMemorization(MemorizationActivePlanModel plan) {
    return plan.actionTypeName == 'newMemorization' ||
        plan.actionTypeName == 'newWithReview';
  }

  static List<MemorizationSessionResultModel> _planResults(
    MemorizationActivePlanModel plan,
    List<MemorizationSessionResultModel> results,
  ) {
    return results
        .where((result) {
          if (result.completedAt.isBefore(plan.createdAt)) return false;

          return result.endGlobalAyahIndex >= plan.scopeStartGlobalAyahIndex &&
              result.startGlobalAyahIndex <= plan.scopeEndGlobalAyahIndex;
        })
        .toList(growable: false);
  }

  static List<MemorizationSessionResultModel> _learningResults(
    List<MemorizationSessionResultModel> results,
  ) {
    return results
        .where((result) {
          return result.taskType == 'dailyNew' ||
              result.taskType == 'dailyReview' ||
              result.taskType == 'weakReview';
        })
        .toList(growable: false);
  }

  static DateTime? _latestCompletion(
    List<MemorizationSessionResultModel> results,
  ) {
    if (results.isEmpty) return null;

    return results
        .map((item) => item.completedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }
}
