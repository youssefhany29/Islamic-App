enum HadithMemoryRating { mastered, partial, review }

enum HadithPracticeMode { read, train, test }

extension HadithMemoryRatingX on HadithMemoryRating {
  String get label {
    switch (this) {
      case HadithMemoryRating.mastered:
        return 'حفظته تمام';
      case HadithMemoryRating.partial:
        return 'نص نص';
      case HadithMemoryRating.review:
        return 'محتاج مراجعة';
    }
  }

  int get score {
    switch (this) {
      case HadithMemoryRating.mastered:
        return 100;
      case HadithMemoryRating.partial:
        return 60;
      case HadithMemoryRating.review:
        return 25;
    }
  }

  bool get needsReview => this != HadithMemoryRating.mastered;
}

extension HadithPracticeModeX on HadithPracticeMode {
  String get label {
    switch (this) {
      case HadithPracticeMode.read:
        return 'قراءة';
      case HadithPracticeMode.train:
        return 'تدريب';
      case HadithPracticeMode.test:
        return 'اختبار';
    }
  }

  double get learningWeight {
    switch (this) {
      case HadithPracticeMode.read:
        return 0.85;
      case HadithPracticeMode.train:
        return 1.0;
      case HadithPracticeMode.test:
        return 1.15;
    }
  }
}

class HadithMemoryAttemptModel {
  const HadithMemoryAttemptModel({
    required this.id,
    required this.itemId,
    required this.categoryId,
    required this.itemTitle,
    required this.categoryTitle,
    required this.rating,
    required this.createdAt,
    required this.repetitionCount,
    this.practiceMode = HadithPracticeMode.test,
    this.previousStrength,
    this.newStrength,
    this.nextReviewAt,
  });

  final String id;
  final String itemId;
  final String categoryId;
  final String itemTitle;
  final String categoryTitle;
  final HadithMemoryRating rating;
  final DateTime createdAt;
  final int repetitionCount;

  /// القراءة أقل وزنًا من التدريب، والاختبار أقوى مؤشر على الحفظ.
  final HadithPracticeMode practiceMode;

  /// القيم دي بتتسجل بعد تحديث حالة الحديث؛ مفيدة للشارت والتحليل الشهري.
  final double? previousStrength;
  final double? newStrength;
  final DateTime? nextReviewAt;

  bool get needsReview => rating.needsReview;

  HadithMemoryAttemptModel copyWith({
    String? id,
    String? itemId,
    String? categoryId,
    String? itemTitle,
    String? categoryTitle,
    HadithMemoryRating? rating,
    DateTime? createdAt,
    int? repetitionCount,
    HadithPracticeMode? practiceMode,
    double? previousStrength,
    double? newStrength,
    DateTime? nextReviewAt,
  }) {
    return HadithMemoryAttemptModel(
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

  factory HadithMemoryAttemptModel.fromJson(Map<String, dynamic> json) {
    final rawRating =
        json['rating'] as String? ?? HadithMemoryRating.review.name;
    final rawMode =
        json['practiceMode'] as String? ?? HadithPracticeMode.test.name;

    return HadithMemoryAttemptModel(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      categoryId: json['categoryId'] as String,
      itemTitle: json['itemTitle'] as String,
      categoryTitle: json['categoryTitle'] as String,
      rating: HadithMemoryRating.values.firstWhere(
        (item) => item.name == rawRating,
        orElse: () => HadithMemoryRating.review,
      ),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      repetitionCount: json['repetitionCount'] as int? ?? 0,
      practiceMode: HadithPracticeMode.values.firstWhere(
        (item) => item.name == rawMode,
        orElse: () => HadithPracticeMode.test,
      ),
      previousStrength: (json['previousStrength'] as num?)?.toDouble(),
      newStrength: (json['newStrength'] as num?)?.toDouble(),
      nextReviewAt: DateTime.tryParse(json['nextReviewAt'] as String? ?? ''),
    );
  }
}
