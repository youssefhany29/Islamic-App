import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class QuranMemorizationProgress {
  final String taskId;
  final int suraIndex;
  final int ayahIndex;
  final int globalAyahIndex;
  final int mushafPageNumber;
  final int pageStartGlobalAyahIndex;
  final int pageEndGlobalAyahIndex;

  /// continuous / mushafText / pngMushaf
  final String viewMode;

  /// reading / repeating / hiding / testing / completed
  final String step;

  final String updatedAt;

  const QuranMemorizationProgress({
    required this.taskId,
    required this.suraIndex,
    required this.ayahIndex,
    required this.globalAyahIndex,
    required this.mushafPageNumber,
    required this.pageStartGlobalAyahIndex,
    required this.pageEndGlobalAyahIndex,
    required this.viewMode,
    required this.step,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'suraIndex': suraIndex,
      'ayahIndex': ayahIndex,
      'globalAyahIndex': globalAyahIndex,
      'mushafPageNumber': mushafPageNumber,
      'pageStartGlobalAyahIndex': pageStartGlobalAyahIndex,
      'pageEndGlobalAyahIndex': pageEndGlobalAyahIndex,
      'viewMode': viewMode,
      'step': step,
      'updatedAt': updatedAt,
    };
  }

  factory QuranMemorizationProgress.fromMap(Map<String, dynamic> map) {
    return QuranMemorizationProgress(
      taskId: map['taskId']?.toString() ?? '',
      suraIndex: int.tryParse(map['suraIndex']?.toString() ?? '') ?? 0,
      ayahIndex: int.tryParse(map['ayahIndex']?.toString() ?? '') ?? 0,
      globalAyahIndex:
          int.tryParse(map['globalAyahIndex']?.toString() ?? '') ?? 0,
      mushafPageNumber:
          int.tryParse(map['mushafPageNumber']?.toString() ?? '') ?? 1,
      pageStartGlobalAyahIndex:
          int.tryParse(map['pageStartGlobalAyahIndex']?.toString() ?? '') ??
          (int.tryParse(map['globalAyahIndex']?.toString() ?? '') ?? 0),
      pageEndGlobalAyahIndex:
          int.tryParse(map['pageEndGlobalAyahIndex']?.toString() ?? '') ??
          (int.tryParse(map['globalAyahIndex']?.toString() ?? '') ?? 0),
      viewMode: map['viewMode']?.toString() ?? 'continuous',
      step: map['step']?.toString() ?? 'reading',
      updatedAt:
          map['updatedAt']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  QuranMemorizationProgress copyWith({
    String? taskId,
    int? suraIndex,
    int? ayahIndex,
    int? globalAyahIndex,
    int? mushafPageNumber,
    int? pageStartGlobalAyahIndex,
    int? pageEndGlobalAyahIndex,
    String? viewMode,
    String? step,
    String? updatedAt,
  }) {
    return QuranMemorizationProgress(
      taskId: taskId ?? this.taskId,
      suraIndex: suraIndex ?? this.suraIndex,
      ayahIndex: ayahIndex ?? this.ayahIndex,
      globalAyahIndex: globalAyahIndex ?? this.globalAyahIndex,
      mushafPageNumber: mushafPageNumber ?? this.mushafPageNumber,
      pageStartGlobalAyahIndex:
          pageStartGlobalAyahIndex ?? this.pageStartGlobalAyahIndex,
      pageEndGlobalAyahIndex:
          pageEndGlobalAyahIndex ?? this.pageEndGlobalAyahIndex,
      viewMode: viewMode ?? this.viewMode,
      step: step ?? this.step,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class QuranMemorizationProgressStorage {
  static const String _progressPrefix = 'quran_memorization_task_progress_';

  static String _key(String taskId) {
    return '$_progressPrefix$taskId';
  }

  static Future<void> saveProgress({
    required String taskId,
    required int suraIndex,
    required int ayahIndex,
    required int globalAyahIndex,
    required int mushafPageNumber,
    int? pageStartGlobalAyahIndex,
    int? pageEndGlobalAyahIndex,
    required String viewMode,
    String step = 'reading',
  }) async {
    if (taskId.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();

    final progress = QuranMemorizationProgress(
      taskId: taskId,
      suraIndex: suraIndex,
      ayahIndex: ayahIndex,
      globalAyahIndex: globalAyahIndex,
      mushafPageNumber: mushafPageNumber.clamp(1, 604).toInt(),
      pageStartGlobalAyahIndex: pageStartGlobalAyahIndex ?? globalAyahIndex,
      pageEndGlobalAyahIndex: pageEndGlobalAyahIndex ?? globalAyahIndex,
      viewMode: viewMode,
      step: step,
      updatedAt: DateTime.now().toIso8601String(),
    );

    await prefs.setString(_key(taskId), jsonEncode(progress.toMap()));
  }

  static Future<QuranMemorizationProgress?> getProgress(String taskId) async {
    if (taskId.trim().isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    final rawProgress = prefs.getString(_key(taskId));

    if (rawProgress == null || rawProgress.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawProgress);

      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      return QuranMemorizationProgress.fromMap(decoded);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearProgress(String taskId) async {
    if (taskId.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(taskId));
  }

  static Future<bool> hasProgress(String taskId) async {
    final progress = await getProgress(taskId);
    return progress != null;
  }
}
