import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class VideoPageHeader extends StatelessWidget {
  final String title;

  const VideoPageHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onBackground;

    return Padding(
      padding: EdgeInsets.only(
        right: 0.w,
        left: 0.w,
        top: 20.h,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(
              minWidth: 38.w,
              minHeight: 38.h,
            ),
            onPressed: () {
              AppHaptics.tap(context);
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 17.sp,
              color: textColor,
            ),
          ),

          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
height: 1.25,
fontWeight: FontWeight.w800,
                color: textColor
),
            ),
          ),

          SizedBox(
            width: 38.w,
            height: 38.h,
          ),
        ],
      ),
    );
  }
}