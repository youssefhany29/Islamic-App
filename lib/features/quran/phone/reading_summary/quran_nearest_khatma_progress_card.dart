import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'tiny_quran_progress_circle.dart';

class QuranNearestKhatmaProgressCard extends StatelessWidget {
  const QuranNearestKhatmaProgressCard({
    super.key,
    required this.progress,
    required this.percent,
  });

  final double progress;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = colors.surface;
    final Color cardColor = isDark ? colors.secondary : Colors.white;
    final String subtitle = percent <= 0
        ? 'ابدأ أول خطوة، وسيظهر تقدم الختمة هنا'
        : 'أنت على الطريق الصحيح، استمر!';

    return Container(
      height: 68.h,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color: textColor.withOpacity(isDark ? 0.08 : 0.055),
          width: 0.9.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.12 : 0.045),
            blurRadius: 15.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Opacity(
              opacity: isDark ? 0.36 : 0.44,
              child: Image.asset(
                'assets/quraan/al-aqsa-mosque.png',
                width: 60.w,
                height: 48.h,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.mosque_rounded,
                  size: 34.sp,
                  color: colors.primary.withOpacity(0.38),
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'تقدم أقرب ختمة',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body(context).copyWith(
                      color: textColor,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.05,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(context).copyWith(
                      color: textColor.withOpacity(0.56),
                      fontSize: 7.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.18,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            TinyQuranProgressCircle(
              progress: progress,
              percent: percent,
            ),
          ],
        ),
      ),
    );
  }
}
