import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_session_result_model.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_today_task_model.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_plan_journey_engine.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_plan_completion_service.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_plan_storage.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_rescue_review_engine.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_session_result_storage.dart';
import 'package:islamic_app/features/memorization/presentation/pages/memorization_training_session_page.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/mastery_empty_state_line.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/mastery_snack_bar.dart';
import 'package:islamic_app/features/memorization/test/pages/memorization_test_session_page.dart';
import 'package:islamic_app/features/quran/reader/quran_reader_helpers.dart';

class _TodayMissionColors {
  const _TodayMissionColors._();

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color card(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return isDark(context) ? colors.secondary : Colors.white;
  }

  static Color tile(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (isDark(context)) return colors.surface.withOpacity(0.045);
    return const Color(0xFFFAFCFE);
  }

  static Color border(BuildContext context, [double? opacity]) {
    final colors = Theme.of(context).colorScheme;
    return colors.surface.withOpacity(
      opacity ?? (isDark(context) ? 0.12 : 0.065),
    );
  }

  static Color text(BuildContext context, [double opacity = 1]) {
    return Theme.of(context).colorScheme.surface.withOpacity(opacity);
  }

  static Color iconCircle(BuildContext context) {
    return Theme.of(
      context,
    ).colorScheme.primary.withOpacity(isDark(context) ? 0.15 : 0.10);
  }

  static Color primary(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  static Color buttonEnd(BuildContext context) {
    return isDark(context)
        ? Theme.of(context).colorScheme.primary.withOpacity(0.72)
        : const Color(0xFF09284D);
  }

  static Color gold(BuildContext context) {
    return const Color(0xFFE8B94D);
  }
}

class TodayMasteryTaskCard extends StatefulWidget {
  const TodayMasteryTaskCard({super.key});

  @override
  State<TodayMasteryTaskCard> createState() => _TodayMasteryTaskCardState();
}

class _TodayMasteryTaskCardState extends State<TodayMasteryTaskCard> {
  Future<_TodayMasteryData> _loadData() async {
    final activePlan = await MemorizationPlanStorage.getActivePlan();
    final activeTask = await MemorizationPlanStorage.getTodayTask();
    final results = await MemorizationSessionResultStorage.getResults();

    if (activePlan != null) {
      final completion = const MemorizationPlanCompletionService().evaluate(
        plan: activePlan,
        results: results,
      );
      if (completion.isCompleted) {
        if (!activePlan.isCompleted) {
          await MemorizationPlanStorage.markPlanCompleted(
            planId: activePlan.id,
            completedAt: completion.completedAt ?? DateTime.now(),
          );
        }
        return _TodayMasteryData(results: results, planCompleted: true);
      }
    }

    final todayDay = _dateOnly(DateTime.now());
    final lookAheadDays = _journeyLookAheadDays(activePlan);

    final allJourneyTasks = await const MemorizationPlanJourneyEngine()
        .buildJourneyTasks(
          plan: activePlan,
          activeTask: activeTask,
          daysAhead: lookAheadDays,
        );

    final todayJourneyTasks = allJourneyTasks.where((item) {
      final itemDay = _dateOnly(item.date);
      final taskDay = _dateOnly(item.task.effectiveScheduledDate);

      if (!_sameDay(itemDay, todayDay)) return false;

      if (item.task.type == 'selfTest') {
        return _sameDay(taskDay, todayDay) && !item.task.isFutureTask;
      }

      return !item.task.isFutureTask;
    }).toList();

    final journeyTasks = _normalizeTodayTasks(todayJourneyTasks);

    final rescueTask = const MemorizationRescueReviewEngine().getDueRescueTask(
      results: results,
      activePlan: activePlan,
    );

    final today = DateTime.now();
    MemorizationSessionResultModel? todayCompleted;

    for (final result in results) {
      final completedAt = result.completedAt;
      final isToday =
          completedAt.year == today.year &&
          completedAt.month == today.month &&
          completedAt.day == today.day;

      if (isToday &&
          result.taskType != 'weakReview' &&
          result.taskType != 'selfTest') {
        todayCompleted = result;
        break;
      }
    }

    return _TodayMasteryData(
      journeyTasks: journeyTasks,
      results: results,
      todayCompletedResult: todayCompleted,
      rescueTask: rescueTask,
    );
  }

  int _journeyLookAheadDays(dynamic activePlan) {
    final totalDays = activePlan?.totalDays;

    if (totalDays is int && totalDays > 0) {
      return totalDays.clamp(30, 365).toInt();
    }

    return 180;
  }

