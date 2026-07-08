enum MemorizationTestStyle {
  system,
  smartMixed,
  multipleChoice,
  ordering,
  completionAndRecitation,
  hiddenMushaf,
  custom,
}

extension MemorizationTestStyleX on MemorizationTestStyle {
  String get code => name;

  String get title {
    switch (this) {
      case MemorizationTestStyle.system:
        return 'حسب النظام';
      case MemorizationTestStyle.smartMixed:
        return 'ذكي مختلط';
      case MemorizationTestStyle.multipleChoice:
        return 'اختيار من متعدد';
      case MemorizationTestStyle.ordering:
        return 'ترتيب آيات وكلمات';
      case MemorizationTestStyle.completionAndRecitation:
        return 'إكمال وتسميع';
      case MemorizationTestStyle.hiddenMushaf:
        return 'تسميع بدون نظر';
      case MemorizationTestStyle.custom:
        return 'مخصص';
    }
  }

  static MemorizationTestStyle fromCode(String? value) {
    return MemorizationTestStyle.values.firstWhere(
      (item) => item.code == value,
      orElse: () => MemorizationTestStyle.system,
    );
  }
}

enum MemorizationTestDifficultyPreference { smart, easy, medium, hard }

extension MemorizationTestDifficultyPreferenceX
    on MemorizationTestDifficultyPreference {
  String get code => name;

  String get title {
    switch (this) {
      case MemorizationTestDifficultyPreference.smart:
        return 'ذكي حسب مستواي';
      case MemorizationTestDifficultyPreference.easy:
        return 'سهل';
      case MemorizationTestDifficultyPreference.medium:
        return 'متوسط';
      case MemorizationTestDifficultyPreference.hard:
        return 'صعب';
    }
  }

  static MemorizationTestDifficultyPreference fromCode(String? value) {
    return MemorizationTestDifficultyPreference.values.firstWhere(
      (item) => item.code == value,
      orElse: () => MemorizationTestDifficultyPreference.smart,
    );
  }
}

class MemorizationTestQuestionCodes {
  static const String completeAyah = 'completeAyah';
  static const String chooseAyahCompletion = 'chooseAyahCompletion';
  static const String chooseWord = 'chooseWord';
  static const String chooseAyah = 'chooseAyah';
  static const String nextAyah = 'nextAyah';
  static const String previousAyah = 'previousAyah';
  static const String orderAyahs = 'orderAyahs';
  static const String orderWords = 'orderWords';
  static const String similarAyahs = 'similarAyahs';
  static const String noTextRecitation = 'noTextRecitation';
  static const String hiddenMushafRecitation = 'hiddenMushafRecitation';

  static const List<String> userSelectable = <String>[
    completeAyah,
    chooseAyahCompletion,
    chooseWord,
    chooseAyah,
    nextAyah,
    previousAyah,
    orderAyahs,
    orderWords,
    similarAyahs,
    noTextRecitation,
    hiddenMushafRecitation,
  ];

  static String title(String code) {
    switch (code) {
      case completeAyah:
        return 'أكمل الآية';
      case chooseAyahCompletion:
        return 'اختر التكملة';
      case chooseWord:
        return 'اختر الكلمة';
      case chooseAyah:
        return 'اختر الآية';
      case nextAyah:
        return 'الآية التالية';
      case previousAyah:
        return 'الآية السابقة';
      case orderAyahs:
        return 'رتب الآيات';
      case orderWords:
        return 'رتب الكلمات';
      case similarAyahs:
        return 'المتشابهات';
      case noTextRecitation:
        return 'تسميع ذاتي';
      case hiddenMushafRecitation:
        return 'تسميع ذاتي';
      default:
        return code;
    }
  }
}

class MemorizationTestPreferences {
  final MemorizationTestStyle style;
  final int questionsPerTest;
  final MemorizationTestDifficultyPreference difficulty;
  final List<String> allowedQuestionTypeCodes;

