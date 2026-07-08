import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/analytics/analytics_ui.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/analytics/memorization_analytics_data.dart';

class AnalyticsSmartSummaryBlock extends StatelessWidget {
  const AnalyticsSmartSummaryBlock({
    super.key,
    required this.summary,
  });

  final AnalyticsSmartSummary summary;

  @override
  Widget build(BuildContext context) {
    final _SummaryToneVisual visual = _SummaryToneVisual.fromTone(context, summary.tone);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
      decoration: BoxDecoration(
        color: visual.backgroundColor,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: visual.color.withOpacity(0.10),
          width: 0.8.w,
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: visual.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(
              visual.icon,
              color: visual.color,
              size: 19.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  summary.title,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    color: AnalyticsThemeColors.textPrimary(context),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  summary.subtitle,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    color: AnalyticsThemeColors.textSecondary(context, 0.60),
                    fontSize: 8.8.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryToneVisual {
  const _SummaryToneVisual({
    required this.color,
    required this.backgroundColor,
    required this.icon,
  });

  final Color color;
  final Color backgroundColor;
  final IconData icon;

  factory _SummaryToneVisual.fromTone(BuildContext context, AnalyticsSummaryTone tone) {
    switch (tone) {
      case AnalyticsSummaryTone.success:
        return _SummaryToneVisual(
          color: AnalyticsColors.green,
          backgroundColor: AnalyticsThemeColors.softTone(
            context,
            AnalyticsColors.softGreen,
            AnalyticsColors.green,
          ),
          icon: Icons.verified_rounded,
        );
      case AnalyticsSummaryTone.warning:
        return _SummaryToneVisual(
          color: AnalyticsColors.orange,
          backgroundColor: AnalyticsThemeColors.softTone(
            context,
            AnalyticsColors.softOrange,
            AnalyticsColors.orange,
          ),
          icon: Icons.auto_awesome_rounded,
        );
      case AnalyticsSummaryTone.neutral:
        return _SummaryToneVisual(
          color: AnalyticsColors.blue,
          backgroundColor: AnalyticsThemeColors.softTone(
            context,
            AnalyticsColors.softBlue,
            AnalyticsColors.blue,
          ),
          icon: Icons.lightbulb_rounded,
        );
    }
  }
}