  List<MemorizationJourneyTask> _normalizeTodayTasks(
    List<MemorizationJourneyTask> tasks,
  ) {
    if (tasks.isEmpty) return const [];

    final normalTasks = tasks
        .where((item) => item.task.type != 'selfTest')
        .toList(growable: true);

    final testTasks =
        tasks
            .where((item) => item.task.type == 'selfTest')
            .toList(growable: true)
          ..sort((a, b) {
            final priorityCompare = a.priority.compareTo(b.priority);
            if (priorityCompare != 0) return priorityCompare;

            final mandatoryA = a.timeLabel.contains('إلزامي') ? 0 : 1;
            final mandatoryB = b.timeLabel.contains('إلزامي') ? 0 : 1;
            return mandatoryA.compareTo(mandatoryB);
          });

    if (testTasks.isNotEmpty) {
      normalTasks.add(testTasks.first);
    }

    normalTasks.sort((a, b) {
      final priorityCompare = a.priority.compareTo(b.priority);
      if (priorityCompare != 0) return priorityCompare;
      return a.date.compareTo(b.date);
    });

    return normalTasks;
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _openSession(
    BuildContext context,
    MemorizationTodayTaskModel task,
  ) async {
    AppHaptics.tap(context);

    if (!task.hasValidRange) {
      MasterySnackBar.show(context, message: 'المهمة غير جاهزة بعد');
      return;
    }

    if (task.isFutureTask) {
      MasterySnackBar.show(
        context,
        message: 'هذه المهمة موعدها قادم. ستظهر لك في يومها بإذن الله.',
      );
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => task.type == 'selfTest'
            ? MemorizationTestSessionPage(task: task)
            : MemorizationTrainingSessionPage(task: task),
      ),
    );

    if (result == true && mounted) setState(() {});
  }

  bool _isCompleted(
    List<MemorizationSessionResultModel> results,
    MemorizationTodayTaskModel task,
  ) {
    return results.any((result) {
      final exactTask = result.taskId == task.id;
      final sameRange =
          result.startGlobalAyahIndex == task.startGlobalAyahIndex &&
          result.endGlobalAyahIndex == task.endGlobalAyahIndex;
      final compatibleType =
          result.taskType == task.type ||
          (task.type == 'dailyNew' && result.taskType == 'dailyReview') ||
          (task.type == 'dailyReview' && result.taskType == 'dailyNew');

      return exactTask || (sameRange && compatibleType);
    });
  }

