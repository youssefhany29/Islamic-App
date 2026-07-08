import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';

class PrayerQuickActionTile extends StatelessWidget {
  const PrayerQuickActionTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.large = false,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = colors.surface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22.r),
        onTap: onTap,
        child: Container(
          height: large ? 118 : 88.h,
          padding: EdgeInsets.symmetric(
            horizontal: large ? 14 : 8.w,
            vertical: large ? 14 : 10.h,
          ),
          decoration: BoxDecoration(
            color: isDark ? colors.secondary : Colors.white,
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(
              color: textColor.withOpacity(isDark ? 0.08 : 0.055),
              width: 0.8.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.14 : 0.045),
                blurRadius: large ? 20 : 15.r,
                offset: Offset(0, large ? 8 : 7.h),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: large ? 48 : 34.w,
                height: large ? 48 : 34.w,
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(isDark ? 0.15 : 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: colors.primary,
                  size: large ? 25 : 18.sp,
                ),
              ),
              SizedBox(height: large ? 10 : 7.h),
              SizedBox(
                width: double.infinity,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    color: textColor,
                    fontSize: large ? 16 : 8.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
