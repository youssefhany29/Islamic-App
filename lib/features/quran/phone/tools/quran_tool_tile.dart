import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/services/app_haptics.dart';
import 'package:islamic_app/core/typography/app_text_styles.dart';

class QuranToolTile extends StatelessWidget {
  const QuranToolTile({
    super.key,
    required this.title,
    required this.icon,
    required this.textColor,
    required this.primaryColor,
    required this.cardColor,
    required this.borderColor,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color textColor;
  final Color primaryColor;
  final Color cardColor;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(15.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(15.r),
        onTap: () {
          AppHaptics.tap(context);
          onTap();
        },
        child: Container(
          height: 48.h,
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(
              color: borderColor,
              width: 0.9.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.035),
                blurRadius: 11.r,
                offset: Offset(0, 5.h),
              ),
            ],
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 20.w,
                height: 20.w,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 10.sp,
                  color: primaryColor,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  title,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    color: textColor,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ),
              SizedBox(width: 5.w),
              Icon(
                Icons.chevron_right_rounded,
                size: 15.sp,
                color: primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
