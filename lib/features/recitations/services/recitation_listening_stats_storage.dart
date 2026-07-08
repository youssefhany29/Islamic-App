import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/recitation_achievement_model.dart';
import '../notifications/recitation_achievement_notification_scheduler.dart';
import '../settings/recitation_notification_settings_provider.dart';

class RecitationListeningStatsStorage {
  RecitationListeningStatsStorage._();

  static const String _totalSecondsKey = 'recitation_stats_total_seconds';
  static const String _streakKey = 'recitation_stats_streak';
  static const String _bestStreakKey = 'recitation_stats_best_streak';
  static const String _lastActiveDateKey = 'recitation_stats_last_active_date';
  static const String _dailyHistoryKey = 'recitation_stats_daily_history';

  static const String _dailyGoalSecondsKey =
      'recitation_stats_daily_goal_seconds';
  static const String _goalCompletedDatesKey =
      'recitation_stats_goal_completed_dates';

  static const String _hourlyHistoryKey = 'recitation_stats_hourly_history';
  static const String _surahHistoryKey = 'recitation_stats_surah_history';
  static const String _reciterHistoryKey = 'recitation_stats_reciter_history';

  static const String _earnedAchievementsKey =
      'recitation_stats_earned_achievements';

  static const int defaultDailyGoalSeconds = 20 * 60;

  static String todayKey() => _dateKey(DateTime.now());

  static String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String _yesterdayKey() {
    return _dateKey(DateTime.now().subtract(const Duration(days: 1)));
  }

  static String _dayName(DateTime date) {
    switch (date.weekday) {
      case DateTime.saturday:
        return 'سبت';
      case DateTime.sunday:
        return 'أحد';
      case DateTime.monday:
        return 'اثن';
      case DateTime.tuesday:
        return 'ثلا';
      case DateTime.wednesday:
        return 'أرب';
      case DateTime.thursday:
        return 'خمي';
      case DateTime.friday:
        return 'جمع';
      default:
        return '';
    }
  }

  static Map<String, int> _decodeIntMap(String? raw) {
    if (raw == null || raw.trim().isEmpty) return <String, int>{};

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! Map) return <String, int>{};

