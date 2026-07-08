import '../models/hadith_memory_attempt_model.dart';
import '../models/hadith_memory_item_state_model.dart';

class HadithReviewPlanService {
  const HadithReviewPlanService();

  double calculateNewStrength({
    required double oldStrength,
    required HadithMemoryRating rating,
    required HadithPracticeMode practiceMode,
  }) {
    final weightedScore = (rating.score * practiceMode.learningWeight)
        .clamp(0, 100)
        .toDouble();

    final newStrength = oldStrength <= 0
        ? weightedScore
        : (oldStrength * 0.70) + (weightedScore * 0.30);

    return newStrength.clamp(0, 100);
  }

  DateTime calculateNextReviewDate({
    required DateTime from,
    required HadithMemoryRating rating,
    required int consecutiveMastered,
    required double memoryStrength,
  }) {
    int days;

    switch (rating) {
      case HadithMemoryRating.review:
        days = 1;
        break;
      case HadithMemoryRating.partial:
        days = memoryStrength >= 65 ? 2 : 1;
        break;
      case HadithMemoryRating.mastered:
        if (consecutiveMastered >= 4 && memoryStrength >= 90) {
          days = 21;
        } else if (consecutiveMastered >= 3 && memoryStrength >= 82) {
          days = 14;
        } else if (consecutiveMastered >= 2 && memoryStrength >= 72) {
          days = 7;
        } else {
          days = 4;
        }
        break;
    }

    final base = DateTime(from.year, from.month, from.day);
    return base.add(Duration(days: days));
  }

  HadithMemoryLevel calculateLevel({
    required double memoryStrength,
    required HadithMemoryRating lastRating,
    required int attemptsCount,
    required int consecutiveMastered,
  }) {
    if (attemptsCount == 0) return HadithMemoryLevel.fresh;

    if (lastRating == HadithMemoryRating.review || memoryStrength < 45) {
      return HadithMemoryLevel.needsReview;
    }

    if (memoryStrength < 70) {
      return HadithMemoryLevel.stabilizing;
    }

    if (memoryStrength >= 88 && consecutiveMastered >= 3) {
      return HadithMemoryLevel.strong;
    }

    return HadithMemoryLevel.memorized;
  }

  HadithMemoryItemStateModel updateState({
    required HadithMemoryItemStateModel? oldState,
    required HadithMemoryAttemptModel attempt,
  }) {
    final now = attempt.createdAt;
    final oldStrength = oldState?.memoryStrength ?? 0;

    final newStrength = calculateNewStrength(
      oldStrength: oldStrength,
      rating: attempt.rating,
      practiceMode: attempt.practiceMode,
    );

    final consecutiveMastered = attempt.rating == HadithMemoryRating.mastered
        ? (oldState?.consecutiveMastered ?? 0) + 1
        : 0;

    final nextReviewAt = calculateNextReviewDate(
      from: now,
      rating: attempt.rating,
      consecutiveMastered: consecutiveMastered,
      memoryStrength: newStrength,
    );

    final attemptsCount = (oldState?.attemptsCount ?? 0) + 1;
    final masteredCount =
        (oldState?.masteredCount ?? 0) +
        (attempt.rating == HadithMemoryRating.mastered ? 1 : 0);
    final partialCount =
        (oldState?.partialCount ?? 0) +
        (attempt.rating == HadithMemoryRating.partial ? 1 : 0);
    final reviewCount =
        (oldState?.reviewCount ?? 0) +
        (attempt.rating == HadithMemoryRating.review ? 1 : 0);

    final currentStreak = attempt.rating == HadithMemoryRating.mastered
        ? (oldState?.currentStreak ?? 0) + 1
        : 0;

    final bestStreak = currentStreak > (oldState?.bestStreak ?? 0)
        ? currentStreak
        : (oldState?.bestStreak ?? 0);

    final level = calculateLevel(
      memoryStrength: newStrength,
      lastRating: attempt.rating,
      attemptsCount: attemptsCount,
      consecutiveMastered: consecutiveMastered,
    );

    return HadithMemoryItemStateModel(
      itemId: attempt.itemId,
      categoryId: attempt.categoryId,
      itemTitle: attempt.itemTitle,
      categoryTitle: attempt.categoryTitle,
      memoryStrength: newStrength,
      attemptsCount: attemptsCount,
      masteredCount: masteredCount,
      partialCount: partialCount,
      reviewCount: reviewCount,
      consecutiveMastered: consecutiveMastered,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      lastRating: attempt.rating,
      lastReviewedAt: now,
      nextReviewAt: nextReviewAt,
      level: level,
      createdAt: oldState?.createdAt ?? now,
      updatedAt: now,
    );
  }
}
