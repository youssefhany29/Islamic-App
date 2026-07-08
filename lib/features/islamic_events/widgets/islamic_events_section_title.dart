import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
bool _eventsSectionTitleLargeScreen(BuildContext context) {
  final Size size = MediaQuery.sizeOf(context);
  return size.shortestSide >= 600 || (size.width >= 700 && size.height >= 500);
}

class IslamicEventsSectionTitle extends StatelessWidget {
  const IslamicEventsSectionTitle({
    super.key,
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool large = _eventsSectionTitleLargeScreen(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: large ? 32 : 28.w,
            height: large ? 32 : 28.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.09),
              borderRadius: BorderRadius.circular(large ? 11 : 10.r),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: large ? 17 : 16.sp,
            ),
          ),
          SizedBox(width: large ? 8 : 6.w),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              locale: const Locale('ar'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body(context).copyWith(
fontWeight: FontWeight.w900,
                color: theme.colorScheme.surface,
                height: 1.35
),
            ),
          ),
        ],
      ),
    );
  }
}
