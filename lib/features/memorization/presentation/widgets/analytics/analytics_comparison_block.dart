import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/analytics/analytics_ui.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/analytics/memorization_analytics_data.dart';

class AnalyticsComparisonBlock extends StatelessWidget {
  const AnalyticsComparisonBlock({
    super.key,
    required this.comparison,
    required this.period,
  });

  final AnalyticsComparison comparison;
  final MemorizationAnalyticsPeriod period;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
      decoration: AnalyticsDecorations.innerCard(context, radius: 18.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                Icons.compare_arrows_rounded,
                color: AnalyticsColors.purple,
                size: 17.sp,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  'مقارنة بالفترة السابقة',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    color: AnalyticsThemeColors.textPrimary(context),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 11.h),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: _ComparisonMiniBox(
                  title: 'الإتقان',
                  value: _signedPercent(comparison.masteryDelta),
                  isGood: comparison.masteryDelta >= 0,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _ComparisonMiniBox(
                  title: 'الجلسات',
                  value: _signedNumber(comparison.sessionsDelta),
                  isGood: comparison.sessionsDelta >= 0,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _ComparisonMiniBox(
                  title: 'النسيان',
                  value: _signedNumber(comparison.forgotDelta),
                  isGood: comparison.forgotDelta <= 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _signedPercent(int value) {
    if (value == 0) return '0%';
    return value > 0 ? '+$value%' : '$value%';
  }

  String _signedNumber(int value) {
    if (value == 0) return '0';
    return value > 0 ? '+$value' : '$value';
  }
}

class _ComparisonMiniBox extends StatelessWidget {
  const _ComparisonMiniBox({
    required this.title,
    required this.value,
    required this.isGood,
  });

  final String title;
  final String value;
  final bool isGood;

  @override
  Widget build(BuildContext context) {
    final color = isGood ? AnalyticsColors.green : AnalyticsColors.red;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body(context).copyWith(
              color: color,
              fontSize: 13.sp,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            title,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(context).copyWith(
              color: AnalyticsThemeColors.textSecondary(context, 0.58),
              fontSize: 8.sp,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
