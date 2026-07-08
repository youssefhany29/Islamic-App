import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/analytics/analytics_ui.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/analytics/memorization_analytics_data.dart';

class AnalyticsTestResultsBlock extends StatelessWidget {
  const AnalyticsTestResultsBlock({
    super.key,
    required this.results,
  });

  final AnalyticsTestResults results;

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
                Icons.fact_check_rounded,
                color: AnalyticsColors.purple,
                size: 17.sp,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  'نتائج الاختبارات',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    color: AnalyticsThemeColors.textPrimary(context),
                    fontSize: 10.8.sp,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 11.h),
          if (!results.hasResults)
            _EmptyTestsLine()
          else ...[
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: _TestMiniBox(
                    title: 'متوسط النتيجة',
                    value: '${results.averageScore}%',
                    color: AnalyticsColors.purple,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _TestMiniBox(
                    title: 'اختبارات قوية',
                    value: '${results.strongTests}',
                    color: AnalyticsColors.green,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _TestMiniBox(
                    title: 'تحتاج تثبيت',
                    value: '${results.needsReviewTests}',
                    color: AnalyticsColors.orange,
                  ),
                ),
              ],
            ),
            if (results.latestItems.isNotEmpty) ...[
              SizedBox(height: 10.h),
              Column(
                children: results.latestItems.map((item) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 7.h),
                    child: _TestResultTile(item: item),
                  );
                }).toList(growable: false),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _TestMiniBox extends StatelessWidget {
  const _TestMiniBox({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

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
              color: color,
              fontSize: 12.sp,
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
              color: AnalyticsThemeColors.textSecondary(context, 0.54),
              fontSize: 7.5.sp,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _TestResultTile extends StatelessWidget {
  const _TestResultTile({required this.item});

  final AnalyticsTestResultItem item;

  Color _ratingColor() {
    switch (item.rating) {
      case 'easy':
        return AnalyticsColors.green;
      case 'good':
        return AnalyticsColors.blue;
      case 'hard':
        return AnalyticsColors.orange;
      case 'forgot':
        return AnalyticsColors.red;
      default:
        return AnalyticsColors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _ratingColor();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
      decoration: AnalyticsDecorations.miniCard(context, radius: 15.r),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Center(
              child: Text(
                item.scoreLabel,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  color: color,
                  fontSize: 8.sp,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    color: AnalyticsThemeColors.textPrimary(context),
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  item.subtitle,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    color: AnalyticsThemeColors.textSecondary(context, 0.56),
                    fontSize: 7.8.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.ratingLabel,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.left,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  color: color,
                  fontSize: 8.2.sp,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              SizedBox(height: 5.h),
              Text(
                item.dateLabel,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.left,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  color: AnalyticsThemeColors.textSecondary(context, 0.46),
                  fontSize: 7.4.sp,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyTestsLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 10.h),
      decoration: AnalyticsDecorations.miniCard(context, radius: 15.r),
      child: Text(
        'لسه مفيش نتائج اختبارات في الفترة المختارة.',
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        style: AppTextStyles.caption(context).copyWith(
          color: AnalyticsThemeColors.textSecondary(context, 0.62),
          fontSize: 8.7.sp,
          fontWeight: FontWeight.w800,
          height: 1.35,
        ),
      ),
    );
  }
}
