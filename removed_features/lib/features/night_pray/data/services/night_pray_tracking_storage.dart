import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class NightPrayTrackingStorage {
  static const String _checkedKey = 'night_pray_tracking_checked';
  static const String _streakKey = 'night_pray_tracking_streak';
  static const String _bestStreakKey = 'night_pray_tracking_best_streak';
  static const String _lastDateKey = 'night_pray_tracking_last_date';
  static const String _completedTodayKey = 'night_pray_tracking_completed_today';
  static const String _dailyHistoryKey = 'night_pray_tracking_daily_history';

  static const int itemsCount = 5;

  static String todayKey() {
    final now = DateTime.now();
    return _dateKey(now);
  }

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static String _yesterdayKey() {
    return _dateKey(DateTime.now().subtract(const Duration(days: 1)));
  }

  static Future<NightPrayTrackingData> loadTrackingData() async {
    final prefs = await SharedPreferences.getInstance();

    final today = todayKey();
    final yesterday = _yesterdayKey();
    final lastDate = prefs.getString(_lastDateKey);

    int streak = prefs.getInt(_streakKey) ?? 0;
    int bestStreak = prefs.getInt(_bestStreakKey) ?? 0;
    bool completedToday = prefs.getBool(_completedTodayKey) ?? false;
    List<bool> checked = List<bool>.filled(itemsCount, false);

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
        List<String>.filled(itemsCount, 'false'),
      );
      await prefs.setBool(_completedTodayKey, false);
      await prefs.setInt(_streakKey, streak);
      await prefs.setInt(_bestStreakKey, bestStreak);

      completedToday = false;
    } else {
      final savedChecked = prefs.getStringList(_checkedKey);

      if (savedChecked != null && savedChecked.length == itemsCount) {
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
      checkedItems: checked,
    );

    final weeklyHistory = await getWeeklyHistory();
    final monthlyStats = await getMonthlyStats();

    return NightPrayTrackingData(
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

    final currentBestStreak = prefs.getInt(_bestStreakKey) ?? 0;
    final updatedBestStreak = streak > currentBestStreak ? streak : currentBestStreak;

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
      checkedItems: checked,
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
    required List<bool> checkedItems,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await _loadHistoryMap();

    history[todayKey()] = NightPrayDailyRecord(
      dateKey: todayKey(),
      completed: completed,
      checkedCount: checkedCount,
      checkedItems: checkedItems,
    );

    final filteredHistory = <String, NightPrayDailyRecord>{};

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
          (key, value) => MapEntry(key, value.toJson()),
        ),
      ),
    );
  }

  static Future<Map<String, NightPrayDailyRecord>> _loadHistoryMap() async {
    final prefs = await SharedPreferences.getInstance();
    final rawHistory = prefs.getString(_dailyHistoryKey);

    if (rawHistory == null || rawHistory.isEmpty) {
      return {};
    }

    final decoded = jsonDecode(rawHistory);

    if (decoded is! Map) {
      return {};
    }

    return decoded.map((key, value) {
      final recordMap = Map<String, dynamic>.from(value as Map);
      return MapEntry(
        key.toString(),
        NightPrayDailyRecord.fromJson(recordMap),
      );
    });
  }

  static Future<List<NightPrayWeeklyDay>> getWeeklyHistory() async {
    final history = await _loadHistoryMap();
    final days = <NightPrayWeeklyDay>[];

    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final key = _dateKey(date);
      final record = history[key];

      days.add(
        NightPrayWeeklyDay(
          dateKey: key,
          dayName: _arabicShortDayName(date.weekday),
          completed: record?.completed ?? false,
          checkedCount: record?.checkedCount ?? 0,
          isToday: key == todayKey(),
        ),
      );
    }

    return days;
  }

  static Future<NightPrayMonthlyStats> getMonthlyStats() async {
    final history = await _loadHistoryMap();
    final now = DateTime.now();

    final monthRecords = history.values.where((record) {
      final parts = record.dateKey.split('-');
      if (parts.length != 3) return false;

      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);

      return year == now.year && month == now.month;
    }).toList();

    final completedNights = monthRecords.where((record) => record.completed).length;
    final totalLoggedItems = monthRecords.fold<int>(
      0,
      (sum, record) => sum + record.checkedCount,
    );
    final nightsWithAnyProgress = monthRecords.where((record) => record.checkedCount > 0).length;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final completionRate = daysInMonth == 0 ? 0.0 : completedNights / daysInMonth;

    return NightPrayMonthlyStats(
      completedNights: completedNights,
      totalLoggedItems: totalLoggedItems,
      nightsWithAnyProgress: nightsWithAnyProgress,
      daysInMonth: daysInMonth,
      completionRate: completionRate,
    );
  }

  static Future<List<NightPrayMonthlyDay>> getCurrentMonthHistory() async {
    final history = await _loadHistoryMap();
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final days = <NightPrayMonthlyDay>[];

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(now.year, now.month, day);
      final key = _dateKey(date);
      final record = history[key];

      days.add(
        NightPrayMonthlyDay(
          dateKey: key,
          dayNumber: day,
          completed: record?.completed ?? false,
          checkedCount: record?.checkedCount ?? 0,
          checkedItems: record?.checkedItems ?? List<bool>.filled(itemsCount, false),
          isToday: key == todayKey(),
          isFuture: date.isAfter(DateTime(now.year, now.month, now.day)),
        ),
      );
    }

    return days;
  }

  static String _arabicShortDayName(int weekday) {
    const days = ['إث', 'ث', 'أر', 'خ', 'ج', 'س', 'أح'];
    return days[weekday - 1];
  }
}

