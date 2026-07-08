import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_active_plan_model.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_session_result_model.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_plan_storage.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_session_result_storage.dart';
import 'package:islamic_app/features/quran/reader/quran_page_mapper.dart';
import 'package:islamic_app/features/quran/reader/quran_reader_helpers.dart';

class QuickMasteryOverviewCard extends StatelessWidget {
  const QuickMasteryOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_QuickMasteryOverviewData>(
      future: _QuickMasteryOverviewData.load(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? const _QuickMasteryOverviewData.empty();

        return Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(13.w, 11.h, 13.w, 13.h),
          decoration: BoxDecoration(
            color: _QuickOverviewColors.card(context),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: _QuickOverviewColors.border(context),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'نظرة سريعة',
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  color: _QuickOverviewColors.text(context),
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: _QuickOverviewStatBox(
                      label: 'الإتقان',
                      value: '${data.masteryPercent}%',
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _QuickOverviewStatBox(
                      label: 'الاختبارات',
                      value: '${data.testsCount}',
                      unit: 'اختبارات',
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _QuickOverviewStatBox(
                      label: 'المراجعة',
                      value: '${data.reviewPages}',
                      unit: 'صفحة',
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _QuickOverviewStatBox(
                      label: 'الحفظ',
                      value: '${data.memorizedPages}',
                      unit: 'صفحة',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickOverviewStatBox extends StatelessWidget {
  const _QuickOverviewStatBox({
    required this.label,
    required this.value,
    this.unit,
  });

  final String label;
  final String value;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62.h,
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: _QuickOverviewColors.statBackground(context),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _QuickOverviewColors.border(context, _QuickOverviewColors.isDark(context) ? 0.10 : 0.08),
          width: 0.8,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(context).copyWith(
              color: _QuickOverviewColors.text(context, 0.72),
              fontSize: 8.sp,
              fontWeight: FontWeight.w700,
              height: 1.05,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.headline(context).copyWith(
              color: _QuickOverviewColors.text(context),
              fontSize: 12.2.sp,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          if (unit != null) ...[
            SizedBox(height: 3.h),
            Text(
              unit!,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
                color: _QuickOverviewColors.text(context, 0.54),
                fontSize: 8.sp,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickMasteryOverviewData {
  const _QuickMasteryOverviewData({
    required this.masteryPercent,
    required this.testsCount,
    required this.reviewPages,
    required this.memorizedPages,
  });

  const _QuickMasteryOverviewData.empty()
      : masteryPercent = 0,
        testsCount = 0,
        reviewPages = 0,
        memorizedPages = 0;

  final int masteryPercent;
  final int testsCount;
  final int reviewPages;
  final int memorizedPages;

  static Future<_QuickMasteryOverviewData> load() async {
    final activePlan = await MemorizationPlanStorage.getActivePlan();

    if (activePlan == null) {
      return const _QuickMasteryOverviewData.empty();
    }

    await QuranPageMapper.load();

    final results = await MemorizationSessionResultStorage.getResults();
    final planResults = results.where((result) {
      return _belongsToActivePlan(plan: activePlan, result: result);
    }).toList();

    if (planResults.isEmpty) {
      return const _QuickMasteryOverviewData.empty();
    }

    final memorizedPages = _uniquePagesCount(
      planResults.where((result) => result.taskType == 'dailyNew'),
    );

    final reviewPages = _totalPagesCount(
      planResults.where(
            (result) => result.taskType == 'dailyReview' || result.taskType == 'weakReview',
      ),
    );

    final testsCount = planResults.where((result) {
      return result.taskType == 'selfTest';
    }).length;

    return _QuickMasteryOverviewData(
      masteryPercent: _overallMasteryPercent(planResults),
      testsCount: testsCount,
      reviewPages: reviewPages,
      memorizedPages: memorizedPages,
    );
  }

  static bool _belongsToActivePlan({
    required MemorizationActivePlanModel plan,
    required MemorizationSessionResultModel result,
  }) {
    if (result.completedAt.isBefore(plan.createdAt)) return false;

    final overlapsMainRange =
        result.endGlobalAyahIndex >= plan.scopeStartGlobalAyahIndex &&
            result.startGlobalAyahIndex <= plan.scopeEndGlobalAyahIndex;

    final overlapsReviewRange = plan.hasValidReviewRange &&
        result.endGlobalAyahIndex >= plan.reviewStartGlobalAyahIndex &&
        result.startGlobalAyahIndex <= plan.reviewEndGlobalAyahIndex;

    return overlapsMainRange || overlapsReviewRange;
  }

  static int _overallMasteryPercent(List<MemorizationSessionResultModel> results) {
    if (results.isEmpty) return 0;

    final score = results.fold<int>(0, (sum, result) {
      return sum + _ratingScore(result.rating);
    });

    return (score / results.length).round().clamp(0, 100).toInt();
  }

  static int _ratingScore(String rating) {
    switch (rating) {
      case 'easy':
        return 100;
      case 'good':
        return 75;
      case 'hard':
        return 40;
      case 'forgot':
        return 15;
      default:
        return 70;
    }
  }

  static int _uniquePagesCount(Iterable<MemorizationSessionResultModel> results) {
    final pages = <int>{};

    for (final result in results) {
      final range = _safeResultPageRange(result);

      for (int page = range.startPage; page <= range.endPage; page++) {
        pages.add(page);
      }
    }

    return pages.length;
  }

  static int _totalPagesCount(Iterable<MemorizationSessionResultModel> results) {
    int total = 0;

    for (final result in results) {
      final range = _safeResultPageRange(result);
      total += math.max(1, range.endPage - range.startPage + 1);
    }

    return total;
  }

  static _PageRange _safeResultPageRange(MemorizationSessionResultModel result) {
    final int maxAyahIndex = QuranReaderHelpers.totalAyahs - 1;
    final int startIndex = result.startGlobalAyahIndex.clamp(0, maxAyahIndex).toInt();
    final int endIndex = result.endGlobalAyahIndex.clamp(startIndex, maxAyahIndex).toInt();

    final int startPage = QuranPageMapper.getPageNumberForGlobalAyah(startIndex)
        .clamp(1, 604)
        .toInt();
    final int endPage = QuranPageMapper.getPageNumberForGlobalAyah(endIndex)
        .clamp(startPage, 604)
        .toInt();

    return _PageRange(startPage: startPage, endPage: endPage);
  }
}

class _PageRange {
  const _PageRange({
    required this.startPage,
    required this.endPage,
  });

  final int startPage;
  final int endPage;
}

class _QuickOverviewColors {
  const _QuickOverviewColors._();

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color card(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return isDark(context) ? colors.secondary : Colors.white;
  }

  static Color statBackground(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (isDark(context)) return colors.surface.withOpacity(0.045);
    return const Color(0xFFF6F9FC);
  }

  static Color text(BuildContext context, [double opacity = 1]) {
    return Theme.of(context).colorScheme.surface.withOpacity(opacity);
  }

  static Color border(BuildContext context, [double? opacity]) {
    final colors = Theme.of(context).colorScheme;
    return colors.surface.withOpacity(opacity ?? (isDark(context) ? 0.10 : 0.065));
  }

}
