part of 'zekr_memory_analytics_page.dart';

class _PhoneAnalyticsBody extends StatelessWidget {
  const _PhoneAnalyticsBody({
    required this.stats,
    required this.onOpenTodayReview,
    required this.onRebuildAnalysis,
    required this.onResetAnalysis,
  });

  final ZekrMemoryDashboardStats stats;
  final VoidCallback onOpenTodayReview;
  final Future<void> Function() onRebuildAnalysis;
  final VoidCallback onResetAnalysis;

  @override
  Widget build(BuildContext context) {
    final m = _AnalyticsMetrics.of(context);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        m.pageHorizontalPadding,
        m.pageTopPadding,
        m.pageHorizontalPadding,
        m.pageBottomPadding,
      ),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      children: [
        _OverviewCard(stats: stats),
        SizedBox(height: m.gap),
        _StatsGrid(stats: stats),
        SizedBox(height: m.gap),
        _SmartPlanCard(stats: stats),
        SizedBox(height: m.gap),
        _MonthlyAttemptsChart(stats: stats),
        SizedBox(height: m.gap),
        _MonthlyStrengthChart(stats: stats),
        SizedBox(height: m.gap),
        _CategoryAnalysisCard(stats: stats),
        SizedBox(height: m.gap),
        _MemoryItemsCard(
          title: 'مراجعة اليوم',
          subtitle: 'الأذكار التي حان وقت مراجعتها فقط حسب خطة الحفظ المتباعد.',
          emptyText:
              'لا توجد مراجعات مستحقة اليوم. راجع تقويم المراجعة لمعرفة الأيام القادمة.',
          items: stats.dueReviews,
          icon: Icons.today_rounded,
          color: Theme.of(context).colorScheme.primary,
          actionText: stats.dueReviews.isEmpty ? null : 'ابدأ مراجعة اليوم',
          onActionTap: stats.dueReviews.isEmpty ? null : onOpenTodayReview,
        ),
        SizedBox(height: m.gap),
        _MemoryItemsCard(
          title: 'أضعف الأذكار',
          subtitle: 'ابدأ بها في التدريب القادم لأنها تحتاج تثبيت أكثر.',
          emptyText:
              'ابدأ بتقييم بعض الأذكار من درّبني على الحفظ، وبعدها هتظهر الأذكار التي تحتاج تثبيت.',
          items: stats.weakestItems,
          icon: Icons.warning_amber_rounded,
          color: const Color(0xffF59E0B),
        ),
        SizedBox(height: m.gap),
        _MemoryItemsCard(
          title: 'أقوى الأذكار',
          subtitle: 'أذكار ثابتة عندك، حافظ عليها بالمراجعة المتباعدة.',
          emptyText:
              'اختار تمام بعد التدريب أكثر من مرة، وبعدها هتظهر هنا الأذكار الثابتة.',
          items: stats.strongestItems,
          icon: Icons.verified_rounded,
          color: const Color(0xff21C58E),
        ),
        SizedBox(height: m.gap),
        _RecentAttemptsCard(attempts: stats.recentAttempts),
        SizedBox(height: m.gap),
        _ActionButtonsRow(
          onRebuildAnalysis: onRebuildAnalysis,
          onResetAnalysis: onResetAnalysis,
        ),
      ],
    );
  }
}

class _LargeAnalyticsBody extends StatelessWidget {
  const _LargeAnalyticsBody({
    required this.stats,
    required this.onOpenTodayReview,
    required this.onRebuildAnalysis,
    required this.onResetAnalysis,
  });

  final ZekrMemoryDashboardStats stats;
  final VoidCallback onOpenTodayReview;
  final Future<void> Function() onRebuildAnalysis;
  final VoidCallback onResetAnalysis;

