import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class TrackingDetailsButton extends StatelessWidget {
  final bool large;
  final VoidCallback onTap;

  const TrackingDetailsButton({
    super.key,
    this.large = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xff171B26),
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: () {
          AppHaptics.tap(context);
          onTap();
        },
        child: SizedBox(
          width: double.infinity,
          height: large ? 34 : 38.h,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                Icons.analytics_rounded,
                color: Colors.white,
                size: large ? 15 : 17.sp,
              ),
              SizedBox(width: large ? 8 : 8.w),
              Text(
                'عرض تفاصيل صلاتي',
                style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w700,
                  color: Colors.white
),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
