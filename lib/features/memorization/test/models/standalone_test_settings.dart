import 'memorization_test_question_model.dart';

enum StandaloneTestScopeType {
  wholeSurah,
  surahRange,
  juz,
  hizb,
  pages,
  customRange,
  lastMemorized,
  weakSpots,
  previousMistakes,
  randomWholeQuran,
}

enum StandaloneQuestionMode {
  mixed,
  chooseCompletion,
  completeAyah,
  chooseWord,
  chooseAyah,
  nextAyah,
  previousAyah,
  orderAyahs,
  orderWords,
  selfRecitation,
  hiddenAyahs,
  hiddenMushaf,
  fullPage,
  similarAyahs,
  weakSpotsOnly,
}

enum StandaloneDifficulty { easy, medium, hard, comprehensive }

enum StandaloneTimerMode { none, perQuestion, fullTest, customMinutes }

class StandaloneTestSettings {
  const StandaloneTestSettings({
    required this.id,
    required this.scopeType,
    required this.scopeLabel,
    required this.questionMode,
    required this.questionCount,
    required this.difficulty,
    required this.timerMode,
    required this.startedAt,
    this.secondsPerQuestion = 60,
    this.fullTestMinutes = 10,
    this.attemptNumber = 1,
  });

  final String id;
  final StandaloneTestScopeType scopeType;
  final String scopeLabel;
  final StandaloneQuestionMode questionMode;
  final int questionCount;
  final StandaloneDifficulty difficulty;
  final StandaloneTimerMode timerMode;
  final int secondsPerQuestion;
  final int fullTestMinutes;
  final DateTime startedAt;
  final int attemptNumber;

  bool get isTimed => timerMode != StandaloneTimerMode.none;

  bool get isPerQuestionTimed => timerMode == StandaloneTimerMode.perQuestion;

  bool get isFullTestTimed =>
      timerMode == StandaloneTimerMode.fullTest ||
      timerMode == StandaloneTimerMode.customMinutes;

  Duration get fullTestDuration {
    if (!isFullTestTimed) return Duration.zero;
    return Duration(minutes: fullTestMinutes.clamp(1, 180).toInt());
  }

  Duration get perQuestionDuration {
    if (!isPerQuestionTimed) return Duration.zero;
    return Duration(seconds: secondsPerQuestion.clamp(10, 600).toInt());
  }

  String get timerModeCode {
    switch (timerMode) {
      case StandaloneTimerMode.none:
        return 'none';
      case StandaloneTimerMode.perQuestion:
        return 'perQuestion';
      case StandaloneTimerMode.fullTest:
        return 'fullTest';
      case StandaloneTimerMode.customMinutes:
        return 'customMinutes';
    }
  }

  String get difficultyCode {
    switch (difficulty) {
      case StandaloneDifficulty.easy:
        return 'easy';
      case StandaloneDifficulty.medium:
        return 'medium';
      case StandaloneDifficulty.hard:
        return 'hard';
      case StandaloneDifficulty.comprehensive:
        return 'comprehensive';
    }
  }

  String get questionModeCode {
    switch (questionMode) {
      case StandaloneQuestionMode.mixed:
        return 'mixed';
      case StandaloneQuestionMode.chooseCompletion:
        return 'chooseCompletion';
      case StandaloneQuestionMode.completeAyah:
        return 'completeAyah';
      case StandaloneQuestionMode.chooseWord:
        return 'chooseWord';
      case StandaloneQuestionMode.chooseAyah:
        return 'chooseAyah';
      case StandaloneQuestionMode.nextAyah:
        return 'nextAyah';
      case StandaloneQuestionMode.previousAyah:
        return 'previousAyah';
      case StandaloneQuestionMode.orderAyahs:
        return 'orderAyahs';
      case StandaloneQuestionMode.orderWords:
        return 'orderWords';
      case StandaloneQuestionMode.selfRecitation:
        return 'selfRecitation';
      case StandaloneQuestionMode.hiddenAyahs:
        return 'hiddenAyahs';
      case StandaloneQuestionMode.hiddenMushaf:
        return 'hiddenMushaf';
      case StandaloneQuestionMode.fullPage:
        return 'fullPage';
      case StandaloneQuestionMode.similarAyahs:
        return 'similarAyahs';
      case StandaloneQuestionMode.weakSpotsOnly:
        return 'weakSpotsOnly';
    }
  }

  String get timerLabel {
    switch (timerMode) {
      case StandaloneTimerMode.none:
        return 'بدون وقت';
      case StandaloneTimerMode.perQuestion:
        return '$secondsPerQuestion ثانية لكل سؤال';
      case StandaloneTimerMode.fullTest:
        return '$fullTestMinutes دقائق للاختبار';
      case StandaloneTimerMode.customMinutes:
        return '$fullTestMinutes دقائق مخصصة';
    }
  }