  @override
  Widget build(BuildContext context) {
    final m = _AnalyticsMetrics.of(context);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        m.pageHorizontalPadding,
        m.pageTopPadding,
        m.pageHorizontalPadding,
        m.pageBottomPadding,
      ),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      children: [
        _OverviewCard(stats: stats),
        SizedBox(height: m.gap),

        // 4 كروت جنب بعض
        _StatsGrid(stats: stats),
        SizedBox(height: m.gap),

        // كارت الخطة المقترحة
        _SmartPlanCard(stats: stats),
        SizedBox(height: m.gap),

        // كارتين الشارت جنب بعض
        _ResponsiveTwoColumn(
          first: _MonthlyAttemptsChart(stats: stats),
          second: _MonthlyStrengthChart(stats: stats),
        ),
        SizedBox(height: m.gap),

        // باقي الكروت بنفس النظام
        _CategoryAnalysisCard(stats: stats),
        SizedBox(height: m.gap),

        _MemoryItemsCard(
          title: 'مراجعة اليوم',
          subtitle: 'الأذكار التي حان وقت مراجعتها فقط حسب خطة الحفظ المتباعد.',
          emptyText:
              'لا توجد مراجعات مستحقة اليوم. راجع تقويم المراجعة لمعرفة الأيام القادمة.',
          items: stats.dueReviews,
          icon: Icons.today_rounded,
          color: Theme.of(context).colorScheme.primary,
          actionText: stats.dueReviews.isEmpty ? null : 'ابدأ مراجعة اليوم',
          onActionTap: stats.dueReviews.isEmpty ? null : onOpenTodayReview,
        ),
        SizedBox(height: m.gap),

        _ResponsiveTwoColumn(
          first: _MemoryItemsCard(
            title: 'أضعف الأذكار',
            subtitle: 'ابدأ بها في التدريب القادم لأنها تحتاج تثبيت أكثر.',
            emptyText:
                'ابدأ بتقييم بعض الأذكار من درّبني على الحفظ، وبعدها هتظهر الأذكار التي تحتاج تثبيت.',
            items: stats.weakestItems,
            icon: Icons.warning_amber_rounded,
            color: const Color(0xffF59E0B),
          ),
          second: _MemoryItemsCard(
            title: 'أقوى الأذكار',
            subtitle: 'أذكار ثابتة عندك، حافظ عليها بالمراجعة المتباعدة.',
            emptyText:
                'اختار تمام بعد التدريب أكثر من مرة، وبعدها هتظهر هنا الأذكار الثابتة.',
            items: stats.strongestItems,
            icon: Icons.verified_rounded,
            color: const Color(0xff21C58E),
          ),
        ),
        SizedBox(height: m.gap),

        _RecentAttemptsCard(attempts: stats.recentAttempts),
        SizedBox(height: m.gap),

        _ActionButtonsRow(
          onRebuildAnalysis: onRebuildAnalysis,
          onResetAnalysis: onResetAnalysis,
        ),
      ],
    );
  }
}

class _ResponsiveTwoColumn extends StatelessWidget {
  const _ResponsiveTwoColumn({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    final m = _AnalyticsMetrics.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            children: [
              first,
              SizedBox(height: m.gap),
              second,
            ],
          );
        }

