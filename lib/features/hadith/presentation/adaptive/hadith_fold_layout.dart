import 'package:flutter/material.dart';

import 'package:islamic_app/features/hadith/presentation/widgets/hadith_daily_journey_card.dart';
import 'package:islamic_app/features/hadith/presentation/widgets/hadith_memory_plan_card.dart';
import 'package:islamic_app/features/hadith/presentation/widgets/hadith_review_calendar_card.dart';
import 'package:islamic_app/features/hadith/presentation/widgets/hadith_today_review_card.dart';

class HadithFoldLayout extends StatelessWidget {
  const HadithFoldLayout({
    super.key,
    required this.memoryPlanLoading,
    required this.memoryPlanEnabled,
    required this.memoryPlanChanging,
    required this.reviewCalendarRefreshTick,
    required this.onMemoryPlanChanged,
    required this.onOpenAnalytics,
    required this.onOpenTodayReview,
    required this.searchAndCategories,
    required this.analyticsEntry,
  });

  final bool memoryPlanLoading;
  final bool memoryPlanEnabled;
  final bool memoryPlanChanging;
  final int reviewCalendarRefreshTick;
  final ValueChanged<bool> onMemoryPlanChanged;
  final VoidCallback onOpenAnalytics;
  final VoidCallback onOpenTodayReview;
  final Widget searchAndCategories;
  final Widget analyticsEntry;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final bool landscape = size.width > size.height;

    final double horizontalPadding = landscape ? 18 : 20;
    final double gap = 14;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          12,
          horizontalPadding,
          22,
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
                Expanded(flex: 6, child: searchAndCategories),
                SizedBox(width: gap),
                Expanded(
                  flex: 5,
                  child: _FoldSideColumn(
                    memoryPlanLoading: memoryPlanLoading,
                    memoryPlanEnabled: memoryPlanEnabled,
                    memoryPlanChanging: memoryPlanChanging,
                    reviewCalendarRefreshTick: reviewCalendarRefreshTick,
                    onMemoryPlanChanged: onMemoryPlanChanged,
                    onOpenTodayReview: onOpenTodayReview,
                    analyticsEntry: analyticsEntry,
                  ),
                ),
              ],
            )
          else ...[
            _FoldSideColumn(
              memoryPlanLoading: memoryPlanLoading,
              memoryPlanEnabled: memoryPlanEnabled,
              memoryPlanChanging: memoryPlanChanging,
              reviewCalendarRefreshTick: reviewCalendarRefreshTick,
              onMemoryPlanChanged: onMemoryPlanChanged,
              onOpenTodayReview: onOpenTodayReview,
              analyticsEntry: analyticsEntry,
            ),
            SizedBox(height: gap),
            searchAndCategories,
          ],
        ],
      ),
    );
  }
}

class _FoldSideColumn extends StatelessWidget {
  const _FoldSideColumn({
    required this.memoryPlanLoading,
    required this.memoryPlanEnabled,
    required this.memoryPlanChanging,
    required this.reviewCalendarRefreshTick,
    required this.onMemoryPlanChanged,
    required this.onOpenTodayReview,
    required this.analyticsEntry,
  });

  final bool memoryPlanLoading;
  final bool memoryPlanEnabled;
  final bool memoryPlanChanging;
  final int reviewCalendarRefreshTick;
  final ValueChanged<bool> onMemoryPlanChanged;
  final VoidCallback onOpenTodayReview;
  final Widget analyticsEntry;

  @override
  Widget build(BuildContext context) {
    const double gap = 14;

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
            const SizedBox(height: gap),
            analyticsEntry,
            const SizedBox(height: gap),
            HadithTodayReviewCard(onTap: onOpenTodayReview),
            const SizedBox(height: gap),
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
