import 'package:shared_preferences/shared_preferences.dart';

class TabletAppUsageStreakSnapshot {
  final int currentStreakDays;
  final int bestStreakDays;
  final int totalActiveDays;
  final String? lastActiveDateKey;

  const TabletAppUsageStreakSnapshot({
    required this.currentStreakDays,
    required this.bestStreakDays,
    required this.totalActiveDays,
    required this.lastActiveDateKey,
  });

  factory TabletAppUsageStreakSnapshot.empty() {
    return const TabletAppUsageStreakSnapshot(
      currentStreakDays: 0,
      bestStreakDays: 0,
      totalActiveDays: 0,
      lastActiveDateKey: null,
    );
  }
}

class TabletAppUsageStreakStorage {
  const TabletAppUsageStreakStorage._();

  static const String _currentStreakKey =
      'tablet_app_usage_current_streak_days_v1';
  static const String _bestStreakKey = 'tablet_app_usage_best_streak_days_v1';
  static const String _totalActiveDaysKey =
      'tablet_app_usage_total_active_days_v1';
  static const String _lastActiveDateKey =
      'tablet_app_usage_last_active_date_key_v1';

  static Future<TabletAppUsageStreakSnapshot> recordTodayAndLoad() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final String today = _dateKey(DateTime.now());
    final String yesterday = _dateKey(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    final String? lastActiveDate = prefs.getString(_lastActiveDateKey);

    int currentStreak = prefs.getInt(_currentStreakKey) ?? 0;
    int bestStreak = prefs.getInt(_bestStreakKey) ?? 0;
    int totalActiveDays = prefs.getInt(_totalActiveDaysKey) ?? 0;

    if (lastActiveDate == today) {
      return TabletAppUsageStreakSnapshot(
        currentStreakDays: currentStreak,
        bestStreakDays: bestStreak,
        totalActiveDays: totalActiveDays,
        lastActiveDateKey: lastActiveDate,
      );
    }

    if (lastActiveDate == yesterday) {
      currentStreak += 1;
    } else {
      currentStreak = 1;
    }

    totalActiveDays += 1;

    if (currentStreak > bestStreak) {
      bestStreak = currentStreak;
    }

    await prefs.setString(_lastActiveDateKey, today);
    await prefs.setInt(_currentStreakKey, currentStreak);
    await prefs.setInt(_bestStreakKey, bestStreak);
    await prefs.setInt(_totalActiveDaysKey, totalActiveDays);

    return TabletAppUsageStreakSnapshot(
      currentStreakDays: currentStreak,
      bestStreakDays: bestStreak,
      totalActiveDays: totalActiveDays,
      lastActiveDateKey: today,
    );
  }

  static String _dateKey(DateTime date) {
    final String year = date.year.toString().padLeft(4, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}