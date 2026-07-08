import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/prayer/presentation/widgets/tracking_widgets/prayer_today_tracking_row.dart';
import 'package:islamic_app/shared/widgets/common_components/app_layout_constants.dart';

import 'package:islamic_app/features/prayer/presentation/widgets/tracking_widgets/prayer_today_tracking_models.dart';

class PrayerTodayTrackingCard extends StatelessWidget {
  const PrayerTodayTrackingCard({
    super.key,
    required this.rows,
    required this.isLoading,
    this.large = false,
  });

  final List<PrayerTodayRowData> rows;
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
            horizontal: large ? 12 : 12.w,
            vertical: large ? 12 : 12.h,
          ),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(
              large ? 22 : AppLayoutConstants.mainCardRadius,
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
          child: isLoading
              ? Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: large ? 18 : 18.h,
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: colors.primary,
                      strokeWidth: 2.2,
                    ),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PrayerTodayHeader(
                      large: large,
                      textColor: textColor,
                      primaryColor: colors.primary,
                    ),
                    SizedBox(height: large ? 10 : 10.h),
                    for (int i = 0; i < rows.length; i++) ...[
                      PrayerTodayTrackingRow(
                        large: large,
                        data: rows[i],
                      ),
                      if (i != rows.length - 1)
                        SizedBox(height: large ? 6 : 6.h),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _PrayerTodayHeader extends StatelessWidget {
  const _PrayerTodayHeader({
    required this.large,
    required this.textColor,
    required this.primaryColor,
  });

  final bool large;
  final Color textColor;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Container(
          width: large ? 32 : 32.w,
          height: large ? 32 : 32.w,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.event_available_rounded,
            color: primaryColor,
            size: large ? 17 : 17.sp,
          ),
        ),
        SizedBox(width: large ? 8 : 8.w),
        Expanded(
          child: Text(
            'صلواتك اليوم',
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body(context).copyWith(
              color: textColor,
              fontSize: large ? 17 : 12.sp,
              fontWeight: FontWeight.w700,
              height: 1.05,
            ),
          ),
        ),
      ],
    );
  }
}
