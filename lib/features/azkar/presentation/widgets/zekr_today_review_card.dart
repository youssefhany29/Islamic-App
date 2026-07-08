import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/theme/app_typography.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import 'package:islamic_app/features/azkar/data/services/zekr_memory_progress_service.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';

class ZekrTodayReviewCard extends StatelessWidget {
  const ZekrTodayReviewCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const service = ZekrMemoryProgressService();

    return FutureBuilder(
      future: service.getDueReviews(),
      builder: (context, snapshot) {
        final dueCount = snapshot.data?.length ?? 0;
        final bool hasDue = dueCount > 0;

        return _ReviewCardBody(
          dueCount: dueCount,
          hasDue: hasDue,
          onTap: onTap,
        );
      },
    );
  }
}

class _ReviewCardBody extends StatelessWidget {
  const _ReviewCardBody({
    required this.dueCount,
    required this.hasDue,
    required this.onTap,
  });

  final int dueCount;
  final bool hasDue;
  final VoidCallback onTap;

  void _handleTap(BuildContext context) {
    AppHaptics.tap(context);

    if (hasDue) {
      onTap();
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        margin: EdgeInsets.only(left: 24.w, right: 24.w, bottom: 18.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        content: Text(
          'لا توجد مراجعات مستحقة اليوم. راجع تقويم المراجعة لمعرفة الأيام القادمة.',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption(
            context,
          ).copyWith(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        duration: const Duration(milliseconds: 1700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color accentColor = hasDue
        ? theme.colorScheme.primary
        : const Color(0xff21C58E);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18.r),
        child: InkWell(
          onTap: () => _handleTap(context),
          borderRadius: BorderRadius.circular(18.r),
          splashColor: theme.colorScheme.primary.withOpacity(0.10),
          highlightColor: theme.colorScheme.primary.withOpacity(0.06),
          child: Ink(
            width: double.infinity,
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.30),
              ),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 42.w,
                  height: 42.w,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(
                    hasDue ? Icons.task_alt_rounded : Icons.verified_rounded,
                    color: accentColor,
                    size: 22.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          'مراجعة اليوم',
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          locale: const Locale('ar'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.cardTitle(
                            context,
                            color: theme.colorScheme.surface,
                          ),
                        ),
                      ),
                      SizedBox(height: 3.h),
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          hasDue
                              ? 'عندك $dueCount أذكار مستحقة اليوم، راجعهم باختبار سريع.'
                              : 'لا توجد مراجعات مستحقة اليوم.',
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          locale: const Locale('ar'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.cardSubtitle(
                            context,
                            color: theme.colorScheme.surface.withOpacity(0.64),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  width: 25.w,
                  height: 25.w,
                  decoration: BoxDecoration(
                    color: hasDue
                        ? theme.colorScheme.primary.withOpacity(0.08)
                        : theme.colorScheme.outline.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(9.r),
                  ),
                  child: Icon(
                    hasDue
                        ? Icons.arrow_forward_ios_rounded
                        : Icons.calendar_view_week_rounded,
                    color: hasDue
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surface.withOpacity(0.45),
                    size: 12.sp,
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
