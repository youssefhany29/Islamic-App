import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/hadith_memory_attempt_model.dart';
import '../models/hadith_memory_item_state_model.dart';
import 'hadith_review_plan_service.dart';

class HadithMemoryProgressService {
  const HadithMemoryProgressService();

  static const String _attemptsKey = 'hadith_memory_attempts';
  static const String _statesKey = 'hadith_memory_item_states';

  HadithMemoryItemStateModel _normalizeUpdatedState({
    required HadithMemoryItemStateModel? oldState,
    required HadithMemoryAttemptModel attempt,
    required HadithMemoryItemStateModel plannedState,
  }) {
    final bool isFirstAttempt = oldState == null || oldState.attemptsCount == 0;

    double strength = plannedState.memoryStrength;

    if (isFirstAttempt) {
      strength = attempt.rating.score.toDouble();
    } else if (attempt.rating == HadithMemoryRating.mastered &&
        strength < oldState.memoryStrength) {
      strength = oldState.memoryStrength;
    }

    strength = strength.clamp(0, 100).toDouble();

    final int consecutiveMastered =
        attempt.rating == HadithMemoryRating.mastered
        ? (oldState?.consecutiveMastered ?? 0) + 1
        : 0;

    final HadithMemoryLevel level = _levelForState(
      strength: strength,
      rating: attempt.rating,
      consecutiveMastered: consecutiveMastered,
    );

    return plannedState.copyWith(
      memoryStrength: strength,
      consecutiveMastered: consecutiveMastered,
      level: level,
    );
  }

  HadithMemoryLevel _levelForState({
    required double strength,
    required HadithMemoryRating rating,
    required int consecutiveMastered,
  }) {
    if (rating == HadithMemoryRating.review) {
      return HadithMemoryLevel.needsReview;
    }

    if (rating == HadithMemoryRating.partial) {
      return strength >= 70
          ? HadithMemoryLevel.stabilizing
          : HadithMemoryLevel.needsReview;
    }

    if (consecutiveMastered >= 3 || strength >= 95) {
      return HadithMemoryLevel.strong;
    }

    if (strength >= 80) {
      return HadithMemoryLevel.memorized;
    }

    return HadithMemoryLevel.stabilizing;
  }

  bool _isWeakState(HadithMemoryItemStateModel item) {
    if (item.attemptsCount <= 0) return false;

    final bool masteredAndStrong =
        item.lastRating == HadithMemoryRating.mastered &&
        item.memoryStrength >= 80;

    if (masteredAndStrong) return false;

    return item.level == HadithMemoryLevel.needsReview ||
        item.lastRating == HadithMemoryRating.review ||
        item.reviewCount > 0 ||
        item.memoryStrength < 60;
  }

  bool _isStrongState(HadithMemoryItemStateModel item) {
    if (item.attemptsCount <= 0) return false;

    return item.lastRating == HadithMemoryRating.mastered &&
        item.memoryStrength >= 80;
  }

  Future<List<HadithMemoryAttemptModel>> getAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final rawData = prefs.getString(_attemptsKey);

    if (rawData == null || rawData.trim().isEmpty) return [];

    final decoded = jsonDecode(rawData) as List<dynamic>;

