import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class NightPrayProgressCard extends StatelessWidget {
  final bool completedToday;
  final int completedCount;
  final int totalCount;
  final double progress;

  const NightPrayProgressCard({
    super.key,
    required this.completedToday,
    required this.completedCount,
    required this.totalCount,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).round();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 11.h,
      ),
      decoration: BoxDecoration(
        color: const Color(0xff171B26),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (completedToday)
            Text(
              'ما شاء الله، أتممت قيام الليلة 🌙',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.35
),
            )
          else
            Row(
              children: [
                Text(
                  'قيام الليلة',
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.35
),
                ),
                const Spacer(),
                Text(
                  '$completedCount / $totalCount  •  $percentage%',
                  textDirection: TextDirection.ltr,
                  style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.35
),
                ),
              ],
            ),
          SizedBox(height: 9.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7.h,
              backgroundColor: Colors.white.withOpacity(0.16),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xff21C58E)),
            ),
          ),
        ],
      ),
    );
  }
}
