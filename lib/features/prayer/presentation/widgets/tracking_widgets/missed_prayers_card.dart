import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class MissedPrayersCard extends StatelessWidget {
  final bool large;
  final List<String> missedPrayers;

  const MissedPrayersCard({
    super.key,
    this.large = false,
    required this.missedPrayers,
  });

  @override
  Widget build(BuildContext context) {
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
          color: Colors.orange.withOpacity(0.75),
          width: large ? 0.8 : 0.8.w,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'لم تُسجل بعد: ${missedPrayers.join('، ')}',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.35
),
            ),
          ),
          SizedBox(width: large ? 9 : 10.w),
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: large ? 16 : 18.sp,
          ),
        ],
      ),
    );
  }
}