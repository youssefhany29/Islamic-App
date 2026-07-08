enum MemorizationTestKind {
  completeAyah,
  orderAyahs,
  hiddenAyahs,
  noTextRecitation,
  hiddenMushafRecitation,
  ayahStarts,
  fullPage,
  randomPassage,
}

extension MemorizationTestKindX on MemorizationTestKind {
  String get code {
    switch (this) {
      case MemorizationTestKind.completeAyah:
        return 'completeAyah';
      case MemorizationTestKind.orderAyahs:
        return 'orderAyahs';
      case MemorizationTestKind.hiddenAyahs:
        return 'hiddenAyahs';
      case MemorizationTestKind.noTextRecitation:
        return 'noTextRecitation';
      case MemorizationTestKind.hiddenMushafRecitation:
        return 'hiddenMushafRecitation';
      case MemorizationTestKind.ayahStarts:
        return 'ayahStarts';
      case MemorizationTestKind.fullPage:
        return 'fullPage';
      case MemorizationTestKind.randomPassage:
        return 'randomPassage';
    }
  }

  String get title {
    switch (this) {
      case MemorizationTestKind.completeAyah:
        return 'أكمل الآية';
      case MemorizationTestKind.orderAyahs:
        return 'ترتيب الآيات';
      case MemorizationTestKind.hiddenAyahs:
        return 'آيات مخفية';
      case MemorizationTestKind.noTextRecitation:
        return 'تسميع بدون نص';
      case MemorizationTestKind.hiddenMushafRecitation:
        return 'تسميع ذاتي';
      case MemorizationTestKind.ayahStarts:
        return 'بدايات الآيات';
      case MemorizationTestKind.fullPage:
        return 'صفحة كاملة';
      case MemorizationTestKind.randomPassage:
        return 'مقطع عشوائي';
    }
  }

  String get calendarSubtitle {
    switch (this) {
      case MemorizationTestKind.completeAyah:
        return 'اختبار إكمال من الذاكرة. يظهر الموضع عند فتح الاختبار.';
      case MemorizationTestKind.orderAyahs:
        return 'اختبار ترتيب وتسلسل. يظهر الموضع عند فتح الاختبار.';
      case MemorizationTestKind.hiddenAyahs:
        return 'اختبار حجب تدريجي. يظهر الموضع عند فتح الاختبار.';
      case MemorizationTestKind.noTextRecitation:
        return 'تسميع بدون نص. يظهر الموضع عند فتح الاختبار.';
      case MemorizationTestKind.hiddenMushafRecitation:
        return 'تُخفى آيات موضع الاختبار لتسمّع لنفسك ثم تقيّم أداءك.';
      case MemorizationTestKind.ayahStarts:
        return 'اختبار بدايات الآيات. يظهر الموضع عند فتح الاختبار.';
      case MemorizationTestKind.fullPage:
        return 'اختبار صفحة كاملة. يظهر الموضع عند فتح الاختبار.';
      case MemorizationTestKind.randomPassage:
        return 'اختبار مقطع عشوائي. يظهر الموضع عند فتح الاختبار.';
    }
  }

  static MemorizationTestKind fromCode(String? value) {
    switch (value) {
      case 'completeAyah':
        return MemorizationTestKind.completeAyah;
      case 'orderAyahs':
        return MemorizationTestKind.orderAyahs;
      case 'hiddenAyahs':
        return MemorizationTestKind.hiddenAyahs;
      case 'noTextRecitation':
        return MemorizationTestKind.noTextRecitation;
      case 'hiddenMushafRecitation':
        return MemorizationTestKind.hiddenMushafRecitation;
      case 'ayahStarts':
        return MemorizationTestKind.ayahStarts;
      case 'fullPage':
        return MemorizationTestKind.fullPage;
      case 'randomPassage':
        return MemorizationTestKind.randomPassage;
      default:
        return MemorizationTestKind.ayahStarts;
    }
  }
}

enum MemorizationTestDifficulty { easy, medium, hard }

extension MemorizationTestDifficultyX on MemorizationTestDifficulty {
  String get code {
    switch (this) {
      case MemorizationTestDifficulty.easy:
        return 'easy';
      case MemorizationTestDifficulty.medium:
        return 'medium';
      case MemorizationTestDifficulty.hard:
        return 'hard';
    }
  }

  String get title {
    switch (this) {
      case MemorizationTestDifficulty.easy:
        return 'سهل';
      case MemorizationTestDifficulty.medium:
        return 'متوسط';
      case MemorizationTestDifficulty.hard:
        return 'صعب';
    }
  }

  static MemorizationTestDifficulty fromCode(String? value) {
    switch (value) {
      case 'easy':
        return MemorizationTestDifficulty.easy;
      case 'hard':
        return MemorizationTestDifficulty.hard;
      case 'medium':
      default:
        return MemorizationTestDifficulty.medium;
    }
  }
}