    return decoded
        .map(
          (item) =>
              HadithMemoryAttemptModel.fromJson(item as Map<String, dynamic>),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<Map<String, HadithMemoryItemStateModel>> getStateMap() async {
    final prefs = await SharedPreferences.getInstance();
    final rawData = prefs.getString(_statesKey);

    if (rawData == null || rawData.trim().isEmpty) return {};

    final decoded = jsonDecode(rawData) as Map<String, dynamic>;

    return decoded.map(
      (key, value) => MapEntry(
        key,
        HadithMemoryItemStateModel.fromJson(value as Map<String, dynamic>),
      ),
    );
  }

  Future<List<HadithMemoryItemStateModel>> getItemStates() async {
    final stateMap = await getStateMap();
    final states = stateMap.values.toList()
      ..sort((a, b) {
        if (a.isDueToday != b.isDueToday) return a.isDueToday ? -1 : 1;
        final strengthCompare = a.memoryStrength.compareTo(b.memoryStrength);
        if (strengthCompare != 0) return strengthCompare;
        return a.nextReviewAt.compareTo(b.nextReviewAt);
      });

    return states;
  }

  Future<void> _saveAttempts(List<HadithMemoryAttemptModel> attempts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _attemptsKey,
      jsonEncode(attempts.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> _saveStateMap(
    Map<String, HadithMemoryItemStateModel> states,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _statesKey,
      jsonEncode(states.map((key, value) => MapEntry(key, value.toJson()))),
    );
  }

  Future<HadithMemoryAttemptModel> saveAttempt(
    HadithMemoryAttemptModel attempt,
  ) async {
    final attempts = await getAttempts();
    final states = await getStateMap();

    final oldState = states[attempt.itemId];
    final plannedState = const HadithReviewPlanService().updateState(
      oldState: oldState,
      attempt: attempt,
    );

    final updatedState = _normalizeUpdatedState(
      oldState: oldState,
      attempt: attempt,
      plannedState: plannedState,
    );

    final enrichedAttempt = attempt.copyWith(
      previousStrength: oldState?.memoryStrength ?? 0,
      newStrength: updatedState.memoryStrength,
      nextReviewAt: updatedState.nextReviewAt,
    );

    states[attempt.itemId] = updatedState;

    final updatedAttempts = [enrichedAttempt, ...attempts];

    await _saveStateMap(states);
    await _saveAttempts(updatedAttempts);

    return enrichedAttempt;
  }

  Future<List<HadithMemoryItemStateModel>> getDueReviews({
    DateTime? date,
  }) async {
    final target = date ?? DateTime.now();
    final targetOnly = DateTime(target.year, target.month, target.day);
    final states = await getItemStates();

    return states.where((state) {
      final dueOnly = DateTime(
        state.nextReviewAt.year,
        state.nextReviewAt.month,
        state.nextReviewAt.day,
      );
      return !dueOnly.isAfter(targetOnly);
    }).toList()..sort((a, b) => a.memoryStrength.compareTo(b.memoryStrength));
  }

  Future<HadithMemoryDashboardStats> getDashboardStats() async {
    final attempts = await getAttempts();
    final states = await getItemStates();

    if (states.isEmpty) {
      return HadithMemoryDashboardStats.empty(attempts: attempts);
    }

    final dueReviews = await getDueReviews();

    final mastered = states
        .where(
          (item) =>
              item.level == HadithMemoryLevel.memorized ||
              item.level == HadithMemoryLevel.strong,
        )
        .length;
    final strong = states
        .where((item) => item.level == HadithMemoryLevel.strong)
        .length;
    final stabilizing = states
        .where((item) => item.level == HadithMemoryLevel.stabilizing)
        .length;
    final needsReview = states
        .where((item) => item.level == HadithMemoryLevel.needsReview)
        .length;

    final averageStrength =
        states.fold<double>(0, (sum, item) => sum + item.memoryStrength) /
        states.length;

    final weakest = states.where(_isWeakState).toList()
      ..sort((a, b) {
        final strength = a.memoryStrength.compareTo(b.memoryStrength);
        if (strength != 0) return strength;
        return b.reviewCount.compareTo(a.reviewCount);
      });

    final strongest = states.where(_isStrongState).toList()
      ..sort((a, b) {
        final strength = b.memoryStrength.compareTo(a.memoryStrength);
        if (strength != 0) return strength;
        return b.consecutiveMastered.compareTo(a.consecutiveMastered);
      });

    final categoryStats = _buildCategoryStats(states);
    final monthlyPoints = _buildMonthlyPoints(attempts);

    return HadithMemoryDashboardStats(
      totalTrackedItems: states.length,
      averageStrength: averageStrength,
      masteredItems: mastered,
      strongItems: strong,
      stabilizingItems: stabilizing,
      needsReviewItems: needsReview,
      dueReviewItems: dueReviews.length,
      allStates: states,
      dueReviews: dueReviews.take(8).toList(),
      weakestItems: weakest.take(8).toList(),
      strongestItems: strongest.take(8).toList(),
      recentAttempts: attempts.take(10).toList(),
      monthlyPoints: monthlyPoints,
      categoryStats: categoryStats,
    );
  }

  List<HadithCategoryMemoryStats> _buildCategoryStats(
    List<HadithMemoryItemStateModel> states,
  ) {
    final grouped = <String, List<HadithMemoryItemStateModel>>{};

    for (final state in states) {
      grouped.putIfAbsent(state.categoryId, () => []).add(state);
    }

    final result = grouped.entries.map((entry) {
      final items = entry.value;
      final average =
          items.fold<double>(0, (sum, item) => sum + item.memoryStrength) /
          items.length;
      final due = items.where((item) => item.isDueToday).length;

      return HadithCategoryMemoryStats(
        categoryId: entry.key,
        categoryTitle: items.first.categoryTitle,
        itemsCount: items.length,
        averageStrength: average,
        dueCount: due,
      );
    }).toList()..sort((a, b) => a.averageStrength.compareTo(b.averageStrength));

    return result;
  }

  List<HadithMemoryMonthlyPoint> _buildMonthlyPoints(
    List<HadithMemoryAttemptModel> attempts,
  ) {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 29));
    final points = <HadithMemoryMonthlyPoint>[];

    for (int i = 0; i < 30; i++) {
      final day = start.add(Duration(days: i));
      final dayAttempts = attempts
          .where((attempt) => _isSameDay(attempt.createdAt, day))
          .toList();

      final averageRating = dayAttempts.isEmpty
          ? 0.0
          : dayAttempts.fold<double>(
                  0,
                  (sum, item) => sum + item.rating.score,
                ) /
                dayAttempts.length;

      final strengthAttempts = dayAttempts
          .where((attempt) => attempt.newStrength != null)
          .toList();
      final averageStrength = strengthAttempts.isEmpty
          ? 0.0
          : strengthAttempts.fold<double>(
                  0,
                  (sum, item) => sum + (item.newStrength ?? 0),
                ) /
                strengthAttempts.length;

      points.add(
        HadithMemoryMonthlyPoint(
          date: day,
          attemptsCount: dayAttempts.length,
          masteredCount: dayAttempts
              .where((item) => item.rating == HadithMemoryRating.mastered)
              .length,
          partialCount: dayAttempts
              .where((item) => item.rating == HadithMemoryRating.partial)
              .length,
          reviewCount: dayAttempts
              .where((item) => item.rating == HadithMemoryRating.review)
              .length,
          averageRatingScore: averageRating,
          averageStrength: averageStrength,
        ),
      );
    }

    return points;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> rebuildStatesFromAttempts() async {
    final attempts = await getAttempts();
    final orderedAttempts = [...attempts]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final states = <String, HadithMemoryItemStateModel>{};
    final enrichedAttempts = <HadithMemoryAttemptModel>[];
    final planner = const HadithReviewPlanService();

    for (final attempt in orderedAttempts) {
      final oldState = states[attempt.itemId];
      final plannedState = planner.updateState(
        oldState: oldState,
        attempt: attempt,
      );
      final updatedState = _normalizeUpdatedState(
        oldState: oldState,
        attempt: attempt,
        plannedState: plannedState,
      );
      states[attempt.itemId] = updatedState;

      enrichedAttempts.add(
        attempt.copyWith(
          previousStrength: oldState?.memoryStrength ?? 0,
          newStrength: updatedState.memoryStrength,
          nextReviewAt: updatedState.nextReviewAt,
        ),
      );
    }

    await _saveStateMap(states);
    await _saveAttempts(
      enrichedAttempts..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_attemptsKey);
    await prefs.remove(_statesKey);
  }
}

class HadithMemoryDashboardStats {
  const HadithMemoryDashboardStats({
    required this.totalTrackedItems,
    required this.averageStrength,
    required this.masteredItems,
    required this.strongItems,
    required this.stabilizingItems,
    required this.needsReviewItems,
    required this.dueReviewItems,
    required this.allStates,
    required this.dueReviews,
    required this.weakestItems,
    required this.strongestItems,
    required this.recentAttempts,
    required this.monthlyPoints,
    required this.categoryStats,
  });

