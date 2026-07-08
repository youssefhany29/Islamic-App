enum MemorizationUserType {
  beginner,
  returning,
  strong,
}

extension MemorizationUserTypeX on MemorizationUserType {
  String get title {
    switch (this) {
      case MemorizationUserType.beginner:
        return 'أبدأ الحفظ لأول مرة';
      case MemorizationUserType.returning:
        return 'حافظ وناسي';
      case MemorizationUserType.strong:
        return 'حافظ قوي';
    }
  }

  String get subtitle {
    switch (this) {
      case MemorizationUserType.beginner:
        return 'أنا لسه هبدأ وعايز التطبيق يمشيني خطوة خطوة.';
      case MemorizationUserType.returning:
        return 'حافظ قبل كده؟ هنبدأ بتثبيت هادي من غير حفظ جديد في الأول.';
      case MemorizationUserType.strong:
        return 'أنا حافظ وعايز أحافظ على مستوايا وأراجع بذكاء.';
    }
  }

  String get shortLabel {
    switch (this) {
      case MemorizationUserType.beginner:
        return 'بداية';
      case MemorizationUserType.returning:
        return 'استرجاع';
      case MemorizationUserType.strong:
        return 'محافظة';
    }
  }
}
