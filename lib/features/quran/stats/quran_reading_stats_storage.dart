import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../reader/data/qpc_reader_perf.dart';

class QuranReadingStats {
  final int totalCompletedWirds;
  final int totalCompletedPages;
  final int totalCompletedKhatmas;
  final int currentStreakDays;
  final String? lastReadingDate;
  final int totalReadPages;
  final int totalReadWords;
  final String? lastActivityAt;
  final String? lastStreakIncrementAt;

  const QuranReadingStats({
    required this.totalCompletedWirds,
    required this.totalCompletedPages,
    required this.totalCompletedKhatmas,
    required this.currentStreakDays,
    required this.lastReadingDate,
    required this.totalReadPages,
    required this.totalReadWords,
    required this.lastActivityAt,
    required this.lastStreakIncrementAt,
  });

  factory QuranReadingStats.empty() {
    return const QuranReadingStats(
      totalCompletedWirds: 0,
      totalCompletedPages: 0,
      totalCompletedKhatmas: 0,
      currentStreakDays: 0,
      lastReadingDate: null,
      totalReadPages: 0,
      totalReadWords: 0,
      lastActivityAt: null,
      lastStreakIncrementAt: null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCompletedWirds': totalCompletedWirds,
      'totalCompletedPages': totalCompletedPages,
      'totalCompletedKhatmas': totalCompletedKhatmas,
      'currentStreakDays': currentStreakDays,
      'lastReadingDate': lastReadingDate,
      'totalReadPages': totalReadPages,
      'totalReadWords': totalReadWords,
      'lastActivityAt': lastActivityAt,
      'lastStreakIncrementAt': lastStreakIncrementAt,
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
      totalReadPages: int.tryParse(json['totalReadPages'].toString()) ?? 0,
      totalReadWords: int.tryParse(json['totalReadWords'].toString()) ?? 0,
      lastActivityAt: json['lastActivityAt']?.toString(),
      lastStreakIncrementAt: json['lastStreakIncrementAt']?.toString(),
    );
  }

  QuranReadingStats copyWith({
    int? totalCompletedWirds,
    int? totalCompletedPages,
    int? totalCompletedKhatmas,
    int? currentStreakDays,
    String? lastReadingDate,
    int? totalReadPages,
    int? totalReadWords,
    String? lastActivityAt,
    String? lastStreakIncrementAt,
  }) {
    return QuranReadingStats(
      totalCompletedWirds: totalCompletedWirds ?? this.totalCompletedWirds,
      totalCompletedPages: totalCompletedPages ?? this.totalCompletedPages,
      totalCompletedKhatmas:
          totalCompletedKhatmas ?? this.totalCompletedKhatmas,
      currentStreakDays: currentStreakDays ?? this.currentStreakDays,
      lastReadingDate: lastReadingDate ?? this.lastReadingDate,
      totalReadPages: totalReadPages ?? this.totalReadPages,
      totalReadWords: totalReadWords ?? this.totalReadWords,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      lastStreakIncrementAt:
          lastStreakIncrementAt ?? this.lastStreakIncrementAt,
    );
  }
}

class QuranReadingStatsStorage {
  static Future<SharedPreferences>? _prefsFuture;

  static const String _statsKey = 'quran_reading_stats';
  static const String _readPagesKey = 'quran_independent_read_pages';
  static const String _readPageWordCountsKey =
      'quran_independent_read_page_word_counts';

  static Future<SharedPreferences> _prefs() {
    return _prefsFuture ??= SharedPreferences.getInstance();
  }

  static Future<QuranReadingStats> getStats() async {
    final prefs = await _prefs();
    final rawStats = prefs.getString(_statsKey);

    QuranReadingStats stats;

    if (rawStats == null || rawStats.trim().isEmpty) {
      stats = QuranReadingStats.empty();
    } else {
      try {
        final decoded = jsonDecode(rawStats) as Map<String, dynamic>;
        stats = QuranReadingStats.fromJson(decoded);
      } catch (_) {
        stats = QuranReadingStats.empty();
      }
    }

    final readPages = prefs.getStringList(_readPagesKey) ?? const <String>[];
    final wordCounts = await getReadPageWordCounts();

    stats = stats.copyWith(
      totalReadPages: readPages.toSet().length,
      totalReadWords: _sumWordCounts(wordCounts),
    );

    if (_isActivityExpired(stats.lastActivityAt)) {
      stats = stats.copyWith(currentStreakDays: 0, lastStreakIncrementAt: null);
      await saveStats(stats);
    }

    return stats;
  }

  static Future<void> saveStats(QuranReadingStats stats) async {
    final prefs = await _prefs();

    await prefs.setString(_statsKey, jsonEncode(stats.toJson()));
  }

  static Future<List<int>> getReadPageNumbers() async {
    final prefs = await _prefs();
    final saved = prefs.getStringList(_readPagesKey) ?? const <String>[];

    final pages =
        saved
            .map((value) => int.tryParse(value))
            .whereType<int>()
            .where((page) => page >= 1 && page <= 604)
            .toSet()
            .toList()
          ..sort();

    return pages;
  }

