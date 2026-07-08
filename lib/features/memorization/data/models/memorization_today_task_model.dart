class MemorizationTodayTaskModel {
  static const String statusNotStarted = 'notStarted';
  static const String statusReading = 'reading';
  static const String statusReadyForTest = 'readyForTest';
  static const String statusSelfTestDone = 'selfTestDone';
  static const String statusCompleted = 'completed';

  final String id;
  final String planId;
  final String type;
  final String title;
  final String subtitle;
  final String scopeTitle;

  final int startGlobalAyahIndex;
  final int endGlobalAyahIndex;
  final int expectedMinutes;
  final String testKindCode;
  final String testTriggerCode;
  final String testStyleCode;
  final String testDifficultyPreferenceCode;
  final int questionsCount;
  final List<String> allowedQuestionTypeCodes;
  final int attemptNumber;
  final int planVersion;

  final bool isCompleted;

  /// حالة المهمة داخل رحلة الإتقان.
  final String status;

  /// اليوم الذي تصبح فيه المهمة قابلة للبدء.
  /// لو null في الملفات القديمة، نعتبر createdAt هو اليوم المتاح.
  final DateTime? scheduledDate;

  final DateTime createdAt;
  final DateTime updatedAt;

  const MemorizationTodayTaskModel({
    required this.id,
    required this.planId,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.scopeTitle,
    required this.startGlobalAyahIndex,
    required this.endGlobalAyahIndex,
    required this.expectedMinutes,
    this.testKindCode = '',
    this.testTriggerCode = '',
    this.testStyleCode = 'system',
    this.testDifficultyPreferenceCode = 'smart',
    this.questionsCount = 10,
    this.allowedQuestionTypeCodes = const <String>[],
    this.attemptNumber = 1,
    this.planVersion = 1,
    required this.isCompleted,
    this.status = statusNotStarted,
    this.scheduledDate,
    required this.createdAt,
    required this.updatedAt,
  });

  DateTime get effectiveScheduledDate {
    return scheduledDate ?? createdAt;
  }

  bool get hasValidRange {
    return startGlobalAyahIndex >= 0 &&
        endGlobalAyahIndex >= startGlobalAyahIndex;
  }

  bool get isAvailableToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scheduled = effectiveScheduledDate;
    final scheduledDay = DateTime(
      scheduled.year,
      scheduled.month,
      scheduled.day,
    );

    return !scheduledDay.isAfter(today);
  }

  bool get isFutureTask {
    return !isAvailableToday;
  }

  int get ayahsCount {
    if (!hasValidRange) return 0;
    return endGlobalAyahIndex - startGlobalAyahIndex + 1;
  }

  bool get hasStarted {
    return status == statusReading ||
        status == statusReadyForTest ||
        status == statusSelfTestDone ||
        status == statusCompleted ||
        isCompleted;
  }

  bool get isReadyForTest {
    return status == statusReadyForTest || status == statusSelfTestDone;
  }

  bool get hasSelfTestDone {
    return status == statusSelfTestDone || status == statusCompleted;
  }

  String get statusTitle {
    if (isCompleted || status == statusCompleted) return 'مكتملة';

    switch (status) {
      case statusReading:
        return 'بدأت القراءة';
      case statusReadyForTest:
        return 'جاهز للاختبار';
      case statusSelfTestDone:
        return 'ينتظر التقييم';
      case statusNotStarted:
      default:
        return 'لم يبدأ';
    }
  }

  MemorizationTodayTaskModel copyWith({
    String? id,
    String? planId,
    String? type,
    String? title,
    String? subtitle,
    String? scopeTitle,
    int? startGlobalAyahIndex,
    int? endGlobalAyahIndex,
    int? expectedMinutes,
    String? testKindCode,
    String? testTriggerCode,
    String? testStyleCode,
    String? testDifficultyPreferenceCode,
    int? questionsCount,
    List<String>? allowedQuestionTypeCodes,
    int? attemptNumber,
    int? planVersion,
    bool? isCompleted,
    String? status,
    DateTime? scheduledDate,
    bool clearScheduledDate = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MemorizationTodayTaskModel(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      scopeTitle: scopeTitle ?? this.scopeTitle,
      startGlobalAyahIndex: startGlobalAyahIndex ?? this.startGlobalAyahIndex,
      endGlobalAyahIndex: endGlobalAyahIndex ?? this.endGlobalAyahIndex,
      expectedMinutes: expectedMinutes ?? this.expectedMinutes,
      testKindCode: testKindCode ?? this.testKindCode,
      testTriggerCode: testTriggerCode ?? this.testTriggerCode,
      testStyleCode: testStyleCode ?? this.testStyleCode,
      testDifficultyPreferenceCode:
          testDifficultyPreferenceCode ?? this.testDifficultyPreferenceCode,
      questionsCount: questionsCount ?? this.questionsCount,
      allowedQuestionTypeCodes:
          allowedQuestionTypeCodes ?? this.allowedQuestionTypeCodes,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      planVersion: planVersion ?? this.planVersion,
      isCompleted: isCompleted ?? this.isCompleted,
      status: status ?? this.status,
      scheduledDate: clearScheduledDate
          ? null
          : scheduledDate ?? this.scheduledDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'planId': planId,
      'type': type,
      'title': title,
      'subtitle': subtitle,
      'scopeTitle': scopeTitle,
      'startGlobalAyahIndex': startGlobalAyahIndex,
      'endGlobalAyahIndex': endGlobalAyahIndex,
      'expectedMinutes': expectedMinutes,
      'testKindCode': testKindCode,
      'testTriggerCode': testTriggerCode,
      'testStyleCode': testStyleCode,
      'testDifficultyPreferenceCode': testDifficultyPreferenceCode,
      'questionsCount': questionsCount,
      'allowedQuestionTypeCodes': allowedQuestionTypeCodes,
      'attemptNumber': attemptNumber,
      'planVersion': planVersion,
      'isCompleted': isCompleted,
      'status': status,
      'scheduledDate': scheduledDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MemorizationTodayTaskModel.fromMap(Map<String, dynamic> map) {
    final createdAt =
        DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now();

    final bool isCompleted = map['isCompleted'] == true;
    final String rawStatus = map['status']?.toString() ?? '';
    final String status = isCompleted
        ? statusCompleted
        : _normalizeStatus(rawStatus);

    return MemorizationTodayTaskModel(
      id: map['id']?.toString() ?? '',
      planId: map['planId']?.toString() ?? '',
      type: map['type']?.toString() ?? 'dailyNew',
      title: map['title']?.toString() ?? 'مهمة اليوم',
      subtitle: map['subtitle']?.toString() ?? '',
      scopeTitle: map['scopeTitle']?.toString() ?? '',
      startGlobalAyahIndex:
          int.tryParse(map['startGlobalAyahIndex']?.toString() ?? '') ?? 0,
      endGlobalAyahIndex:
          int.tryParse(map['endGlobalAyahIndex']?.toString() ?? '') ?? 0,
      expectedMinutes:
          int.tryParse(map['expectedMinutes']?.toString() ?? '') ?? 10,
      testKindCode: map['testKindCode']?.toString() ?? '',
      testTriggerCode: map['testTriggerCode']?.toString() ?? '',
      testStyleCode: map['testStyleCode']?.toString() ?? 'system',
      testDifficultyPreferenceCode:
          map['testDifficultyPreferenceCode']?.toString() ?? 'smart',
      questionsCount:
          (int.tryParse(map['questionsCount']?.toString() ?? '') ?? 10)
              .clamp(1, 30)
              .toInt(),
      allowedQuestionTypeCodes: map['allowedQuestionTypeCodes'] is List
          ? (map['allowedQuestionTypeCodes'] as List)
                .map((item) => item.toString())
                .toList(growable: false)
          : const <String>[],
      attemptNumber: (int.tryParse(map['attemptNumber']?.toString() ?? '') ?? 1)
          .clamp(1, 9999)
          .toInt(),
      planVersion: (int.tryParse(map['planVersion']?.toString() ?? '') ?? 1)
          .clamp(1, 99999)
          .toInt(),
      isCompleted: isCompleted,
      status: status,
      scheduledDate: DateTime.tryParse(map['scheduledDate']?.toString() ?? ''),
      createdAt: createdAt,
      updatedAt:
          DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? createdAt,
    );
  }

  static String _normalizeStatus(String value) {
    switch (value) {
      case statusReading:
      case statusReadyForTest:
      case statusSelfTestDone:
      case statusCompleted:
        return value;
      case statusNotStarted:
      default:
        return statusNotStarted;
    }
  }
}
