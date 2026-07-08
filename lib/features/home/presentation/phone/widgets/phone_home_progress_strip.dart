import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/shared/widgets/common_components/app_layout_constants.dart';

class PhoneHomeProgressStrip extends StatelessWidget {
  const PhoneHomeProgressStrip({
    super.key,
    this.streakDays = 0,
    this.quranPages = 0,
    this.completedAzkar = 0,
    this.achievements = 0,
  });

  final int streakDays;
  final int quranPages;
  final int completedAzkar;
  final int achievements;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: AppLayoutConstants.mainCardWidth,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isDark ? colors.secondary : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.06),
              width: 0.8.w,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _ProgressItem(
                  icon: '🔥',
                  value: streakDays,
                  label: 'يوم',
                ),
              ),
              Expanded(
                child: _ProgressItem(
                  icon: '📖',
                  value: quranPages,
                  label: 'صفحة',
                ),
              ),
              Expanded(
                child: _ProgressItem(
                  icon: '🤲',
                  value: completedAzkar,
                  label: 'ذكر',
                ),
              ),
              Expanded(
                child: _ProgressItem(
                  icon: '⭐',
                  value: achievements,
                  label: 'إنجاز',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressItem extends StatelessWidget {
  const _ProgressItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final String icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.surface;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          icon,
          style: TextStyle(fontSize: 15.sp, height: 1),
        ),
        SizedBox(height: 3.h),
        Text(
          '$value',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption(context).copyWith(
            fontWeight: FontWeight.w900,
            color: textColor,
            height: 1,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption(context).copyWith(
            fontSize: 9.sp,
            fontWeight: FontWeight.w600,
            color: textColor.withOpacity(0.58),
            height: 1,
          ),
        ),
      ],
    );
  }
}