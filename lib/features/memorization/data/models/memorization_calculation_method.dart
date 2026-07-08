enum MemorizationCalculationMethod {
  smartSuggestion,
  dailyAmount,
  finishByDuration,
}

extension MemorizationCalculationMethodX on MemorizationCalculationMethod {
  String get title {
    switch (this) {
      case MemorizationCalculationMethod.smartSuggestion:
        return 'خطة مقترحة ذكية';
      case MemorizationCalculationMethod.dailyAmount:
        return 'مقدار يومي';
      case MemorizationCalculationMethod.finishByDuration:
        return 'موعد نهاية';
    }
  }

  String get subtitle {
    switch (this) {
      case MemorizationCalculationMethod.smartSuggestion:
        return 'التطبيق يختار مقدارًا مريحًا حسب نوع الرحلة والنطاق.';
      case MemorizationCalculationMethod.dailyAmount:
        return 'أنت تحدد مقدار الحفظ أو المراجعة اليومي.';
      case MemorizationCalculationMethod.finishByDuration:
        return 'أنت تحدد المدة، والتطبيق يحسب المطلوب يوميًا.';
    }
  }
}