      return decoded.map<String, int>((key, value) {
        return MapEntry(
          key.toString(),
          value is int ? value : int.tryParse(value.toString()) ?? 0,
        );
      });
    } catch (_) {
      return <String, int>{};
    }
  }

  static Map<String, RecitationListenTargetStats> _decodeTargetStats(
      String? raw,
      ) {
    if (raw == null || raw.trim().isEmpty) {
      return <String, RecitationListenTargetStats>{};
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! Map) return <String, RecitationListenTargetStats>{};

      return decoded.map<String, RecitationListenTargetStats>((key, value) {
        if (value is Map) {
          return MapEntry(
            key.toString(),
            RecitationListenTargetStats.fromJson(
              Map<String, dynamic>.from(value),
            ),
          );
        }

        return MapEntry(
          key.toString(),
          RecitationListenTargetStats(
            id: key.toString(),
            name: 'غير معروف',
            seconds: 0,
          ),
        );
      });
    } catch (_) {
      return <String, RecitationListenTargetStats>{};
    }
  }

  static Future<void> _saveIntMap(String key, Map<String, int> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(map));
  }

  static Future<void> _saveTargetStats(
      String key,
      Map<String, RecitationListenTargetStats> map,
      ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      key,
      jsonEncode(
        map.map((mapKey, value) {
          return MapEntry(mapKey, value.toJson());
        }),
      ),
    );
  }

  static Future<int> getDailyGoalSeconds() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getInt(_dailyGoalSecondsKey) ?? defaultDailyGoalSeconds;
  }

  static Future<void> setDailyGoalMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();

    final safeMinutes = minutes.clamp(1, 180).toInt();
    await prefs.setInt(_dailyGoalSecondsKey, safeMinutes * 60);
  }

  static Future<void> addListeningSeconds({
    required int seconds,
    int? reciterId,
    String? reciterName,
    int? surahNumber,
    String? surahName,
  }) async {
    if (seconds <= 0) return;

    final safeSeconds = seconds > 60 ? 60 : seconds;
    final prefs = await SharedPreferences.getInstance();

    final oldTotalSeconds = prefs.getInt(_totalSecondsKey) ?? 0;
    final hasAchievementBaseline = prefs.containsKey(_earnedAchievementsKey);
    final oldEarnedIds =
    (prefs.getStringList(_earnedAchievementsKey) ?? <String>[]).toSet();

    final today = todayKey();
    final yesterday = _yesterdayKey();

    final history = _decodeIntMap(prefs.getString(_dailyHistoryKey));
    final todayBefore = history[today] ?? 0;
    history[today] = todayBefore + safeSeconds;

    await prefs.setInt(_totalSecondsKey, oldTotalSeconds + safeSeconds);

    if (todayBefore == 0) {
      final lastActiveDate = prefs.getString(_lastActiveDateKey);
      int streak = prefs.getInt(_streakKey) ?? 0;

      if (lastActiveDate == today) {
        streak = streak <= 0 ? 1 : streak;
      } else if (lastActiveDate == yesterday) {
        streak += 1;
      } else {
        streak = 1;
      }

      final bestStreak = prefs.getInt(_bestStreakKey) ?? 0;

      await prefs.setInt(_streakKey, streak);
      await prefs.setInt(
        _bestStreakKey,
        streak > bestStreak ? streak : bestStreak,
      );
      await prefs.setString(_lastActiveDateKey, today);
    }

    await _trimAndSaveDailyHistory(history);
    await _addHourlySeconds(safeSeconds);

    await _addSurahSeconds(
      seconds: safeSeconds,
      surahNumber: surahNumber,
      surahName: surahName,
    );

    await _addReciterSeconds(
      seconds: safeSeconds,
      reciterId: reciterId,
      reciterName: reciterName,
    );

    final dailyGoal = await getDailyGoalSeconds();
    final todayAfter = history[today] ?? 0;

    if (todayBefore < dailyGoal && todayAfter >= dailyGoal) {
      final completedDates =
          prefs.getStringList(_goalCompletedDatesKey) ?? <String>[];

      if (!completedDates.contains(today)) {
        completedDates.add(today);
        await prefs.setStringList(_goalCompletedDatesKey, completedDates);
      }
    }

    final achievements = await refreshAchievements();

    // لو المستخدم عنده إحصائيات قديمة قبل إضافة نظام الجوائز،
    // نعمل baseline لأول مرة بدون إرسال عشرات الإشعارات.
    if (!hasAchievementBaseline && oldTotalSeconds > 0) {
      return;
    }

    final newEarnedAchievements = achievements.where((achievement) {
      return achievement.earned && !oldEarnedIds.contains(achievement.id);
    }).toList();

    if (newEarnedAchievements.isEmpty) return;

    final canNotify =
    await RecitationNotificationSettingsProvider.canShowAchievementNotifications();

    if (!canNotify) return;

    for (final achievement in newEarnedAchievements) {
      await RecitationAchievementNotificationScheduler()
          .showAchievementNotification(
        achievementId: achievement.id,
        title: 'جائزة استماع جديدة 🏆',
        message: '${achievement.title} — ${achievement.description}',
      );
    }
  }

  static Future<void> _trimAndSaveDailyHistory(Map<String, int> history) async {
    final prefs = await SharedPreferences.getInstance();

    final keys = history.keys.toList()..sort();
    const maxDaysToKeep = 120;

    while (keys.length > maxDaysToKeep) {
      final key = keys.removeAt(0);
      history.remove(key);
    }

    await prefs.setString(_dailyHistoryKey, jsonEncode(history));
  }

  static Future<void> _addHourlySeconds(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    final hourly = _decodeIntMap(prefs.getString(_hourlyHistoryKey));
    final hour = DateTime.now().hour.toString().padLeft(2, '0');

    hourly[hour] = (hourly[hour] ?? 0) + seconds;
    await _saveIntMap(_hourlyHistoryKey, hourly);
  }

  static Future<void> _addSurahSeconds({
    required int seconds,
    int? surahNumber,
    String? surahName,
  }) async {
    if (surahNumber == null || surahName == null || surahName.trim().isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final surahs = _decodeTargetStats(prefs.getString(_surahHistoryKey));
    final key = surahNumber.toString();

    final current = surahs[key];

    surahs[key] = RecitationListenTargetStats(
      id: key,
      name: surahName,
      seconds: (current?.seconds ?? 0) + seconds,
    );

    await _saveTargetStats(_surahHistoryKey, surahs);
  }

  static Future<void> _addReciterSeconds({
    required int seconds,
    int? reciterId,
    String? reciterName,
  }) async {
    if (reciterId == null || reciterName == null || reciterName.trim().isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final reciters = _decodeTargetStats(prefs.getString(_reciterHistoryKey));
    final key = reciterId.toString();

    final current = reciters[key];

    reciters[key] = RecitationListenTargetStats(
      id: key,
      name: reciterName,
      seconds: (current?.seconds ?? 0) + seconds,
    );

    await _saveTargetStats(_reciterHistoryKey, reciters);
  }

  static Future<RecitationListeningStatsData> loadStats() async {
    final prefs = await SharedPreferences.getInstance();

    final today = todayKey();
    final yesterday = _yesterdayKey();

    final history = _decodeIntMap(prefs.getString(_dailyHistoryKey));
    final lastActiveDate = prefs.getString(_lastActiveDateKey);

    int streak = prefs.getInt(_streakKey) ?? 0;
    int bestStreak = prefs.getInt(_bestStreakKey) ?? 0;

    if (lastActiveDate != null &&
        lastActiveDate != today &&
        lastActiveDate != yesterday) {
      streak = 0;
      await prefs.setInt(_streakKey, streak);
    }

    if (streak > bestStreak) {
      bestStreak = streak;
      await prefs.setInt(_bestStreakKey, bestStreak);
    }

    final dailyGoalSeconds = await getDailyGoalSeconds();

    final weeklyHistory = <RecitationWeeklyDay>[];

    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final key = _dateKey(date);
      final seconds = history[key] ?? 0;

      weeklyHistory.add(
        RecitationWeeklyDay(
          dateKey: key,
          dayName: _dayName(date),
          seconds: seconds,
          goalSeconds: dailyGoalSeconds,
          isToday: key == today,
        ),
      );
    }

    final todaySeconds = history[today] ?? 0;
    final totalSeconds = prefs.getInt(_totalSecondsKey) ?? 0;
    final goalCompletedDates =
        prefs.getStringList(_goalCompletedDatesKey) ?? <String>[];

    final hourly = _decodeIntMap(prefs.getString(_hourlyHistoryKey));
    final surahs = _decodeTargetStats(prefs.getString(_surahHistoryKey));
    final reciters = _decodeTargetStats(prefs.getString(_reciterHistoryKey));

    final now = DateTime.now();
    final monthPrefix = '${now.year}-${now.month.toString().padLeft(2, '0')}-';

    int monthlySeconds = 0;

    history.forEach((key, value) {
      if (key.startsWith(monthPrefix)) {
        monthlySeconds += value;
      }
    });

    final monthCompletedGoalDays = goalCompletedDates
        .where((dateKey) => dateKey.startsWith(monthPrefix))
        .length;

    final uniqueSurahCount =
        surahs.values.where((item) => item.seconds > 0).length;

    final uniqueReciterCount =
        reciters.values.where((item) => item.seconds > 0).length;

    final achievements = await _buildAchievements(
      todaySeconds: todaySeconds,
      totalSeconds: totalSeconds,
      dailyGoalSeconds: dailyGoalSeconds,
      streak: streak,
      weeklyHistory: weeklyHistory,
      completedGoalDays: goalCompletedDates.length,
      uniqueSurahCount: uniqueSurahCount,
      uniqueReciterCount: uniqueReciterCount,
      monthlySeconds: monthlySeconds,
      monthCompletedGoalDays: monthCompletedGoalDays,
    );

    return RecitationListeningStatsData(
      todaySeconds: todaySeconds,
      totalSeconds: totalSeconds,
      dailyGoalSeconds: dailyGoalSeconds,
      streak: streak,
      bestStreak: bestStreak,
      weeklyHistory: weeklyHistory,
      topListeningTime: _topListeningTime(hourly),
      topSurah: _topTarget(surahs),
      topReciter: _topTarget(reciters),
      completedGoalDays: goalCompletedDates.length,
      monthlySeconds: monthlySeconds,
      monthCompletedGoalDays: monthCompletedGoalDays,
      uniqueSurahCount: uniqueSurahCount,
      uniqueReciterCount: uniqueReciterCount,
      achievements: achievements,
    );
  }

  static RecitationListenTargetStats? _topTarget(
      Map<String, RecitationListenTargetStats> map,
      ) {
    if (map.isEmpty) return null;

    final values = map.values.toList()
      ..sort((a, b) => b.seconds.compareTo(a.seconds));

    final top = values.first;

    return top.seconds <= 0 ? null : top;
  }

  static RecitationListeningTimeInsight _topListeningTime(
      Map<String, int> hourly,
      ) {
    if (hourly.isEmpty) {
      return const RecitationListeningTimeInsight(
        title: 'لم يتحدد بعد',
        subtitle: 'استمع أكثر ليظهر وقتك المفضل',
        seconds: 0,
      );
    }

    final buckets = <String, int>{
      'الفجر والصباح الباكر': 0,
      'الصباح': 0,
      'بعد الظهر': 0,
      'المساء': 0,
      'الليل': 0,
    };

    hourly.forEach((hourText, seconds) {
      final hour = int.tryParse(hourText) ?? 0;

      if (hour >= 4 && hour < 8) {
        buckets['الفجر والصباح الباكر'] =
            buckets['الفجر والصباح الباكر']! + seconds;
      } else if (hour >= 8 && hour < 12) {
        buckets['الصباح'] = buckets['الصباح']! + seconds;
      } else if (hour >= 12 && hour < 17) {
        buckets['بعد الظهر'] = buckets['بعد الظهر']! + seconds;
      } else if (hour >= 17 && hour < 22) {
        buckets['المساء'] = buckets['المساء']! + seconds;
      } else {
        buckets['الليل'] = buckets['الليل']! + seconds;
      }
    });

    final entries = buckets.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = entries.first;

    if (top.value <= 0) {
      return const RecitationListeningTimeInsight(
        title: 'لم يتحدد بعد',
        subtitle: 'استمع أكثر ليظهر وقتك المفضل',
        seconds: 0,
      );
    }

    return RecitationListeningTimeInsight(
      title: top.key,
      subtitle: 'أكثر فترة تستمع فيها للقرآن',
      seconds: top.value,
    );
  }

  static Future<List<RecitationAchievement>> _buildAchievements({
    required int todaySeconds,
    required int totalSeconds,
    required int dailyGoalSeconds,
    required int streak,
    required List<RecitationWeeklyDay> weeklyHistory,
    required int completedGoalDays,
    required int uniqueSurahCount,
    required int uniqueReciterCount,
    required int monthlySeconds,
    required int monthCompletedGoalDays,
  }) async {
    final weeklyCompletedDays =
        weeklyHistory.where((day) => day.completedGoal).length;

    return <RecitationAchievement>[
      RecitationAchievement(
        id: 'first_listen',
        title: 'أول استماع',
        description: 'ابدأ أول تلاوة في التطبيق',
        icon: Icons.headphones_rounded,
        requiredValue: 1,
        currentValue: totalSeconds > 0 ? 1 : 0,
        earned: totalSeconds > 0,
      ),
      RecitationAchievement(
        id: 'daily_goal',
        title: 'ورد الاستماع اليومي',
        description: 'أكمل هدف الاستماع اليومي',
        icon: Icons.check_circle_rounded,
        requiredValue: dailyGoalSeconds,
        currentValue: todaySeconds,
        earned: todaySeconds >= dailyGoalSeconds,
      ),
      RecitationAchievement(
        id: 'today_30',
        title: 'نصف ساعة في يوم',
        description: 'استمع 30 دقيقة في يوم واحد',
        icon: Icons.timer_rounded,
        requiredValue: 30 * 60,
        currentValue: todaySeconds,
        earned: todaySeconds >= 30 * 60,
      ),
      RecitationAchievement(
        id: 'today_60',
        title: 'ساعة في يوم',
        description: 'استمع ساعة كاملة في يوم واحد',
        icon: Icons.access_time_filled_rounded,
        requiredValue: 60 * 60,
        currentValue: todaySeconds,
        earned: todaySeconds >= 60 * 60,
      ),
      RecitationAchievement(
        id: 'streak_3',
        title: 'ثلاثة أيام متتالية',
        description: 'استمع للقرآن 3 أيام متتالية',
        icon: Icons.local_fire_department_rounded,
        requiredValue: 3,
        currentValue: streak,
        earned: streak >= 3,
      ),
      RecitationAchievement(
        id: 'streak_7',
        title: 'أسبوع من التلاوة',
        description: 'حافظ على الاستماع 7 أيام متتالية',
        icon: Icons.emoji_events_rounded,
        requiredValue: 7,
        currentValue: streak,
        earned: streak >= 7,
      ),
      RecitationAchievement(
        id: 'streak_14',
        title: 'أسبوعان من الثبات',
        description: 'استمع للقرآن 14 يومًا متتاليًا',
        icon: Icons.whatshot_rounded,
        requiredValue: 14,
        currentValue: streak,
        earned: streak >= 14,
      ),
      RecitationAchievement(
        id: 'streak_30',
        title: 'شهر كامل مع القرآن',
        description: 'حافظ على الاستماع 30 يومًا متتاليًا',
        icon: Icons.military_tech_rounded,
        requiredValue: 30,
        currentValue: streak,
        earned: streak >= 30,
      ),
      RecitationAchievement(
        id: 'weekly_4',
        title: 'أسبوع نشيط',
        description: 'أكملت هدفك في 4 أيام خلال آخر أسبوع',
        icon: Icons.calendar_month_rounded,
        requiredValue: 4,
        currentValue: weeklyCompletedDays,
        earned: weeklyCompletedDays >= 4,
      ),
      RecitationAchievement(
        id: 'weekly_7',
        title: 'أسبوع كامل',
        description: 'أكملت هدفك في 7 أيام خلال آخر أسبوع',
        icon: Icons.workspace_premium_rounded,
        requiredValue: 7,
        currentValue: weeklyCompletedDays,
        earned: weeklyCompletedDays >= 7,
      ),
      RecitationAchievement(
        id: 'total_30',
        title: 'نصف ساعة قرآن',
        description: 'وصل إجمالي استماعك إلى 30 دقيقة',
        icon: Icons.timer_rounded,
        requiredValue: 30 * 60,
        currentValue: totalSeconds,
        earned: totalSeconds >= 30 * 60,
      ),
      RecitationAchievement(
        id: 'total_60',
        title: 'ساعة قرآن',
        description: 'وصل إجمالي استماعك إلى ساعة كاملة',
        icon: Icons.workspace_premium_rounded,
        requiredValue: 60 * 60,
        currentValue: totalSeconds,
        earned: totalSeconds >= 60 * 60,
      ),
      RecitationAchievement(
        id: 'total_180',
        title: 'ثلاث ساعات قرآن',
        description: 'وصل إجمالي استماعك إلى 3 ساعات',
        icon: Icons.star_rounded,
        requiredValue: 3 * 60 * 60,
        currentValue: totalSeconds,
        earned: totalSeconds >= 3 * 60 * 60,
      ),
      RecitationAchievement(
        id: 'total_300',
        title: 'خمس ساعات قرآن',
        description: 'وصل إجمالي استماعك إلى 5 ساعات',
        icon: Icons.auto_awesome_rounded,
        requiredValue: 5 * 60 * 60,
        currentValue: totalSeconds,
        earned: totalSeconds >= 5 * 60 * 60,
      ),
      RecitationAchievement(
        id: 'total_600',
        title: 'عشر ساعات قرآن',
        description: 'وصل إجمالي استماعك إلى 10 ساعات',
        icon: Icons.diamond_rounded,
        requiredValue: 10 * 60 * 60,
        currentValue: totalSeconds,
        earned: totalSeconds >= 10 * 60 * 60,
      ),
      RecitationAchievement(
        id: 'total_1200',
        title: 'عشرون ساعة قرآن',
        description: 'وصل إجمالي استماعك إلى 20 ساعة',
        icon: Icons.diamond_outlined,
        requiredValue: 20 * 60 * 60,
        currentValue: totalSeconds,
        earned: totalSeconds >= 20 * 60 * 60,
      ),
      RecitationAchievement(
        id: 'goals_3',
        title: 'ثلاثة أهداف مكتملة',
        description: 'أكملت هدف الاستماع في 3 أيام مختلفة',
        icon: Icons.flag_rounded,
        requiredValue: 3,
        currentValue: completedGoalDays,
        earned: completedGoalDays >= 3,
      ),
      RecitationAchievement(
        id: 'goals_7',
        title: 'سبعة أهداف مكتملة',
        description: 'أكملت هدف الاستماع في 7 أيام مختلفة',
        icon: Icons.stars_rounded,
        requiredValue: 7,
        currentValue: completedGoalDays,
        earned: completedGoalDays >= 7,
      ),
      RecitationAchievement(
        id: 'goals_15',
        title: 'خمسة عشر هدفًا',
        description: 'أكملت هدف الاستماع في 15 يومًا مختلفًا',
        icon: Icons.task_alt_rounded,
        requiredValue: 15,
        currentValue: completedGoalDays,
        earned: completedGoalDays >= 15,
      ),
      RecitationAchievement(
        id: 'goals_30',
        title: 'ثلاثون هدفًا مكتملًا',
        description: 'أكملت هدف الاستماع في 30 يومًا مختلفًا',
        icon: Icons.workspace_premium_rounded,
        requiredValue: 30,
        currentValue: completedGoalDays,
        earned: completedGoalDays >= 30,
      ),
      RecitationAchievement(
        id: 'month_60',
        title: 'ساعة هذا الشهر',
        description: 'استمعت ساعة خلال هذا الشهر',
        icon: Icons.date_range_rounded,
        requiredValue: 60 * 60,
        currentValue: monthlySeconds,
        earned: monthlySeconds >= 60 * 60,
      ),
      RecitationAchievement(
        id: 'month_300',
        title: 'خمس ساعات هذا الشهر',
        description: 'استمعت 5 ساعات خلال هذا الشهر',
        icon: Icons.calendar_month_rounded,
        requiredValue: 5 * 60 * 60,
        currentValue: monthlySeconds,
        earned: monthlySeconds >= 5 * 60 * 60,
      ),
      RecitationAchievement(
        id: 'month_goals_7',
        title: 'سبعة أهداف شهرية',
        description: 'أكملت 7 أهداف في هذا الشهر',
        icon: Icons.event_available_rounded,
        requiredValue: 7,
        currentValue: monthCompletedGoalDays,
        earned: monthCompletedGoalDays >= 7,
      ),
      RecitationAchievement(
        id: 'month_goals_20',
        title: 'عشرون هدفًا شهريًا',
        description: 'أكملت 20 هدفًا في هذا الشهر',
        icon: Icons.verified_rounded,
        requiredValue: 20,
        currentValue: monthCompletedGoalDays,
        earned: monthCompletedGoalDays >= 20,
      ),
      RecitationAchievement(
        id: 'surahs_3',
        title: 'ثلاث سور',
        description: 'استمعت إلى 3 سور مختلفة',
        icon: Icons.menu_book_rounded,
        requiredValue: 3,
        currentValue: uniqueSurahCount,
        earned: uniqueSurahCount >= 3,
      ),
      RecitationAchievement(
        id: 'surahs_5',
        title: 'تنوع في السور',
        description: 'استمعت إلى 5 سور مختلفة',
        icon: Icons.menu_book_rounded,
        requiredValue: 5,
        currentValue: uniqueSurahCount,
        earned: uniqueSurahCount >= 5,
      ),
      RecitationAchievement(
        id: 'surahs_10',
        title: 'رحلة بين السور',
        description: 'استمعت إلى 10 سور مختلفة',
        icon: Icons.library_books_rounded,
        requiredValue: 10,
        currentValue: uniqueSurahCount,
        earned: uniqueSurahCount >= 10,
      ),
      RecitationAchievement(
        id: 'surahs_25',
        title: 'ربع الطريق',
        description: 'استمعت إلى 25 سورة مختلفة',
        icon: Icons.library_add_check_rounded,
        requiredValue: 25,
        currentValue: uniqueSurahCount,
        earned: uniqueSurahCount >= 25,
      ),
      RecitationAchievement(
        id: 'surahs_50',
        title: 'خمسون سورة',
        description: 'استمعت إلى 50 سورة مختلفة',
        icon: Icons.collections_bookmark_rounded,
        requiredValue: 50,
        currentValue: uniqueSurahCount,
        earned: uniqueSurahCount >= 50,
      ),
      RecitationAchievement(
        id: 'surahs_114',
        title: 'رحلة المصحف',
        description: 'استمعت إلى 114 سورة مختلفة',
        icon: Icons.auto_stories_rounded,
        requiredValue: 114,
        currentValue: uniqueSurahCount,
        earned: uniqueSurahCount >= 114,
      ),
      RecitationAchievement(
        id: 'reciters_2',
        title: 'قارئان',
        description: 'استمعت إلى قارئين مختلفين',
        icon: Icons.record_voice_over_rounded,
        requiredValue: 2,
        currentValue: uniqueReciterCount,
        earned: uniqueReciterCount >= 2,
      ),
      RecitationAchievement(
        id: 'reciters_3',
        title: 'ثلاثة قراء',
        description: 'استمعت إلى 3 قراء مختلفين',
        icon: Icons.record_voice_over_rounded,
        requiredValue: 3,
        currentValue: uniqueReciterCount,
        earned: uniqueReciterCount >= 3,
      ),
      RecitationAchievement(
        id: 'reciters_5',
        title: 'تنوع في القراء',
        description: 'استمعت إلى 5 قراء مختلفين',
        icon: Icons.groups_rounded,
        requiredValue: 5,
        currentValue: uniqueReciterCount,
        earned: uniqueReciterCount >= 5,
      ),
      RecitationAchievement(
        id: 'reciters_10',
        title: 'عشرة قراء',
        description: 'استمعت إلى 10 قراء مختلفين',
        icon: Icons.groups_2_rounded,
        requiredValue: 10,
        currentValue: uniqueReciterCount,
        earned: uniqueReciterCount >= 10,
      ),
    ];
  }

  static Future<List<RecitationAchievement>> refreshAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final stats = await loadStats();

    final earnedIds = stats.achievements
        .where((achievement) => achievement.earned)
        .map((achievement) => achievement.id)
        .toSet()
        .toList();

    await prefs.setStringList(_earnedAchievementsKey, earnedIds);

    return stats.achievements;
  }

  static String formatListeningTime(int totalSeconds) {
    if (totalSeconds <= 0) return '0 دقيقة';

    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    if (hours > 0 && minutes > 0) {
      return '$hours ساعة و $minutes دقيقة';
    }

    if (hours > 0) {
      return '$hours ساعة';
    }

    return '$minutes دقيقة';
  }

  static String formatShortTime(int totalSeconds) {
    if (totalSeconds <= 0) return '0د';

    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    if (hours > 0 && minutes > 0) return '${hours}س ${minutes}د';
    if (hours > 0) return '${hours}س';

    return '${minutes}د';
  }
}

