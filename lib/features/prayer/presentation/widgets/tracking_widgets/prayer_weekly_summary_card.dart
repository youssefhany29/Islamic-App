import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/prayer/data/services/prayer_tracking_storage.dart';
import 'package:islamic_app/features/prayer/presentation/widgets/tracking_widgets/prayer_weekly_summary_day_tile.dart';
import 'package:islamic_app/shared/widgets/common_components/app_layout_constants.dart';

class PrayerWeeklySummaryCard extends StatelessWidget {
  const PrayerWeeklySummaryCard({
    super.key,
    required this.weeklyHistory,
    required this.isLoading,
    this.large = false,
  });

  final List<PrayerWeeklyDay> weeklyHistory;
  final bool isLoading;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color cardColor = isDark ? colors.secondary : Colors.white;
    final Color textColor = colors.surface;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: large ? double.infinity : AppLayoutConstants.mainCardWidth,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: large ? 16 : 12.w,
            vertical: large ? 14 : 11.h,
          ),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(
              large ? 24 : AppLayoutConstants.mainCardRadius,
            ),
            border: Border.all(
              color: textColor.withOpacity(isDark ? 0.08 : 0.055),
              width: large ? 0.8 : 0.8.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.14 : 0.045),
                blurRadius: large ? 16 : 16.r,
                offset: Offset(0, large ? 7 : 7.h),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  _HeaderIcon(
                    large: large,
                    icon: Icons.event_available_rounded,
                    color: colors.primary,
                  ),
                  SizedBox(width: large ? 10 : 8.w),
                  Expanded(
                    child: Text(
                      'ملخص الأسبوع',
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body(context).copyWith(
                        color: textColor,
                        fontSize: large ? 19 : 12.sp,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: large ? 13 : 10.h),
              if (isLoading)
                SizedBox(
                  height: large ? 72 : 56.h,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: colors.primary,
                      strokeWidth: 2.2,
                    ),
                  ),
                )
              else
                _WeeklyDaysScroller(
                  large: large,
                  weeklyHistory: weeklyHistory,
                  textColor: textColor,
                  primaryColor: colors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyDaysScroller extends StatelessWidget {
  const _WeeklyDaysScroller({
    required this.large,
    required this.weeklyHistory,
    required this.textColor,
    required this.primaryColor,
  });

  final bool large;
  final List<PrayerWeeklyDay> weeklyHistory;
  final Color textColor;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    if (weeklyHistory.isEmpty) {
      return SizedBox(
        height: large ? 74 : 58.h,
        child: Center(
          child: Text(
            'لا توجد بيانات لهذا الأسبوع بعد',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.caption(context).copyWith(
              color: textColor.withOpacity(0.58),
              fontSize: large ? 13 : 9.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    final List<PrayerWeeklyDay> orderedDays = weeklyHistory;

    return ClipRRect(
      borderRadius: BorderRadius.circular(large ? 18 : 16.r),
      child: SizedBox(
        width: double.infinity,
        height: large ? 80 : 62.h,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.hardEdge,
          padding: EdgeInsetsDirectional.only(
            start: large ? 2 : 2.w,
            end: large ? 2 : 2.w,
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: List.generate(orderedDays.length, (index) {
              final day = orderedDays[index];

              return Padding(
                padding: EdgeInsetsDirectional.only(
                  start: index == 0 ? 0 : large ? 10 : 8.w,
                ),
                child: PrayerWeeklySummaryDayTile(
                  large: large,
                  day: day,
                  dayLabel: _fullDayName(day),
                  textColor: textColor,
                  primaryColor: primaryColor,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  String _fullDayName(PrayerWeeklyDay day) {
    final DateTime? date = _parseDateKey(day.dateKey);

    if (date == null) {
      return day.dayName;
    }

    const List<String> names = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];

    return names[(date.weekday - 1).clamp(0, 6).toInt()];
  }

  DateTime? _parseDateKey(String value) {
    final parts = value.split('-');
    if (parts.length != 3) return null;

    final int? year = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    final int? day = int.tryParse(parts[2]);

    if (year == null || month == null || day == null) return null;

    return DateTime(year, month, day);
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.large,
    required this.icon,
    required this.color,
  });

  final bool large;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: large ? 38 : 30.w,
      height: large ? 38 : 30.w,
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color,
        size: large ? 18 : 14.sp,
      ),
    );
  }
}
