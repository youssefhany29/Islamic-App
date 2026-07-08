import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/features/memorization/presentation/widgets/analytics/analytics_commitment_block.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/analytics/analytics_comparison_block.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/analytics/analytics_mastery_chart_block.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/analytics/analytics_range_groups_block.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/analytics/analytics_session_quality_block.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/analytics/analytics_smart_summary_block.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/analytics/analytics_test_results_block.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/analytics/analytics_ui.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/analytics/analytics_upcoming_tasks_block.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/analytics/memorization_analytics_data.dart';

class AnalyticsInsightsCard extends StatelessWidget {
  const AnalyticsInsightsCard({
    super.key,
    required this.data,
    required this.period,
  });

  final MemorizationAnalyticsData data;
  final MemorizationAnalyticsPeriod period;

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 13.h + bottomSafe),
      decoration: AnalyticsDecorations.outerCard(context, radius: 24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnalyticsSmartSummaryBlock(summary: data.smartSummary),
          SizedBox(height: 10.h),
          AnalyticsMasteryChartBlock(
            period: period,
            points: data.trendPoints,
            labels: data.trendLabels,
          ),
          SizedBox(height: 10.h),
          AnalyticsComparisonBlock(
            comparison: data.comparison,
            period: period,
          ),
          SizedBox(height: 10.h),
          AnalyticsSessionQualityBlock(quality: data.sessionQuality),
          SizedBox(height: 10.h),
          AnalyticsTestResultsBlock(results: data.testResults),
          SizedBox(height: 10.h),
          AnalyticsCommitmentBlock(commitment: data.commitment),
          SizedBox(height: 10.h),
          AnalyticsUpcomingTasksBlock(items: data.upcomingItems),
          SizedBox(height: 10.h),
          AnalyticsRangeGroupsBlock(
            title: 'نقاط القوة',
            icon: Icons.verified_rounded,
            iconColor: AnalyticsColors.green,
            chipColor: AnalyticsThemeColors.softTone(context, AnalyticsColors.softGreen, AnalyticsColors.green),
            chipTextColor: AnalyticsThemeColors.isDark(context) ? Colors.white.withOpacity(0.86) : const Color(0xFF2D6E61),
            emptyText: 'لا توجد نقاط قوة كافية حتى الآن',
            groups: data.strongGroups,
          ),
          SizedBox(height: 10.h),
          AnalyticsRangeGroupsBlock(
            title: 'نقاط تحتاج تركيز',
            icon: Icons.track_changes_rounded,
            iconColor: AnalyticsColors.red,
            chipColor: AnalyticsThemeColors.softTone(context, AnalyticsColors.softRed, AnalyticsColors.red),
            chipTextColor: AnalyticsThemeColors.isDark(context) ? Colors.white.withOpacity(0.86) : const Color(0xFFB54848),
            emptyText: 'لا توجد نقاط تحتاج تركيز الآن',
            groups: data.weakGroups,
          ),
        ],
      ),
    );
  }
}
