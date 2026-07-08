import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';

class CurrentPlanTodayReviewCard extends StatelessWidget {
  const CurrentPlanTodayReviewCard({super.key, required this.pageLabels});

  final List<String> pageLabels;

  @override
  Widget build(BuildContext context) {
    if (pageLabels.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? colors.surface : const Color(0xFF18385F);
    final cardColor = isDark ? colors.secondary : Colors.white;
    final borderColor = isDark
        ? colors.outline.withOpacity(0.12)
        : const Color(0xFFE7EDF5);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 15.h, 14.w, 16.h),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: borderColor, width: 0.8.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.09),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.refresh_rounded,
                  color: colors.primary,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'مراجعة اليوم',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body(context).copyWith(
                        color: textColor,
                        fontSize: 12.2.sp,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    SizedBox(height: 7.h),
                    Text(
                      'راجع الصفحات التالية لتثبيت حفظك',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                        color: textColor.withOpacity(0.56),
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 52.w),
            ],
          ),
          SizedBox(height: 20.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            physics: const BouncingScrollPhysics(),
            child: Row(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int index = 0; index < pageLabels.length; index++) ...[
                  _ReviewPageChip(
                    label: pageLabels[index],
                    textColor: textColor,
                    borderColor: borderColor,
                    isDark: isDark,
                  ),
                  if (index != pageLabels.length - 1) SizedBox(width: 9.w),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewPageChip extends StatelessWidget {
  const _ReviewPageChip({
    required this.label,
    required this.textColor,
    required this.borderColor,
    required this.isDark,
  });

  final String label;
  final Color textColor;
  final Color borderColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: 90.w),
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).colorScheme.surface.withOpacity(0.045)
            : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: borderColor, width: 0.8.w),
      ),
      child: Text(
        label,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.caption(context).copyWith(
          color: textColor,
          fontSize: 9.3.sp,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}
