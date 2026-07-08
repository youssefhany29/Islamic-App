import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/recitation_custom_goal_model.dart';
import '../notifications/recitation_achievement_notification_scheduler.dart';
import '../settings/recitation_notification_settings_provider.dart';
import 'recitation_listening_stats_storage.dart';

class RecitationCustomGoalProgress {
  final RecitationCustomGoal goal;
  final int currentValue;
  final int targetValue;

  const RecitationCustomGoalProgress({
    required this.goal,
    required this.currentValue,
    required this.targetValue,
  });

  bool get completed => currentValue >= targetValue;

  double get progress {
    if (targetValue <= 0) return 0;
    return (currentValue / targetValue).clamp(0.0, 1.0);
  }

  String get progressText {
    return '$currentValue / $targetValue ${goal.type.info.unit}';
  }
}

class RecitationCustomGoalsStorage {
  RecitationCustomGoalsStorage._();

  static const String _goalsKey = 'recitation_custom_goals';
  static const String _notifiedCompletedGoalsKey =
      'recitation_custom_goals_notified_completed';

  static const String _surahHistoryKey = 'recitation_stats_surah_history';
  static const String _reciterHistoryKey = 'recitation_stats_reciter_history';

  static Future<List<RecitationCustomGoal>> loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_goalsKey);

    if (raw == null || raw.trim().isEmpty) return <RecitationCustomGoal>[];

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) return <RecitationCustomGoal>[];

      return decoded
          .whereType<Map>()
          .map(
            (item) => RecitationCustomGoal.fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
          .where((goal) => goal.id.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return <RecitationCustomGoal>[];
    }
  }

  static Future<void> saveGoals(List<RecitationCustomGoal> goals) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _goalsKey,
      jsonEncode(
        goals.map((goal) => goal.toJson()).toList(),
      ),
    );
  }

  static Future<void> addGoal(RecitationCustomGoal goal) async {
    final goals = await loadGoals();
    final stats = await RecitationListeningStatsStorage.loadStats();

    final Map<String, int> startTargetSeconds;

    if (goal.type == RecitationCustomGoalType.uniqueSurahs) {
      startTargetSeconds = await _loadTargetSeconds(_surahHistoryKey);
    } else if (goal.type == RecitationCustomGoalType.uniqueReciters) {
      startTargetSeconds = await _loadTargetSeconds(_reciterHistoryKey);
    } else {
      startTargetSeconds = const <String, int>{};
    }

    final goalStartingNow = goal.copyWith(
      startValue: _totalValueForGoal(goal, stats),
      startTargetSeconds: startTargetSeconds,
    );

    goals.insert(0, goalStartingNow);

    await saveGoals(goals);
  }

  static Future<void> deleteGoal(String id) async {
    final goals = await loadGoals();

    goals.removeWhere((goal) => goal.id == id);

    await saveGoals(goals);
    await _removeNotifiedGoal(id);
  }

  static Future<List<RecitationCustomGoalProgress>> loadGoalsProgress() async {
    final goals = await loadGoals();
    final stats = await RecitationListeningStatsStorage.loadStats();

    final currentSurahSeconds = await _loadTargetSeconds(_surahHistoryKey);
    final currentReciterSeconds = await _loadTargetSeconds(_reciterHistoryKey);

    final progressList = goals.map((goal) {
      return RecitationCustomGoalProgress(
        goal: goal,
        currentValue: _currentValueForGoal(
          goal: goal,
          stats: stats,
          currentSurahSeconds: currentSurahSeconds,
          currentReciterSeconds: currentReciterSeconds,
        ),
        targetValue: goal.targetValue,
      );
    }).toList();

    await _notifyNewlyCompletedGoals(progressList);

    return progressList;
  }

  static Future<Map<String, int>> _loadTargetSeconds(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);

    if (raw == null || raw.trim().isEmpty) return <String, int>{};

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! Map) return <String, int>{};

      final result = <String, int>{};

      decoded.forEach((mapKey, value) {
        if (value is Map) {
          final secondsValue = value['seconds'];
          result[mapKey.toString()] = secondsValue is int
              ? secondsValue
              : int.tryParse(secondsValue.toString()) ?? 0;
        } else {
          result[mapKey.toString()] =
          value is int ? value : int.tryParse(value.toString()) ?? 0;
        }
      });

      return result;
    } catch (_) {
      return <String, int>{};
    }
  }

  static int _countTargetsIncreasedAfterGoal({
    required RecitationCustomGoal goal,
    required Map<String, int> currentTargetSeconds,
  }) {
    int count = 0;

    currentTargetSeconds.forEach((targetId, currentSeconds) {
      final startSeconds = goal.startTargetSeconds[targetId] ?? 0;

      if (currentSeconds > startSeconds) {
        count++;
      }
    });

    return count;
  }

  static Future<void> _removeNotifiedGoal(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final notifiedIds =
        prefs.getStringList(_notifiedCompletedGoalsKey) ?? <String>[];

    notifiedIds.remove(id);

    await prefs.setStringList(_notifiedCompletedGoalsKey, notifiedIds);
  }

  static Future<void> _notifyNewlyCompletedGoals(
      List<RecitationCustomGoalProgress> goalsProgress,
      ) async {
    final completedGoals = goalsProgress.where((item) {
      return item.completed;
    }).toList();

    if (completedGoals.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final notifiedIds =
    (prefs.getStringList(_notifiedCompletedGoalsKey) ?? <String>[]).toSet();

    final newlyCompletedGoals = completedGoals.where((item) {
      return !notifiedIds.contains(item.goal.id);
    }).toList();

    if (newlyCompletedGoals.isEmpty) return;

    for (final goalProgress in newlyCompletedGoals) {
      notifiedIds.add(goalProgress.goal.id);
    }

    await prefs.setStringList(
      _notifiedCompletedGoalsKey,
      notifiedIds.toList(),
    );

    final canNotify = await RecitationNotificationSettingsProvider
        .canShowPersonalGoalNotifications();

    if (!canNotify) return;

    for (final goalProgress in newlyCompletedGoals) {
      await RecitationAchievementNotificationScheduler().showGoalNotification(
        goalId: goalProgress.goal.id,
        title: 'تم إكمال هدف شخصي 🎯',
        message: 'أحسنت، اكتمل هدف: ${goalProgress.goal.title}',
      );
    }
  }

  static int _currentValueForGoal({
    required RecitationCustomGoal goal,
    required RecitationListeningStatsData stats,
    required Map<String, int> currentSurahSeconds,
    required Map<String, int> currentReciterSeconds,
  }) {
    switch (goal.type) {
      case RecitationCustomGoalType.uniqueSurahs:
        return _countTargetsIncreasedAfterGoal(
          goal: goal,
          currentTargetSeconds: currentSurahSeconds,
        );

      case RecitationCustomGoalType.uniqueReciters:
        return _countTargetsIncreasedAfterGoal(
          goal: goal,
          currentTargetSeconds: currentReciterSeconds,
        );

      case RecitationCustomGoalType.dailyListeningMinutes:
      case RecitationCustomGoalType.weeklyListeningMinutes:
      case RecitationCustomGoalType.monthlyListeningHours:
      case RecitationCustomGoalType.totalListeningHours:
      case RecitationCustomGoalType.streakDays:
      case RecitationCustomGoalType.completedDailyGoals:
        final totalValue = _totalValueForGoal(goal, stats);
        final currentValue = totalValue - goal.startValue;

        if (currentValue < 0) return 0;

        return currentValue;
    }
  }

  static int _totalValueForGoal(
      RecitationCustomGoal goal,
      RecitationListeningStatsData stats,
      ) {
    switch (goal.type) {
      case RecitationCustomGoalType.dailyListeningMinutes:
        return stats.todaySeconds ~/ 60;

      case RecitationCustomGoalType.weeklyListeningMinutes:
        final weeklySeconds = stats.weeklyHistory.fold<int>(
          0,
              (sum, day) => sum + day.seconds,
        );
        return weeklySeconds ~/ 60;

      case RecitationCustomGoalType.monthlyListeningHours:
        return stats.monthlySeconds ~/ 3600;

      case RecitationCustomGoalType.totalListeningHours:
        return stats.totalSeconds ~/ 3600;

      case RecitationCustomGoalType.uniqueSurahs:
        return stats.uniqueSurahCount;

      case RecitationCustomGoalType.uniqueReciters:
        return stats.uniqueReciterCount;

      case RecitationCustomGoalType.streakDays:
        return stats.streak;

      case RecitationCustomGoalType.completedDailyGoals:
        return stats.completedGoalDays;
    }
  }
}