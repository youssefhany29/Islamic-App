import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/services/app_haptics.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
enum MasteryPrimaryButtonStyle {
  filled,
  outlinedOnPrimary,
}

class MasteryPrimaryButton extends StatelessWidget {
  const MasteryPrimaryButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
    this.style = MasteryPrimaryButtonStyle.filled,
    this.iconAfterText = true,
  });

  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final MasteryPrimaryButtonStyle style;

  /// true = النص ثم الأيقونة بعده.
  /// مناسب لزر "التالي".
  final bool iconAfterText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bool isOutlinedOnPrimary =
        style == MasteryPrimaryButtonStyle.outlinedOnPrimary;

    final Color backgroundColor = isOutlinedOnPrimary
        ? Colors.white.withOpacity(0.08)
        : theme.colorScheme.primary;

    final Color borderColor = isOutlinedOnPrimary
        ? Colors.white.withOpacity(0.72)
        : theme.colorScheme.primary;

    final Color shadowColor = isOutlinedOnPrimary
        ? Colors.white.withOpacity(0.06)
        : theme.colorScheme.primary.withOpacity(0.20);

    const Color foregroundColor = Colors.white;

    final List<Widget> content = iconAfterText
        ? [
      Text(
        text,
        textDirection: TextDirection.rtl,
        style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
          color: foregroundColor,
          height: 1.0
),
      ),
      SizedBox(width: 8.w),
      Icon(
        icon,
        color: foregroundColor,
        size: 18.sp,
      ),
    ]
        : [
      Icon(
        icon,
        color: foregroundColor,
        size: 18.sp,
      ),
      SizedBox(width: 8.w),
      Text(
        text,
        textDirection: TextDirection.rtl,
        style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
          color: foregroundColor,
          height: 1.0
),
      ),
    ];

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(17.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(17.r),
        onTap: () {
          AppHaptics.tap(context);
          onTap();
        },
        child: Container(
          width: double.infinity,
          height: 46.h,
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(17.r),
            border: Border.all(
              color: borderColor,
              width: isOutlinedOnPrimary ? 1.15 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 12,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: TextDirection.rtl,
            children: content,
          ),
        ),
      ),
    );
  }
}