  String get difficultyLabel {
    switch (difficulty) {
      case StandaloneDifficulty.easy:
        return 'سهل';
      case StandaloneDifficulty.medium:
        return 'متوسط';
      case StandaloneDifficulty.hard:
        return 'صعب';
      case StandaloneDifficulty.comprehensive:
        return 'شامل';
    }
  }

  String get questionModeLabel {
    switch (questionMode) {
      case StandaloneQuestionMode.mixed:
        return 'مختلط';
      case StandaloneQuestionMode.chooseCompletion:
        return 'اختر التكملة الصحيحة';
      case StandaloneQuestionMode.completeAyah:
        return 'أكمل الآية';
      case StandaloneQuestionMode.chooseWord:
        return 'اختر الكلمة الصحيحة';
      case StandaloneQuestionMode.chooseAyah:
        return 'اختر الآية الصحيحة';
      case StandaloneQuestionMode.nextAyah:
        return 'ما الآية التالية؟';
      case StandaloneQuestionMode.previousAyah:
        return 'ما الآية السابقة؟';
      case StandaloneQuestionMode.orderAyahs:
        return 'رتّب الآيات';
      case StandaloneQuestionMode.orderWords:
        return 'رتّب كلمات الآية';
      case StandaloneQuestionMode.selfRecitation:
        return 'تسميع ذاتي';
      case StandaloneQuestionMode.hiddenAyahs:
        return 'وضع إخفاء الآيات';
      case StandaloneQuestionMode.hiddenMushaf:
        return 'تسميع بدون نظر';
      case StandaloneQuestionMode.fullPage:
        return 'اختبار صفحة كاملة';
      case StandaloneQuestionMode.similarAyahs:
        return 'المتشابهات';
      case StandaloneQuestionMode.weakSpotsOnly:
        return 'مواضع ضعيفة فقط';
    }
  }

  List<String> get allowedQuestionTypeCodes {
    switch (questionMode) {
      case StandaloneQuestionMode.mixed:
      case StandaloneQuestionMode.weakSpotsOnly:
        return const <String>[];
      case StandaloneQuestionMode.chooseCompletion:
        return <String>[MemorizationQuestionType.chooseAyahCompletion.code];
      case StandaloneQuestionMode.completeAyah:
        return <String>[MemorizationQuestionType.completeAyah.code];
      case StandaloneQuestionMode.chooseWord:
        return <String>[MemorizationQuestionType.chooseWord.code];
      case StandaloneQuestionMode.chooseAyah:
        return <String>[MemorizationQuestionType.chooseAyah.code];
      case StandaloneQuestionMode.nextAyah:
        return <String>[MemorizationQuestionType.nextAyah.code];
      case StandaloneQuestionMode.previousAyah:
        return <String>[MemorizationQuestionType.previousAyah.code];
      case StandaloneQuestionMode.orderAyahs:
        return <String>[MemorizationQuestionType.orderAyahs.code];
      case StandaloneQuestionMode.orderWords:
        return <String>[MemorizationQuestionType.orderWords.code];
      case StandaloneQuestionMode.selfRecitation:
        return <String>[MemorizationQuestionType.noTextRecitation.code];
      case StandaloneQuestionMode.hiddenAyahs:
        return <String>[MemorizationQuestionType.hiddenAyahs.code];
      case StandaloneQuestionMode.hiddenMushaf:
        return <String>[MemorizationQuestionType.hiddenMushafRecitation.code];
      case StandaloneQuestionMode.fullPage:
        return <String>[MemorizationQuestionType.fullPageRecitation.code];
      case StandaloneQuestionMode.similarAyahs:
        return <String>[MemorizationQuestionType.similarAyahs.code];
    }
  }
}

extension StandaloneQuestionModeLabels on StandaloneQuestionMode {
  String get questionModeCode {
    switch (this) {
      case StandaloneQuestionMode.mixed:
        return 'mixed';
      case StandaloneQuestionMode.chooseCompletion:
        return 'chooseCompletion';
      case StandaloneQuestionMode.completeAyah:
        return 'completeAyah';
      case StandaloneQuestionMode.chooseWord:
        return 'chooseWord';
      case StandaloneQuestionMode.chooseAyah:
        return 'chooseAyah';
      case StandaloneQuestionMode.nextAyah:
        return 'nextAyah';
      case StandaloneQuestionMode.previousAyah:
        return 'previousAyah';
      case StandaloneQuestionMode.orderAyahs:
        return 'orderAyahs';
      case StandaloneQuestionMode.orderWords:
        return 'orderWords';
      case StandaloneQuestionMode.selfRecitation:
        return 'selfRecitation';
      case StandaloneQuestionMode.hiddenAyahs:
        return 'hiddenAyahs';
      case StandaloneQuestionMode.hiddenMushaf:
        return 'hiddenMushaf';
      case StandaloneQuestionMode.fullPage:
        return 'fullPage';
      case StandaloneQuestionMode.similarAyahs:
        return 'similarAyahs';
      case StandaloneQuestionMode.weakSpotsOnly:
        return 'weakSpotsOnly';
    }
  }

