import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/memorization_test_question_model.dart';

class MemorizationQuestionHistoryStorage {
  static const String _storageKey = 'memorization_question_history_v1';
  static const int _maxStoredAttempts = 40;

  const MemorizationQuestionHistoryStorage();

  Future<Set<String>> getRecentFingerprints({
    required String planId,
    int recentAttempts = 5,
  }) async {
    final entries = await _read();
    final attemptKeys = <String>[];
    final fingerprintsByAttempt = <String, Set<String>>{};

    for (final entry in entries.reversed) {
      if (entry.planId != planId) continue;
      if (!fingerprintsByAttempt.containsKey(entry.attemptKey)) {
        if (attemptKeys.length >= recentAttempts) continue;
        attemptKeys.add(entry.attemptKey);
        fingerprintsByAttempt[entry.attemptKey] = <String>{};
      }
      fingerprintsByAttempt[entry.attemptKey]?.add(entry.fingerprint);
    }

    return {for (final values in fingerprintsByAttempt.values) ...values};
  }

  Future<void> saveAttempt({
    required String planId,
    required String taskId,
    required int attemptNumber,
    required List<MemorizationTestQuestionModel> questions,
    DateTime? completedAt,
  }) async {
    if (questions.isEmpty) return;
    final now = completedAt ?? DateTime.now();
    final attemptKey =
        '${taskId}_${attemptNumber}_${now.microsecondsSinceEpoch}';
    final entries = await _read();

    entries.addAll(
      questions.map(
        (question) => _QuestionHistoryEntry(
          planId: planId,
          taskId: taskId,
          attemptKey: attemptKey,
          fingerprint: question.questionFingerprint,
          questionType: question.type.code,
          startGlobalAyahIndex: question.startGlobalAyahIndex,
          endGlobalAyahIndex: question.endGlobalAyahIndex,
          completedAt: now,
        ),
      ),
    );

    final attempts = <String>[];
    for (final entry in entries.reversed) {
      if (!attempts.contains(entry.attemptKey)) attempts.add(entry.attemptKey);
    }
    final retainedAttempts = attempts.take(_maxStoredAttempts).toSet();
    final retained = entries
        .where((entry) => retainedAttempts.contains(entry.attemptKey))
        .toList(growable: false);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(retained.map((entry) => entry.toMap()).toList()),
    );
  }

  Future<List<_QuestionHistoryEntry>> _read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) return <_QuestionHistoryEntry>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <_QuestionHistoryEntry>[];
      return decoded
          .whereType<Map>()
          .map(
            (item) =>
                _QuestionHistoryEntry.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (_) {
      return <_QuestionHistoryEntry>[];
    }
  }
}

class _QuestionHistoryEntry {
  final String planId;
  final String taskId;
  final String attemptKey;
  final String fingerprint;
  final String questionType;
  final int startGlobalAyahIndex;
  final int endGlobalAyahIndex;
  final DateTime completedAt;

  const _QuestionHistoryEntry({
    required this.planId,
    required this.taskId,
    required this.attemptKey,
    required this.fingerprint,
    required this.questionType,
    required this.startGlobalAyahIndex,
    required this.endGlobalAyahIndex,
    required this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'planId': planId,
      'taskId': taskId,
      'attemptKey': attemptKey,
      'fingerprint': fingerprint,
      'questionType': questionType,
      'startGlobalAyahIndex': startGlobalAyahIndex,
      'endGlobalAyahIndex': endGlobalAyahIndex,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory _QuestionHistoryEntry.fromMap(Map<String, dynamic> map) {
    return _QuestionHistoryEntry(
      planId: map['planId']?.toString() ?? '',
      taskId: map['taskId']?.toString() ?? '',
      attemptKey: map['attemptKey']?.toString() ?? '',
      fingerprint: map['fingerprint']?.toString() ?? '',
      questionType: map['questionType']?.toString() ?? '',
      startGlobalAyahIndex:
          int.tryParse(map['startGlobalAyahIndex']?.toString() ?? '') ?? 0,
      endGlobalAyahIndex:
          int.tryParse(map['endGlobalAyahIndex']?.toString() ?? '') ?? 0,
      completedAt:
          DateTime.tryParse(map['completedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
