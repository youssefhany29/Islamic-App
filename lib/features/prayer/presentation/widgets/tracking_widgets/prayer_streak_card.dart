import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class PrayerStreakCard extends StatelessWidget {
  final bool large;
  final int streak;
  final int bestStreak;

  const PrayerStreakCard({
    super.key,
    this.large = false,
    required this.streak,
    required this.bestStreak,
  });

  void _showStreakInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.r),
            ),
            title: Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: large ? 20 : 22.sp,
                ),
                SizedBox(width: large ? 8 : 8.w),
                Expanded(
                  child: Text(
                    'طريقة حساب الأيام المتتالية',
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: AppTextStyles.body(context).copyWith(
fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.surface
),
                  ),
                ),
              ],
            ),
            content: Text(
              'تزيد الأيام المتتالية عند إتمام صلوات اليوم في موعدها.\n\n'
                  'أما الصلاة التي يتم قضاؤها بعد وقتها، فتُسجَّل لك لكنها لا تزيد الأيام المتتالية.',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w600,
                height: 1.6,
                color: Theme.of(context).colorScheme.surface.withOpacity(0.78)
),
            ),
            actionsAlignment: MainAxisAlignment.start,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'فهمت',
                  style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.primary
),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color infoColor = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      height: 58.h,
      padding: EdgeInsets.symmetric(
        horizontal: large ? 10 : 12.w,
        vertical: large ? 7 : 8.h,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Material(
            color: infoColor.withOpacity(0.14),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _showStreakInfo(context),
              child: SizedBox(
                width: large ? 28 : 30.w,
                height: large ? 28 : 30.w,
                child: Icon(
                  Icons.info_outline_rounded,
                  color: infoColor,
                  size: large ? 15 : 17.sp,
                ),
              ),
            ),
          ),

          SizedBox(width: 5.w),

          Expanded(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أيام متتالية: $streak',
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.surface
),
                  ),

                  SizedBox(height: 2.h),

                  Text(
                    'أفضل سلسلة: $bestStreak',
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w600,
                      color: infoColor.withOpacity(0.9)
),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(width: large ? 8 : 8.w),

          Icon(
            Icons.local_fire_department_rounded,
            color: Colors.orange,
            size: large ? 20 : 22.sp,
          ),
        ],
      ),
    );
  }
}