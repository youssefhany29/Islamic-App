import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PrayerTrackingStorage {
  static const String _checkedKey = 'prayer_tracking_checked';
  static const String _streakKey = 'prayer_tracking_streak';
  static const String _bestStreakKey = 'prayer_tracking_best_streak';
  static const String _lastDateKey = 'prayer_tracking_last_date';
  static const String _completedTodayKey = 'prayer_tracking_completed_today';
  static const String _dailyHistoryKey = 'prayer_tracking_daily_history';

  static const int prayersCount = 5;

  static String todayKey() {
    final now = DateTime.now();
    return _dateKey(now);
  }

  static String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String _yesterdayKey() {
    return _dateKey(DateTime.now().subtract(const Duration(days: 1)));
  }

  static Future<PrayerTrackingData> loadTrackingData() async {
    final prefs = await SharedPreferences.getInstance();

    final today = todayKey();
    final yesterday = _yesterdayKey();

    final lastDate = prefs.getString(_lastDateKey);

    int streak = prefs.getInt(_streakKey) ?? 0;
    int bestStreak = prefs.getInt(_bestStreakKey) ?? 0;
    bool completedToday = prefs.getBool(_completedTodayKey) ?? false;

    List<bool> checked = List<bool>.filled(prayersCount, false);

    if (lastDate != today) {
      if (lastDate != null && lastDate != yesterday) {
        streak = 0;
      }

      if (lastDate == yesterday && !completedToday) {
        streak = 0;
      }

      await prefs.setString(_lastDateKey, today);
      await prefs.setStringList(
        _checkedKey,
        List<String>.filled(prayersCount, 'false'),
      );
      await prefs.setBool(_completedTodayKey, false);
      await prefs.setInt(_streakKey, streak);
      await prefs.setInt(_bestStreakKey, bestStreak);

      completedToday = false;
    } else {
      final savedChecked = prefs.getStringList(_checkedKey);

      if (savedChecked != null && savedChecked.length == prayersCount) {
        checked = savedChecked.map((value) => value == 'true').toList();
      }
    }

    if (streak > bestStreak) {
      bestStreak = streak;
      await prefs.setInt(_bestStreakKey, bestStreak);
    }

    await _saveTodayHistory(
      checkedCount: checked.where((value) => value).length,
      completed: completedToday,
      checkedPrayers: checked,
    );

    final weeklyHistory = await getWeeklyHistory();
    final monthlyStats = await getMonthlyStats();

    return PrayerTrackingData(
      checked: checked,
      streak: streak,
      bestStreak: bestStreak,
      completedToday: completedToday,
      weeklyHistory: weeklyHistory,
      monthlyStats: monthlyStats,
    );
  }

  static Future<void> saveTrackingData({
    required List<bool> checked,
    required int streak,
    required bool completedToday,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final int currentBestStreak = prefs.getInt(_bestStreakKey) ?? 0;
    final int updatedBestStreak =
    streak > currentBestStreak ? streak : currentBestStreak;

    await prefs.setString(_lastDateKey, todayKey());
    await prefs.setStringList(
      _checkedKey,
      checked.map((value) => value.toString()).toList(),
    );
    await prefs.setInt(_streakKey, streak);
    await prefs.setInt(_bestStreakKey, updatedBestStreak);
    await prefs.setBool(_completedTodayKey, completedToday);

    await _saveTodayHistory(
      checkedCount: checked.where((value) => value).length,
      completed: completedToday,
      checkedPrayers: checked,
    );
  }

  static Future<void> resetTrackingData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_checkedKey);
    await prefs.remove(_streakKey);
    await prefs.remove(_bestStreakKey);
    await prefs.remove(_lastDateKey);
    await prefs.remove(_completedTodayKey);
    await prefs.remove(_dailyHistoryKey);

    await prefs.setString(_lastDateKey, todayKey());
  }

  static Future<void> _saveTodayHistory({
    required int checkedCount,
    required bool completed,
    required List<bool> checkedPrayers,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final history = await _loadHistoryMap();

    history[todayKey()] = PrayerDailyRecord(
      dateKey: todayKey(),
      completed: completed,
      checkedCount: checkedCount,
      checkedPrayers: checkedPrayers,
    );

    final filteredHistory = <String, PrayerDailyRecord>{};

    for (int i = 180; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final key = _dateKey(date);

      if (history.containsKey(key)) {
        filteredHistory[key] = history[key]!;
      }
    }

    await prefs.setString(
      _dailyHistoryKey,
      jsonEncode(
        filteredHistory.map(
              (key, value) => MapEntry(
            key,
            value.toJson(),
          ),
        ),
      ),
    );
  }

  static Future<Map<String, PrayerDailyRecord>> _loadHistoryMap() async {
    final prefs = await SharedPreferences.getInstance();

    final rawHistory = prefs.getString(_dailyHistoryKey);

    if (rawHistory == null || rawHistory.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(rawHistory);

      if (decoded is! Map) {
        await prefs.remove(_dailyHistoryKey);
        return {};
      }

      return decoded.map(
            (key, value) {
          final recordMap = Map<String, dynamic>.from(value as Map);

          return MapEntry(
            key.toString(),
            PrayerDailyRecord.fromJson(recordMap),
          );
        },
      );
    } catch (_) {
      await prefs.remove(_dailyHistoryKey);
      return {};
    }
  }

  static Future<List<PrayerWeeklyDay>> getWeeklyHistory() async {
    final history = await _loadHistoryMap();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final int daysFromSaturday = (today.weekday + 1) % 7;
    final DateTime weekStart = today.subtract(
      Duration(days: daysFromSaturday),
    );

    final List<PrayerWeeklyDay> days = [];

    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final key = _dateKey(normalizedDate);
      final record = history[key];
      final bool isFuture = normalizedDate.isAfter(today);

      days.add(
        PrayerWeeklyDay(
          dateKey: key,
          dayName: _arabicShortDayName(normalizedDate.weekday),
          completed: record?.completed ?? false,
          checkedCount: record?.checkedCount ?? 0,
          isToday: key == todayKey(),
          isFuture: isFuture,
        ),
      );
    }

    return days;
  }

  static Future<PrayerMonthlyStats> getMonthlyStats() async {
    final history = await _loadHistoryMap();
    final now = DateTime.now();

    final monthRecords = history.values.where((record) {
      final parts = record.dateKey.split('-');

      if (parts.length != 3) return false;

      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);

      return year == now.year && month == now.month;
    }).toList();

    final int completedDays =
        monthRecords.where((record) => record.completed).length;

    final int totalLoggedPrayers = monthRecords.fold<int>(
      0,
          (sum, record) => sum + record.checkedCount,
    );

    final int daysWithAnyProgress =
        monthRecords.where((record) => record.checkedCount > 0).length;

    final int daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    final double monthlyCompletionRate =
    daysInMonth == 0 ? 0 : completedDays / daysInMonth;

    return PrayerMonthlyStats(
      completedDays: completedDays,
      totalLoggedPrayers: totalLoggedPrayers,
      daysWithAnyProgress: daysWithAnyProgress,
      daysInMonth: daysInMonth,
      completionRate: monthlyCompletionRate,
    );
  }

  static Future<List<PrayerMonthlyDay>> getCurrentMonthHistory() async {
    final history = await _loadHistoryMap();
    final now = DateTime.now();

    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final List<PrayerMonthlyDay> days = [];

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(now.year, now.month, day);
      final key = _dateKey(date);
      final record = history[key];

      days.add(
        PrayerMonthlyDay(
          dateKey: key,
          dayNumber: day,
          completed: record?.completed ?? false,
          checkedCount: record?.checkedCount ?? 0,
          checkedPrayers:
          record?.checkedPrayers ?? List<bool>.filled(prayersCount, false),
          isToday: key == todayKey(),
          isFuture: date.isAfter(
            DateTime(now.year, now.month, now.day),
          ),
        ),
      );
    }

    return days;
  }

  static Future<int> getBestStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_bestStreakKey) ?? 0;
  }

  static String _arabicShortDayName(int weekday) {
    const days = [
      'إث',
      'ث',
      'أر',
      'خ',
      'ج',
      'س',
      'أح',
    ];

    return days[weekday - 1];
  }
}

