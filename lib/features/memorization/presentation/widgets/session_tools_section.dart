import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/session_tool_tile.dart';

class SessionToolsSection extends StatelessWidget {
  const SessionToolsSection({
    super.key,
    required this.onOpenReviewSchedule,
    required this.onOpenAnalytics,
    required this.onOpenCurrentPlan,
    required this.onOpenCompletedPlans,
    required this.onCreatePlan,
    required this.onOpenManualTest,
  });

  final VoidCallback onOpenReviewSchedule;
  final VoidCallback onOpenAnalytics;
  final VoidCallback onOpenCurrentPlan;
  final VoidCallback onOpenCompletedPlans;
  final VoidCallback onCreatePlan;
  final VoidCallback onOpenManualTest;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = colors.surface;
    final Color cardColor = isDark ? colors.secondary : Colors.white;
    final Color borderColor = textColor.withOpacity(isDark ? 0.08 : 0.06);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SessionToolsHeader(
              title: 'أدوات الجلسة',
              subtitle: 'كل ما تحتاجه لتنظيم الحفظ في مكان واحد',
              textColor: textColor,
              primaryColor: colors.primary,
            ),
            SizedBox(height: 12.h),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: SessionToolTile(
                    title: 'إنشاء خطة',
                    icon: Icons.add_task_rounded,
                    textColor: textColor,
                    primaryColor: colors.primary,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    onTap: onCreatePlan,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: SessionToolTile(
                    title: 'التحليلات',
                    icon: Icons.insights_rounded,
                    textColor: textColor,
                    primaryColor: colors.primary,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    onTap: onOpenAnalytics,
                  ),
                ),
              ],
            ),
            SizedBox(height: 9.h),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: SessionToolTile(
                    title: 'الخطة الحالية',
                    icon: Icons.route_rounded,
                    textColor: textColor,
                    primaryColor: colors.primary,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    onTap: onOpenCurrentPlan,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: SessionToolTile(
                    title: 'جدول المراجعة',
                    icon: Icons.calendar_month_rounded,
                    textColor: textColor,
                    primaryColor: colors.primary,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    onTap: onOpenReviewSchedule,
                  ),
                ),
              ],
            ),
            SizedBox(height: 9.h),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: SessionToolTile(
                    title: 'اختبرني',
                    icon: Icons.fact_check_rounded,
                    textColor: textColor,
                    primaryColor: colors.primary,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    onTap: onOpenManualTest,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: SessionToolTile(
                    title: 'الخطط المكتملة',
                    icon: Icons.workspace_premium_rounded,
                    textColor: textColor,
                    primaryColor: colors.primary,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    onTap: onOpenCompletedPlans,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionToolsHeader extends StatelessWidget {
  const _SessionToolsHeader({
    required this.title,
    required this.subtitle,
    required this.textColor,
    required this.primaryColor,
  });

  final String title;
  final String subtitle;
  final Color textColor;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 38.w,
          height: 38.w,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.work_rounded, size: 18.sp, color: primaryColor),
        ),
        SizedBox(width: 9.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body(context).copyWith(
                  color: textColor,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                subtitle,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  color: textColor.withOpacity(0.56),
                  fontSize: 8.6.sp,
                  fontWeight: FontWeight.w500,
                  height: 1.05,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
