import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/features/prayer/data/services/prayer_tracking_storage.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class WeeklyBadgeCard extends StatelessWidget {
  final bool large;
  final List<PrayerWeeklyDay> weeklyHistory;

  const WeeklyBadgeCard({
    super.key,
    this.large = false,
    required this.weeklyHistory,
  });

  @override
  Widget build(BuildContext context) {
    final completedDays = weeklyHistory.where((day) => day.completed).length;

    final String message = completedDays >= 7
        ? 'أسبوع كامل مكتمل، ما شاء الله ✨'
        : completedDays >= 4
        ? 'أسبوعك جيد، اقتربت من أسبوع كامل'
        : 'اجعل هذا الأسبوع بداية جديدة';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: large ? 10 : 12.w,
        vertical: large ? 8 : 10.h,
      ),
      decoration: BoxDecoration(
        color: const Color(0xff171B26),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: completedDays >= 7
              ? const Color(0xff21C58E)
              : Colors.white.withOpacity(0.12),
          width: large ? 0.8 : 0.8.w,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.82),
                height: 1.35
),
            ),
          ),
          SizedBox(width: large ? 9 : 10.w),
          Icon(
            Icons.workspace_premium_rounded,
            color: completedDays >= 7
                ? const Color(0xffffb300)
                : Colors.white70,
            size: large ? 16 : 18.sp,
          ),
        ],
      ),
    );
  }
}