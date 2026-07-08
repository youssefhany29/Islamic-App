import 'memorization_test_kind.dart';
import 'memorization_test_preferences.dart';
import 'memorization_today_task_model.dart';

class MemorizationScheduledTestModel {
  final String id;
  final String planId;

  final MemorizationTestKind kind;
  final MemorizationTestDifficulty difficulty;
  final MemorizationTestTrigger trigger;

  final int startGlobalAyahIndex;
  final int endGlobalAyahIndex;

  final DateTime scheduledDate;
  final int orderIndex;

  /// نسبة التقدم داخل الدورة: 0.25 / 0.5 / 0.75 / 1.0...
  /// لا تُستخدم لتقسيم الآيات، فقط لتوضيح سبب الاختبار.
  final double cycleProgress;

  final bool isMandatory;
  final int planVersion;
  final MemorizationTestPreferences preferences;

  const MemorizationScheduledTestModel({
    required this.id,
    required this.planId,
    required this.kind,
    required this.difficulty,
    required this.trigger,
    required this.startGlobalAyahIndex,
    required this.endGlobalAyahIndex,
    required this.scheduledDate,
    required this.orderIndex,
    required this.cycleProgress,
    required this.isMandatory,
    this.planVersion = 1,
    this.preferences = const MemorizationTestPreferences(),
  });

  int get ayahsCount {
    return endGlobalAyahIndex - startGlobalAyahIndex + 1;
  }

  bool get hasValidRange {
    return startGlobalAyahIndex >= 0 &&
        endGlobalAyahIndex >= startGlobalAyahIndex;
  }

  String get title {
    return trigger.title;
  }

  String get subtitle {
    if (isMandatory) return 'اختبار مهم في هذه المرحلة';
    return 'اختبار تثبيت قصير';
  }

  MemorizationTodayTaskModel toTodayTask() {
    final cleanDate = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
    );

    return MemorizationTodayTaskModel(
      id: id,
      planId: planId,
      type: 'selfTest',
      title: title,
      subtitle: subtitle,
      scopeTitle: 'اختبار حسب خطتك',
      startGlobalAyahIndex: startGlobalAyahIndex,
      endGlobalAyahIndex: endGlobalAyahIndex,
      expectedMinutes: _expectedMinutes(),
      testKindCode: kind.code,
      testTriggerCode: trigger.code,
      testStyleCode: preferences.style.code,
      testDifficultyPreferenceCode: preferences.difficulty.code,
      questionsCount: preferences.questionsPerTest,
      allowedQuestionTypeCodes: preferences.effectiveQuestionTypeCodes,
      attemptNumber: 1,
      planVersion: planVersion,
      isCompleted: false,
      status: MemorizationTodayTaskModel.statusNotStarted,
      scheduledDate: cleanDate,
      createdAt: cleanDate,
      updatedAt: cleanDate,
    );
  }

  int _expectedMinutes() {
    final base = difficulty == MemorizationTestDifficulty.easy
        ? 6
        : difficulty == MemorizationTestDifficulty.medium
        ? 9
        : 12;

    final extra = (ayahsCount / 12).ceil();
    return (base + extra).clamp(6, 35).toInt();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'planId': planId,
      'kind': kind.code,
      'difficulty': difficulty.code,
      'trigger': trigger.code,
      'startGlobalAyahIndex': startGlobalAyahIndex,
      'endGlobalAyahIndex': endGlobalAyahIndex,
      'scheduledDate': scheduledDate.toIso8601String(),
      'orderIndex': orderIndex,
      'cycleProgress': cycleProgress,
      'isMandatory': isMandatory,
      'planVersion': planVersion,
      'preferences': preferences.toMap(),
    };
  }

  factory MemorizationScheduledTestModel.fromMap(Map<String, dynamic> map) {
    return MemorizationScheduledTestModel(
      id: map['id']?.toString() ?? '',
      planId: map['planId']?.toString() ?? '',
      kind: MemorizationTestKindX.fromCode(map['kind']?.toString()),
      difficulty: MemorizationTestDifficultyX.fromCode(
        map['difficulty']?.toString(),
      ),
      trigger: MemorizationTestTriggerX.fromCode(map['trigger']?.toString()),
      startGlobalAyahIndex:
          int.tryParse(map['startGlobalAyahIndex']?.toString() ?? '') ?? 0,
      endGlobalAyahIndex:
          int.tryParse(map['endGlobalAyahIndex']?.toString() ?? '') ?? 0,
      scheduledDate:
          DateTime.tryParse(map['scheduledDate']?.toString() ?? '') ??
          DateTime.now(),
      orderIndex: int.tryParse(map['orderIndex']?.toString() ?? '') ?? 0,
      cycleProgress:
          double.tryParse(map['cycleProgress']?.toString() ?? '') ?? 0,
      isMandatory: map['isMandatory'] == true,
      planVersion: (int.tryParse(map['planVersion']?.toString() ?? '') ?? 1)
          .clamp(1, 99999)
          .toInt(),
      preferences: MemorizationTestPreferences.fromMap(map['preferences']),
    );
  }
}
