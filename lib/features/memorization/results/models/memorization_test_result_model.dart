class MemorizationQuestionResultModel {
  final String questionId;
  final String questionType;
  final int startGlobalAyahIndex;
  final int endGlobalAyahIndex;
  final bool isCorrect;
  final String selectedAnswer;
  final String correctAnswer;
  final int timeSpentSeconds;
  final bool timedOut;
  final bool skipped;
  final String mistakeType;

  const MemorizationQuestionResultModel({
    required this.questionId,
    required this.questionType,
    required this.startGlobalAyahIndex,
    required this.endGlobalAyahIndex,
    required this.isCorrect,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.timeSpentSeconds,
    this.timedOut = false,
    this.skipped = false,
    required this.mistakeType,
  });

  Map<String, dynamic> toMap() => {
    'questionId': questionId,
    'questionType': questionType,
    'startGlobalAyahIndex': startGlobalAyahIndex,
    'endGlobalAyahIndex': endGlobalAyahIndex,
    'isCorrect': isCorrect,
    'selectedAnswer': selectedAnswer,
    'correctAnswer': correctAnswer,
    'timeSpentSeconds': timeSpentSeconds,
    'timedOut': timedOut,
    'skipped': skipped,
    'mistakeType': mistakeType,
  };

  factory MemorizationQuestionResultModel.fromMap(Map<String, dynamic> map) {
    return MemorizationQuestionResultModel(
      questionId: map['questionId']?.toString() ?? '',
      questionType: map['questionType']?.toString() ?? '',
      startGlobalAyahIndex:
          int.tryParse(map['startGlobalAyahIndex']?.toString() ?? '') ?? 0,
      endGlobalAyahIndex:
          int.tryParse(map['endGlobalAyahIndex']?.toString() ?? '') ?? 0,
      isCorrect: map['isCorrect'] == true,
      selectedAnswer: map['selectedAnswer']?.toString() ?? '',
      correctAnswer: map['correctAnswer']?.toString() ?? '',
      timeSpentSeconds:
          int.tryParse(map['timeSpentSeconds']?.toString() ?? '') ?? 0,
      timedOut: map['timedOut'] == true,
      skipped: map['skipped'] == true,
      mistakeType: map['mistakeType']?.toString() ?? '',
    );
  }
}

class MemorizationTestResultModel {
  final String id;
  final String planId;
  final int planVersion;
  final String taskId;
  final String testType;
  final String scope;
  final String timerMode;
  final DateTime startedAt;
  final DateTime scheduledDate;
  final DateTime completedAt;
  final int startGlobalAyahIndex;
  final int endGlobalAyahIndex;
  final int questionCount;
  final int correctCount;
  final int wrongCount;
  final int skippedCount;
  final int timeoutCount;
  final double scorePercent;
  final int durationSeconds;
  final int totalDurationSeconds;
  final String difficulty;
  final Map<String, int> questionTypeBreakdown;
  final List<String> weakSpots;
  final String selfEvaluation;
  final int attemptNumber;
  final List<MemorizationQuestionResultModel> questionResults;

  const MemorizationTestResultModel({
    required this.id,
    required this.planId,
    required this.planVersion,
    required this.taskId,
    required this.testType,
    this.scope = '',
    this.timerMode = 'none',
    DateTime? startedAt,
    required this.scheduledDate,
    required this.completedAt,
    required this.startGlobalAyahIndex,
    required this.endGlobalAyahIndex,
    required this.questionCount,
    required this.correctCount,
    this.wrongCount = 0,
    this.skippedCount = 0,
    this.timeoutCount = 0,
    required this.scorePercent,
    required this.durationSeconds,
    int? totalDurationSeconds,
    required this.difficulty,
    required this.questionTypeBreakdown,
    required this.weakSpots,
    required this.selfEvaluation,
    required this.attemptNumber,
    required this.questionResults,
  }) : startedAt = startedAt ?? scheduledDate,
       totalDurationSeconds = totalDurationSeconds ?? durationSeconds;

