import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/analytics/analytics_ui.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/analytics/memorization_analytics_data.dart';

class AnalyticsCommitmentBlock extends StatelessWidget {
  const AnalyticsCommitmentBlock({
    super.key,
    required this.commitment,
  });

  final AnalyticsCommitment commitment;

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
                Icons.local_fire_department_rounded,
                color: AnalyticsColors.orange,
                size: 17.sp,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  'الالتزام والاستمرارية',
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
                child: _CommitmentMiniBox(
                  title: 'أيام نشطة',
                  value: '${commitment.activeDays}/${commitment.periodDays}',
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _CommitmentMiniBox(
                  title: 'متوسط الجلسة',
                  value: commitment.averageMinutes <= 0
                      ? '—'
                      : '${commitment.averageMinutes} د',
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _CommitmentMiniBox(
                  title: 'آخر جلسة',
                  value: commitment.lastSessionLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommitmentMiniBox extends StatelessWidget {
  const _CommitmentMiniBox({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 9.h),
      decoration: AnalyticsDecorations.miniCard(context, radius: 15.r),
      child: Column(
        children: [
          Text(
            value,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body(context).copyWith(
              color: AnalyticsThemeColors.textPrimary(context),
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
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
              color: AnalyticsThemeColors.textSecondary(context, 0.50),
              fontSize: 6.8.sp,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
