import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';

class TinyQuranProgressCircle extends StatelessWidget {
  const TinyQuranProgressCircle({
    super.key,
    required this.progress,
    required this.percent,
  });

  final double progress;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final Color textColor = colors.surface;
    final double safeProgress = progress.clamp(0.0, 1.0).toDouble();

    return SizedBox(
      width: 44.w,
      height: 44.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 42.w,
            height: 42.w,
            child: CircularProgressIndicator(
              value: safeProgress,
              strokeWidth: 3.2.w,
              backgroundColor: textColor.withOpacity(0.10),
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
          Text(
            '${percent.clamp(0, 100)}%',
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption(context).copyWith(
              color: textColor,
              fontSize: 8.sp,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