  Map<String, dynamic> toMap() => {
    'id': id,
    'planId': planId,
    'planVersion': planVersion,
    'taskId': taskId,
    'testType': testType,
    'scope': scope,
    'timerMode': timerMode,
    'startedAt': startedAt.toIso8601String(),
    'scheduledDate': scheduledDate.toIso8601String(),
    'completedAt': completedAt.toIso8601String(),
    'startGlobalAyahIndex': startGlobalAyahIndex,
    'endGlobalAyahIndex': endGlobalAyahIndex,
    'questionCount': questionCount,
    'correctCount': correctCount,
    'wrongCount': wrongCount,
    'skippedCount': skippedCount,
    'timeoutCount': timeoutCount,
    'scorePercent': scorePercent,
    'durationSeconds': durationSeconds,
    'totalDurationSeconds': totalDurationSeconds,
    'difficulty': difficulty,
    'questionTypeBreakdown': questionTypeBreakdown,
    'weakSpots': weakSpots,
    'selfEvaluation': selfEvaluation,
    'attemptNumber': attemptNumber,
    'questionResults': questionResults.map((item) => item.toMap()).toList(),
  };

  factory MemorizationTestResultModel.fromMap(Map<String, dynamic> map) {
    final rawBreakdown = map['questionTypeBreakdown'];
    final rawQuestionResults = map['questionResults'];
    return MemorizationTestResultModel(
      id: map['id']?.toString() ?? '',
      planId: map['planId']?.toString() ?? '',
      planVersion: int.tryParse(map['planVersion']?.toString() ?? '') ?? 1,
      taskId: map['taskId']?.toString() ?? '',
      testType: map['testType']?.toString() ?? '',
      scope: map['scope']?.toString() ?? '',
      timerMode: map['timerMode']?.toString() ?? 'none',
      startedAt: DateTime.tryParse(map['startedAt']?.toString() ?? ''),
      scheduledDate:
          DateTime.tryParse(map['scheduledDate']?.toString() ?? '') ??
          DateTime.now(),
      completedAt:
          DateTime.tryParse(map['completedAt']?.toString() ?? '') ??
          DateTime.now(),
      startGlobalAyahIndex:
          int.tryParse(map['startGlobalAyahIndex']?.toString() ?? '') ?? 0,
      endGlobalAyahIndex:
          int.tryParse(map['endGlobalAyahIndex']?.toString() ?? '') ?? 0,
      questionCount: int.tryParse(map['questionCount']?.toString() ?? '') ?? 0,
      correctCount: int.tryParse(map['correctCount']?.toString() ?? '') ?? 0,
      wrongCount: int.tryParse(map['wrongCount']?.toString() ?? '') ?? 0,
      skippedCount: int.tryParse(map['skippedCount']?.toString() ?? '') ?? 0,
      timeoutCount: int.tryParse(map['timeoutCount']?.toString() ?? '') ?? 0,
      scorePercent: double.tryParse(map['scorePercent']?.toString() ?? '') ?? 0,
      durationSeconds:
          int.tryParse(map['durationSeconds']?.toString() ?? '') ?? 0,
      totalDurationSeconds: int.tryParse(
        map['totalDurationSeconds']?.toString() ?? '',
      ),
      difficulty: map['difficulty']?.toString() ?? 'smart',
      questionTypeBreakdown: rawBreakdown is Map
          ? rawBreakdown.map(
              (key, value) =>
                  MapEntry(key.toString(), int.tryParse(value.toString()) ?? 0),
            )
          : const <String, int>{},
      weakSpots: map['weakSpots'] is List
          ? (map['weakSpots'] as List)
                .map((item) => item.toString())
                .toList(growable: false)
          : const <String>[],
      selfEvaluation: map['selfEvaluation']?.toString() ?? '',
      attemptNumber: int.tryParse(map['attemptNumber']?.toString() ?? '') ?? 1,
      questionResults: rawQuestionResults is List
          ? rawQuestionResults
                .whereType<Map>()
                .map(
                  (item) => MemorizationQuestionResultModel.fromMap(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(growable: false)
          : const <MemorizationQuestionResultModel>[],
    );
  }
}
