import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class MasteryStatBox extends StatelessWidget {
  const MasteryStatBox({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.surface;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 7.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.055),
        borderRadius: BorderRadius.circular(17.r),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.14),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 20.sp,
          ),
          SizedBox(height: 5.h),
          Text(
            value,
            style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
              color: textColor,
              height: 1
),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w700,
              color: textColor.withOpacity(0.56)
),
          ),
        ],
      ),
    );
  }
}
