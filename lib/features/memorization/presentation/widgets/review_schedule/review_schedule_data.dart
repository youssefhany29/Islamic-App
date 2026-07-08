import 'dart:math' as math;

import 'package:islamic_app/features/memorization/data/models/memorization_active_plan_model.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_today_task_model.dart';
import 'package:islamic_app/features/memorization/data/models/planning/memorization_plan_timeline_summary.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_plan_journey_engine.dart';
import 'package:islamic_app/features/memorization/data/services/planning/memorization_plan_timeline_resolver.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_plan_storage.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_rescue_review_engine.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_session_result_storage.dart';
import 'package:islamic_app/features/memorization/data/services/quran_range_label_resolver.dart';
import 'package:islamic_app/features/quran/reader/quran_page_mapper.dart';

class ReviewScheduleData {
  const ReviewScheduleData({
    required this.plansCount,
    required this.activePlan,
    required this.months,
    this.timelineSummary,
  });

  final int plansCount;
  final MemorizationActivePlanModel? activePlan;
  final List<ReviewScheduleMonth> months;
  final MemorizationPlanTimelineSummary? timelineSummary;

  bool get hasActivePlan => activePlan != null;

  static Future<ReviewScheduleData> load() async {
    final plans = await MemorizationPlanStorage.getPlans();
    final activePlan = await MemorizationPlanStorage.getActivePlan();

    if (activePlan == null) {
      return ReviewScheduleData(
        plansCount: plans.length,
        activePlan: null,
        months: const [],
      );
    }

    final activeTask = await MemorizationPlanStorage.getTodayTask();
    final results = await MemorizationSessionResultStorage.getResults();
    await QuranPageMapper.load();
    final horizonDays = _horizonDaysForPlan(activePlan);

    final journeyTasks = await const MemorizationPlanJourneyEngine()
        .buildJourneyTasks(
          plan: activePlan,
          activeTask: activeTask,
          daysAhead: horizonDays,
        );
    final timelineSummary = const MemorizationPlanTimelineResolver().resolve(
      plan: activePlan,
      journeyTasks: journeyTasks,
      results: results,
    );

    final items = <ReviewScheduleItem>[
      ...journeyTasks.map(ReviewScheduleItem.fromJourney),
    ];

    final rescueTasks = const MemorizationRescueReviewEngine()
        .getUpcomingRescueTasks(
          results: results,
          activePlan: activePlan,
          daysAhead: horizonDays,
        );

    for (final task in rescueTasks) {
      items.add(
        ReviewScheduleItem.fromTask(
          task: task,
          date: task.effectiveScheduledDate,
          timeLabel: 'إنقاذ',
          priority: 4,
          isRescue: true,
        ),
      );
    }

    items.sort((a, b) {
      final dateCompare = a.date.compareTo(b.date);
      if (dateCompare != 0) return dateCompare;
      return a.priority.compareTo(b.priority);
    });

    return ReviewScheduleData(
      plansCount: plans.length,
      activePlan: activePlan,
      months: _buildMonths(items: items),
      timelineSummary: timelineSummary,
    );
  }

  static int _horizonDaysForPlan(MemorizationActivePlanModel plan) {
    final baseDays = math.max(
      plan.effectiveCalendarDays,
      math.max(plan.totalDays, math.max(plan.effectiveReviewDays, 30)),
    );
    final testsBuffer = math.max(14, (baseDays / 4).ceil());

    return (baseDays + testsBuffer).clamp(30, 2200).toInt();
  }

  static List<ReviewScheduleMonth> _buildMonths({
    required List<ReviewScheduleItem> items,
  }) {
    final today = _dateOnly(DateTime.now());
    final firstMonth = DateTime(today.year, today.month, 1);
    DateTime lastDate = today;

    for (final item in items) {
      if (item.date.isAfter(lastDate)) lastDate = item.date;
    }

    final lastMonth = DateTime(lastDate.year, lastDate.month, 1);
    final monthsCount =
        ((lastMonth.year - firstMonth.year) * 12) +
        lastMonth.month -
        firstMonth.month +
        1;

    return List.generate(monthsCount.clamp(1, 96).toInt(), (index) {
      final monthDate = DateTime(firstMonth.year, firstMonth.month + index, 1);
      final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;

      final days = List.generate(daysInMonth, (dayIndex) {
        final date = DateTime(monthDate.year, monthDate.month, dayIndex + 1);
        final dayItems =
            items.where((item) => _sameDay(item.date, date)).toList()
              ..sort((a, b) => a.priority.compareTo(b.priority));

        return ReviewScheduleDay(date: date, items: dayItems);
      });

      return ReviewScheduleMonth(month: monthDate, days: days);
    });
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class ReviewScheduleMonth {
  const ReviewScheduleMonth({required this.month, required this.days});

  final DateTime month;
  final List<ReviewScheduleDay> days;

  int get tasksCount {
    return days.fold<int>(0, (sum, day) => sum + day.items.length);
  }
}

class ReviewScheduleDay {
  const ReviewScheduleDay({required this.date, required this.items});

  final DateTime date;
  final List<ReviewScheduleItem> items;

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class ReviewScheduleItem {
  const ReviewScheduleItem({
    required this.date,
    required this.task,
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    required this.priority,
    required this.isRescue,
  });

  final DateTime date;
  final MemorizationTodayTaskModel task;
  final String title;
  final String subtitle;
  final String timeLabel;
  final int priority;
  final bool isRescue;

  bool get isCompleted {
    return task.isCompleted ||
        task.status == MemorizationTodayTaskModel.statusCompleted;
  }

  String get typeLabel {
    if (isRescue || task.type == 'weakReview') return 'تثبيت';
    if (task.type == 'selfTest') return 'اختبار';
    if (task.type == 'dailyReview') return 'مراجعة';
    return 'حفظ';
  }

  factory ReviewScheduleItem.fromJourney(MemorizationJourneyTask item) {
    return ReviewScheduleItem.fromTask(
      task: item.task,
      date: item.date,
      timeLabel: item.timeLabel,
      priority: item.priority,
      isRescue: false,
    );
  }

  factory ReviewScheduleItem.fromTask({
    required MemorizationTodayTaskModel task,
    required DateTime date,
    required String timeLabel,
    required int priority,
    required bool isRescue,
  }) {
    return ReviewScheduleItem(
      date: DateTime(date.year, date.month, date.day),
      task: task,
      title: task.title,
      subtitle: _subtitleForTask(task),
      timeLabel: timeLabel,
      priority: priority,
      isRescue: isRescue,
    );
  }

  static String _subtitleForTask(MemorizationTodayTaskModel task) {
    if (!task.hasValidRange) {
      return task.subtitle.trim().isEmpty
          ? 'مهمة مجدولة حسب الخطة'
          : task.subtitle;
    }
    final range = const QuranRangeLabelResolver().resolveAyahs(
      startGlobalAyahIndex: task.startGlobalAyahIndex,
      endGlobalAyahIndex: task.endGlobalAyahIndex,
    );
    return '${range.actualAyahCount} آية • '
        '${range.displayLabel} • ${range.pagesLabel}';
  }
}
