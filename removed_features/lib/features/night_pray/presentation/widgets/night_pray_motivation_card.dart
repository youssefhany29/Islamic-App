import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class NightPrayMotivationCard extends StatelessWidget {
  final String message;

  const NightPrayMotivationCard({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
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
          color: Colors.white.withOpacity(0.12),
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
                color: Colors.white.withOpacity(0.8),
                height: 1.35
),
            ),
          ),
          SizedBox(width: 10.w),
          Icon(
            Icons.favorite_rounded,
            color: const Color(0xff21C58E),
            size: 18.sp,
          ),
        ],
      ),
    );
  }
}