        return IntrinsicHeight(
          child: Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: SizedBox.expand(child: first)),
              SizedBox(width: m.gap),
              Expanded(child: SizedBox.expand(child: second)),
            ],
          ),
        );
      },
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.stats});

  final ZekrMemoryDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final m = _AnalyticsMetrics.of(context);
    final theme = Theme.of(context);
    final progress = (stats.averageStrength / 100).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(m.large ? 18 : 15.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(m.large ? 24 : 22.r),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _WhiteHeaderRow(
              icon: Icons.insights_rounded,
              title: 'قوة الحفظ العامة',
              subtitle: stats.smartMessage,
            ),
            SizedBox(height: m.large ? 16 : 14.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: m.large ? 8 : 9.h,
                backgroundColor: Colors.white.withOpacity(0.18),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(height: m.large ? 10 : 9.h),
            Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${stats.averageStrength.toStringAsFixed(0)}%',
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: AppTextStyles.display(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0,
                    height: 1.05,
                  ),
                ),
                SizedBox(width: m.large ? 14 : 12.w),
                Expanded(
                  child: Text(
                    'نشاط الشهر: ${stats.activeDaysThisMonth} أيام • ${stats.totalAttemptsThisMonth} محاولة',
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    softWrap: true,
                    style: AppTextStyles.caption(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.82),
                      height: 1.45,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final ZekrMemoryDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final m = _AnalyticsMetrics.of(context);

    final cards = <Widget>[
      _MiniStatCard(
        title: 'مراجعة اليوم',
        value: '${stats.dueReviewItems}',
        icon: Icons.today_rounded,
        color: Theme.of(context).colorScheme.primary,
      ),
      _MiniStatCard(
        title: 'محفوظ بثبات',
        value: '${stats.strongItems}',
        icon: Icons.verified_rounded,
        color: const Color(0xff21C58E),
      ),
      _MiniStatCard(
        title: 'قيد التثبيت',
        value: '${stats.stabilizingItems}',
        icon: Icons.adjust_rounded,
        color: const Color(0xffF59E0B),
      ),
      _MiniStatCard(
        title: 'يحتاج مراجعة',
        value: '${stats.needsReviewItems}',
        icon: Icons.refresh_rounded,
        color: const Color(0xffEF4444),
      ),
    ];

    if (m.large) {
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 720) {
            return Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    textDirection: TextDirection.rtl,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: SizedBox.expand(child: cards[0])),
                      SizedBox(width: m.gap),
                      Expanded(child: SizedBox.expand(child: cards[1])),
                    ],
                  ),
                ),
                SizedBox(height: m.gap),
                IntrinsicHeight(
                  child: Row(
                    textDirection: TextDirection.rtl,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: SizedBox.expand(child: cards[2])),
                      SizedBox(width: m.gap),
                      Expanded(child: SizedBox.expand(child: cards[3])),
                    ],
                  ),
                ),
              ],
            );
          }

          return IntrinsicHeight(
            child: Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < cards.length; i++) ...[
                  Expanded(child: SizedBox.expand(child: cards[i])),
                  if (i != cards.length - 1) SizedBox(width: m.gap),
                ],
              ],
            ),
          );
        },
      );
    }

    return Column(
      children: [
        Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(child: cards[0]),
            SizedBox(width: 8.w),
            Expanded(child: cards[1]),
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(child: cards[2]),
            SizedBox(width: 8.w),
            Expanded(child: cards[3]),
          ],
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final m = _AnalyticsMetrics.of(context);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: m.statCardHeight),
      padding: EdgeInsets.symmetric(
        horizontal: m.large ? 10 : 10.w,
        vertical: m.large ? 10 : 9.h,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(m.large ? 18 : 18.r),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness == Brightness.dark ? 0.10 : 0.025,
            ),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: m.large ? 22 : 20.sp),
            SizedBox(height: m.large ? 5 : 6.h),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: m.statValueSize,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.surface,
                  height: 1.05,
                ),
              ),
            ),
            SizedBox(height: m.large ? 3 : 3.h),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.rtl,
              locale: const Locale('ar'),
              style: TextStyle(
                fontFamily: 'cairo',
                fontSize: m.statTitleSize,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.surface.withOpacity(0.62),
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmartPlanCard extends StatelessWidget {
  const _SmartPlanCard({required this.stats});

  final ZekrMemoryDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final m = _AnalyticsMetrics.of(context);
    final theme = Theme.of(context);

    return _AnalyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _HeaderRow(
            icon: Icons.lightbulb_outline_rounded,
            color: theme.colorScheme.primary,
            title: 'الخطة المقترحة',
            subtitle: 'اقتراح مبني على المراجعات المستحقة وأضعف الأذكار.',
          ),
          SizedBox(height: m.large ? 10 : 10.h),
          _ArabicText(
            stats.recommendedAction,
            fontSize: m.bodyTextSize,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.surface.withOpacity(0.72),
            height: 1.65,
          ),
        ],
      ),
    );
  }
}