  factory HadithMemoryDashboardStats.empty({
    List<HadithMemoryAttemptModel> attempts = const [],
  }) {
    return HadithMemoryDashboardStats(
      totalTrackedItems: 0,
      averageStrength: 0,
      masteredItems: 0,
      strongItems: 0,
      stabilizingItems: 0,
      needsReviewItems: 0,
      dueReviewItems: 0,
      allStates: const [],
      dueReviews: const [],
      weakestItems: const [],
      strongestItems: const [],
      recentAttempts: attempts.take(10).toList(),
      monthlyPoints: const [],
      categoryStats: const [],
    );
  }

  final int totalTrackedItems;
  final double averageStrength;
  final int masteredItems;
  final int strongItems;
  final int stabilizingItems;
  final int needsReviewItems;
  final int dueReviewItems;
  final List<HadithMemoryItemStateModel> allStates;
  final List<HadithMemoryItemStateModel> dueReviews;
  final List<HadithMemoryItemStateModel> weakestItems;
  final List<HadithMemoryItemStateModel> strongestItems;
  final List<HadithMemoryAttemptModel> recentAttempts;
  final List<HadithMemoryMonthlyPoint> monthlyPoints;
  final List<HadithCategoryMemoryStats> categoryStats;

  int get activeDaysThisMonth {
    return monthlyPoints.where((point) => point.attemptsCount > 0).length;
  }

