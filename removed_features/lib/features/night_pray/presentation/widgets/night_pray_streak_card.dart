import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class NightPrayStreakCard extends StatelessWidget {
  final int streak;
  final int bestStreak;
  final bool completedToday;

  const NightPrayStreakCard({
    super.key,
    required this.streak,
    required this.bestStreak,
    required this.completedToday,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniNightStatCard(
            title: 'السلسلة الحالية',
            value: '$streak ليلة',
            icon: Icons.local_fire_department_rounded,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _MiniNightStatCard(
            title: 'أفضل سلسلة',
            value: '$bestStreak ليلة',
            icon: Icons.workspace_premium_rounded,
          ),
        ),
      ],
    );
  }
}

class _MiniNightStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MiniNightStatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10.w,
        vertical: 10.h,
      ),
      decoration: BoxDecoration(
        color: const Color(0xff171B26),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Icon(
            icon,
            color: const Color(0xffffb300),
            size: 18.sp,
          ),
          SizedBox(height: 6.h),
          Text(
            value,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
              color: Colors.white
),
          ),
          SizedBox(height: 2.h),
          Text(
            title,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.68)
),
          ),
        ],
      ),
    );
  }
}
