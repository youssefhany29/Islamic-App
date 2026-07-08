import 'zekr_memory_attempt_model.dart';

enum ZekrMemoryLevel { fresh, needsReview, stabilizing, memorized, strong }

extension ZekrMemoryLevelX on ZekrMemoryLevel {
  String get label {
    switch (this) {
      case ZekrMemoryLevel.fresh:
        return 'جديد';
      case ZekrMemoryLevel.needsReview:
        return 'يحتاج مراجعة';
      case ZekrMemoryLevel.stabilizing:
        return 'قيد التثبيت';
      case ZekrMemoryLevel.memorized:
        return 'محفوظ';
      case ZekrMemoryLevel.strong:
        return 'محفوظ بثبات';
    }
  }
}

class ZekrMemoryItemStateModel {
  const ZekrMemoryItemStateModel({
    required this.itemId,
    required this.categoryId,
    required this.itemTitle,
    required this.categoryTitle,
    required this.memoryStrength,
    required this.attemptsCount,
    required this.masteredCount,
    required this.partialCount,
    required this.reviewCount,
    required this.consecutiveMastered,
    required this.currentStreak,
    required this.bestStreak,
    required this.lastRating,
    required this.lastReviewedAt,
    required this.nextReviewAt,
    required this.level,
    required this.createdAt,
    required this.updatedAt,
  });

  final String itemId;
  final String categoryId;
  final String itemTitle;
  final String categoryTitle;
  final double memoryStrength;
  final int attemptsCount;
  final int masteredCount;
  final int partialCount;
  final int reviewCount;
  final int consecutiveMastered;
  final int currentStreak;
  final int bestStreak;
  final ZekrMemoryRating lastRating;
  final DateTime lastReviewedAt;
  final DateTime nextReviewAt;
  final ZekrMemoryLevel level;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isDueToday {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dueOnly = DateTime(
      nextReviewAt.year,
      nextReviewAt.month,
      nextReviewAt.day,
    );
    return !dueOnly.isAfter(todayOnly);
  }

  int get daysUntilReview {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dueOnly = DateTime(
      nextReviewAt.year,
      nextReviewAt.month,
      nextReviewAt.day,
    );
    return dueOnly.difference(todayOnly).inDays;
  }

  String get reviewDateText {
    final days = daysUntilReview;
    if (days < 0) return 'متأخر ${days.abs()} يوم';
    if (days == 0) return 'اليوم';
    if (days == 1) return 'غدًا';
    if (days == 2) return 'بعد يومين';
    return 'بعد $days أيام';
  }

  ZekrMemoryItemStateModel copyWith({
    String? itemId,
    String? categoryId,
    String? itemTitle,
    String? categoryTitle,
    double? memoryStrength,
    int? attemptsCount,
    int? masteredCount,
    int? partialCount,
    int? reviewCount,
    int? consecutiveMastered,
    int? currentStreak,
    int? bestStreak,
    ZekrMemoryRating? lastRating,
    DateTime? lastReviewedAt,
    DateTime? nextReviewAt,
    ZekrMemoryLevel? level,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ZekrMemoryItemStateModel(
      itemId: itemId ?? this.itemId,
      categoryId: categoryId ?? this.categoryId,
      itemTitle: itemTitle ?? this.itemTitle,
      categoryTitle: categoryTitle ?? this.categoryTitle,
      memoryStrength: memoryStrength ?? this.memoryStrength,
      attemptsCount: attemptsCount ?? this.attemptsCount,
      masteredCount: masteredCount ?? this.masteredCount,
      partialCount: partialCount ?? this.partialCount,
      reviewCount: reviewCount ?? this.reviewCount,
      consecutiveMastered: consecutiveMastered ?? this.consecutiveMastered,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastRating: lastRating ?? this.lastRating,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      level: level ?? this.level,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'categoryId': categoryId,
      'itemTitle': itemTitle,
      'categoryTitle': categoryTitle,
      'memoryStrength': memoryStrength,
      'attemptsCount': attemptsCount,
      'masteredCount': masteredCount,
      'partialCount': partialCount,
      'reviewCount': reviewCount,
      'consecutiveMastered': consecutiveMastered,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'lastRating': lastRating.name,
      'lastReviewedAt': lastReviewedAt.toIso8601String(),
      'nextReviewAt': nextReviewAt.toIso8601String(),
      'level': level.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ZekrMemoryItemStateModel.fromJson(Map<String, dynamic> json) {
    final rawRating =
        json['lastRating'] as String? ?? ZekrMemoryRating.review.name;
    final rawLevel = json['level'] as String? ?? ZekrMemoryLevel.fresh.name;
    final now = DateTime.now();

    return ZekrMemoryItemStateModel(
      itemId: json['itemId'] as String,
      categoryId: json['categoryId'] as String,
      itemTitle: json['itemTitle'] as String,
      categoryTitle: json['categoryTitle'] as String,
      memoryStrength: (json['memoryStrength'] as num?)?.toDouble() ?? 0,
      attemptsCount: json['attemptsCount'] as int? ?? 0,
      masteredCount: json['masteredCount'] as int? ?? 0,
      partialCount: json['partialCount'] as int? ?? 0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      consecutiveMastered: json['consecutiveMastered'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
      lastRating: ZekrMemoryRating.values.firstWhere(
        (item) => item.name == rawRating,
        orElse: () => ZekrMemoryRating.review,
      ),
      lastReviewedAt:
          DateTime.tryParse(json['lastReviewedAt'] as String? ?? '') ?? now,
      nextReviewAt:
          DateTime.tryParse(json['nextReviewAt'] as String? ?? '') ?? now,
      level: ZekrMemoryLevel.values.firstWhere(
        (item) => item.name == rawLevel,
        orElse: () => ZekrMemoryLevel.fresh,
      ),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? now,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? now,
    );
  }
}
