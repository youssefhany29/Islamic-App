import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/features/memorization/presentation/widgets/analytics/analytics_insights_card.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/analytics/analytics_period_selector.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/analytics/analytics_stats_grid.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/analytics/analytics_ui.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/analytics/memorization_analytics_data.dart';
import 'package:islamic_app/shared/widgets/app_main_components/custom_app_bar.dart';

class MemorizationAnalyticsPage extends StatefulWidget {
  const MemorizationAnalyticsPage({super.key});

  @override
  State<MemorizationAnalyticsPage> createState() =>
      _MemorizationAnalyticsPageState();
}

class _MemorizationAnalyticsPageState extends State<MemorizationAnalyticsPage> {
  MemorizationAnalyticsPeriod selectedPeriod =
      MemorizationAnalyticsPeriod.last7Days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final Color pageBackground = AnalyticsThemeColors.pageBackground(context);

    final ThemeData appBarTheme = theme.copyWith(
      colorScheme: colors.copyWith(
        background: pageBackground,
        surface: Colors.white,
      ),
      iconTheme: theme.iconTheme.copyWith(color: Colors.white),
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      textTheme: theme.textTheme.copyWith(
        headlineLarge: theme.textTheme.headlineLarge?.copyWith(
          color: Colors.white,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Theme(
              data: appBarTheme,
              child: const CustomAppBar(
                category: CustomAppBarCategory(text: 'التحليلات'),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.zero,
                child: FutureBuilder<MemorizationAnalyticsData>(
                  future: MemorizationAnalyticsData.load(selectedPeriod),
                  builder: (context, snapshot) {
                    final data = snapshot.data ??
                        MemorizationAnalyticsData.empty(selectedPeriod);

                    return Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 0),
                          child: AnalyticsPeriodSelector(
                            selectedPeriod: selectedPeriod,
                            onChanged: (period) {
                              setState(() => selectedPeriod = period);
                            },
                          ),
                        ),
                        SizedBox(height: 18.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14.w),
                          child: AnalyticsStatsGrid(data: data),
                        ),
                        SizedBox(height: 14.h),
                        AnalyticsInsightsCard(
                          data: data,
                          period: selectedPeriod,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