enum MemorizationTestTrigger {
  strongHafizCadence,
  weeklyCheckpoint,
  monthlyCheckpoint,
  quarterCycle,
  halfCycle,
  threeQuarterCycle,
  endOfCycle,
  juzCheckpoint,
  fiveJuzCheckpoint,
  tenJuzCheckpoint,
  weakSpotRecovery,
  manual,
}

extension MemorizationTestTriggerX on MemorizationTestTrigger {
  String get code {
    switch (this) {
      case MemorizationTestTrigger.strongHafizCadence:
        return 'strongHafizCadence';
      case MemorizationTestTrigger.weeklyCheckpoint:
        return 'weeklyCheckpoint';
      case MemorizationTestTrigger.monthlyCheckpoint:
        return 'monthlyCheckpoint';
      case MemorizationTestTrigger.quarterCycle:
        return 'quarterCycle';
      case MemorizationTestTrigger.halfCycle:
        return 'halfCycle';
      case MemorizationTestTrigger.threeQuarterCycle:
        return 'threeQuarterCycle';
      case MemorizationTestTrigger.endOfCycle:
        return 'endOfCycle';
      case MemorizationTestTrigger.juzCheckpoint:
        return 'juzCheckpoint';
      case MemorizationTestTrigger.fiveJuzCheckpoint:
        return 'fiveJuzCheckpoint';
      case MemorizationTestTrigger.tenJuzCheckpoint:
        return 'tenJuzCheckpoint';
      case MemorizationTestTrigger.weakSpotRecovery:
        return 'weakSpotRecovery';
      case MemorizationTestTrigger.manual:
        return 'manual';
    }
  }

  String get title {
    switch (this) {
      case MemorizationTestTrigger.strongHafizCadence:
        return 'اختبار الحافظ القوي';
      case MemorizationTestTrigger.weeklyCheckpoint:
        return 'اختبار الأسبوع';
      case MemorizationTestTrigger.monthlyCheckpoint:
        return 'اختبار الشهر';
      case MemorizationTestTrigger.quarterCycle:
        return 'اختبار ربع الدورة';
      case MemorizationTestTrigger.halfCycle:
        return 'اختبار منتصف الدورة';
      case MemorizationTestTrigger.threeQuarterCycle:
        return 'اختبار ثلاثة أرباع الدورة';
      case MemorizationTestTrigger.endOfCycle:
        return 'اختبار ختام الدورة';
      case MemorizationTestTrigger.juzCheckpoint:
        return 'اختبار نهاية جزء';
      case MemorizationTestTrigger.fiveJuzCheckpoint:
        return 'اختبار تجميعي';
      case MemorizationTestTrigger.tenJuzCheckpoint:
        return 'اختبار شامل مرحلي';
      case MemorizationTestTrigger.weakSpotRecovery:
        return 'اختبار إنقاذ';
      case MemorizationTestTrigger.manual:
        return 'اختبار حر';
    }
  }

  bool get isMandatory {
    switch (this) {
      case MemorizationTestTrigger.endOfCycle:
      case MemorizationTestTrigger.monthlyCheckpoint:
      case MemorizationTestTrigger.juzCheckpoint:
      case MemorizationTestTrigger.fiveJuzCheckpoint:
      case MemorizationTestTrigger.tenJuzCheckpoint:
        return true;
      case MemorizationTestTrigger.strongHafizCadence:
      case MemorizationTestTrigger.weeklyCheckpoint:
      case MemorizationTestTrigger.quarterCycle:
      case MemorizationTestTrigger.halfCycle:
      case MemorizationTestTrigger.threeQuarterCycle:
      case MemorizationTestTrigger.weakSpotRecovery:
      case MemorizationTestTrigger.manual:
        return false;
    }
  }

  static MemorizationTestTrigger fromCode(String? value) {
    switch (value) {
      case 'strongHafizCadence':
        return MemorizationTestTrigger.strongHafizCadence;
      case 'weeklyCheckpoint':
        return MemorizationTestTrigger.weeklyCheckpoint;
      case 'monthlyCheckpoint':
        return MemorizationTestTrigger.monthlyCheckpoint;
      case 'quarterCycle':
        return MemorizationTestTrigger.quarterCycle;
      case 'halfCycle':
        return MemorizationTestTrigger.halfCycle;
      case 'threeQuarterCycle':
        return MemorizationTestTrigger.threeQuarterCycle;
      case 'endOfCycle':
        return MemorizationTestTrigger.endOfCycle;
      case 'juzCheckpoint':
        return MemorizationTestTrigger.juzCheckpoint;
      case 'fiveJuzCheckpoint':
        return MemorizationTestTrigger.fiveJuzCheckpoint;
      case 'tenJuzCheckpoint':
        return MemorizationTestTrigger.tenJuzCheckpoint;
      case 'weakSpotRecovery':
        return MemorizationTestTrigger.weakSpotRecovery;
      case 'manual':
        return MemorizationTestTrigger.manual;
      default:
        return MemorizationTestTrigger.manual;
    }
  }
}
