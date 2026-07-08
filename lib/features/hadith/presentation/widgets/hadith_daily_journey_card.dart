import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/theme/app_typography.dart';

import 'package:islamic_app/features/hadith/data/datasources/hadith_local_data.dart';
import 'package:islamic_app/features/hadith/data/services/hadith_data_service.dart';
import 'package:islamic_app/features/hadith/data/services/hadith_progress_service.dart';

class HadithDailyJourneyCard extends StatelessWidget {
  const HadithDailyJourneyCard({super.key});

  Future<_DailyJourneyData> _loadData() async {
    const HadithDataService dataService = HadithDataService();
    const HadithProgressService progressService = HadithProgressService();

    int completedCategories = 0;
    int totalCategories = 0;

    for (final category in HadithLocalData.categories) {
      if (!category.isDailyTarget) continue;

      totalCategories++;

      final items = await dataService.getItemsByCategory(category.id);
      final completedCount = await progressService.getCompletedCountForCategory(
        category.id,
      );

      if (items.isNotEmpty && completedCount >= items.length) {
        completedCategories++;
      }
    }

    return _DailyJourneyData(
      completedCategories: completedCategories,
      totalCategories: totalCategories,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final bool isLargeScreen =
        size.shortestSide >= 600 || (size.width >= 700 && size.height >= 500);

    final double padding = isLargeScreen ? 15 : 14.w;
    final double radius = isLargeScreen ? 22 : 18.r;
    final double iconBox = isLargeScreen ? 38 : 39.w;
    final double iconSize = isLargeScreen ? 20 : 21.sp;
    final double progressHeight = isLargeScreen ? 7 : 7.h;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool hasBoundedHeight =
            constraints.hasBoundedHeight && constraints.maxHeight.isFinite;

        return FutureBuilder<_DailyJourneyData>(
          future: _loadData(),
          builder: (context, snapshot) {
            final int completed = snapshot.data?.completedCategories ?? 0;
            final int total = snapshot.data?.totalCategories ?? 4;
            final double progress = total == 0 ? 0 : completed / total;

            final String footerText = completed == total
                ? 'ما شاء الله، أتممت ورد الحديث اليوم'
                : 'ابدأ بخطوة صغيرة، حديث واحد يكفي لتبدأ';

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                width: double.infinity,
                height: hasBoundedHeight ? double.infinity : null,
                padding: EdgeInsets.all(padding),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(radius),
                ),
                child: Column(
                  mainAxisSize: hasBoundedHeight
                      ? MainAxisSize.max
                      : MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      textDirection: TextDirection.rtl,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: Text(
                                  'وردك اليومي',
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.rtl,
                                  locale: const Locale('ar'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.cardTitle(
                                    context,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(height: isLargeScreen ? 4 : 3.h),
                              SizedBox(
                                width: double.infinity,
                                child: Text(
                                  'أنجزت $completed من $total أحاديث أساسية اليوم',
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.rtl,
                                  locale: const Locale('ar'),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.cardSubtitle(
                                    context,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white.withOpacity(0.78),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: isLargeScreen ? 10 : 10.w),
                        Container(
                          width: iconBox,
                          height: iconBox,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(
                              isLargeScreen ? 14 : 14.r,
                            ),
                          ),
                          child: Icon(
                            Icons.local_florist_rounded,
                            color: Colors.white,
                            size: iconSize,
                          ),
                        ),
                      ],
                    ),
                    if (hasBoundedHeight)
                      const Spacer()
                    else
                      SizedBox(height: isLargeScreen ? 18 : 16.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: progressHeight,
                        backgroundColor: Colors.white.withOpacity(0.18),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: isLargeScreen ? 7 : 7.h),
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        footerText,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        locale: const Locale('ar'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.cardSubtitle(
                          context,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.86),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DailyJourneyData {
  const _DailyJourneyData({
    required this.completedCategories,
    required this.totalCategories,
  });

  final int completedCategories;
  final int totalCategories;
}
