import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class QuranReadingStats {
  final int totalCompletedWirds;
  final int totalCompletedPages;
  final int totalCompletedKhatmas;
  final int currentStreakDays;
  final String? lastReadingDate;

  const QuranReadingStats({
    required this.totalCompletedWirds,
    required this.totalCompletedPages,
    required this.totalCompletedKhatmas,
    required this.currentStreakDays,
    required this.lastReadingDate,
  });

  factory QuranReadingStats.empty() {
    return const QuranReadingStats(
      totalCompletedWirds: 0,
      totalCompletedPages: 0,
      totalCompletedKhatmas: 0,
      currentStreakDays: 0,
      lastReadingDate: null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCompletedWirds': totalCompletedWirds,
      'totalCompletedPages': totalCompletedPages,
      'totalCompletedKhatmas': totalCompletedKhatmas,
      'currentStreakDays': currentStreakDays,
      'lastReadingDate': lastReadingDate,
    };
  }

  factory QuranReadingStats.fromJson(Map<String, dynamic> json) {
    return QuranReadingStats(
      totalCompletedWirds:
      int.tryParse(json['totalCompletedWirds'].toString()) ?? 0,
      totalCompletedPages:
      int.tryParse(json['totalCompletedPages'].toString()) ?? 0,
      totalCompletedKhatmas:
      int.tryParse(json['totalCompletedKhatmas'].toString()) ?? 0,
      currentStreakDays:
      int.tryParse(json['currentStreakDays'].toString()) ?? 0,
      lastReadingDate: json['lastReadingDate']?.toString(),
    );
  }

  QuranReadingStats copyWith({
    int? totalCompletedWirds,
    int? totalCompletedPages,
    int? totalCompletedKhatmas,
    int? currentStreakDays,
    String? lastReadingDate,
  }) {
    return QuranReadingStats(
      totalCompletedWirds:
      totalCompletedWirds ?? this.totalCompletedWirds,
      totalCompletedPages:
      totalCompletedPages ?? this.totalCompletedPages,
      totalCompletedKhatmas:
      totalCompletedKhatmas ?? this.totalCompletedKhatmas,
      currentStreakDays:
      currentStreakDays ?? this.currentStreakDays,
      lastReadingDate:
      lastReadingDate ?? this.lastReadingDate,
    );
  }
}

class QuranReadingStatsStorage {
  static const String _statsKey = 'quran_reading_stats';

  static Future<QuranReadingStats> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    final rawStats = prefs.getString(_statsKey);

    if (rawStats == null || rawStats.trim().isEmpty) {
      return QuranReadingStats.empty();
    }

    try {
      final decoded = jsonDecode(rawStats) as Map<String, dynamic>;
      return QuranReadingStats.fromJson(decoded);
    } catch (_) {
      return QuranReadingStats.empty();
    }
  }

  static Future<void> saveStats(QuranReadingStats stats) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _statsKey,
      jsonEncode(stats.toJson()),
    );
  }

  static Future<void> recordCompletedWird({
    required int completedPages,
    required bool completedKhatma,
  }) async {
    final oldStats = await getStats();

    final today = _dateOnly(DateTime.now());
    final lastDate = oldStats.lastReadingDate;

    final newStreak = _calculateNewStreak(
      oldStreak: oldStats.currentStreakDays,
      lastReadingDate: lastDate,
      today: today,
    );

    final updatedStats = oldStats.copyWith(
      totalCompletedWirds: oldStats.totalCompletedWirds + 1,
      totalCompletedPages: oldStats.totalCompletedPages + completedPages,
      totalCompletedKhatmas: completedKhatma
          ? oldStats.totalCompletedKhatmas + 1
          : oldStats.totalCompletedKhatmas,
      currentStreakDays: newStreak,
      lastReadingDate: today,
    );

    await saveStats(updatedStats);
  }

  static Future<void> resetStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_statsKey);
  }

  static int _calculateNewStreak({
    required int oldStreak,
    required String? lastReadingDate,
    required String today,
  }) {
    if (lastReadingDate == null || lastReadingDate.trim().isEmpty) {
      return 1;
    }

    if (lastReadingDate == today) {
      return oldStreak <= 0 ? 1 : oldStreak;
    }

    final lastDate = DateTime.tryParse(lastReadingDate);
    final todayDate = DateTime.tryParse(today);

    if (lastDate == null || todayDate == null) {
      return 1;
    }

    final yesterday = todayDate.subtract(const Duration(days: 1));
    final yesterdayText = _dateOnly(yesterday);

    if (lastReadingDate == yesterdayText) {
      return oldStreak + 1;
    }

    return 1;
  }

  static String _dateOnly(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}