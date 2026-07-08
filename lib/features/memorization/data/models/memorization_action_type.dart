enum MemorizationActionType {
  newMemorization,
  reviewOnly,
  newWithReview,
  strengthenAndTest,
}

extension MemorizationActionTypeX on MemorizationActionType {
  String get title {
    switch (this) {
      case MemorizationActionType.newMemorization:
        return 'حفظ جديد';
      case MemorizationActionType.reviewOnly:
        return 'مراجعة فقط';
      case MemorizationActionType.newWithReview:
        return 'حفظ + مراجعة';
      case MemorizationActionType.strengthenAndTest:
        return 'اختبار وتقوية';
    }
  }

  String get subtitle {
    switch (this) {
      case MemorizationActionType.newMemorization:
        return 'ابدأ حفظ مقطع جديد مع مراجعة تثبيت بسيطة.';
      case MemorizationActionType.reviewOnly:
        return 'راجع محفوظك بدون إضافة حفظ جديد الآن.';
      case MemorizationActionType.newWithReview:
        return 'أضف حفظًا بسيطًا مع ورد مراجعة يومي.';
      case MemorizationActionType.strengthenAndTest:
        return 'اختبر حفظك واكشف المواضع الضعيفة.';
    }
  }

  String get badge {
    switch (this) {
      case MemorizationActionType.newMemorization:
        return 'حفظ';
      case MemorizationActionType.reviewOnly:
        return 'تثبيت';
      case MemorizationActionType.newWithReview:
        return 'متوازن';
      case MemorizationActionType.strengthenAndTest:
        return 'اختبار';
    }
  }
}
