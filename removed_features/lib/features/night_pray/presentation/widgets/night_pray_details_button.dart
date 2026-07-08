import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class NightPrayDetailsButton extends StatelessWidget {
  final VoidCallback onTap;

  const NightPrayDetailsButton({
    super.key,
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
          height: 38.h,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                Icons.analytics_rounded,
                color: Colors.white,
                size: 17.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'عرض تفاصيل قيام الليل',
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
