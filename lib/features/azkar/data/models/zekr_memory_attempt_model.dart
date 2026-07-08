enum ZekrMemoryRating { mastered, partial, review }

enum ZekrPracticeMode { read, train, test }

extension ZekrMemoryRatingX on ZekrMemoryRating {
  String get label {
    switch (this) {
      case ZekrMemoryRating.mastered:
        return 'حفظته تمام';
      case ZekrMemoryRating.partial:
        return 'نص نص';
      case ZekrMemoryRating.review:
        return 'محتاج مراجعة';
    }
  }

  int get score {
    switch (this) {
      case ZekrMemoryRating.mastered:
        return 100;
      case ZekrMemoryRating.partial:
        return 60;
      case ZekrMemoryRating.review:
        return 25;
    }
  }

  bool get needsReview => this != ZekrMemoryRating.mastered;
}

extension ZekrPracticeModeX on ZekrPracticeMode {
  String get label {
    switch (this) {
      case ZekrPracticeMode.read:
        return 'قراءة';
      case ZekrPracticeMode.train:
        return 'تدريب';
      case ZekrPracticeMode.test:
        return 'اختبار';
    }
  }

  double get learningWeight {
    switch (this) {
      case ZekrPracticeMode.read:
        return 0.85;
      case ZekrPracticeMode.train:
        return 1.0;
      case ZekrPracticeMode.test:
        return 1.15;
    }
  }
}

class ZekrMemoryAttemptModel {
  const ZekrMemoryAttemptModel({
    required this.id,
    required this.itemId,
    required this.categoryId,
    required this.itemTitle,
    required this.categoryTitle,
    required this.rating,
    required this.createdAt,
    required this.repetitionCount,
    this.practiceMode = ZekrPracticeMode.test,
    this.previousStrength,
    this.newStrength,
    this.nextReviewAt,
  });

  final String id;
  final String itemId;
  final String categoryId;
  final String itemTitle;
  final String categoryTitle;
  final ZekrMemoryRating rating;
  final DateTime createdAt;
  final int repetitionCount;

  /// القراءة أقل وزنًا من التدريب، والاختبار أقوى مؤشر على الحفظ.
  final ZekrPracticeMode practiceMode;

  /// القيم دي بتتسجل بعد تحديث حالة الذكر؛ مفيدة للشارت والتحليل الشهري.
  final double? previousStrength;
  final double? newStrength;
  final DateTime? nextReviewAt;

  bool get needsReview => rating.needsReview;

  ZekrMemoryAttemptModel copyWith({
    String? id,
    String? itemId,
    String? categoryId,
    String? itemTitle,
    String? categoryTitle,
    ZekrMemoryRating? rating,
    DateTime? createdAt,
    int? repetitionCount,
    ZekrPracticeMode? practiceMode,
    double? previousStrength,
    double? newStrength,
    DateTime? nextReviewAt,
  }) {
    return ZekrMemoryAttemptModel(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      categoryId: categoryId ?? this.categoryId,
      itemTitle: itemTitle ?? this.itemTitle,
      categoryTitle: categoryTitle ?? this.categoryTitle,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      repetitionCount: repetitionCount ?? this.repetitionCount,
      practiceMode: practiceMode ?? this.practiceMode,
      previousStrength: previousStrength ?? this.previousStrength,
      newStrength: newStrength ?? this.newStrength,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'categoryId': categoryId,
      'itemTitle': itemTitle,
      'categoryTitle': categoryTitle,
      'rating': rating.name,
      'createdAt': createdAt.toIso8601String(),
      'repetitionCount': repetitionCount,
      'practiceMode': practiceMode.name,
      'previousStrength': previousStrength,
      'newStrength': newStrength,
      'nextReviewAt': nextReviewAt?.toIso8601String(),
    };
  }

  factory ZekrMemoryAttemptModel.fromJson(Map<String, dynamic> json) {
    final rawRating = json['rating'] as String? ?? ZekrMemoryRating.review.name;
    final rawMode =
        json['practiceMode'] as String? ?? ZekrPracticeMode.test.name;

    return ZekrMemoryAttemptModel(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      categoryId: json['categoryId'] as String,
      itemTitle: json['itemTitle'] as String,
      categoryTitle: json['categoryTitle'] as String,
      rating: ZekrMemoryRating.values.firstWhere(
        (item) => item.name == rawRating,
        orElse: () => ZekrMemoryRating.review,
      ),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      repetitionCount: json['repetitionCount'] as int? ?? 0,
      practiceMode: ZekrPracticeMode.values.firstWhere(
        (item) => item.name == rawMode,
        orElse: () => ZekrPracticeMode.test,
      ),
      previousStrength: (json['previousStrength'] as num?)?.toDouble(),
      newStrength: (json['newStrength'] as num?)?.toDouble(),
      nextReviewAt: DateTime.tryParse(json['nextReviewAt'] as String? ?? ''),
    );
  }
}
