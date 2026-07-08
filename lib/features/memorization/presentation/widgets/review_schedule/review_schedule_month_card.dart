import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/services/app_haptics.dart';
import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/analytics/analytics_ui.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/review_schedule/review_schedule_data.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/review_schedule/review_schedule_ui.dart';

class ReviewScheduleMonthCard extends StatelessWidget {
  const ReviewScheduleMonthCard({
    super.key,
    required this.month,
    required this.monthIndex,
    required this.monthsCount,
    required this.isExpanded,
    required this.selectedDay,
    required this.onToggleExpanded,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onDaySelected,
    required this.onClearDaySelection,
  });

  final ReviewScheduleMonth month;
  final int monthIndex;
  final int monthsCount;
  final bool isExpanded;
  final DateTime? selectedDay;
  final VoidCallback onToggleExpanded;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback onClearDaySelection;

  @override
  Widget build(BuildContext context) {
    final textColor = AnalyticsThemeColors.textPrimary(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12.w, 2.h, 12.w, 13.h),
      decoration: AnalyticsDecorations.innerCard(context, radius: 22.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MonthHeader(
            title: ReviewScheduleText.monthTitle(month.month),
            subtitle: month.tasksCount == 0
                ? 'لا توجد مهام في هذا الشهر'
                : '${month.tasksCount} مهمة في هذا الشهر',
            textColor: textColor,
            isExpanded: isExpanded,
            canGoPrevious: monthIndex > 0,
            canGoNext: monthIndex < monthsCount - 1,
            onToggleExpanded: onToggleExpanded,
            onPreviousMonth: onPreviousMonth,
            onNextMonth: onNextMonth,
          ),
          SizedBox(height: 10.h),
          const _LegendRow(),
          if (!isExpanded) ...[
            SizedBox(height: 10.h),
            _CollapsedDaysStrip(
              month: month,
              selectedDay: selectedDay,
              onDaySelected: onDaySelected,
              onClearDaySelection: onClearDaySelection,
            ),
          ],
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: isExpanded
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 12.h),
                      _WeekDaysRow(textColor: textColor),
                      SizedBox(height: 7.h),
                      _MonthGrid(
                        month: month,
                        selectedDay: selectedDay,
                        onDaySelected: onDaySelected,
                        onClearDaySelection: onClearDaySelection,
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _CollapsedDaysStrip extends StatelessWidget {
  const _CollapsedDaysStrip({
    required this.month,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onClearDaySelection,
  });

  final ReviewScheduleMonth month;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback onClearDaySelection;

  @override
  Widget build(BuildContext context) {
    final cells = _activeWeekCells();
    final textColor = AnalyticsThemeColors.textPrimary(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CollapsedWeekDaysRow(textColor: textColor),
          SizedBox(height: 7.h),
          SizedBox(
            height: 48.h,
            child: Row(
              children: [
                for (final day in cells)
                  Expanded(
                    child: day == null
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: EdgeInsets.symmetric(horizontal: 1.5.w),
                            child: SizedBox.expand(
                              child: _DayCell(
                                day: day,
                                isSelected: _sameDay(day.date, selectedDay),
                                onTap: () {
                                  AppHaptics.tap(context);
                                  if (_sameDay(day.date, selectedDay)) {
                                    onClearDaySelection();
                                  } else {
                                    onDaySelected(day.date);
                                  }
                                },
                              ),
                            ),
                          ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<ReviewScheduleDay?> _activeWeekCells() {
    if (month.days.isEmpty) return List<ReviewScheduleDay?>.filled(7, null);

    final today = _dateOnly(DateTime.now());
    final availableDays = month.days.where((day) {
      return !_dateOnly(day.date).isBefore(today);
    }).toList();
    if (availableDays.isEmpty) return List<ReviewScheduleDay?>.filled(7, null);

    final anchor =
        selectedDay != null &&
            selectedDay!.year == month.month.year &&
            selectedDay!.month == month.month.month &&
            !_dateOnly(selectedDay!).isBefore(today)
        ? selectedDay!
        : month.month.year == today.year && month.month.month == today.month
        ? today
        : availableDays.first.date;
    final weekStart = _dateOnly(
      anchor,
    ).subtract(Duration(days: anchor.weekday % DateTime.daysPerWeek));

    return List.generate(7, (offset) {
      final date = weekStart.add(Duration(days: offset));

      if (date.year != month.month.year || date.month != month.month.month) {
        return null;
      }

      if (_dateOnly(date).isBefore(today)) {
        return null;
      }

      final dayNumber = date.day;
      if (dayNumber < 1 || dayNumber > month.days.length) {
        return null;
      }

      return month.days[dayNumber - 1];
    });
  }

  bool _sameDay(DateTime a, DateTime? b) {
    if (b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}

class _CollapsedWeekDaysRow extends StatelessWidget {
  const _CollapsedWeekDaysRow({required this.textColor});

  final Color textColor;

  @override
  Widget build(BuildContext context) {
    const labels = [
      'الأحد',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
    ];

    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  style: AppTextStyles.caption(context).copyWith(
                    color: textColor.withOpacity(0.56),
                    fontSize: 7.2.sp,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.title,
    required this.subtitle,
    required this.textColor,
    required this.isExpanded,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onToggleExpanded,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final String title;
  final String subtitle;
  final Color textColor;
  final bool isExpanded;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onToggleExpanded;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        _CircleAction(
          icon: isExpanded
              ? Icons.keyboard_arrow_up_rounded
              : Icons.keyboard_arrow_down_rounded,
          onTap: onToggleExpanded,
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                title,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body(context).copyWith(
                  color: textColor,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                subtitle,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                maxLines: 3,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  color: textColor.withOpacity(0.56),
                  fontSize: 8.8.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        _CircleAction(
          icon: Icons.chevron_right_rounded,
          isEnabled: canGoPrevious,
          onTap: onPreviousMonth,
        ),
        SizedBox(width: 6.w),
        _CircleAction(
          icon: Icons.chevron_left_rounded,
          isEnabled: canGoNext,
          onTap: onNextMonth,
        ),
      ],
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.onTap,
    this.isEnabled = true,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.primary.withOpacity(isEnabled ? 0.09 : 0.04),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: isEnabled
            ? () {
                AppHaptics.tap(context);
                onTap();
              }
            : null,
        child: SizedBox(
          width: 28.w,
          height: 28.w,
          child: Icon(
            icon,
            color: colors.primary.withOpacity(isEnabled ? 1 : 0.28),
            size: 18.sp,
          ),
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      textDirection: TextDirection.rtl,
      alignment: WrapAlignment.end,
      spacing: 8.w,
      runSpacing: 6.h,
      children: const [
        _LegendItem(label: 'حفظ', color: ReviewScheduleColors.memorization),
        _LegendItem(label: 'مراجعة', color: ReviewScheduleColors.review),
        _LegendItem(label: 'طارئة', color: ReviewScheduleColors.rescue),
        _LegendItem(label: 'اختبار', color: ReviewScheduleColors.test),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textColor = AnalyticsThemeColors.textSecondary(context, 0.62);

    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.rtl,
      children: [
        Container(
          width: 6.w,
          height: 6.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 4.w),
        Text(
          label,
          textDirection: TextDirection.rtl,
          style: AppTextStyles.caption(context).copyWith(
            color: textColor,
            fontSize: 8.2.sp,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _WeekDaysRow extends StatelessWidget {
  const _WeekDaysRow({required this.textColor});

  final Color textColor;

  @override
  Widget build(BuildContext context) {
    const labels = [
      'الأحد',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        children: [
          for (final label in labels)
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    style: AppTextStyles.caption(context).copyWith(
                      color: textColor.withOpacity(0.56),
                      fontSize: 7.2.sp,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onClearDaySelection,
  });

  final ReviewScheduleMonth month;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback onClearDaySelection;

  @override
  Widget build(BuildContext context) {
    final leadingEmptyDays = month.month.weekday % 7;
    final cellsCount = leadingEmptyDays + month.days.length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cellsCount,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 4.h,
          crossAxisSpacing: 4.w,
          childAspectRatio: 1.02,
        ),
        itemBuilder: (context, index) {
          if (index < leadingEmptyDays) {
            return const SizedBox.shrink();
          }

          final day = month.days[index - leadingEmptyDays];
          return _DayCell(
            day: day,
            isSelected: _sameDay(day.date, selectedDay),
            onTap: () {
              AppHaptics.tap(context);
              if (_sameDay(day.date, selectedDay)) {
                onClearDaySelection();
              } else {
                onDaySelected(day.date);
              }
            },
          );
        },
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime? b) {
    if (b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.onTap,
  });

  final ReviewScheduleDay day;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = AnalyticsThemeColors.textPrimary(context);
    final colors = Theme.of(context).colorScheme;
    final hasTasks = day.items.isNotEmpty;
    final dotColors = _taskDotColors();
    final background = isSelected
        ? colors.primary
        : day.isToday
        ? colors.primary.withOpacity(0.11)
        : hasTasks
        ? AnalyticsThemeColors.innerCard(context)
        : Colors.transparent;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(13.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(13.r),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13.r),
            border: Border.all(
              color: isSelected
                  ? colors.primary
                  : day.isToday
                  ? colors.primary.withOpacity(0.32)
                  : AnalyticsThemeColors.border(
                      context,
                      hasTasks ? 0.70 : 0.20,
                    ),
              width: 0.8.w,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isTight = constraints.maxHeight < 38.h;
              final dotRadius = isTight ? 1.55.w : 2.05.w;
              final dotGap = isTight ? 1.5.w : 2.w;
              final numberSize = isTight ? 8.6.sp : 10.sp;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(
                    '${day.date.day}',
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    style: TextStyle(
                      color: isSelected ? Colors.white : textColor,
                      fontSize: numberSize,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  if (dotColors.isNotEmpty)
                    SizedBox(height: isTight ? 3.h : 4.h),
                  if (dotColors.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (
                          var index = 0;
                          index < dotColors.length;
                          index++
                        ) ...[
                          Container(
                            width: dotRadius * 2,
                            height: dotRadius * 2,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.92)
                                  : dotColors[index],
                              shape: BoxShape.circle,
                            ),
                          ),
                          if (index != dotColors.length - 1)
                            SizedBox(width: dotGap),
                        ],
                      ],
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Color> _taskDotColors() {
    final colors = <Color>[];

    for (final item in day.items) {
      final color = ReviewScheduleColors.taskColor(
        item.task.type,
        isRescue: item.isRescue,
      );
      if (!colors.contains(color)) colors.add(color);
    }

    return colors.take(4).toList();
  }
}
