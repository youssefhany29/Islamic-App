import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class VideoSearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const VideoSearchBox({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor =
    isDark ? const Color(0xff222837) : const Color(0xffDEE9EF);

    final textColor = isDark ? Colors.white : Colors.black87;
    final iconColor = isDark ? Colors.white70 : Colors.black54;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final hasText = value.text.trim().isNotEmpty;

        return Container(
          height: 36.h,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(22.r),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w600,
                color: textColor
),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'ابحث',
                hintTextDirection: TextDirection.rtl,
                hintStyle: AppTextStyles.caption(context).copyWith(
color: textColor.withOpacity(0.45)
),
                suffixIcon: Icon(
                  Icons.search_rounded,
                  size: 18.sp,
                  color: iconColor,
                ),
                suffixIconConstraints: BoxConstraints(
                  minWidth: 28.w,
                  minHeight: 24.h,
                ),
                prefixIcon: hasText
                    ? GestureDetector(
                  onTap: () {
                    AppHaptics.tap(context);
                    onClear();
                  },
                  child: Icon(
                    Icons.close_rounded,
                    size: 18.sp,
                    color: iconColor,
                  ),
                )
                    : null,
                prefixIconConstraints: BoxConstraints(
                  minWidth: 26.w,
                  minHeight: 24.h,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}