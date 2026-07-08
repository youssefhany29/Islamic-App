import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/features/memorization/presentation/widgets/analytics/analytics_ui.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/review_schedule/review_schedule_data.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/review_schedule/review_schedule_month_card.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/review_schedule/review_schedule_tasks_card.dart';

class ReviewScheduleBoardCard extends StatelessWidget {
  const ReviewScheduleBoardCard({
    super.key,
    required this.months,
    required this.selectedMonthIndex,
    required this.monthController,
    required this.isCalendarExpanded,
    required this.selectedDay,
    required this.onMonthChanged,
    required this.onToggleCalendar,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onDaySelected,
    required this.onClearDaySelection,
    required this.onTaskTap,
  });

  final List<ReviewScheduleMonth> months;
  final int selectedMonthIndex;
  final PageController monthController;
  final bool isCalendarExpanded;
  final DateTime? selectedDay;
  final ValueChanged<int> onMonthChanged;
  final VoidCallback onToggleCalendar;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback onClearDaySelection;
  final ValueChanged<ReviewScheduleItem> onTaskTap;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final safeMonthIndex = selectedMonthIndex
        .clamp(0, months.length - 1)
        .toInt();
    final currentMonth = months[safeMonthIndex];
    final isDark = AnalyticsThemeColors.isDark(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final calendarHeight = _calendarHeightForMonth(
          context: context,
          month: currentMonth,
          maxWidth: constraints.maxWidth,
          isExpanded: isCalendarExpanded,
        );

        return Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, bottomPadding + 12.h),
          decoration: BoxDecoration(
            color: AnalyticsThemeColors.outerCard(context),
            borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
            border: Border.all(
              color: isDark
                  ? AnalyticsThemeColors.border(context, 0.16)
                  : Colors.white.withOpacity(0.82),
              width: 0.8.w,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                height: calendarHeight,
                child: ClipRect(
                  child: PageView.builder(
                    controller: monthController,
                    reverse: true,
                    itemCount: months.length,
                    onPageChanged: onMonthChanged,
                    itemBuilder: (context, index) {
                      return SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: ReviewScheduleMonthCard(
                          month: months[index],
                          monthIndex: index,
                          monthsCount: months.length,
                          isExpanded: isCalendarExpanded,
                          selectedDay: index == selectedMonthIndex
                              ? selectedDay
                              : null,
                          onToggleExpanded: onToggleCalendar,
                          onPreviousMonth: onPreviousMonth,
                          onNextMonth: onNextMonth,
                          onDaySelected: onDaySelected,
                          onClearDaySelection: onClearDaySelection,
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              Expanded(
                child: ReviewScheduleTasksCard(
                  month: currentMonth,
                  selectedDay: selectedDay,
                  onTaskTap: onTaskTap,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double _calendarHeightForMonth({
    required BuildContext context,
    required ReviewScheduleMonth month,
    required double maxWidth,
    required bool isExpanded,
  }) {
    if (!isExpanded) return 188.h;

    final leadingEmptyDays = month.month.weekday % 7;
    final rows = ((leadingEmptyDays + month.days.length + 6) ~/ 7)
        .clamp(1, 6)
        .toInt();

    final availableWidth = maxWidth - 48.w;
    final calendarWidth = availableWidth > 0 ? availableWidth : maxWidth;
    final cellWidth = (calendarWidth - (6 * 4.w)) / 7;
    final cellHeight = cellWidth / 1.02;
    final gridHeight = (rows * cellHeight) + ((rows - 1) * 4.h);

    return 154.h + gridHeight;
  }
}