class RecitationListeningStatsData {
  final int todaySeconds;
  final int totalSeconds;
  final int dailyGoalSeconds;
  final int streak;
  final int bestStreak;
  final List<RecitationWeeklyDay> weeklyHistory;
  final RecitationListeningTimeInsight topListeningTime;
  final RecitationListenTargetStats? topSurah;
  final RecitationListenTargetStats? topReciter;
  final int completedGoalDays;
  final int monthlySeconds;
  final int monthCompletedGoalDays;
  final int uniqueSurahCount;
  final int uniqueReciterCount;
  final List<RecitationAchievement> achievements;

  const RecitationListeningStatsData({
    required this.todaySeconds,
    required this.totalSeconds,
    required this.dailyGoalSeconds,
    required this.streak,
    required this.bestStreak,
    required this.weeklyHistory,
    required this.topListeningTime,
    required this.topSurah,
    required this.topReciter,
    required this.completedGoalDays,
    required this.monthlySeconds,
    required this.monthCompletedGoalDays,
    required this.uniqueSurahCount,
    required this.uniqueReciterCount,
    required this.achievements,
  });

  double get todayProgress {
    if (dailyGoalSeconds <= 0) return 0;

    return (todaySeconds / dailyGoalSeconds).clamp(0.0, 1.0);
  }