  String get questionModeLabel {
    switch (this) {
      case StandaloneQuestionMode.mixed:
        return 'مختلط';
      case StandaloneQuestionMode.chooseCompletion:
        return 'اختر التكملة الصحيحة';
      case StandaloneQuestionMode.completeAyah:
        return 'أكمل الآية';
      case StandaloneQuestionMode.chooseWord:
        return 'اختر الكلمة الصحيحة';
      case StandaloneQuestionMode.chooseAyah:
        return 'اختر الآية الصحيحة';
      case StandaloneQuestionMode.nextAyah:
        return 'ما الآية التالية؟';
      case StandaloneQuestionMode.previousAyah:
        return 'ما الآية السابقة؟';
      case StandaloneQuestionMode.orderAyahs:
        return 'رتّب الآيات';
      case StandaloneQuestionMode.orderWords:
        return 'رتّب كلمات الآية';
      case StandaloneQuestionMode.selfRecitation:
        return 'تسميع ذاتي';
      case StandaloneQuestionMode.hiddenAyahs:
        return 'وضع إخفاء الآيات';
      case StandaloneQuestionMode.hiddenMushaf:
        return 'تسميع بدون نظر';
      case StandaloneQuestionMode.fullPage:
        return 'اختبار صفحة كاملة';
      case StandaloneQuestionMode.similarAyahs:
        return 'المتشابهات';
      case StandaloneQuestionMode.weakSpotsOnly:
        return 'مواضع ضعيفة فقط';
    }
  }

  List<String> get allowedQuestionTypeCodes {
    switch (this) {
      case StandaloneQuestionMode.mixed:
      case StandaloneQuestionMode.weakSpotsOnly:
        return const <String>[];
      case StandaloneQuestionMode.chooseCompletion:
        return <String>[MemorizationQuestionType.chooseAyahCompletion.code];
      case StandaloneQuestionMode.completeAyah:
        return <String>[MemorizationQuestionType.completeAyah.code];
      case StandaloneQuestionMode.chooseWord:
        return <String>[MemorizationQuestionType.chooseWord.code];
      case StandaloneQuestionMode.chooseAyah:
        return <String>[MemorizationQuestionType.chooseAyah.code];
      case StandaloneQuestionMode.nextAyah:
        return <String>[MemorizationQuestionType.nextAyah.code];
      case StandaloneQuestionMode.previousAyah:
        return <String>[MemorizationQuestionType.previousAyah.code];
      case StandaloneQuestionMode.orderAyahs:
        return <String>[MemorizationQuestionType.orderAyahs.code];
      case StandaloneQuestionMode.orderWords:
        return <String>[MemorizationQuestionType.orderWords.code];
      case StandaloneQuestionMode.selfRecitation:
        return <String>[MemorizationQuestionType.noTextRecitation.code];
      case StandaloneQuestionMode.hiddenAyahs:
        return <String>[MemorizationQuestionType.hiddenAyahs.code];
      case StandaloneQuestionMode.hiddenMushaf:
        return <String>[MemorizationQuestionType.hiddenMushafRecitation.code];
      case StandaloneQuestionMode.fullPage:
        return <String>[MemorizationQuestionType.fullPageRecitation.code];
      case StandaloneQuestionMode.similarAyahs:
        return <String>[MemorizationQuestionType.similarAyahs.code];
    }
  }
}

extension StandaloneDifficultyLabels on StandaloneDifficulty {
  String get difficultyCode {
    switch (this) {
      case StandaloneDifficulty.easy:
        return 'easy';
      case StandaloneDifficulty.medium:
        return 'medium';
      case StandaloneDifficulty.hard:
        return 'hard';
      case StandaloneDifficulty.comprehensive:
        return 'comprehensive';
    }
  }

  String get difficultyLabel {
    switch (this) {
      case StandaloneDifficulty.easy:
        return 'سهل';
      case StandaloneDifficulty.medium:
        return 'متوسط';
      case StandaloneDifficulty.hard:
        return 'صعب';
      case StandaloneDifficulty.comprehensive:
        return 'شامل';
    }
  }
}

extension StandaloneTimerModeLabels on StandaloneTimerMode {
  String get timerModeCode {
    switch (this) {
      case StandaloneTimerMode.none:
        return 'none';
      case StandaloneTimerMode.perQuestion:
        return 'perQuestion';
      case StandaloneTimerMode.fullTest:
        return 'fullTest';
      case StandaloneTimerMode.customMinutes:
        return 'customMinutes';
    }
  }
}
