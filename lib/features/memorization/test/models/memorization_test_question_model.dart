enum MemorizationQuestionType {
  completeAyah,
  chooseAyahCompletion,
  chooseWord,
  chooseAyah,
  nextAyah,
  orderAyahs,
  orderWords,
  hiddenAyahs,
  noTextRecitation,
  hiddenMushafRecitation,
  ayahStarts,
  ayahEndings,
  previousAyah,
  ayahPosition,
  similarAyahs,
  fullPageRecitation,
}

extension MemorizationQuestionTypeX on MemorizationQuestionType {
  String get code {
    switch (this) {
      case MemorizationQuestionType.completeAyah:
        return 'completeAyah';
      case MemorizationQuestionType.chooseAyahCompletion:
        return 'chooseAyahCompletion';
      case MemorizationQuestionType.chooseWord:
        return 'chooseWord';
      case MemorizationQuestionType.chooseAyah:
        return 'chooseAyah';
      case MemorizationQuestionType.nextAyah:
        return 'nextAyah';
      case MemorizationQuestionType.orderAyahs:
        return 'orderAyahs';
      case MemorizationQuestionType.orderWords:
        return 'orderWords';
      case MemorizationQuestionType.hiddenAyahs:
        return 'hiddenAyahs';
      case MemorizationQuestionType.noTextRecitation:
        return 'noTextRecitation';
      case MemorizationQuestionType.hiddenMushafRecitation:
        return 'hiddenMushafRecitation';
      case MemorizationQuestionType.ayahStarts:
        return 'ayahStarts';
      case MemorizationQuestionType.ayahEndings:
        return 'ayahEndings';
      case MemorizationQuestionType.previousAyah:
        return 'previousAyah';
      case MemorizationQuestionType.ayahPosition:
        return 'ayahPosition';
      case MemorizationQuestionType.similarAyahs:
        return 'similarAyahs';
      case MemorizationQuestionType.fullPageRecitation:
        return 'fullPageRecitation';
    }
  }

  String get title {
    switch (this) {
      case MemorizationQuestionType.completeAyah:
        return 'أكمل الآية';
      case MemorizationQuestionType.chooseAyahCompletion:
        return 'اختر تكملة الآية';
      case MemorizationQuestionType.chooseWord:
        return 'اختر الكلمة الصحيحة';
      case MemorizationQuestionType.chooseAyah:
        return 'اختر الآية الصحيحة';
      case MemorizationQuestionType.nextAyah:
        return 'ما الآية التالية؟';
      case MemorizationQuestionType.orderAyahs:
        return 'رتّب الآيات';
      case MemorizationQuestionType.orderWords:
        return 'رتّب كلمات الآية';
      case MemorizationQuestionType.hiddenAyahs:
        return 'إخفاء تدريجي';
      case MemorizationQuestionType.noTextRecitation:
        return 'تسميع بدون نص';
      case MemorizationQuestionType.hiddenMushafRecitation:
        return 'تسميع ذاتي';
      case MemorizationQuestionType.ayahStarts:
        return 'بدايات الآيات';
      case MemorizationQuestionType.ayahEndings:
        return 'خواتيم الآيات';
      case MemorizationQuestionType.previousAyah:
        return 'ما الآية السابقة؟';
      case MemorizationQuestionType.ayahPosition:
        return 'موضع الآية';
      case MemorizationQuestionType.similarAyahs:
        return 'المتشابهات';
      case MemorizationQuestionType.fullPageRecitation:
        return 'تسميع صفحة كاملة';
    }
  }
}

class MemorizationQuestionOption {
  final String id;
  final String text;
  final bool isCorrect;
  final int? correctOrder;

  const MemorizationQuestionOption({
    required this.id,
    required this.text,
    required this.isCorrect,
    this.correctOrder,
  });
}

class MemorizationTestQuestionModel {
  final String id;
  final MemorizationQuestionType type;
  final String title;
  final String prompt;
  final String hint;
  final int startGlobalAyahIndex;
  final int endGlobalAyahIndex;
  final List<MemorizationQuestionOption> options;
  final String correctAnswerText;
  final String promptAyahText;
  final String fullAyahText;
  final String sourceLabel;
  final String pageLabel;

  const MemorizationTestQuestionModel({
    required this.id,
    required this.type,
    required this.title,
    required this.prompt,
    required this.hint,
    required this.startGlobalAyahIndex,
    required this.endGlobalAyahIndex,
    required this.options,
    required this.correctAnswerText,
    this.promptAyahText = '',
    this.fullAyahText = '',
    this.sourceLabel = '',
    this.pageLabel = '',
  });

  bool get hasOptions => options.isNotEmpty;

  bool get isOrderingQuestion {
    return type == MemorizationQuestionType.orderAyahs ||
        type == MemorizationQuestionType.orderWords;
  }

  int get ayahsCount {
    return endGlobalAyahIndex - startGlobalAyahIndex + 1;
  }

  String get questionFingerprint {
    final source =
        '${type.code}|$startGlobalAyahIndex|$endGlobalAyahIndex|'
        '${correctAnswerText.replaceAll(RegExp(r'\s+'), ' ').trim()}';
    int hash = 0x811C9DC5;
    for (final codeUnit in source.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return '${type.code}_${hash.toRadixString(16)}';
  }

  MemorizationTestQuestionModel copyWith({
    String? prompt,
    String? hint,
    List<MemorizationQuestionOption>? options,
    String? correctAnswerText,
    String? promptAyahText,
    String? fullAyahText,
    String? sourceLabel,
    String? pageLabel,
  }) {
    return MemorizationTestQuestionModel(
      id: id,
      type: type,
      title: title,
      prompt: prompt ?? this.prompt,
      hint: hint ?? this.hint,
      startGlobalAyahIndex: startGlobalAyahIndex,
      endGlobalAyahIndex: endGlobalAyahIndex,
      options: options ?? this.options,
      correctAnswerText: correctAnswerText ?? this.correctAnswerText,
      promptAyahText: promptAyahText ?? this.promptAyahText,
      fullAyahText: fullAyahText ?? this.fullAyahText,
      sourceLabel: sourceLabel ?? this.sourceLabel,
      pageLabel: pageLabel ?? this.pageLabel,
    );
  }
}

class MemorizationQuestionAnswer {
  final String questionId;
  final bool isCorrect;
  final DateTime answeredAt;
  final bool timedOut;
  final bool skipped;

  const MemorizationQuestionAnswer({
    required this.questionId,
    required this.isCorrect,
    required this.answeredAt,
    this.timedOut = false,
    this.skipped = false,
  });
}

class MemorizationTestSessionSummary {
  final int totalQuestions;
  final int correctAnswers;
  final DateTime completedAt;

  const MemorizationTestSessionSummary({
    required this.totalQuestions,
    required this.correctAnswers,
    required this.completedAt,
  });

  double get score {
    if (totalQuestions <= 0) return 0;
    return correctAnswers / totalQuestions;
  }

  String get rating {
    if (score >= 0.9) return 'easy';
    if (score >= 0.7) return 'good';
    if (score >= 0.45) return 'hard';
    return 'forgot';
  }
}