  bool get completedTodayGoal => todaySeconds >= dailyGoalSeconds;

  int get earnedAchievementsCount {
    return achievements.where((achievement) => achievement.earned).length;
  }
}

class RecitationWeeklyDay {
  final String dateKey;
  final String dayName;
  final int seconds;
  final int goalSeconds;
  final bool isToday;

  const RecitationWeeklyDay({
    required this.dateKey,
    required this.dayName,
    required this.seconds,
    required this.goalSeconds,
    required this.isToday,
  });

  bool get listened => seconds > 0;

  bool get completedGoal => goalSeconds > 0 && seconds >= goalSeconds;

  double get progress {
    if (goalSeconds <= 0) return 0;

    return (seconds / goalSeconds).clamp(0.0, 1.0);
  }
}

class RecitationListeningTimeInsight {
  final String title;
  final String subtitle;
  final int seconds;

  const RecitationListeningTimeInsight({
    required this.title,
    required this.subtitle,
    required this.seconds,
  });
}

class RecitationListenTargetStats {
  final String id;
  final String name;
  final int seconds;

  const RecitationListenTargetStats({
    required this.id,
    required this.name,
    required this.seconds,
  });

  factory RecitationListenTargetStats.fromJson(Map<String, dynamic> json) {
    return RecitationListenTargetStats(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'غير معروف',
      seconds: int.tryParse(json['seconds'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'seconds': seconds,
    };
  }
}