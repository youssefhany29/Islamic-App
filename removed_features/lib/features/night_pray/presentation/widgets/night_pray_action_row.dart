import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class NightPrayActionRow extends StatelessWidget {
  final String text;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  const NightPrayActionRow({
    super.key,
    required this.text,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: enabled
            ? () {
          AppHaptics.tap(context);
          onChanged(!value);
        }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 38.h,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: value
                ? Colors.white.withOpacity(0.16)
                : enabled
                ? const Color(0xff171B26)
                : Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: value
                  ? const Color(0xff21C58E)
                  : enabled
                  ? Colors.white24
                  : Colors.white.withOpacity(0.10),
              width: 1.w,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w700,
                    color: enabled ? Colors.white : Colors.white.withOpacity(0.42)
),
                ),
              ),
              SizedBox(width: 10.w),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 23.w,
                height: 23.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value ? const Color(0xff21C58E) : Colors.transparent,
                  border: Border.all(
                    color: enabled ? Colors.white : Colors.white.withOpacity(0.28),
                    width: 1.4.w,
                  ),
                ),
                child: value
                    ? Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16.sp,
                )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
