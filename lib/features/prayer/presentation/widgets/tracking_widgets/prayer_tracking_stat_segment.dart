import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/prayer/presentation/widgets/tracking_widgets/tiny_prayer_progress_circle.dart';

class PrayerTrackingNumberStatSegment extends StatelessWidget {
  const PrayerTrackingNumberStatSegment({
    super.key,
    required this.label,
    required this.value,
    required this.suffix,
    required this.textColor,
    required this.primaryColor,
    this.large = false,
  });

  final String label;
  final int value;
  final String suffix;
  final Color textColor;
  final Color primaryColor;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption(context).copyWith(
            color: textColor.withOpacity(0.68),
            fontSize: large ? 12 : 8.7.sp,
            fontWeight: FontWeight.w600,
            height: 1.05,
          ),
        ),
        SizedBox(height: large ? 4 : 3.h),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value.toString(),
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            style: AppTextStyles.body(context).copyWith(
              color: primaryColor,
              fontSize: large ? 21 : 15.8.sp,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
        SizedBox(height: large ? 3 : 2.h),
        Text(
          suffix,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption(context).copyWith(
            color: textColor.withOpacity(0.58),
            fontSize: large ? 11 : 8.sp,
            fontWeight: FontWeight.w600,
            height: 1.05,
          ),
        ),
      ],
    );
  }
}

class PrayerTrackingCompletionStatSegment extends StatelessWidget {
  const PrayerTrackingCompletionStatSegment({
    super.key,
    required this.percent,
    required this.progress,
    required this.textColor,
    required this.primaryColor,
    this.large = false,
  });

  final int percent;
  final double progress;
  final Color textColor;
  final Color primaryColor;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'اكتمال',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  color: textColor.withOpacity(0.68),
                  fontSize: large ? 12 : 8.7.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.05,
                ),
              ),
              SizedBox(height: large ? 4 : 3.h),
              Text(
                'اليوم',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  color: textColor.withOpacity(0.58),
                  fontSize: large ? 11 : 8.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.05,
                ),
              ),
              SizedBox(height: large ? 4 : 3.h),
              Text(
                'حتى الآن',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  color: textColor.withOpacity(0.58),
                  fontSize: large ? 11 : 8.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.05,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: large ? 10 : 7.w),
        TinyPrayerProgressCircle(
          progress: progress,
          percent: percent,
          color: primaryColor,
          large: large,
        ),
      ],
    );
  }
}
