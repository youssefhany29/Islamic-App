import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

class NightPrayTrackingHeader extends StatelessWidget {
  final VoidCallback onReset;

  const NightPrayTrackingHeader({
    super.key,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'تتبع قيام الليل',
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const Spacer(),
        SizedBox(
          width: 34.w,
          height: 34.h,
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
              size: 18.sp,
            ),
          ),
        ),
      ],
    );
  }
}
