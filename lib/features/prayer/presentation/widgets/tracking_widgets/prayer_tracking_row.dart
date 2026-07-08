import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class PrayerTrackingRow extends StatelessWidget {
  final bool large;
  final String text;
  final bool value;
  final bool enabled;
  final String? statusText;
  final IconData? statusIcon;
  final Color? statusColor;
  final ValueChanged<bool> onChanged;

  const PrayerTrackingRow({
    super.key,
    this.large = false,
    required this.text,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.statusText,
    this.statusIcon,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveStatusColor =
        statusColor ?? Colors.white.withOpacity(0.62);

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Opacity(
        opacity: enabled ? 1 : 0.62,
        child: InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: enabled
              ? () {
                  AppHaptics.tap(context);
                  onChanged(!value);
                }
              : () {
                  AppHaptics.tap(context);
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: BoxConstraints(
              minHeight: statusText == null ? (large ? 34 : 38.h) : (large ? 44 : 48.h),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: large ? 10 : 12.w,
              vertical: statusText == null ? 0 : 7.h,
            ),
            decoration: BoxDecoration(
              color: value
                  ? Colors.white.withOpacity(0.16)
                  : const Color(0xff171B26),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: value
                    ? const Color(0xff21C58E)
                    : enabled
                        ? Colors.white24
                        : Colors.white10,
                width: 1.w,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        text,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w700,
                          color: Colors.white
),
                      ),
                      if (statusText != null) ...[
                        SizedBox(height: 2.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Text(
                                statusText!,
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.rtl,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w600,
                                  color: effectiveStatusColor
),
                              ),
                            ),
                            if (statusIcon != null) ...[
                              SizedBox(width: 4.w),
                              Icon(
                                statusIcon,
                                color: effectiveStatusColor,
                                size: 12.sp,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(width: large ? 9 : 10.w),

                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: large ? 22 : 23.w,
                  height: large ? 22 : 23.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: value ? const Color(0xff21C58E) : Colors.transparent,
                    border: Border.all(
                      color: enabled ? Colors.white : Colors.white38,
                      width: 1.4.w,
                    ),
                  ),
                  child: value
                      ? Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 16.sp,
                        )
                      : enabled
                          ? null
                          : Icon(
                              Icons.lock_rounded,
                              color: Colors.white38,
                              size: 13.sp,
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
