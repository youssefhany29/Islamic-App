import 'planning/memorization_plan_intensity.dart';

class MemorizationPlanPreviewModel {
  final String pathTitle;
  final String scopeTitle;
  final String scopeSizeText;
  final String calculationText;

  final String durationText;
  final String dailyNewText;
  final String dailyBaseReviewText;
  final String weakReviewText;
  final String selfTestText;
  final String loadText;

  final int totalDays;
  final int totalAyahs;
  final int totalPages;
  final int targetLearningDays;
  final int learningSessionsCount;
  final int effectiveCalendarDays;
  final int plannedTestsCount;
  final MemorizationPlanIntensity intensity;
  final String intensityWarningText;
  final int dailyNewAyahs;
  final double dailyNewPages;
  final double dailyReviewPages;

  final List<String> systemPoints;
  final List<String> reviewRules;

  const MemorizationPlanPreviewModel({
    required this.pathTitle,
    required this.scopeTitle,
    required this.scopeSizeText,
    required this.calculationText,
    required this.durationText,
    required this.dailyNewText,
    required this.dailyBaseReviewText,
    required this.weakReviewText,
    required this.selfTestText,
    required this.loadText,
    required this.totalDays,
    required this.totalAyahs,
    required this.totalPages,
    required this.targetLearningDays,
    required this.learningSessionsCount,
    required this.effectiveCalendarDays,
    required this.plannedTestsCount,
    required this.intensity,
    required this.intensityWarningText,
    required this.dailyNewAyahs,
    required this.dailyNewPages,
    required this.dailyReviewPages,
    required this.systemPoints,
    required this.reviewRules,
  });
}
