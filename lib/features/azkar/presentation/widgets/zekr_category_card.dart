import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/theme/app_typography.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import 'package:islamic_app/features/azkar/data/models/zekr_category_model.dart';
import 'package:islamic_app/features/azkar/data/services/zekr_data_service.dart';
import 'package:islamic_app/features/azkar/data/services/zekr_progress_service.dart';

class ZekrCategoryCard extends StatelessWidget {
  const ZekrCategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  final ZekrCategoryModel category;
  final VoidCallback onTap;

  Future<_CategoryProgressData> _loadProgress() async {
    const ZekrDataService dataService = ZekrDataService();
    const ZekrProgressService progressService = ZekrProgressService();

    final items = await dataService.getItemsByCategory(category.id);
    final completed = await progressService.getCompletedCountForCategory(
      category.id,
    );

    return _CategoryProgressData(total: items.length, completed: completed);
  }

  void _handleTap(BuildContext context) {
    AppHaptics.tap(context);
    onTap();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isLarge = AppTypography.isLarge(context);

    return FutureBuilder<_CategoryProgressData>(
      future: _loadProgress(),
      builder: (context, snapshot) {
        final int total = snapshot.data?.total ?? 0;
        final int completed = snapshot.data?.completed ?? 0;
        final bool isDone = total > 0 && completed >= total;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20.r),
            child: InkWell(
              onTap: () => _handleTap(context),
              borderRadius: BorderRadius.circular(20.r),
              splashColor: theme.colorScheme.primary.withOpacity(0.10),
              highlightColor: theme.colorScheme.primary.withOpacity(0.06),
              child: Ink(
                width: double.infinity,
                padding: EdgeInsets.all(isLarge ? 14 : 12.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(
                      isDark ? 0.18 : 0.42,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.10 : 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: isLarge ? 42 : 40.w,
                      height: isLarge ? 42 : 40.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDone
                            ? const Color(0xff21C58E).withOpacity(0.14)
                            : theme.colorScheme.primary.withOpacity(
                                isDark ? 0.24 : 0.10,
                              ),
                        borderRadius: BorderRadius.circular(
                          isLarge ? 14 : 14.r,
                        ),
                      ),
                      child: Icon(
                        isDone ? Icons.check_rounded : category.icon,
                        color: isDone
                            ? const Color(0xff21C58E)
                            : theme.colorScheme.primary,
                        size: isLarge ? 22 : 20.sp,
                      ),
                    ),
                    SizedBox(width: isLarge ? 10 : 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              category.title,
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
                          SizedBox(height: isLarge ? 4 : 4.h),
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              category.subtitle,
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              locale: const Locale('ar'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.cardSubtitle(
                                context,
                                color: theme.colorScheme.surface.withOpacity(
                                  0.65,
                                ),
                              ),
                            ),
                          ),
                          if (total > 0) ...[
                            SizedBox(height: isLarge ? 8 : 8.h),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(100.r),
                              child: LinearProgressIndicator(
                                value: total == 0 ? 0 : completed / total,
                                minHeight: isLarge ? 5 : 5.h,
                                backgroundColor: theme.colorScheme.outline
                                    .withOpacity(0.20),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: isLarge ? 10 : 10.w),
                    Container(
                      width: isLarge ? 28 : 26.w,
                      height: isLarge ? 28 : 26.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(
                          isDark ? 0.18 : 0.08,
                        ),
                        borderRadius: BorderRadius.circular(isLarge ? 9 : 9.r),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: theme.colorScheme.primary,
                        size: isLarge ? 12 : 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CategoryProgressData {
  const _CategoryProgressData({required this.total, required this.completed});

  final int total;
  final int completed;
}
