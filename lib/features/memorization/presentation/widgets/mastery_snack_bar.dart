import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class MasterySnackBar {
  const MasterySnackBar._();

  static void show(
      BuildContext context, {
        required String message,
      }) {
    final theme = Theme.of(context);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
        margin: EdgeInsets.symmetric(
          horizontal: 18.w,
          vertical: 14.h,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        content: Text(
          message,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
            color: Colors.white
),
        ),
        duration: const Duration(milliseconds: 1300),
      ),
    );
  }
}
