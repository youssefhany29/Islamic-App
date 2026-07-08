import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../hiding/quran_hide_mode.dart';
import '../theme/quran_reader_theme.dart';

class QpcFloatingHideButton extends StatelessWidget {
  const QpcFloatingHideButton({
    super.key,
    required this.visible,
    required this.hideMode,
    required this.readerTheme,
    required this.onTap,
  });

  final bool visible;
  final QuranHideMode hideMode;
  final QuranReaderTheme readerTheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool active = hideMode != QuranHideMode.visible;

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 160),
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: onTap,
          child: Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: active
                  ? readerTheme.selectedWordTextColor
                  : readerTheme.controlsBackgroundColor,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: active
                    ? readerTheme.selectedWordTextColor
                    : readerTheme.dividerColor,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.14),
                  blurRadius: 16,
                  offset: Offset(0, 6.h),
                ),
              ],
            ),
            child: Icon(
              active ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: active
                  ? readerTheme.pageBackground
                  : readerTheme.controlsTextColor,
              size: 16.sp,
            ),
          ),
        ),
      ),
    );
  }
}