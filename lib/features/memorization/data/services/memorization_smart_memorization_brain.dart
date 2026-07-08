import 'dart:math' as math;

import '../models/memorization_active_plan_model.dart';
import '../models/memorization_mastery_state_model.dart';
import '../models/memorization_session_result_model.dart';

class MemorizationSmartMemorizationBrain {
  const MemorizationSmartMemorizationBrain();

  static const List<int> _spacedReviewDays = [1, 3, 7, 14, 30];

  List<MemorizationMasteryStateModel> buildStates({
    required MemorizationActivePlanModel plan,
    required List<MemorizationSessionResultModel> results,
    DateTime? now,
  }) {
    final planResults = results.where((result) {
      if (result.completedAt.isBefore(plan.createdAt)) return false;
      return result.endGlobalAyahIndex >= plan.scopeStartGlobalAyahIndex &&
          result.startGlobalAyahIndex <= plan.scopeEndGlobalAyahIndex;
    }).toList()..sort((a, b) => a.completedAt.compareTo(b.completedAt));

    final byRange = <String, List<MemorizationSessionResultModel>>{};
    for (final result in planResults) {
      final key = '${result.startGlobalAyahIndex}:${result.endGlobalAyahIndex}';
      byRange.putIfAbsent(key, () => []).add(result);
    }

    return byRange.values.map((rangeResults) {
      final last = rangeResults.last;
      final reviews = rangeResults
          .where(
            (item) =>
                item.taskType == 'dailyReview' ||
                item.taskType == 'weakReview' ||
                item.taskType == 'selfTest',
          )
          .length;
      final mistakes = rangeResults
          .where(
            (item) =>
                item.rating == 'hard' ||
                item.rating == 'forgot' ||
                item.needsRescueReview,
          )
          .length;
      final testResults = rangeResults
          .where((item) => item.taskType == 'selfTest')
          .toList();
      final testScore = testResults.isEmpty
          ? _ratingScore(last.rating)
          : testResults
                    .map((item) => _ratingScore(item.rating))
                    .reduce((a, b) => a + b) /
                testResults.length;
      final hesitation =
          rangeResults
              .map((item) => _hesitationFor(item.rating))
              .reduce((a, b) => a + b) /
          rangeResults.length;
      final mastery = _masteryScore(
        ratingScore: _ratingScore(last.rating),
        testScore: testScore,
        hesitation: hesitation,
        mistakes: mistakes,
        timesReviewed: reviews,
      );
      final interval = _nextIntervalDays(
        masteryScore: mastery,
        mistakesCount: mistakes,
        timesReviewed: reviews,
      );

      return MemorizationMasteryStateModel(
        planId: plan.id,
        startGlobalAyahIndex: last.startGlobalAyahIndex,
        endGlobalAyahIndex: last.endGlobalAyahIndex,
        masteryScore: mastery,
        lastReviewedAt: last.completedAt,
        mistakesCount: mistakes,
        hesitationScore: hesitation,
        testScore: testScore,
        timesReviewed: reviews,
        nextReviewDueDate: DateTime(
          last.completedAt.year,
          last.completedAt.month,
          last.completedAt.day,
        ).add(Duration(days: interval)),
      );
    }).toList()..sort((a, b) {
      final due = a.nextReviewDueDate.compareTo(b.nextReviewDueDate);
      if (due != 0) return due;
      return a.masteryScore.compareTo(b.masteryScore);
    });
  }

  List<MemorizationMasteryStateModel> dueReviews({
    required MemorizationActivePlanModel plan,
    required List<MemorizationSessionResultModel> results,
    DateTime? onDate,
  }) {
    final date = onDate ?? DateTime.now();
    return buildStates(
      plan: plan,
      results: results,
      now: date,
    ).where((state) => state.isDueOn(date)).toList();
  }

  List<MemorizationMasteryStateModel> buildAyahStates({
    required MemorizationActivePlanModel plan,
    required List<MemorizationSessionResultModel> results,
  }) {
    return buildStates(plan: plan, results: results).expand((state) {
      return List.generate(
        state.endGlobalAyahIndex - state.startGlobalAyahIndex + 1,
        (offset) {
          final ayah = state.startGlobalAyahIndex + offset;
          return MemorizationMasteryStateModel(
            planId: state.planId,
            startGlobalAyahIndex: ayah,
            endGlobalAyahIndex: ayah,
            masteryScore: state.masteryScore,
            lastReviewedAt: state.lastReviewedAt,
            mistakesCount: state.mistakesCount,
            hesitationScore: state.hesitationScore,
            testScore: state.testScore,
            timesReviewed: state.timesReviewed,
            nextReviewDueDate: state.nextReviewDueDate,
          );
        },
      );
    }).toList();
  }

  int _nextIntervalDays({
    required double masteryScore,
    required int mistakesCount,
    required int timesReviewed,
  }) {
    if (mistakesCount > 0 || masteryScore < 0.55) return 1;
    final index = timesReviewed.clamp(0, _spacedReviewDays.length - 1);
    final base = _spacedReviewDays[index];
    if (masteryScore >= 0.9 && timesReviewed >= _spacedReviewDays.length) {
      return 45;
    }
    return base;
  }

  double _masteryScore({
    required double ratingScore,
    required double testScore,
    required double hesitation,
    required int mistakes,
    required int timesReviewed,
  }) {
    final reviewBoost = math.min(0.15, timesReviewed * 0.025);
    final mistakePenalty = math.min(0.45, mistakes * 0.12);
    return (ratingScore * 0.45 +
            testScore * 0.35 +
            (1 - hesitation) * 0.20 +
            reviewBoost -
            mistakePenalty)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  double _ratingScore(String rating) {
    switch (rating) {
      case 'easy':
        return 1;
      case 'good':
        return 0.8;
      case 'hard':
        return 0.5;
      case 'forgot':
      default:
        return 0.2;
    }
  }

  double _hesitationFor(String rating) {
    switch (rating) {
      case 'easy':
        return 0.05;
      case 'good':
        return 0.25;
      case 'hard':
        return 0.65;
      case 'forgot':
      default:
        return 1;
    }
  }
}
