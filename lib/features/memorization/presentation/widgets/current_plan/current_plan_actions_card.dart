import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';

class CurrentPlanActionsCard extends StatelessWidget {
  const CurrentPlanActionsCard({
    super.key,
    required this.planName,
    required this.onRescheduleTap,
    required this.onPauseTap,
    required this.onDeleteTap,
    this.isBusy = false,
  });

  final String planName;
  final VoidCallback onRescheduleTap;
  final VoidCallback onPauseTap;
  final VoidCallback onDeleteTap;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? colors.surface : const Color(0xFF18385F);
    final cardColor = isDark ? colors.secondary : Colors.white;
    final tileColor = isDark
        ? colors.surface.withOpacity(0.055)
        : const Color(0xFFFAFCFE);
    final borderColor = isDark
        ? colors.outline.withOpacity(0.12)
        : const Color(0xFFE7EDF5);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: borderColor, width: 0.8.w),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          SizedBox(width: 16.w),
          _CurrentPlanActionButton(
            text: 'تعديل',
            icon: Icons.edit_calendar_rounded,
            color: colors.primary,
            backgroundColor: tileColor,
            borderColor: borderColor,
            isEnabled: !isBusy,
            onTap: onRescheduleTap,
          ),
          SizedBox(width: 7.w),
          _CurrentPlanActionButton(
            text: 'إيقاف',
            icon: Icons.pause_rounded,
            color: colors.primary,
            backgroundColor: tileColor,
            borderColor: borderColor,
            isEnabled: !isBusy,
            onTap: onPauseTap,
          ),
          SizedBox(width: 7.w),
          _CurrentPlanActionButton(
            text: 'حذف',
            icon: Icons.delete_outline_rounded,
            color: Colors.redAccent,
            backgroundColor: tileColor,
            borderColor: borderColor,
            isEnabled: !isBusy,
            onTap: onDeleteTap,
          ),
        ],
      ),
    );
  }
}

class _CurrentPlanActionButton extends StatelessWidget {
  const _CurrentPlanActionButton({
    required this.text,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.borderColor,
    required this.isEnabled,
    required this.onTap,
  });

  final String text;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final Color borderColor;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isEnabled ? color : color.withOpacity(0.34);

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: isEnabled ? onTap : null,
        child: Container(
          height: 34.h,
          padding: EdgeInsets.symmetric(horizontal: 9.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: borderColor, width: 0.8.w),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: [
              Icon(icon, color: effectiveColor, size: 13.sp),
              SizedBox(width: 4.w),
              Text(
                text,
                textDirection: TextDirection.rtl,
                style: AppTextStyles.caption(context).copyWith(
                  color: effectiveColor,
                  fontSize: 8.8.sp,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
