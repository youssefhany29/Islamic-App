import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import '../models/memorization_active_plan_model.dart';
import '../models/memorization_session_result_model.dart';
import '../models/memorization_today_task_model.dart';
import 'memorization_plan_storage.dart';
import 'memorization_session_result_storage.dart';

class MemorizationJourneyCompanionReport {
  final MemorizationActivePlanModel? activePlan;
  final int completedTasks;
  final int weakTasks;
  final int forgottenTasks;
  final int elapsedPlanDays;
  final int expectedPlanDays;
  final double commitmentScore;
  final double stabilityScore;
  final bool shouldOfferStabilizationPlan;
  final MemorizationQuickStabilizationPlan? quickPlan;
  final String title;
  final String message;
  final List<String> focusPoints;

  const MemorizationJourneyCompanionReport({
    required this.activePlan,
    required this.completedTasks,
    required this.weakTasks,
    required this.forgottenTasks,
    required this.elapsedPlanDays,
    required this.expectedPlanDays,
    required this.commitmentScore,
    required this.stabilityScore,
    required this.shouldOfferStabilizationPlan,
    required this.quickPlan,
    required this.title,
    required this.message,
    required this.focusPoints,
  });

  bool get hasActivePlan => activePlan != null;

  int get commitmentPercent => (commitmentScore * 100).round().clamp(0, 100);

  int get stabilityPercent => (stabilityScore * 100).round().clamp(0, 100);

  bool get hasWeakness => weakTasks > 0 || forgottenTasks > 0;
}

class MemorizationQuickStabilizationPlan {
  final String title;
  final String subtitle;
  final int days;
  final int startGlobalAyahIndex;
  final int endGlobalAyahIndex;
  final int estimatedDailyAyahs;
  final int plannedTestsCount;
  final List<String> focusPoints;

  const MemorizationQuickStabilizationPlan({
    required this.title,
    required this.subtitle,
    required this.days,
    required this.startGlobalAyahIndex,
    required this.endGlobalAyahIndex,
    required this.estimatedDailyAyahs,
    required this.plannedTestsCount,
    required this.focusPoints,
  });

  int get ayahsCount {
    if (endGlobalAyahIndex < startGlobalAyahIndex) return 0;
    return endGlobalAyahIndex - startGlobalAyahIndex + 1;
  }
}

class MemorizationJourneyCompanionService {
  static const String _plansKey = 'my_lessons_memorization_plans';
  static const String _activePlanIdKey =
      'my_lessons_active_memorization_plan_id';
  static const String _legacyActivePlanKey =
      'my_lessons_active_memorization_plan';
  static const String _legacyTodayTaskKey =
      'my_lessons_today_memorization_task';
  static const String _taskPrefix = 'my_lessons_today_memorization_task_';

  const MemorizationJourneyCompanionService();

  Future<MemorizationJourneyCompanionReport> buildReport() async {
    final activePlan = await MemorizationPlanStorage.getActivePlan();

    if (activePlan == null) {
      return const MemorizationJourneyCompanionReport(
        activePlan: null,
        completedTasks: 0,
        weakTasks: 0,
        forgottenTasks: 0,
        elapsedPlanDays: 0,
        expectedPlanDays: 0,
        commitmentScore: 0,
        stabilityScore: 0,
        shouldOfferStabilizationPlan: false,
        quickPlan: null,
        title: 'رحلتك هتبدأ بهدوء',
        message:
            'بعد إنشاء خطة الحفظ، هتلاقي هنا متابعة لطيفة لالتزامك، وماذا تحتاج في المرحلة القادمة.',
        focusPoints: [],
      );
    }

    final allResults = await MemorizationSessionResultStorage.getResults();

    final planResults = _resultsForPlan(plan: activePlan, results: allResults);

    final weakResults = planResults.where(_isWeakResult).toList();
    final forgottenResults = planResults
        .where((result) => result.rating == 'forgot')
        .toList(growable: false);

    final today = _dateOnly(DateTime.now());
    final planStartDay = _dateOnly(activePlan.createdAt);
    final elapsedDays = today.difference(planStartDay).inDays + 1;
    final expectedDays = math.max(1, activePlan.totalDays);

    final elapsedPlanDays = elapsedDays.clamp(1, expectedDays).toInt();

    final primaryCompleted = planResults.where((result) {
      return result.taskType == 'dailyNew' ||
          result.taskType == 'dailyReview' ||
          result.taskType == 'selfTest';
    }).length;

    final commitmentScore = _safeRatio(
      primaryCompleted.toDouble(),
      elapsedPlanDays.toDouble(),
    ).clamp(0.0, 1.0);

    final stabilityScore = _calculateStabilityScore(
      completedTasks: primaryCompleted,
      weakTasks: weakResults.length,
      forgottenTasks: forgottenResults.length,
    );

    final quickPlan = _buildQuickPlanIfNeeded(
      plan: activePlan,
      planResults: planResults,
      weakResults: weakResults,
      forgottenResults: forgottenResults,
      commitmentScore: commitmentScore,
      stabilityScore: stabilityScore,
    );

    final shouldOffer = quickPlan != null;

    return MemorizationJourneyCompanionReport(
      activePlan: activePlan,
      completedTasks: primaryCompleted,
      weakTasks: weakResults.length,
      forgottenTasks: forgottenResults.length,
      elapsedPlanDays: elapsedPlanDays,
      expectedPlanDays: expectedDays,
      commitmentScore: commitmentScore,
      stabilityScore: stabilityScore,
      shouldOfferStabilizationPlan: shouldOffer,
      quickPlan: quickPlan,
      title: _buildTitle(
        commitmentScore: commitmentScore,
        stabilityScore: stabilityScore,
        weakCount: weakResults.length,
      ),
      message: _buildMessage(
        commitmentScore: commitmentScore,
        stabilityScore: stabilityScore,
        weakCount: weakResults.length,
        hasQuickPlan: shouldOffer,
      ),
      focusPoints: _buildFocusPoints(
        weakResults: weakResults,
        forgottenResults: forgottenResults,
        commitmentScore: commitmentScore,
      ),
    );
  }

