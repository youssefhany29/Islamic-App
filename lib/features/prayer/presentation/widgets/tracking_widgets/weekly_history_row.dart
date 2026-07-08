import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/features/prayer/data/services/prayer_tracking_storage.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class WeeklyHistoryRow extends StatelessWidget {
  final bool large;
  final List<PrayerWeeklyDay> weeklyHistory;

  const WeeklyHistoryRow({
    super.key,
    this.large = false,
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
        horizontal: large ? 7 : 8.w,
        vertical: large ? 8 : 10.h,
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
              'آخر ٧ أيام',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w700,
                color: Colors.white
),
            ),
          ),

          SizedBox(height: large ? 7 : 8.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: weeklyHistory.map((day) {
              return Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: large ? 22 : 23.w,
                    height: large ? 22 : 23.w,
                    decoration: BoxDecoration(
                      color: day.completed
                          ? const Color(0xff21C58E)
                          : day.checkedCount > 0
                          ? Colors.amber
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
                      size: large ? 14 : 15.sp,
                    )
                        : day.checkedCount > 0
                        ? Center(
                      child: Text(
                        '${day.checkedCount}',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
                          color: Colors.white
),
                      ),
                    )
                        : null,
                  ),

                  SizedBox(height: large ? 4 : 4.h),

                  Text(
                    day.dayName,
                    textDirection: TextDirection.rtl,
                    style: AppTextStyles.caption(context).copyWith(
fontWeight:
                      day.isToday ? FontWeight.w800 : FontWeight.w500,
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