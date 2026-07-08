import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class QuranWirdProgress {
  final String planId;
  final int suraIndex;
  final int ayahIndex;
  final int mushafPageNumber;
  final String viewMode;
  final String updatedAt;

  const QuranWirdProgress({
    required this.planId,
    required this.suraIndex,
    required this.ayahIndex,
    required this.mushafPageNumber,
    required this.viewMode,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'planId': planId,
      'suraIndex': suraIndex,
      'ayahIndex': ayahIndex,
      'mushafPageNumber': mushafPageNumber,
      'viewMode': viewMode,
      'updatedAt': updatedAt,
    };
  }

  factory QuranWirdProgress.fromMap(Map<String, dynamic> map) {
    return QuranWirdProgress(
      planId: map['planId'].toString(),
      suraIndex: int.tryParse(map['suraIndex'].toString()) ?? 0,
      ayahIndex: int.tryParse(map['ayahIndex'].toString()) ?? 0,
      mushafPageNumber: int.tryParse(map['mushafPageNumber'].toString()) ?? 1,
      viewMode: map['viewMode']?.toString() ?? 'pngMushaf',
      updatedAt:
          map['updatedAt']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }
}

class QuranWirdProgressStorage {
  static const String _progressPrefix = 'quran_wird_progress_';
  static const String _completedTodayPrefix = 'quran_wird_completed_today_';

  static String _key(String planId) => '$_progressPrefix$planId';

  static String _completedTodayKey(String planId) {
    return '$_completedTodayPrefix$planId';
  }

  static String _todayKey() {
    final now = DateTime.now();

    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  static Future<void> saveProgress({
    required String planId,
    required int suraIndex,
    required int ayahIndex,
    required int mushafPageNumber,
    required String viewMode,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final progress = QuranWirdProgress(
      planId: planId,
      suraIndex: suraIndex,
      ayahIndex: ayahIndex,
      mushafPageNumber: mushafPageNumber,
      viewMode: viewMode,
      updatedAt: DateTime.now().toIso8601String(),
    );

    await prefs.setString(_key(planId), jsonEncode(progress.toMap()));
  }

  static Future<QuranWirdProgress?> getProgress(String planId) async {
    final prefs = await SharedPreferences.getInstance();
    final rawProgress = prefs.getString(_key(planId));

    if (rawProgress == null || rawProgress.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawProgress) as Map<String, dynamic>;
      return QuranWirdProgress.fromMap(decoded);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearProgress(String planId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(planId));
  }

  static Future<void> markTodayCompleted(String planId) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_completedTodayKey(planId), _todayKey());
  }

  static Future<bool> wasCompletedToday(String planId) async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_completedTodayKey(planId)) == _todayKey();
  }

  static Future<void> clearTodayCompleted(String planId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_completedTodayKey(planId));
  }
}
