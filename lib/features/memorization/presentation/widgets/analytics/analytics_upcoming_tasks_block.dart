import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/analytics/analytics_ui.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/analytics/memorization_analytics_data.dart';

class AnalyticsUpcomingTasksBlock extends StatelessWidget {
  const AnalyticsUpcomingTasksBlock({
    super.key,
    required this.items,
  });

  final List<AnalyticsUpcomingItem> items;

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
                Icons.event_available_rounded,
                color: AnalyticsColors.blue,
                size: 17.sp,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  'القادم في الخطة',
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
          SizedBox(height: 10.h),
          if (items.isEmpty)
            Text(
              'لا توجد مراجعات إنقاذ أو اختبارات قريبة حاليًا.',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: AppTextStyles.caption(context).copyWith(
                color: AnalyticsThemeColors.textSecondary(context, 0.48),
                fontSize: 8.8.sp,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            )
          else
            ...items.map(
              (item) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: _UpcomingItemTile(item: item),
              ),
            ),
        ],
      ),
    );
  }
}

class _UpcomingItemTile extends StatelessWidget {
  const _UpcomingItemTile({required this.item});

  final AnalyticsUpcomingItem item;

  @override
  Widget build(BuildContext context) {
    final bool isTest = item.type == AnalyticsUpcomingType.test;
    final Color color = isTest ? AnalyticsColors.purple : AnalyticsColors.orange;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 30.w,
            height: 30.w,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              isTest ? Icons.fact_check_rounded : Icons.healing_rounded,
              color: color,
              size: 16.sp,
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
                  maxLines: 2,
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
          Text(
            item.dateLabel,
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
        ],
      ),
    );
  }
}
