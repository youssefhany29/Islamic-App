import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/features/night_pray/data/services/night_pray_tracking_storage.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class NightPrayWeeklyHistoryRow extends StatelessWidget {
  final List<NightPrayWeeklyDay> weeklyHistory;

  const NightPrayWeeklyHistoryRow({
    super.key,
    required this.weeklyHistory,
  });

  @override
  Widget build(BuildContext context) {
    if (weeklyHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 8.w,
        vertical: 10.h,
      ),
      decoration: BoxDecoration(
        color: const Color(0xff171B26),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'آخر ٧ ليالي',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w700,
                color: Colors.white
),
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: weeklyHistory.map((day) {
              return Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 23.w,
                    height: 23.w,
                    decoration: BoxDecoration(
                      color: day.completed
                          ? const Color(0xff21C58E)
                          : Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(7.r),
                      border: Border.all(
                        color: day.isToday
                            ? Colors.white
                            : Colors.white.withOpacity(0.18),
                        width: day.isToday ? 1.2.w : 0.6.w,
                      ),
                    ),
                    child: day.completed
                        ? Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 15.sp,
                          )
                        : null,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    day.dayName,
                    textDirection: TextDirection.rtl,
                    style: AppTextStyles.caption(context).copyWith(
fontWeight: day.isToday ? FontWeight.w800 : FontWeight.w500,
                      color: Colors.white.withOpacity(0.82)
),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