class NightPrayTrackingData {
  final List<bool> checked;
  final int streak;
  final int bestStreak;
  final bool completedToday;
  final List<NightPrayWeeklyDay> weeklyHistory;
  final NightPrayMonthlyStats monthlyStats;

  const NightPrayTrackingData({
    required this.checked,
    required this.streak,
    required this.bestStreak,
    required this.completedToday,
    required this.weeklyHistory,
    required this.monthlyStats,
  });
}

class NightPrayWeeklyDay {
  final String dateKey;
  final String dayName;
  final bool completed;
  final int checkedCount;
  final bool isToday;

  const NightPrayWeeklyDay({
    required this.dateKey,
    required this.dayName,
    required this.completed,
    required this.checkedCount,
    required this.isToday,
  });
}

class NightPrayMonthlyDay {
  final String dateKey;
  final int dayNumber;
  final bool completed;
  final int checkedCount;
  final List<bool> checkedItems;
  final bool isToday;
  final bool isFuture;

  const NightPrayMonthlyDay({
    required this.dateKey,
    required this.dayNumber,
    required this.completed,
    required this.checkedCount,
    required this.checkedItems,
    required this.isToday,
    required this.isFuture,
  });
}

class NightPrayMonthlyStats {
  final int completedNights;
  final int totalLoggedItems;
  final int nightsWithAnyProgress;
  final int daysInMonth;
  final double completionRate;

  const NightPrayMonthlyStats({
    required this.completedNights,
    required this.totalLoggedItems,
    required this.nightsWithAnyProgress,
    required this.daysInMonth,
    required this.completionRate,
  });
}

class NightPrayDailyRecord {
  final String dateKey;
  final bool completed;
  final int checkedCount;
  final List<bool> checkedItems;

  const NightPrayDailyRecord({
    required this.dateKey,
    required this.completed,
    required this.checkedCount,
    required this.checkedItems,
  });

  Map<String, dynamic> toJson() {
    return {
      'dateKey': dateKey,
      'completed': completed,
      'checkedCount': checkedCount,
      'checkedItems': checkedItems,
    };
  }

  factory NightPrayDailyRecord.fromJson(Map<String, dynamic> json) {
    return NightPrayDailyRecord(
      dateKey: json['dateKey']?.toString() ?? '',
      completed: json['completed'] == true,
      checkedCount: json['checkedCount'] is int ? json['checkedCount'] as int : 0,
      checkedItems: json['checkedItems'] is List
          ? (json['checkedItems'] as List).map((value) => value == true).toList()
          : List<bool>.filled(NightPrayTrackingStorage.itemsCount, false),
    );
  }
}
