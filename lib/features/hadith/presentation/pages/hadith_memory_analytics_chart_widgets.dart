part of 'hadith_memory_analytics_page.dart';

class _MonthlyAttemptsChart extends StatelessWidget {
  const _MonthlyAttemptsChart({required this.stats});

  final HadithMemoryDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final m = _AnalyticsMetrics.of(context);
    final theme = Theme.of(context);
    final points = stats.monthlyPoints;

    return _ChartShell(
      title: 'محاولات الحفظ خلال 30 يوم',
      subtitle: 'كل عمود يمثل عدد تقييمات الحفظ في يوم.',
      child: points.isEmpty
          ? const _EmptyChartText()
          : SizedBox(
              height: m.chartHeight,
              child: BarChart(
                BarChartData(
                  maxY: stats.maxMonthlyAttempts,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: theme.colorScheme.outline.withOpacity(0.14),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: m.large ? 22 : 24.h,
                        interval: 5,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= points.length) {
                            return const SizedBox.shrink();
                          }
                          if (index % 5 != 0 && index != points.length - 1) {
                            return const SizedBox.shrink();
                          }

                          return Text(
                            points[index].dayLabel,
                            style: AppTextStyles.caption(context).copyWith(
                              color: theme.colorScheme.surface.withOpacity(
                                0.55,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(points.length, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: points[index].attemptsCount.toDouble(),
                          width: m.large ? 5 : 6.w,
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
    );
  }
}

class _MonthlyStrengthChart extends StatelessWidget {
  const _MonthlyStrengthChart({required this.stats});

  final HadithMemoryDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final m = _AnalyticsMetrics.of(context);
    final theme = Theme.of(context);
    final points = stats.monthlyPoints;

    return _ChartShell(
      title: 'متوسط جودة الحفظ الشهري',
      subtitle:
          'الخط مبني على تقييماتك اليومية بعد القراءة أو التدريب أو الاختبار.',
      child: points.isEmpty
          ? const _EmptyChartText()
          : SizedBox(
              height: m.chartHeight,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 100,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: theme.colorScheme.outline.withOpacity(0.14),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: m.large ? 22 : 24.h,
                        interval: 5,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= points.length) {
                            return const SizedBox.shrink();
                          }
                          if (index % 5 != 0 && index != points.length - 1) {
                            return const SizedBox.shrink();
                          }

                          return Text(
                            points[index].dayLabel,
                            style: AppTextStyles.caption(context).copyWith(
                              color: theme.colorScheme.surface.withOpacity(
                                0.55,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      barWidth: m.large ? 2.5 : 3,
                      color: theme.colorScheme.primary,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: theme.colorScheme.primary.withOpacity(0.10),
                      ),
                      spots: List.generate(points.length, (index) {
                        final value = points[index].averageRatingScore;
                        return FlSpot(index.toDouble(), value <= 0 ? 0 : value);
                      }),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ChartShell extends StatelessWidget {
  const _ChartShell({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final m = _AnalyticsMetrics.of(context);
    final theme = Theme.of(context);

    return _AnalyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _ArabicText(
            title,
            fontSize: m.headerTitleSize,
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.surface,
          ),
          SizedBox(height: m.large ? 3 : 3.h),
          _ArabicText(
            subtitle,
            fontSize: m.headerSubtitleSize,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.surface.withOpacity(0.62),
            height: 1.5,
          ),
          SizedBox(height: m.large ? 12 : 14.h),
          child,
        ],
      ),
    );
  }
}

class _EmptyChartText extends StatelessWidget {
  const _EmptyChartText();

  @override
  Widget build(BuildContext context) {
    final m = _AnalyticsMetrics.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: m.large ? 24 : 22.h),
      child: _ArabicText(
        'لسه مفيش بيانات كافية للشارت.',
        textAlign: TextAlign.center,
        fontSize: m.bodyTextSize,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.surface.withOpacity(0.60),
      ),
    );
  }
}

class _CategoryAnalysisCard extends StatelessWidget {
  const _CategoryAnalysisCard({required this.stats});

  final HadithMemoryDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final m = _AnalyticsMetrics.of(context);
    final theme = Theme.of(context);

    return _AnalyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _HeaderRow(
            icon: Icons.category_outlined,
            color: theme.colorScheme.primary,
            title: 'تحليل حسب الأقسام',
            subtitle: 'يعرض متوسط قوة الحفظ لكل قسم وعدد المراجعات المستحقة.',
          ),
          SizedBox(height: m.large ? 11 : 10.h),
          if (stats.categoryStats.isEmpty)
            _ArabicText(
              'لسه مفيش بيانات أقسام.',
              fontSize: m.bodyTextSize,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.surface.withOpacity(0.62),
            )
          else
            ...stats.categoryStats.map(
              (item) => Padding(
                padding: EdgeInsets.only(bottom: m.large ? 9 : 9.h),
                child: _CategoryProgressLine(item: item),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryProgressLine extends StatelessWidget {
  const _CategoryProgressLine({required this.item});

  final HadithCategoryMemoryStats item;

  @override
  Widget build(BuildContext context) {
    final m = _AnalyticsMetrics.of(context);
    final theme = Theme.of(context);
    final value = (item.averageStrength / 100).clamp(0.0, 1.0);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(m.large ? 10 : 10.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.045),
          borderRadius: BorderRadius.circular(m.large ? 14 : 14.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _ArabicText(
                    item.categoryTitle,
                    fontSize: m.tileTitleSize,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.surface,
                    maxLines: 1,
                  ),
                ),
                SizedBox(width: m.large ? 8 : 8.w),
                Text(
                  '${item.averageStrength.toStringAsFixed(0)}%',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'cairo',
                    fontSize: m.bodyTextSize,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: m.large ? 6 : 5.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: value,
                minHeight: m.large ? 6 : 6.h,
                backgroundColor: theme.colorScheme.outline.withOpacity(0.18),
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
            if (item.dueCount > 0) ...[
              SizedBox(height: m.large ? 5 : 3.h),
              _ArabicText(
                '${item.dueCount} مراجعة مستحقة',
                fontSize: m.smallTextSize,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