  Future<void> activateQuickStabilizationPlan({
    required MemorizationQuickStabilizationPlan quickPlan,
    required MemorizationActivePlanModel sourcePlan,
  }) async {
    if (quickPlan.ayahsCount <= 0) return;

    final prefs = await SharedPreferences.getInstance();
    final oldPlans = await MemorizationPlanStorage.getPlans();
    final now = DateTime.now();
    final today = _dateOnly(now);

    final newPlanId = 'memorization_plan_${now.microsecondsSinceEpoch}';

    final newPlan = sourcePlan.copyWith(
      id: newPlanId,
      planName: quickPlan.title,
      userTypeName: sourcePlan.userTypeName,
      actionTypeName: 'reviewOnly',
      pathTitle: 'رحلة تثبيت قصيرة',
      scopeTitle: quickPlan.subtitle,
      scopeSizeText: '${quickPlan.ayahsCount} آية تحتاج تثبيت',
      calculationText: 'خطة تلقائية مبنية على نتيجة رحلتك السابقة',
      durationText: '${quickPlan.days} أيام',
      dailyNewText: 'لا يوجد حفظ جديد في هذه الرحلة',
      dailyBaseReviewText:
          'مراجعة مركزة: ${quickPlan.estimatedDailyAyahs} آية تقريبًا يوميًا',
      weakReviewText: 'تركيز على المواضع التي ظهر فيها تردد أو نسيان',
      selfTestText: 'اختبارات تثبيت تلقائية حسب التقدم',
      loadText: 'رحلة هادئة بدون ضغط، هدفها تثبيت ما سبق.',
      totalDays: quickPlan.days,
      targetLearningDays: quickPlan.days,
      learningSessionsCount: quickPlan.days,
      effectiveCalendarDays: quickPlan.days + quickPlan.plannedTestsCount,
      intensityModeName: 'normal',
      planVersion: sourcePlan.planVersion + 1,
      totalAyahs: quickPlan.ayahsCount,
      dailyNewAyahs: 0,
      dailyNewPages: 0,
      dailyReviewPages: _estimateDailyReviewPages(
        ayahsCount: quickPlan.ayahsCount,
        days: quickPlan.days,
      ),
      scopeStartGlobalAyahIndex: quickPlan.startGlobalAyahIndex,
      scopeEndGlobalAyahIndex: quickPlan.endGlobalAyahIndex,
      reviewStartGlobalAyahIndex: quickPlan.startGlobalAyahIndex,
      reviewEndGlobalAyahIndex: quickPlan.endGlobalAyahIndex,
      reviewScopeTitle: quickPlan.subtitle,
      reviewFromLearnedOnly: false,
      reviewEveryDays: 1,
      reviewSessionsCount: quickPlan.days,
      effectiveReviewDays: quickPlan.days,
      reviewScheduleNote:
          'هذه رحلة تثبيت قصيرة بُنيت تلقائيًا من المواضع التي احتاجت مراجعة.',
      plannedTestsCount: quickPlan.plannedTestsCount,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    final archivedPlans = oldPlans.map((plan) {
      if (!plan.isActive) return plan;
      return plan.copyWith(isActive: false, updatedAt: now);
    }).toList();

    final updatedPlans = <MemorizationActivePlanModel>[
      newPlan,
      ...archivedPlans.where((plan) => plan.id != newPlan.id),
    ];

    final firstTask = MemorizationTodayTaskModel(
      id: 'task_${newPlan.id}_review_0_${today.millisecondsSinceEpoch}',
      planId: newPlan.id,
      type: 'dailyReview',
      title: 'بداية رحلة التثبيت',
      subtitle: 'راجع بهدوء أول جزء من المواضع التي احتاجت تثبيت.',
      scopeTitle: quickPlan.subtitle,
      startGlobalAyahIndex: quickPlan.startGlobalAyahIndex,
      endGlobalAyahIndex: _firstTaskEndIndex(quickPlan: quickPlan),
      expectedMinutes: _estimateMinutes(
        ayahsCount: quickPlan.estimatedDailyAyahs,
      ),
      isCompleted: false,
      status: MemorizationTodayTaskModel.statusNotStarted,
      scheduledDate: today,
      createdAt: now,
      updatedAt: now,
    );

    await prefs.setString(
      _plansKey,
      jsonEncode(updatedPlans.map((plan) => plan.toMap()).toList()),
    );

    await prefs.setString(_activePlanIdKey, newPlan.id);
    await prefs.setString(_legacyActivePlanKey, jsonEncode(newPlan.toMap()));

    await prefs.setString(_taskKey(newPlan.id), jsonEncode(firstTask.toMap()));

    await prefs.setString(_legacyTodayTaskKey, jsonEncode(firstTask.toMap()));
  }

  List<MemorizationSessionResultModel> _resultsForPlan({
    required MemorizationActivePlanModel plan,
    required List<MemorizationSessionResultModel> results,
  }) {
    return results.where((result) {
      if (result.completedAt.isBefore(plan.createdAt)) return false;

      final overlapsMainRange =
          result.endGlobalAyahIndex >= plan.scopeStartGlobalAyahIndex &&
          result.startGlobalAyahIndex <= plan.scopeEndGlobalAyahIndex;

      final overlapsReviewRange =
          plan.hasValidReviewRange &&
          result.endGlobalAyahIndex >= plan.reviewStartGlobalAyahIndex &&
          result.startGlobalAyahIndex <= plan.reviewEndGlobalAyahIndex;

      return overlapsMainRange || overlapsReviewRange;
    }).toList();
  }

  bool _isWeakResult(MemorizationSessionResultModel result) {
    return result.needsRescueReview ||
        result.rating == 'hard' ||
        result.rating == 'forgot';
  }

  double _calculateStabilityScore({
    required int completedTasks,
    required int weakTasks,
    required int forgottenTasks,
  }) {
    if (completedTasks <= 0) return 0;

    final weakPenalty = weakTasks * 0.08;
    final forgotPenalty = forgottenTasks * 0.14;
    final score = 1.0 - weakPenalty - forgotPenalty;

    return score.clamp(0.0, 1.0);
  }

  MemorizationQuickStabilizationPlan? _buildQuickPlanIfNeeded({
    required MemorizationActivePlanModel plan,
    required List<MemorizationSessionResultModel> planResults,
    required List<MemorizationSessionResultModel> weakResults,
    required List<MemorizationSessionResultModel> forgottenResults,
    required double commitmentScore,
    required double stabilityScore,
  }) {
    if (planResults.length < 3) return null;

    final needsPlan =
        weakResults.length >= 2 ||
        forgottenResults.isNotEmpty ||
        stabilityScore < 0.72 ||
        commitmentScore < 0.60;

    if (!needsPlan) return null;

    final weakSource = weakResults.isNotEmpty ? weakResults : planResults;

    int start = weakSource
        .map((result) => result.startGlobalAyahIndex)
        .reduce(math.min);

    int end = weakSource
        .map((result) => result.endGlobalAyahIndex)
        .reduce(math.max);

    start = start
        .clamp(plan.scopeStartGlobalAyahIndex, plan.scopeEndGlobalAyahIndex)
        .toInt();
    end = end.clamp(start, plan.scopeEndGlobalAyahIndex).toInt();

    final ayahsCount = (end - start + 1).clamp(1, 999999).toInt();

    final days = _suggestStabilizationDays(
      ayahsCount: ayahsCount,
      weakCount: weakResults.length,
      forgotCount: forgottenResults.length,
      commitmentScore: commitmentScore,
    );

    final dailyAyahs = (ayahsCount / days).ceil().clamp(1, 40).toInt();

    return MemorizationQuickStabilizationPlan(
      title: 'رحلة تثبيت قصيرة',
      subtitle: 'تثبيت المواضع التي احتاجت مراجعة',
      days: days,
      startGlobalAyahIndex: start,
      endGlobalAyahIndex: end,
      estimatedDailyAyahs: dailyAyahs,
      plannedTestsCount: days >= 7 ? 2 : 1,
      focusPoints: _buildFocusPoints(
        weakResults: weakResults,
        forgottenResults: forgottenResults,
        commitmentScore: commitmentScore,
      ),
    );
  }

  int _suggestStabilizationDays({
    required int ayahsCount,
    required int weakCount,
    required int forgotCount,
    required double commitmentScore,
  }) {
    if (forgotCount >= 2) return 7;
    if (ayahsCount > 80) return 7;
    if (weakCount >= 4) return 6;
    if (commitmentScore < 0.55) return 5;
    return 4;
  }

  List<String> _buildFocusPoints({
    required List<MemorizationSessionResultModel> weakResults,
    required List<MemorizationSessionResultModel> forgottenResults,
    required double commitmentScore,
  }) {
    final points = <String>[];

    if (weakResults.isNotEmpty) {
      points.add('راجع المواضع التي ظهر فيها تردد قبل إضافة حفظ جديد.');
    }

    if (forgottenResults.isNotEmpty) {
      points.add('ابدأ بالتسميع الهادئ ثم اضغط عرض النص عند الحاجة فقط.');
    }

    if (commitmentScore < 0.70) {
      points.add('حاول تثبيت وقت قصير ثابت يوميًا؛ حتى لو 10 دقائق فقط.');
    }

    if (points.isEmpty) {
      points.add('استمر بنفس الهدوء، وراجع قبل الاختبار النهائي بيوم.');
    }

    return points.take(3).toList(growable: false);
  }

  String _buildTitle({
    required double commitmentScore,
    required double stabilityScore,
    required int weakCount,
  }) {
    if (weakCount >= 2 || stabilityScore < 0.65) {
      return 'خلّينا نثبت الرحلة بهدوء';
    }

    if (commitmentScore < 0.65) {
      return 'الرحلة ماشية، ونحتاج ثبات أكثر';
    }

    if (commitmentScore >= 0.85 && stabilityScore >= 0.85) {
      return 'رحلتك مستقرة جدًا';
    }

    return 'متابعين رحلتك خطوة بخطوة';
  }

  String _buildMessage({
    required double commitmentScore,
    required double stabilityScore,
    required int weakCount,
    required bool hasQuickPlan,
  }) {
    if (hasQuickPlan) {
      return 'لاحظنا أن في مواضع تحتاج تثبيت. جهزنا لك رحلة قصيرة بدون ضغط، ولو وافقت هنحطها مباشرة في التقويم.';
    }

    if (commitmentScore < 0.65) {
      return 'لا تقلق، التقويم بيتحرك معاك بدون تراكم، لكن نسبة الالتزام بتتأثر عشان تفضل قريب من هدفك.';
    }

    if (stabilityScore < 0.75 || weakCount > 0) {
      return 'أداؤك جيد، لكن في مواضع صغيرة تحتاج مراجعة هادئة قبل الاختبار القادم.';
    }

    return 'أداؤك مطمئن. كمل بنفس الهدوء، والتطبيق هيفكرك بالاختبارات في وقتها فقط.';
  }

  double _safeRatio(double value, double total) {
    if (total <= 0) return 0;
    return value / total;
  }

  double _estimateDailyReviewPages({
    required int ayahsCount,
    required int days,
  }) {
    final safeDays = math.max(1, days);
    final roughPages = (ayahsCount / 10).clamp(0.25, 604).toDouble();
    return (roughPages / safeDays).clamp(0.25, 2.0).toDouble();
  }

  int _firstTaskEndIndex({
    required MemorizationQuickStabilizationPlan quickPlan,
  }) {
    final end =
        quickPlan.startGlobalAyahIndex + quickPlan.estimatedDailyAyahs - 1;
    return end
        .clamp(quickPlan.startGlobalAyahIndex, quickPlan.endGlobalAyahIndex)
        .toInt();
  }

  int _estimateMinutes({required int ayahsCount}) {
    return (ayahsCount * 2).clamp(8, 45).toInt();
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _taskKey(String planId) => '$_taskPrefix$planId';
}
