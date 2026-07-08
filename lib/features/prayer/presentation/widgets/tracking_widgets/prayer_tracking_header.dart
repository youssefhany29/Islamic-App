import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

class PrayerTrackingHeader extends StatelessWidget {
  final bool large;
  final VoidCallback onReset;

  const PrayerTrackingHeader({
    super.key,
    this.large = false,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'تتبع صلاتك',
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const Spacer(),
        SizedBox(
          width: large ? 32 : 34.w,
          height: large ? 32 : 34.h,
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(
              minWidth: 34.w,
              minHeight: 34.h,
            ),
            onPressed: () {
              AppHaptics.medium(context);
              onReset();
            },
            icon: Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: large ? 16 : 18.sp,
            ),
          ),
        ),
      ],
    );
  }
}
