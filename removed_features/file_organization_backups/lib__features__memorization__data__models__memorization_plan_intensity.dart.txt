enum MemorizationPlanIntensity { normal, strong, intensive, extreme }

extension MemorizationPlanIntensityX on MemorizationPlanIntensity {
  String get code => name;

  String get title {
    switch (this) {
      case MemorizationPlanIntensity.normal:
        return 'عادي';
      case MemorizationPlanIntensity.strong:
        return 'قوي';
      case MemorizationPlanIntensity.intensive:
        return 'مكثف';
      case MemorizationPlanIntensity.extreme:
        return 'مكثف جدًا';
    }
  }

  int get maxLearningSessionsPerDay {
    switch (this) {
      case MemorizationPlanIntensity.normal:
        return 1;
      case MemorizationPlanIntensity.strong:
        return 2;
      case MemorizationPlanIntensity.intensive:
        return 3;
      case MemorizationPlanIntensity.extreme:
        return 4;
    }
  }

  int get maxTasksPerDay => maxLearningSessionsPerDay + 1;

  double get maxPagesPerLearningSession {
    switch (this) {
      case MemorizationPlanIntensity.normal:
        return 2;
      case MemorizationPlanIntensity.strong:
        return 4;
      case MemorizationPlanIntensity.intensive:
        return 8;
      case MemorizationPlanIntensity.extreme:
        return 16;
    }
  }

  static MemorizationPlanIntensity fromCode(String? value) {
    return MemorizationPlanIntensity.values.firstWhere(
      (item) => item.code == value,
      orElse: () => MemorizationPlanIntensity.normal,
    );
  }
}

class MemorizationPlanIntensityResolver {
  const MemorizationPlanIntensityResolver();

  MemorizationPlanIntensity resolve({
    required int totalPages,
    required int targetLearningDays,
  }) {
    final days = targetLearningDays <= 0 ? 1 : targetLearningDays;
    final pagesPerDay = totalPages <= 0 ? 0.0 : totalPages / days;

    if (pagesPerDay <= 2) return MemorizationPlanIntensity.normal;
    if (pagesPerDay <= 5) return MemorizationPlanIntensity.strong;
    if (pagesPerDay <= 15) return MemorizationPlanIntensity.intensive;
    return MemorizationPlanIntensity.extreme;
  }

  int learningSessionsCount({
    required int totalPages,
    required int targetLearningDays,
    required double requestedDailyPages,
    required MemorizationPlanIntensity intensity,
  }) {
    if (totalPages <= 0) return targetLearningDays.clamp(1, 99999).toInt();

    final sessionPages = requestedDailyPages
        .clamp(0.5, intensity.maxPagesPerLearningSession)
        .toDouble();

    final byLoad = (totalPages / sessionPages).ceil();
    final minimumForCapacity = (targetLearningDays <= 0)
        ? 1
        : (byLoad / intensity.maxLearningSessionsPerDay).ceil();

    if (minimumForCapacity > targetLearningDays) {
      return byLoad.clamp(1, 99999).toInt();
    }

    return byLoad.clamp(1, 99999).toInt();
  }

  String warningText({
    required int totalPages,
    required int targetLearningDays,
    required MemorizationPlanIntensity intensity,
  }) {
    if (intensity == MemorizationPlanIntensity.extreme) {
      final suggestedDays = (totalPages / 8).ceil().clamp(
        targetLearningDays + 1,
        3650,
      );
      return 'هذه خطة مكثفة جدًا وتحتاج خبرة وثباتًا عاليًا. '
          'للمبتدئ نوصي بمدة أقرب إلى $suggestedDays يومًا أو أكثر.';
    }

    if (intensity == MemorizationPlanIntensity.intensive) {
      return 'الخطة مكثفة وستحتوي بعض الأيام على أكثر من جلسة حفظ.';
    }

    return '';
  }
}
