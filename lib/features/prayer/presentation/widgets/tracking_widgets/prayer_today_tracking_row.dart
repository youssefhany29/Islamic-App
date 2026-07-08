import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/services/app_haptics.dart';
import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/prayer/presentation/widgets/tracking_widgets/prayer_today_tracking_models.dart';

class PrayerTodayTrackingRow extends StatelessWidget {
  const PrayerTodayTrackingRow({
    super.key,
    required this.data,
    this.large = false,
  });

  final PrayerTodayRowData data;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final _PrayerRowStyle style = _styleForState(
      context: context,
      state: data.state,
      isDark: isDark,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: data.enabled
            ? () {
                AppHaptics.tap(context);
                data.onTap();
              }
            : () {
                AppHaptics.tap(context);
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: large ? 42 : 42.h,
          padding: EdgeInsets.symmetric(
            horizontal: large ? 10 : 10.w,
          ),
          decoration: BoxDecoration(
            color: style.backgroundColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: style.borderColor,
              width: large ? 0.8 : 0.8.w,
            ),
            boxShadow: data.state == PrayerTodayRowState.current
                ? [
                    BoxShadow(
                      color: colors.primary.withOpacity(isDark ? 0.22 : 0.18),
                      blurRadius: large ? 13 : 13.r,
                      offset: Offset(0, large ? 5 : 5.h),
                    ),
                  ]
                : null,
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: large ? 84 : 50.w,
                child: Text(
                  data.prayerName,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body(context).copyWith(
                    color: style.titleColor,
                    fontSize: large ? 14 : 11.sp,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
              SizedBox(
                width: large ? 56 : 50.w,
                child: Text(
                  data.timeText,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    color: style.timeColor,
                    fontSize: large ? 12 : 11.sp,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  data.statusText,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    color: style.statusColor,
                    fontSize: large ? 11.5 : 10.sp,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
              SizedBox(width: large ? 8 : 8.w),
              _PrayerStateIcon(
                large: large,
                style: style,
              ),
            ],
          ),
        ),
      ),
    );
  }

  _PrayerRowStyle _styleForState({
    required BuildContext context,
    required PrayerTodayRowState state,
    required bool isDark,
  }) {
    final colors = Theme.of(context).colorScheme;
    final Color textColor = colors.surface;
    final Color primaryColor = colors.primary;
    const Color completedColor = Color(0xFF4FBF84);
    const Color missedColor = Color(0xFFB96B6B);

    switch (state) {
      case PrayerTodayRowState.completed:
        return _PrayerRowStyle(
          backgroundColor: completedColor.withOpacity(isDark ? 0.18 : 0.13),
          borderColor: completedColor.withOpacity(0.10),
          titleColor: textColor,
          timeColor: textColor.withOpacity(0.70),
          statusColor: completedColor,
          iconData: Icons.check_rounded,
          iconForegroundColor: Colors.white,
          iconBackgroundColor: completedColor,
        );
      case PrayerTodayRowState.current:
        return _PrayerRowStyle(
          backgroundColor: primaryColor,
          borderColor: Colors.white.withOpacity(isDark ? 0.08 : 0.02),
          titleColor: Colors.white,
          timeColor: Colors.white.withOpacity(0.92),
          statusColor: const Color(0xFF36D08E),
          iconData: Icons.timer_outlined,
          iconForegroundColor: Colors.white,
          iconBackgroundColor: Colors.white.withOpacity(0.14),
        );
      case PrayerTodayRowState.missed:
        return _PrayerRowStyle(
          backgroundColor: missedColor.withOpacity(isDark ? 0.16 : 0.08),
          borderColor: missedColor.withOpacity(0.08),
          titleColor: textColor.withOpacity(0.84),
          timeColor: textColor.withOpacity(0.58),
          statusColor: missedColor,
          iconData: Icons.lock_clock_rounded,
          iconForegroundColor: missedColor,
          iconBackgroundColor: missedColor.withOpacity(isDark ? 0.18 : 0.12),
        );
      case PrayerTodayRowState.future:
        return _PrayerRowStyle(
          backgroundColor: primaryColor.withOpacity(isDark ? 0.10 : 0.055),
          borderColor: primaryColor.withOpacity(isDark ? 0.05 : 0.035),
          titleColor: textColor.withOpacity(0.86),
          timeColor: textColor.withOpacity(0.60),
          statusColor: textColor.withOpacity(0.42),
          iconData: Icons.lock_rounded,
          iconForegroundColor: textColor.withOpacity(0.38),
          iconBackgroundColor: textColor.withOpacity(isDark ? 0.10 : 0.07),
        );
    }
  }
}

class _PrayerStateIcon extends StatelessWidget {
  const _PrayerStateIcon({
    required this.large,
    required this.style,
  });

  final bool large;
  final _PrayerRowStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: large ? 27 : 21.w,
      height: large ? 27 : 21.w,
      decoration: BoxDecoration(
        color: style.iconBackgroundColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        style.iconData,
        size: large ? 15 : 12.sp,
        color: style.iconForegroundColor,
      ),
    );
  }
}

class _PrayerRowStyle {
  const _PrayerRowStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.titleColor,
    required this.timeColor,
    required this.statusColor,
    required this.iconData,
    required this.iconForegroundColor,
    required this.iconBackgroundColor,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color titleColor;
  final Color timeColor;
  final Color statusColor;
  final IconData iconData;
  final Color iconForegroundColor;
  final Color iconBackgroundColor;
}
