import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/prayer/data/services/prayer_tracking_storage.dart';

class PrayerWeeklySummaryDayTile extends StatelessWidget {
  const PrayerWeeklySummaryDayTile({
    super.key,
    required this.day,
    required this.dayLabel,
    required this.textColor,
    required this.primaryColor,
    this.large = false,
  });

  final PrayerWeeklyDay day;
  final String dayLabel;
  final Color textColor;
  final Color primaryColor;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final _WeeklyTileState state = _resolveState();
    final _WeeklyTileColors tileColors = _resolveColors(state);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: large ? 92 : 73.w,
      height: large ? 76 : 58.h,
      padding: EdgeInsets.symmetric(
        horizontal: large ? 8 : 7.w,
        vertical: large ? 8 : 7.h,
      ),
      decoration: BoxDecoration(
        color: tileColors.tileColor,
        borderRadius: BorderRadius.circular(large ? 18 : 16.r),
        border: Border.all(
          color: tileColors.borderColor,
          width: large ? 0.9 : 0.9.w,
        ),
        boxShadow: day.isToday
            ? [
          BoxShadow(
            color: tileColors.accentColor.withOpacity(0.14),
            blurRadius: large ? 12 : 12.r,
            offset: Offset(0, large ? 5 : 5.h),
          ),
        ]
            : const [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: Text(
              dayLabel,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
                color: tileColors.labelColor,
                fontSize: large ? 12 : 8.6.sp,
                fontWeight: day.isToday ? FontWeight.w900 : FontWeight.w700,
                height: 1.05,
              ),
            ),
          ),
          SizedBox(height: large ? 9 : 7.h),
          Container(
            width: large ? 24 : 19.w,
            height: large ? 24 : 19.w,
            decoration: BoxDecoration(
              color: tileColors.statusBackground,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: _StatusIcon(
              checkedCount: day.checkedCount,
              state: state,
              color: tileColors.statusColor,
              large: large,
            ),
          ),
        ],
      ),
    );
  }

  _WeeklyTileState _resolveState() {
    if (day.completed) {
      return _WeeklyTileState.completed;
    }

    if (day.checkedCount > 0) {
      return _WeeklyTileState.partial;
    }

    if (day.isFuture || day.isToday) {
      return _WeeklyTileState.notStarted;
    }

    return _WeeklyTileState.missed;
  }

  _WeeklyTileColors _resolveColors(_WeeklyTileState state) {
    const Color green = Color(0xFF45B77E);
    const Color orange = Color(0xFFF59E0B);
    const Color red = Color(0xFFE25555);

    switch (state) {
      case _WeeklyTileState.completed:
        return _WeeklyTileColors(
          accentColor: green,
          tileColor: green.withOpacity(0.10),
          borderColor: green.withOpacity(day.isToday ? 0.34 : 0.16),
          labelColor: green.withOpacity(0.95),
          statusBackground: green,
          statusColor: Colors.white,
        );
      case _WeeklyTileState.partial:
        return _WeeklyTileColors(
          accentColor: orange,
          tileColor: orange.withOpacity(0.11),
          borderColor: orange.withOpacity(day.isToday ? 0.36 : 0.17),
          labelColor: orange.withOpacity(0.96),
          statusBackground: orange,
          statusColor: Colors.white,
        );
      case _WeeklyTileState.missed:
        return _WeeklyTileColors(
          accentColor: red,
          tileColor: red.withOpacity(0.09),
          borderColor: red.withOpacity(0.18),
          labelColor: red.withOpacity(0.95),
          statusBackground: red,
          statusColor: Colors.white,
        );
      case _WeeklyTileState.notStarted:
        final Color neutralBackground = textColor.withOpacity(0.050);
        return _WeeklyTileColors(
          accentColor: day.isToday ? primaryColor : textColor,
          tileColor: neutralBackground,
          borderColor: day.isToday
              ? primaryColor.withOpacity(0.20)
              : textColor.withOpacity(0.035),
          labelColor: day.isToday
              ? primaryColor
              : textColor.withOpacity(0.68),
          statusBackground: textColor.withOpacity(0.12),
          statusColor: textColor.withOpacity(0.46),
        );
    }
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({
    required this.checkedCount,
    required this.state,
    required this.color,
    required this.large,
  });

  final int checkedCount;
  final _WeeklyTileState state;
  final Color color;
  final bool large;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case _WeeklyTileState.completed:
        return Icon(
          Icons.check_rounded,
          color: color,
          size: large ? 16 : 12.5.sp,
        );
      case _WeeklyTileState.partial:
        return Text(
          checkedCount.toString(),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          style: AppTextStyles.caption(context).copyWith(
            color: color,
            fontSize: large ? 12 : 8.5.sp,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        );
      case _WeeklyTileState.missed:
        return Icon(
          Icons.close_rounded,
          color: color,
          size: large ? 15 : 12.sp,
        );
      case _WeeklyTileState.notStarted:
        return Icon(
          Icons.remove_rounded,
          color: color,
          size: large ? 15 : 12.sp,
        );
    }
  }
}

enum _WeeklyTileState {
  completed,
  partial,
  missed,
  notStarted,
}

class _WeeklyTileColors {
  const _WeeklyTileColors({
    required this.accentColor,
    required this.tileColor,
    required this.borderColor,
    required this.labelColor,
    required this.statusBackground,
    required this.statusColor,
  });

  final Color accentColor;
  final Color tileColor;
  final Color borderColor;
  final Color labelColor;
  final Color statusBackground;
  final Color statusColor;
}