  static Future<Map<int, int>> getReadPageWordCounts() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_readPageWordCountsKey);

    if (raw == null || raw.trim().isEmpty) {
      return <int, int>{};
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((key, value) {
        final page = int.tryParse(key) ?? 0;
        final words = int.tryParse(value.toString()) ?? 0;
        return MapEntry(page, words);
      })..removeWhere((page, words) => page < 1 || page > 604 || words <= 0);
    } catch (_) {
      return <int, int>{};
    }
  }

  static Future<void> saveReadPageWordCount({
    required int pageNumber,
    required int wordCount,
  }) async {
    final safePageNumber = pageNumber.clamp(1, 604).toInt();
    final safeWordCount = wordCount < 0 ? 0 : wordCount;
    if (safeWordCount <= 0) return;

    final prefs = await _prefs();
    final wordCounts = await getReadPageWordCounts();

    wordCounts[safePageNumber] = safeWordCount;

    final encoded = wordCounts.map(
      (page, words) => MapEntry(page.toString(), words),
    );

    await prefs.setString(_readPageWordCountsKey, jsonEncode(encoded));

    final oldStats = await getStats();
    await saveStats(
      oldStats.copyWith(totalReadWords: _sumWordCounts(wordCounts)),
    );
  }

  /// يسجل أي نشاط داخل قسم القرآن.
  /// الستريك لا يزيد مع كل ضغطة.
  /// يزيد مرة واحدة فقط بعد مرور 24 ساعة من آخر زيادة للستريك.
  /// أما lastActivityAt فيتحدث مع كل نشاط عشان نعرف آخر استخدام لقسم القرآن.
  static Future<void> recordQuranActivity() async {
    final oldStats = await getStats();
    final now = DateTime.now();

    final activityExpired = _isActivityExpired(oldStats.lastActivityAt);
    final canIncrementStreak =
        activityExpired || _canIncreaseStreak(oldStats.lastStreakIncrementAt);

    final updatedStats = oldStats.copyWith(
      currentStreakDays: canIncrementStreak
          ? (activityExpired ? 1 : oldStats.currentStreakDays + 1)
          : oldStats.currentStreakDays,
      lastActivityAt: now.toIso8601String(),
      lastStreakIncrementAt: canIncrementStreak
          ? now.toIso8601String()
          : oldStats.lastStreakIncrementAt,
    );

    await saveStats(updatedStats);
  }

  /// الصفحات المقروءة هنا مستقلة عن رقم آخر صفحة وصل لها المستخدم.
  /// الرقم هنا يعني عدد الصفحات التي قرأها المستخدم على مدار الوقت.
  /// الصفحة الواحدة تُحسب مرة واحدة حتى لا يزيد العداد بسبب rebuild أو الرجوع لنفس الصفحة.
  static Future<void> recordReadPage(int pageNumber, {int? wordCount}) async {
    final safePageNumber = pageNumber.clamp(1, 604).toInt();
    await QpcReaderPerf.timeAsync(
      'record read page p$safePageNumber',
      () async {
        final prefs = await _prefs();

        final pages = (prefs.getStringList(_readPagesKey) ?? <String>[])
            .toSet();
        final wasAdded = pages.add(safePageNumber.toString());

        await prefs.setStringList(_readPagesKey, pages.toList()..sort());

        if (wordCount != null && wordCount > 0) {
          await saveReadPageWordCount(
            pageNumber: safePageNumber,
            wordCount: wordCount,
          );
        }

        final wordCounts = await getReadPageWordCounts();
        final oldStats = await getStats();

        await saveStats(
          oldStats.copyWith(
            totalReadPages: pages.length,
            totalReadWords: _sumWordCounts(wordCounts),
          ),
        );

        if (wasAdded) {
          await recordQuranActivity();
        }
      },
    );
  }

  static Future<void> resetReadPages() async {
    final prefs = await _prefs();
    await prefs.remove(_readPagesKey);
    await prefs.remove(_readPageWordCountsKey);

    final oldStats = await getStats();
    await saveStats(oldStats.copyWith(totalReadPages: 0, totalReadWords: 0));
  }

  static Future<void> recordCompletedWird({
    required int completedPages,
    required bool completedKhatma,
  }) async {
    final oldStats = await getStats();

    final today = _dateOnly(DateTime.now());

    final updatedStats = oldStats.copyWith(
      totalCompletedWirds: oldStats.totalCompletedWirds + 1,
      totalCompletedPages: oldStats.totalCompletedPages + completedPages,
      totalCompletedKhatmas: completedKhatma
          ? oldStats.totalCompletedKhatmas + 1
          : oldStats.totalCompletedKhatmas,
      lastReadingDate: today,
    );

    await saveStats(updatedStats);
    await recordQuranActivity();
  }

  static Future<void> resetStats() async {
    final prefs = await _prefs();
    await prefs.remove(_statsKey);
    await prefs.remove(_readPagesKey);
    await prefs.remove(_readPageWordCountsKey);
  }

  static int _sumWordCounts(Map<int, int> wordCounts) {
    return wordCounts.values.fold<int>(0, (sum, value) => sum + value);
  }

  static bool _isActivityExpired(String? lastActivityAt) {
    if (lastActivityAt == null || lastActivityAt.trim().isEmpty) {
      return true;
    }

    final lastActivity = DateTime.tryParse(lastActivityAt);
    if (lastActivity == null) return true;

    return DateTime.now().difference(lastActivity) >= const Duration(hours: 48);
  }

  static bool _canIncreaseStreak(String? lastStreakIncrementAt) {
    if (lastStreakIncrementAt == null || lastStreakIncrementAt.trim().isEmpty) {
      return true;
    }

    final lastIncrement = DateTime.tryParse(lastStreakIncrementAt);
    if (lastIncrement == null) return true;

    return DateTime.now().difference(lastIncrement) >=
        const Duration(hours: 24);
  }

  static String _dateOnly(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
