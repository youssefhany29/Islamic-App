import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import 'package:islamic_app/features/hadith/data/models/hadith_memory_attempt_model.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';

Future<HadithMemoryRating?> showHadithMemoryReviewSheet({
  required BuildContext context,
  required String itemTitle,
}) {
  return showModalBottomSheet<HadithMemoryRating>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) {
      return _HadithMemoryReviewSheet(itemTitle: itemTitle);
    },
  );
}

class _HadithMemoryReviewSheet extends StatelessWidget {
  const _HadithMemoryReviewSheet({required this.itemTitle});

  final String itemTitle;

  void _choose(BuildContext context, HadithMemoryRating rating) {
    AppHaptics.tap(context);
    Navigator.pop(context, rating);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Center(
                child: Container(
                  width: 44.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(100.r),
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              Text(
                'قيّم حفظك',
                textAlign: TextAlign.right,
                style: AppTextStyles.headline(context).copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.surface,
                  letterSpacing: 0,
                ),
              ),

              SizedBox(height: 4.h),

              Text(
                itemTitle,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.surface.withOpacity(0.65),
                  letterSpacing: 0,
                ),
              ),

              SizedBox(height: 14.h),

              _RatingButton(
                title: 'حفظته تمام',
                subtitle: 'كنت قادر تسترجعه بثقة',
                icon: Icons.verified_rounded,
                color: const Color(0xff21C58E),
                onTap: () => _choose(context, HadithMemoryRating.mastered),
              ),

              SizedBox(height: 10.h),

              _RatingButton(
                title: 'نص نص',
                subtitle: 'فاكره لكن محتاج تدريب بسيط',
                icon: Icons.adjust_rounded,
                color: const Color(0xffF59E0B),
                onTap: () => _choose(context, HadithMemoryRating.partial),
              ),

              SizedBox(height: 10.h),

              _RatingButton(
                title: 'محتاج مراجعة',
                subtitle: 'مش مشكلة، هنراجعه معاك بهدوء',
                icon: Icons.refresh_rounded,
                color: const Color(0xffEF4444),
                onTap: () => _choose(context, HadithMemoryRating.review),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  const _RatingButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Ink(
          padding: EdgeInsets.all(13.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(
                isDark ? 0.18 : 0.35,
              ),
            ),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(icon, color: color, size: 22.sp),
              ),

              SizedBox(width: 10.w),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.caption(context).copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.surface,
                        letterSpacing: 0,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      subtitle,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.caption(context).copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.surface.withOpacity(0.62),
                        height: 1.4,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
