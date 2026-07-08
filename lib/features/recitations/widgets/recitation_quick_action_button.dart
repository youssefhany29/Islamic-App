import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class RecitationQuickActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool muted;

  const RecitationQuickActionButton({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Material(
      color: muted ? primary.withOpacity(0.58) : primary,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Container(
          height: 50.h,
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18.sp),
              SizedBox(height: 3.h),
              Text(
                title,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
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
