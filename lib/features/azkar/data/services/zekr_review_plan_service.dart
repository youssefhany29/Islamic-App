import '../models/zekr_memory_attempt_model.dart';
import '../models/zekr_memory_item_state_model.dart';

class ZekrReviewPlanService {
  const ZekrReviewPlanService();

  double calculateNewStrength({
    required double oldStrength,
    required ZekrMemoryRating rating,
    required ZekrPracticeMode practiceMode,
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
    required ZekrMemoryRating rating,
    required int consecutiveMastered,
    required double memoryStrength,
  }) {
    int days;

    switch (rating) {
      case ZekrMemoryRating.review:
        days = 1;
        break;
      case ZekrMemoryRating.partial:
        days = memoryStrength >= 65 ? 2 : 1;
        break;
      case ZekrMemoryRating.mastered:
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

  ZekrMemoryLevel calculateLevel({
    required double memoryStrength,
    required ZekrMemoryRating lastRating,
    required int attemptsCount,
    required int consecutiveMastered,
  }) {
    if (attemptsCount == 0) return ZekrMemoryLevel.fresh;

    if (lastRating == ZekrMemoryRating.review || memoryStrength < 45) {
      return ZekrMemoryLevel.needsReview;
    }

    if (memoryStrength < 70) {
      return ZekrMemoryLevel.stabilizing;
    }

    if (memoryStrength >= 88 && consecutiveMastered >= 3) {
      return ZekrMemoryLevel.strong;
    }

    return ZekrMemoryLevel.memorized;
  }

  ZekrMemoryItemStateModel updateState({
    required ZekrMemoryItemStateModel? oldState,
    required ZekrMemoryAttemptModel attempt,
  }) {
    final now = attempt.createdAt;
    final oldStrength = oldState?.memoryStrength ?? 0;

    final newStrength = calculateNewStrength(
      oldStrength: oldStrength,
      rating: attempt.rating,
      practiceMode: attempt.practiceMode,
    );

    final consecutiveMastered = attempt.rating == ZekrMemoryRating.mastered
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
        (attempt.rating == ZekrMemoryRating.mastered ? 1 : 0);
    final partialCount =
        (oldState?.partialCount ?? 0) +
        (attempt.rating == ZekrMemoryRating.partial ? 1 : 0);
    final reviewCount =
        (oldState?.reviewCount ?? 0) +
        (attempt.rating == ZekrMemoryRating.review ? 1 : 0);

    final currentStreak = attempt.rating == ZekrMemoryRating.mastered
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

    return ZekrMemoryItemStateModel(
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