  int _remainingCount(List<_TodayTaskItem> items) {
    return items.where((item) => !item.isCompleted).length;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TodayMasteryData>(
      future: _loadData(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? const _TodayMasteryData();

        final List<_TodayTaskItem> items = [
          ...data.journeyTasks.map(
            (item) => _TodayTaskItem(
              task: item.task,
              timeLabel: item.timeLabel,
              isCompleted: _isCompleted(data.results, item.task),
              isRescue: false,
            ),
          ),
          if (data.rescueTask != null)
            _TodayTaskItem(
              task: data.rescueTask!,
              timeLabel: 'أولوية اليوم',
              isCompleted: false,
              isRescue: true,
            ),
        ];

        if (items.isEmpty && data.todayCompletedResult == null) {
          if (data.planCompleted) {
            return const _TodayMissionShell(
              headerIcon: Icons.verified_rounded,
              child: MasteryEmptyStateLine(
                icon: Icons.workspace_premium_rounded,
                title: 'تم إتمام خطة الحفظ',
                subtitle:
                    'بارك الله فيك، أتممت الخطة بنجاح. افتح الخطة الحالية لعرض الشهادة.',
              ),
            );
          }

          return const _TodayMissionShell(
            headerIcon: Icons.wb_sunny_rounded,
            child: MasteryEmptyStateLine(
              icon: Icons.menu_book_rounded,
              title: 'لا توجد مهام حالية',
              subtitle: 'بعد إنشاء الخطة، ستظهر هنا مهمة الحفظ أو المراجعة.',
            ),
          );
        }

        final remaining = _remainingCount(items);

        if (items.isEmpty && data.todayCompletedResult != null) {
          return _TodayMissionShell(
            headerIcon: Icons.verified_rounded,
            child: _CompletedTodayBlock(result: data.todayCompletedResult!),
          );
        }

        final primaryItem = items.firstWhere(
          (item) => !item.isCompleted,
          orElse: () => items.first,
        );

        final secondaryItems = items
            .where((item) => item.task.id != primaryItem.task.id)
            .toList(growable: false);

        return _TodayMissionShell(
          headerIcon: remaining == 0
              ? Icons.verified_rounded
              : Icons.wb_sunny_rounded,
          child: Column(
            children: [
              _PrimaryTodayMissionTile(
                item: primaryItem,
                onTap: primaryItem.isCompleted
                    ? null
                    : () => _openSession(context, primaryItem.task),
              ),
              if (secondaryItems.isNotEmpty) ...[
                SizedBox(height: 10.h),
                ...secondaryItems.map(
                  (item) => Padding(
                    padding: EdgeInsets.only(bottom: 7.h),
                    child: _SecondaryTodayMissionTile(
                      item: item,
                      onTap: item.isCompleted
                          ? null
                          : () => _openSession(context, item.task),
                    ),
                  ),
                ),
              ],
              if (remaining == 0 && data.todayCompletedResult != null) ...[
                SizedBox(height: 10.h),
                _CompletedTodayBlock(result: data.todayCompletedResult!),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TodayMissionShell extends StatelessWidget {
  const _TodayMissionShell({required this.headerIcon, required this.child});

  final IconData headerIcon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(13.w, 8.h, 13.w, 13.h),
      decoration: BoxDecoration(
        color: _TodayMissionColors.card(context),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: _TodayMissionColors.border(context),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: Text(
                  'مهام اليوم',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    color: _TodayMissionColors.text(context),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                ),
              ),
              Container(
                width: 32.w,
                height: 32.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  headerIcon,
                  color: _TodayMissionColors.gold(context),
                  size: 19.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 9.h),
          child,
        ],
      ),
    );
  }
}

class _PrimaryTodayMissionTile extends StatelessWidget {
  const _PrimaryTodayMissionTile({required this.item, required this.onTap});

  final _TodayTaskItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final visual = _TaskVisualData.fromTask(item.task, isRescue: item.isRescue);
    final range = _TaskRangeText.fromTask(item.task);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12.w, 13.h, 12.w, 12.h),
      decoration: BoxDecoration(
        color: _TodayMissionColors.tile(context),
        borderRadius: BorderRadius.circular(21.r),
        border: Border.all(
          color: _TodayMissionColors.border(context),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: _TodayMissionColors.iconCircle(context),
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: Icon(
                  item.isCompleted ? Icons.check_rounded : visual.icon,
                  color: _TodayMissionColors.primary(context),
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      item.isCompleted ? 'تمت المهمة' : visual.badge,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                        color: _TodayMissionColors.text(context, 0.42),
                        fontSize: 8.5.sp,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      range.surahTitle,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                        color: _TodayMissionColors.text(context),
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      range.ayahRangeText,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                        color: _TodayMissionColors.text(context),
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      range.countText,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                        color: _TodayMissionColors.text(context, 0.55),
                        fontSize: 8.8.sp,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 42.w),
            ],
          ),
          SizedBox(height: 13.h),
          _MissionPrimaryButton(
            label: item.isCompleted ? 'تمت مهمة اليوم' : visual.buttonLabel,
            icon: item.isCompleted ? Icons.check_rounded : visual.icon,
            enabled: onTap != null,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class _SecondaryTodayMissionTile extends StatelessWidget {
  const _SecondaryTodayMissionTile({required this.item, required this.onTap});

  final _TodayTaskItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final visual = _TaskVisualData.fromTask(item.task, isRescue: item.isRescue);
    final range = _TaskRangeText.fromTask(item.task);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
          decoration: BoxDecoration(
            color: _TodayMissionColors.tile(context),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: _TodayMissionColors.border(context),
              width: 1,
            ),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                item.isCompleted ? Icons.check_circle_rounded : visual.icon,
                color: _TodayMissionColors.primary(context),
                size: 17.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '${visual.badge} • ${range.surahTitle} • ${range.ayahRangeText}',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    color: _TodayMissionColors.text(context).withOpacity(0.72),
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
              SizedBox(width: 7.w),
              Icon(
                Icons.chevron_left_rounded,
                color: _TodayMissionColors.primary(context).withOpacity(0.80),
                size: 18.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissionPrimaryButton extends StatelessWidget {
  const _MissionPrimaryButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled
          ? _TodayMissionColors.primary(context)
          : _TodayMissionColors.primary(context).withOpacity(0.34),
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: enabled ? onTap : null,
        child: Container(
          width: double.infinity,
          height: 30.h,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 13.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            gradient: enabled
                ? LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      _TodayMissionColors.primary(context),
                      _TodayMissionColors.buttonEnd(context),
                    ],
                  )
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: TextDirection.rtl,
            children: [
              Text(
                label,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  color: Colors.white,
                  fontSize: 9.2.sp,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              SizedBox(width: 7.w),
              Icon(icon, color: Colors.white.withOpacity(0.92), size: 16.sp),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletedTodayBlock extends StatelessWidget {
  const _CompletedTodayBlock({required this.result});

  final MemorizationSessionResultModel result;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: _TodayMissionColors.tile(context),
        borderRadius: BorderRadius.circular(17.r),
        border: Border.all(
          color: _TodayMissionColors.border(context),
          width: 1,
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(
            Icons.verified_rounded,
            color: _TodayMissionColors.primary(context),
            size: 18.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'تم حفظ إنجاز اليوم. ستظهر أي مراجعة أو اختبار في وقته داخل مهام اليوم.',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
                fontWeight: FontWeight.w700,
                color: _TodayMissionColors.text(context).withOpacity(0.62),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayTaskItem {
  const _TodayTaskItem({
    required this.task,
    required this.timeLabel,
    required this.isCompleted,
    required this.isRescue,
  });

  final MemorizationTodayTaskModel task;
  final String timeLabel;
  final bool isCompleted;
  final bool isRescue;
}

class _TaskVisualData {
  const _TaskVisualData({
    required this.icon,
    required this.badge,
    required this.buttonLabel,
  });

  final IconData icon;
  final String badge;
  final String buttonLabel;

  factory _TaskVisualData.fromTask(
    MemorizationTodayTaskModel task, {
    required bool isRescue,
  }) {
    if (isRescue || task.type == 'weakReview') {
      return const _TaskVisualData(
        icon: Icons.healing_rounded,
        badge: 'مراجعة إنقاذ',
        buttonLabel: 'ابدأ مراجعة الإنقاذ',
      );
    }

    switch (task.type) {
      case 'dailyNew':
        return const _TaskVisualData(
          icon: Icons.menu_book_rounded,
          badge: 'حفظ اليوم',
          buttonLabel: 'أكمل حفظ اليوم',
        );
      case 'selfTest':
        return const _TaskVisualData(
          icon: Icons.fact_check_rounded,
          badge: 'اختبار اليوم',
          buttonLabel: 'ابدأ الاختبار',
        );
      case 'dailyReview':
        return const _TaskVisualData(
          icon: Icons.repeat_rounded,
          badge: 'مراجعة',
          buttonLabel: 'ابدأ جلسة المراجعة',
        );
      default:
        return const _TaskVisualData(
          icon: Icons.menu_book_rounded,
          badge: 'مهمة اليوم',
          buttonLabel: 'ابدأ المهمة',
        );
    }
  }
}

class _TaskRangeText {
  const _TaskRangeText({
    required this.surahTitle,
    required this.ayahRangeText,
    required this.countText,
  });

  final String surahTitle;
  final String ayahRangeText;
  final String countText;

  factory _TaskRangeText.fromTask(MemorizationTodayTaskModel task) {
    if (!task.hasValidRange) {
      return _TaskRangeText(
        surahTitle: task.scopeTitle.isEmpty ? task.title : task.scopeTitle,
        ayahRangeText: task.subtitle.isEmpty
            ? 'المهمة غير جاهزة'
            : task.subtitle,
        countText: '—',
      );
    }

    final int maxIndex = QuranReaderHelpers.totalAyahs - 1;
    final int safeStart = task.startGlobalAyahIndex.clamp(0, maxIndex).toInt();
    final int safeEnd = task.endGlobalAyahIndex
        .clamp(safeStart, maxIndex)
        .toInt();

    final start = QuranReaderHelpers.getPositionFromGlobalIndex(safeStart);
    final end = QuranReaderHelpers.getPositionFromGlobalIndex(safeEnd);

    final startSurahName = QuranReaderHelpers.getSuraName(start.suraIndex);
    final endSurahName = QuranReaderHelpers.getSuraName(end.suraIndex);

    final int startAyah = start.ayahIndex + 1;
    final int endAyah = end.ayahIndex + 1;
    final int ayahsCount = (safeEnd - safeStart + 1).clamp(0, 100000).toInt();

    if (start.suraIndex == end.suraIndex) {
      return _TaskRangeText(
        surahTitle: 'سورة $startSurahName',
        ayahRangeText: 'الآيات $startAyah - $endAyah',
        countText: '$ayahsCount آية',
      );
    }

    return _TaskRangeText(
      surahTitle: 'من $startSurahName إلى $endSurahName',
      ayahRangeText: 'آية $startAyah إلى آية $endAyah',
      countText: '$ayahsCount آية',
    );
  }
}

class _TodayMasteryData {
  final List<MemorizationJourneyTask> journeyTasks;
  final List<MemorizationSessionResultModel> results;
  final MemorizationSessionResultModel? todayCompletedResult;
  final MemorizationTodayTaskModel? rescueTask;
  final bool planCompleted;

  const _TodayMasteryData({
    this.journeyTasks = const [],
    this.results = const [],
    this.todayCompletedResult,
    this.rescueTask,
    this.planCompleted = false,
  });
}
