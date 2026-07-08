import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import 'package:islamic_app/features/memorization/data/models/memorization_today_task_model.dart';
import '../pages/memorization_training_session_page.dart';
import 'package:islamic_app/features/memorization/test/pages/memorization_test_session_page.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_plan_journey_engine.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_plan_storage.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_rescue_review_engine.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_session_result_storage.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
part 'memorization_schedule_calendar_widgets.dart';
part 'memorization_schedule_calendar_content.dart';
part 'memorization_schedule_calendar_data.dart';
part 'memorization_schedule_calendar_sheet.dart';

class MemorizationScheduleCalendarCard extends StatefulWidget {
  const MemorizationScheduleCalendarCard({super.key});

  @override
  State<MemorizationScheduleCalendarCard> createState() =>
      _MemorizationScheduleCalendarCardState();
}

class _MemorizationScheduleCalendarCardState
    extends State<MemorizationScheduleCalendarCard> {
  Future<_ScheduleData>? scheduleFuture;
  Timer? refreshTimer;
  int selectedDayOffset = 0;

  @override
  void initState() {
    super.initState();
    _refreshSchedule();
    refreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _refreshSchedule(),
    );
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  void _refreshSchedule() {
    if (!mounted) return;

    // الكارت الصغير يعرض 7 أيام فقط، لذلك نطلب مدى قصير وخفيف.
    final future = _loadSchedule(daysAhead: 7);

    setState(() {
      scheduleFuture = future;
    });
  }

  int _monthCalendarHorizonDays(activePlan) {
    if (activePlan == null) return 180;

    final baseDays = activePlan.totalDays > 0 ? activePlan.totalDays : 180;
    final buffer = (baseDays * 0.30).ceil().clamp(60, 360).toInt();

    // يكفي للخطط الطويلة جدًا مثل 700 يوم، مع حد آمن حتى لا نثقل التطبيق.
    return (baseDays + buffer).clamp(180, 1400).toInt();
  }

  Future<_ScheduleData> _loadSchedule({required int? daysAhead}) async {
    final plans = await MemorizationPlanStorage.getPlans();
    if (plans.isEmpty) {
      return const _ScheduleData(plansCount: 0, items: []);
    }

    final activePlan = await MemorizationPlanStorage.getActivePlan();
    final activeTask = await MemorizationPlanStorage.getTodayTask();
    final results = await MemorizationSessionResultStorage.getResults();
    final horizonDays = daysAhead ?? _monthCalendarHorizonDays(activePlan);

    final journeyItems = await const MemorizationPlanJourneyEngine()
        .buildJourneyTasks(
          plan: activePlan,
          activeTask: activeTask,
          daysAhead: horizonDays,
        );

    final items = <_ScheduleItem>[
      ...journeyItems.map(_ScheduleItem.fromJourney),
    ];

    final rescueTasks = const MemorizationRescueReviewEngine()
        .getUpcomingRescueTasks(
          results: results,
          activePlan: activePlan,
          daysAhead: horizonDays,
        );

    for (final task in rescueTasks) {
      items.add(
        _ScheduleItem.fromTask(
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

    return _ScheduleData(plansCount: plans.length, items: items);
  }

  void _selectDay(int dayOffset) {
    AppHaptics.tap(context);
    setState(() => selectedDayOffset = dayOffset);
  }

  Future<void> _onTaskDisplayTap(_ScheduleItem item) async {
    AppHaptics.tap(context);

    if (!item.task.hasValidRange) return;

    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => item.task.type == 'selfTest'
            ? MemorizationTestSessionPage(task: item.task)
            : MemorizationTrainingSessionPage(task: item.task),
      ),
    );

    if (mounted) _refreshSchedule();
  }

  Future<void> _openMonthCalendarSheet() async {
    AppHaptics.tap(context);

    // التقويم الشهري يتحسب عند فتح الأيقونة فقط، وبمدى يغطي الخطة كاملة.
    final data = await _loadSchedule(daysAhead: null);

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MonthCalendarSheet(data: data),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ScheduleData>(
      future: scheduleFuture,
      builder: (context, snapshot) {
        final data =
            snapshot.data ?? const _ScheduleData(plansCount: 0, items: []);

        return _ScheduleCalendarContent(
          data: data,
          selectedDayOffset: selectedDayOffset,
          onDayTap: _selectDay,
          onTaskTap: (item) => _onTaskDisplayTap(item),
          onOpenMonthCalendar: _openMonthCalendarSheet,
        );
      },
    );
  }
}
