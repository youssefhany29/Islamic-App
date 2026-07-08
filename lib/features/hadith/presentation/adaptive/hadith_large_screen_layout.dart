import 'package:flutter/material.dart';

import 'package:islamic_app/features/hadith/presentation/widgets/hadith_daily_journey_card.dart';
import 'package:islamic_app/features/hadith/presentation/widgets/hadith_memory_plan_card.dart';
import 'package:islamic_app/features/hadith/presentation/widgets/hadith_review_calendar_card.dart';
import 'package:islamic_app/features/hadith/presentation/widgets/hadith_today_review_card.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';

class HadithLargeScreenLayout extends StatelessWidget {
  const HadithLargeScreenLayout({
    super.key,
    required this.memoryPlanLoading,
    required this.memoryPlanEnabled,
    required this.memoryPlanChanging,
    required this.reviewCalendarRefreshTick,
    required this.onMemoryPlanChanged,
    required this.onOpenAnalytics,
    required this.onOpenTodayReview,
    required this.searchAndCategories,
  });

  final bool memoryPlanLoading;
  final bool memoryPlanEnabled;
  final bool memoryPlanChanging;
  final int reviewCalendarRefreshTick;
  final ValueChanged<bool> onMemoryPlanChanged;
  final VoidCallback onOpenAnalytics;
  final VoidCallback onOpenTodayReview;
  final Widget searchAndCategories;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final bool landscape = size.width > size.height;
    final bool isTablet = size.shortestSide >= 600;

    final double gap = landscape ? 18 : 16;
    final double horizontalPadding = landscape ? 26 : 30;
    final double verticalPadding = isTablet ? 18 : 14;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          verticalPadding,
          horizontalPadding,
          24,
        ),
        physics: const BouncingScrollPhysics(),
        children: [
          const HadithDailyJourneyCard(),

          SizedBox(height: gap),

          if (landscape)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.rtl,
              children: [
                Expanded(flex: 7, child: searchAndCategories),
                SizedBox(width: gap),
                Expanded(
                  flex: 5,
                  child: _HadithLargeSidePanel(
                    memoryPlanLoading: memoryPlanLoading,
                    memoryPlanEnabled: memoryPlanEnabled,
                    memoryPlanChanging: memoryPlanChanging,
                    reviewCalendarRefreshTick: reviewCalendarRefreshTick,
                    onMemoryPlanChanged: onMemoryPlanChanged,
                    onOpenAnalytics: onOpenAnalytics,
                    onOpenTodayReview: onOpenTodayReview,
                  ),
                ),
              ],
            )
          else ...[
            _HadithLargeSidePanel(
              memoryPlanLoading: memoryPlanLoading,
              memoryPlanEnabled: memoryPlanEnabled,
              memoryPlanChanging: memoryPlanChanging,
              reviewCalendarRefreshTick: reviewCalendarRefreshTick,
              onMemoryPlanChanged: onMemoryPlanChanged,
              onOpenAnalytics: onOpenAnalytics,
              onOpenTodayReview: onOpenTodayReview,
            ),
            SizedBox(height: gap),
            searchAndCategories,
          ],
        ],
      ),
    );
  }
}

class _HadithLargeSidePanel extends StatelessWidget {
  const _HadithLargeSidePanel({
    required this.memoryPlanLoading,
    required this.memoryPlanEnabled,
    required this.memoryPlanChanging,
    required this.reviewCalendarRefreshTick,
    required this.onMemoryPlanChanged,
    required this.onOpenAnalytics,
    required this.onOpenTodayReview,
  });

  final bool memoryPlanLoading;
  final bool memoryPlanEnabled;
  final bool memoryPlanChanging;
  final int reviewCalendarRefreshTick;
  final ValueChanged<bool> onMemoryPlanChanged;
  final VoidCallback onOpenAnalytics;
  final VoidCallback onOpenTodayReview;

  @override
  Widget build(BuildContext context) {
    final double gap =
        MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height
        ? 14
        : 16;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (memoryPlanLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          HadithMemoryPlanCard(
            enabled: memoryPlanEnabled,
            isChanging: memoryPlanChanging,
            onChanged: onMemoryPlanChanged,
          ),

          if (memoryPlanEnabled) ...[
            SizedBox(height: gap),
            _LargeAnalyticsEntryCard(onTap: onOpenAnalytics),
            SizedBox(height: gap),
            HadithTodayReviewCard(onTap: onOpenTodayReview),
            SizedBox(height: gap),
            HadithReviewCalendarCard(
              refreshTick: reviewCalendarRefreshTick,
              onOpenTodayReview: onOpenTodayReview,
            ),
          ],
        ],
      ],
    );
  }
}

class _LargeAnalyticsEntryCard extends StatelessWidget {
  const _LargeAnalyticsEntryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.22),
              ),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.insights_rounded,
                    color: theme.colorScheme.primary,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'تحليل الحفظ',
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.headline(context).copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.surface,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'تابع الأحاديث المحفوظة واللي محتاجة مراجعة.',
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption(context).copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.surface.withOpacity(0.64),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