class PrayerTrackingData {
  final List<bool> checked;
  final int streak;
  final int bestStreak;
  final bool completedToday;
  final List<PrayerWeeklyDay> weeklyHistory;
  final PrayerMonthlyStats monthlyStats;

  const PrayerTrackingData({
    required this.checked,
    required this.streak,
    required this.bestStreak,
    required this.completedToday,
    required this.weeklyHistory,
    required this.monthlyStats,
  });
}

class PrayerWeeklyDay {
  final String dateKey;
  final String dayName;
  final bool completed;
  final int checkedCount;
  final bool isToday;
  final bool isFuture;

  const PrayerWeeklyDay({
    required this.dateKey,
    required this.dayName,
    required this.completed,
    required this.checkedCount,
    required this.isToday,
    this.isFuture = false,
  });
}

class PrayerMonthlyDay {
  final String dateKey;
  final int dayNumber;
  final bool completed;
  final int checkedCount;
  final List<bool> checkedPrayers;
  final bool isToday;
  final bool isFuture;

  const PrayerMonthlyDay({
    required this.dateKey,
    required this.dayNumber,
    required this.completed,
    required this.checkedCount,
    required this.checkedPrayers,
    required this.isToday,
    required this.isFuture,
  });
}

class PrayerDailyRecord {
  final String dateKey;
  final bool completed;
  final int checkedCount;
  final List<bool> checkedPrayers;

  const PrayerDailyRecord({
    required this.dateKey,
    required this.completed,
    required this.checkedCount,
    required this.checkedPrayers,
  });

  factory PrayerDailyRecord.fromJson(Map<String, dynamic> json) {
    final rawCheckedPrayers = json['checkedPrayers'];

    List<bool> parsedCheckedPrayers = List<bool>.filled(
      PrayerTrackingStorage.prayersCount,
      false,
    );

    if (rawCheckedPrayers is List) {
      parsedCheckedPrayers = rawCheckedPrayers
          .map((value) => value == true || value.toString() == 'true')
          .toList();

      if (parsedCheckedPrayers.length != PrayerTrackingStorage.prayersCount) {
        parsedCheckedPrayers = List<bool>.filled(
          PrayerTrackingStorage.prayersCount,
          false,
        );
      }
    }

    return PrayerDailyRecord(
      dateKey: json['dateKey']?.toString() ?? '',
      completed: json['completed'] == true,
      checkedCount: int.tryParse(json['checkedCount'].toString()) ?? 0,
      checkedPrayers: parsedCheckedPrayers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateKey': dateKey,
      'completed': completed,
      'checkedCount': checkedCount,
      'checkedPrayers': checkedPrayers,
    };
  }
}

class PrayerMonthlyStats {
  final int completedDays;
  final int totalLoggedPrayers;
  final int daysWithAnyProgress;
  final int daysInMonth;
  final double completionRate;

  const PrayerMonthlyStats({
    required this.completedDays,
    required this.totalLoggedPrayers,
    required this.daysWithAnyProgress,
    required this.daysInMonth,
    required this.completionRate,
  });
}