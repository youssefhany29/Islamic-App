import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class MasteryBaseCard extends StatelessWidget {
  const MasteryBaseCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String badgeText;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = theme.colorScheme.secondary;
    final textColor = theme.colorScheme.surface;
    final subTextColor = theme.colorScheme.surface.withOpacity(0.62);
    final accentColor = theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(isDark ? 0.18 : 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.16 : 0.055),
            blurRadius: 16,
            offset: Offset(0, 7.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 9.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
                        color: textColor,
                        height: 1.25
),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      subtitle,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w600,
                        color: subTextColor,
                        height: 1.45
),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(30.r),
                ),
                child: Text(
                  badgeText,
                  textDirection: TextDirection.rtl,
                  style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
                    color: accentColor
),
                ),
              ),
            ],
          ),
          SizedBox(height: 13.h),
          child,
        ],
      ),
    );
  }
}