  const MemorizationTestPreferences({
    this.style = MemorizationTestStyle.system,
    this.questionsPerTest = 10,
    this.difficulty = MemorizationTestDifficultyPreference.smart,
    this.allowedQuestionTypeCodes =
        MemorizationTestQuestionCodes.userSelectable,
  });

  MemorizationTestPreferences copyWith({
    MemorizationTestStyle? style,
    int? questionsPerTest,
    MemorizationTestDifficultyPreference? difficulty,
    List<String>? allowedQuestionTypeCodes,
  }) {
    return MemorizationTestPreferences(
      style: style ?? this.style,
      questionsPerTest: _safeQuestions(
        questionsPerTest ?? this.questionsPerTest,
      ),
      difficulty: difficulty ?? this.difficulty,
      allowedQuestionTypeCodes: _safeTypes(
        allowedQuestionTypeCodes ?? this.allowedQuestionTypeCodes,
      ),
    );
  }

  List<String> get effectiveQuestionTypeCodes {
    switch (style) {
      case MemorizationTestStyle.system:
      case MemorizationTestStyle.smartMixed:
        return _safeTypes(allowedQuestionTypeCodes);
      case MemorizationTestStyle.multipleChoice:
        return const <String>[
          MemorizationTestQuestionCodes.chooseAyahCompletion,
          MemorizationTestQuestionCodes.chooseWord,
          MemorizationTestQuestionCodes.chooseAyah,
          MemorizationTestQuestionCodes.nextAyah,
          MemorizationTestQuestionCodes.previousAyah,
        ];
      case MemorizationTestStyle.ordering:
        return const <String>[
          MemorizationTestQuestionCodes.orderAyahs,
          MemorizationTestQuestionCodes.orderWords,
        ];
      case MemorizationTestStyle.completionAndRecitation:
        return const <String>[
          MemorizationTestQuestionCodes.completeAyah,
          MemorizationTestQuestionCodes.noTextRecitation,
          MemorizationTestQuestionCodes.chooseAyahCompletion,
        ];
      case MemorizationTestStyle.hiddenMushaf:
        return const <String>[
          MemorizationTestQuestionCodes.hiddenMushafRecitation,
        ];
      case MemorizationTestStyle.custom:
        return _safeTypes(allowedQuestionTypeCodes);
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'style': style.code,
      'questionsPerTest': _safeQuestions(questionsPerTest),
      'difficulty': difficulty.code,
      'allowedQuestionTypeCodes': _safeTypes(allowedQuestionTypeCodes),
    };
  }

  factory MemorizationTestPreferences.fromMap(Object? value) {
    if (value is! Map) return const MemorizationTestPreferences();
    final map = Map<String, dynamic>.from(value);
    final rawTypes = map['allowedQuestionTypeCodes'];
    return MemorizationTestPreferences(
      style: MemorizationTestStyleX.fromCode(map['style']?.toString()),
      questionsPerTest: _safeQuestions(
        int.tryParse(map['questionsPerTest']?.toString() ?? '') ?? 10,
      ),
      difficulty: MemorizationTestDifficultyPreferenceX.fromCode(
        map['difficulty']?.toString(),
      ),
      allowedQuestionTypeCodes: _safeTypes(
        rawTypes is List
            ? rawTypes.map((item) => item.toString()).toList()
            : const [],
      ),
    );
  }

  static int _safeQuestions(int value) {
    const allowed = <int>[5, 10, 15, 20];
    return allowed.reduce(
      (best, item) => (item - value).abs() < (best - value).abs() ? item : best,
    );
  }

  static List<String> _safeTypes(List<String> values) {
    final safe = values
        .where(MemorizationTestQuestionCodes.userSelectable.contains)
        .toSet()
        .toList(growable: false);
    return safe.isEmpty ? MemorizationTestQuestionCodes.userSelectable : safe;
  }
}
