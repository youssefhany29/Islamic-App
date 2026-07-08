import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/analytics/analytics_ui.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/analytics/memorization_analytics_data.dart';

class AnalyticsSessionQualityBlock extends StatelessWidget {
  const AnalyticsSessionQualityBlock({
    super.key,
    required this.quality,
  });

  final AnalyticsSessionQuality quality;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
      decoration: AnalyticsDecorations.innerCard(context, radius: 18.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _BlockHeader(
            title: 'جودة الجلسات',
            icon: Icons.bar_chart_rounded,
            color: AnalyticsColors.blue,
          ),
          SizedBox(height: 12.h),
          if (quality.total == 0)
            _EmptyLine(text: 'لا توجد جلسات في هذه الفترة بعد')
          else ...[
            _QualityRow(
              label: 'سهل',
              value: quality.easy,
              total: quality.total,
              color: AnalyticsColors.green,
            ),
            SizedBox(height: 8.h),
            _QualityRow(
              label: 'جيد',
              value: quality.good,
              total: quality.total,
              color: AnalyticsColors.blue,
            ),
            SizedBox(height: 8.h),
            _QualityRow(
              label: 'صعب',
              value: quality.hard,
              total: quality.total,
              color: AnalyticsColors.orange,
            ),
            SizedBox(height: 8.h),
            _QualityRow(
              label: 'نسيان',
              value: quality.forgot,
              total: quality.total,
              color: AnalyticsColors.red,
            ),
          ],
        ],
      ),
    );
  }
}

class _QualityRow extends StatelessWidget {
  const _QualityRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  final String label;
  final int value;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : value / total;

    return Row(
      textDirection: TextDirection.rtl,
      children: [
        SizedBox(
          width: 42.w,
          child: Text(
            label,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(context).copyWith(
              color: AnalyticsThemeColors.textSecondary(context, 0.72),
              fontSize: 8.8.sp,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99.r),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0).toDouble(),
              minHeight: 5.h,
              backgroundColor: AnalyticsThemeColors.textSecondary(context, 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        SizedBox(
          width: 26.w,
          child: Text(
            '$value',
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.left,
            style: AppTextStyles.caption(context).copyWith(
              color: AnalyticsThemeColors.textPrimary(context),
              fontSize: 9.sp,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _BlockHeader extends StatelessWidget {
  const _BlockHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Icon(icon, color: color, size: 17.sp),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            title,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: AppTextStyles.caption(context).copyWith(
              color: AnalyticsThemeColors.textPrimary(context),
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      style: AppTextStyles.caption(context).copyWith(
        color: AnalyticsThemeColors.textSecondary(context, 0.46),
        fontSize: 8.8.sp,
        fontWeight: FontWeight.w700,
        height: 1.4,
      ),
    );
  }
}
