import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/services/app_haptics.dart';
import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/analytics/analytics_ui.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/review_schedule/review_schedule_data.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/review_schedule/review_schedule_ui.dart';

class ReviewScheduleTasksCard extends StatelessWidget {
  const ReviewScheduleTasksCard({
    super.key,
    required this.month,
    required this.selectedDay,
    required this.onTaskTap,
  });

  final ReviewScheduleMonth month;
  final DateTime? selectedDay;
  final ValueChanged<ReviewScheduleItem> onTaskTap;

  @override
  Widget build(BuildContext context) {
    final days = _visibleDays;
    final textColor = AnalyticsThemeColors.textPrimary(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AnalyticsThemeColors.innerCard(context),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AnalyticsThemeColors.border(
            context,
            AnalyticsThemeColors.isDark(context) ? 0.22 : 0.95,
          ),
          width: 1.05.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(13.w, 13.h, 13.w, 8.h),
            child: _TasksHeader(
              title: _title,
              subtitle: _subtitle,
              textColor: textColor,
              hasSelection: selectedDay != null,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18.r),
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(10.w, 0, 10.w, 12.h),
                itemCount: days.length,
                separatorBuilder: (_, __) => SizedBox(height: 8.h),
                itemBuilder: (context, index) {
                  final day = days[index];
                  return _DayTasksGroup(day: day, onTaskTap: onTaskTap);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<ReviewScheduleDay> get _visibleDays {
    final day = selectedDay;
    if (day == null) {
      return month.days
          .where((item) => !_isPast(item.date) && item.items.isNotEmpty)
          .toList();
    }

    return month.days
        .where(
          (item) =>
              _sameDay(item.date, day) &&
              !_isPast(item.date) &&
              item.items.isNotEmpty,
        )
        .toList();
  }

  String get _title {
    final day = selectedDay;
    if (day == null)
      return 'مهام ${ReviewScheduleText.monthTitle(month.month)}';
    return 'مهام ${ReviewScheduleText.dateTitle(day)}';
  }

  String get _subtitle {
    final days = _visibleDays;
    final count = days.fold<int>(0, (sum, day) => sum + day.items.length);

    if (selectedDay == null) {
      return count == 0
          ? 'لا توجد مهام في هذا الشهر'
          : '$count مهمة موزعة على الشهر';
    }

    return count == 0
        ? 'لا توجد مهام في هذا اليوم'
        : '$count مهمة في هذا اليوم';
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isPast(DateTime date) {
    return _dateOnly(date).isBefore(_dateOnly(DateTime.now()));
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}

class _TasksHeader extends StatelessWidget {
  const _TasksHeader({
    required this.title,
    required this.subtitle,
    required this.textColor,
    required this.hasSelection,
  });

  final String title;
  final String subtitle;
  final Color textColor;
  final bool hasSelection;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Container(
          width: 38.w,
          height: 38.w,
          decoration: BoxDecoration(
            color: colors.primary.withOpacity(0.09),
            shape: BoxShape.circle,
          ),
          child: Icon(
            hasSelection
                ? Icons.event_available_rounded
                : Icons.calendar_view_month_rounded,
            color: colors.primary,
            size: 19.sp,
          ),
        ),
        SizedBox(width: 9.w),
        Expanded(
          child: Column(
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
                  fontSize: 12.2.sp,
                  fontWeight: FontWeight.w800,
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
      ],
    );
  }
}

class _DayTasksGroup extends StatelessWidget {
  const _DayTasksGroup({required this.day, required this.onTaskTap});

  final ReviewScheduleDay day;
  final ValueChanged<ReviewScheduleItem> onTaskTap;

  @override
  Widget build(BuildContext context) {
    final textColor = AnalyticsThemeColors.textPrimary(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 10.h),
      decoration: AnalyticsDecorations.innerCard(context, radius: 18.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: day.items.isEmpty
                      ? textColor.withOpacity(0.18)
                      : Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 7.w),
              Expanded(
                child: Text(
                  day.isToday
                      ? 'اليوم'
                      : ReviewScheduleText.dateTitle(day.date),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.caption(context).copyWith(
                    color: textColor,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
              ),
              Text(
                day.items.isEmpty ? 'فارغ' : '${day.items.length} مهمة',
                textDirection: TextDirection.rtl,
                style: AppTextStyles.caption(context).copyWith(
                  color: textColor.withOpacity(0.50),
                  fontSize: 8.sp,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          if (day.items.isEmpty)
            _EmptyDayLine(textColor: textColor)
          else
            for (int index = 0; index < day.items.length; index++) ...[
              _TaskTile(
                item: day.items[index],
                onTap: () => onTaskTap(day.items[index]),
              ),
              if (index != day.items.length - 1) SizedBox(height: 7.h),
            ],
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.item, required this.onTap});

  final ReviewScheduleItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = AnalyticsThemeColors.textPrimary(context);
    final color = ReviewScheduleColors.taskColor(
      item.task.type,
      isRescue: item.isRescue,
    );
    final icon = ReviewScheduleColors.taskIcon(
      item.task.type,
      isRescue: item.isRescue,
    );

    return Material(
      color: AnalyticsThemeColors.miniCard(context),
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: item.task.hasValidRange
            ? () {
                AppHaptics.tap(context);
                onTap();
              }
            : null,
        child: Container(
          padding: EdgeInsets.fromLTRB(10.w, 9.h, 10.w, 9.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AnalyticsThemeColors.border(context, 0.74),
              width: 0.8.w,
            ),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16.sp),
              ),
              SizedBox(width: 9.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.title,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                        color: textColor,
                        fontSize: 9.8.sp,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      item.subtitle,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 3,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                        color: textColor.withOpacity(0.56),
                        fontSize: 8.2.sp,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              _TaskBadge(text: item.typeLabel, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskBadge extends StatelessWidget {
  const _TaskBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Text(
        text,
        textDirection: TextDirection.rtl,
        style: AppTextStyles.caption(context).copyWith(
          color: color,
          fontSize: 7.8.sp,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _EmptyDayLine extends StatelessWidget {
  const _EmptyDayLine({required this.textColor});

  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: AnalyticsThemeColors.emptyChip(context),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Text(
        'لا توجد مهام في هذا اليوم',
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        style: AppTextStyles.caption(context).copyWith(
          color: textColor.withOpacity(0.50),
          fontSize: 8.4.sp,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
      ),
    );
  }
}