  int get totalAttemptsThisMonth {
    return monthlyPoints.fold<int>(
      0,
      (sum, point) => sum + point.attemptsCount,
    );
  }

  double get maxMonthlyAttempts {
    if (monthlyPoints.isEmpty) return 1;

    final int maxAttempts = monthlyPoints.fold<int>(
      0,
      (maxValue, point) =>
          point.attemptsCount > maxValue ? point.attemptsCount : maxValue,
    );

    if (maxAttempts <= 0) return 1;

    return (maxAttempts + 1).toDouble();
  }

  String get smartMessage {
    if (totalTrackedItems == 0) {
      return 'ابدأ بتقييم أول حديث، وبعدها هنبني لك تحليل حفظ دقيق.';
    }

    if (dueReviewItems > 0) {
      return 'عندك $dueReviewItems أحاديث مستحقة للمراجعة اليوم.';
    }

    if (needsReviewItems > 0) {
      return 'فيه $needsReviewItems أحاديث محتاجة تثبيت ومراجعة هادئة.';
    }

    if (stabilizingItems > 0) {
      return 'مستواك جيد، ركّز على الأحاديث قيد التثبيت.';
    }

    if (strongItems > 0 && averageStrength >= 75) {
      return 'ما شاء الله، حفظك ثابت. حافظ على مراجعة خفيفة يوميًا.';
    }

    return 'استمر في التقييم بعد كل مراجعة علشان التحليل يبقى أدق.';
  }

  String get recommendation {
    if (totalTrackedItems == 0) {
      return 'ابدأ بأول تقييم حفظ، وبعدها هنبني لك خطة مراجعة دقيقة.';
    }

    if (dueReviewItems > 0) {
      return 'ابدأ بمراجعة $dueReviewItems أحاديث مستحقة اليوم، ويفضل تستخدم وضع الاختبار.';
    }

    if (needsReviewItems > 0) {
      return 'عندك أحاديث محتاجة تثبيت، راجع أضعف 3 أحاديث فقط بدون ضغط.';
    }

    if (stabilizingItems > 0) {
      return 'مستواك جيد، ركّز على الأحاديث قيد التثبيت علشان تتحول لمحفوظة بثبات.';
    }

    return 'ما شاء الله، حافظ على مراجعة خفيفة يومية حتى يثبت الحفظ.';
  }

  String get recommendedAction => recommendation;
}

class HadithMemoryMonthlyPoint {
  const HadithMemoryMonthlyPoint({
    required this.date,
    required this.attemptsCount,
    required this.masteredCount,
    required this.partialCount,
    required this.reviewCount,
    required this.averageRatingScore,
    required this.averageStrength,
  });

  final DateTime date;
  final int attemptsCount;
  final int masteredCount;
  final int partialCount;
  final int reviewCount;
  final double averageRatingScore;
  final double averageStrength;

  String get dayLabel {
    return '${date.day}/${date.month}';
  }
}

class HadithCategoryMemoryStats {
  const HadithCategoryMemoryStats({
    required this.categoryId,
    required this.categoryTitle,
    required this.itemsCount,
    required this.averageStrength,
    required this.dueCount,
  });

  final String categoryId;
  final String categoryTitle;
  final int itemsCount;
  final double averageStrength;
  final int dueCount;
}
