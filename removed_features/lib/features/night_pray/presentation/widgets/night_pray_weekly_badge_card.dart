import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/features/night_pray/data/services/night_pray_tracking_storage.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class NightPrayWeeklyBadgeCard extends StatelessWidget {
  final List<NightPrayWeeklyDay> weeklyHistory;

  const NightPrayWeeklyBadgeCard({
    super.key,
    required this.weeklyHistory,
  });

  @override
  Widget build(BuildContext context) {
    final completedNights = weeklyHistory.where((day) => day.completed).length;

    final message = completedNights >= 7
        ? 'أسبوع كامل من قيام الليل، ما شاء الله ✨'
        : completedNights >= 4
            ? 'أسبوعك جميل، اقتربت من أسبوع كامل'
            : 'ابدأ الليلة ولو بركعتين خفيفتين';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 10.h,
      ),
      decoration: BoxDecoration(
        color: const Color(0xff171B26),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: completedNights >= 7
              ? const Color(0xff21C58E)
              : Colors.white.withOpacity(0.12),
          width: 0.8.w,
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
          SizedBox(width: 10.w),
          Icon(
            Icons.workspace_premium_rounded,
            color: completedNights >= 7 ? const Color(0xffffb300) : Colors.white70,
            size: 18.sp,
          ),
        ],
      ),
    );
  }
}
