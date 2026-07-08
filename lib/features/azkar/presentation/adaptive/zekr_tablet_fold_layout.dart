import 'package:flutter/material.dart';

import 'package:islamic_app/features/azkar/presentation/widgets/zekr_daily_journey_card.dart';
import 'package:islamic_app/features/azkar/presentation/widgets/zekr_memory_plan_card.dart'
    as memory_plan;
import 'package:islamic_app/features/azkar/presentation/widgets/zekr_review_calendar_card.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';

class ZekrTabletFoldLayout extends StatelessWidget {
  const ZekrTabletFoldLayout({
    super.key,
    required this.memoryPlanLoading,
    required this.memoryPlanEnabled,
    required this.memoryPlanChanging,
    required this.reviewCalendarRefreshTick,
    required this.onMemoryPlanChanged,
    required this.onOpenAnalytics,
    required this.onOpenTodayReview,
    required this.searchField,
    required this.contentBelowSearch,
  });

  final bool memoryPlanLoading;
  final bool memoryPlanEnabled;
  final bool memoryPlanChanging;
  final int reviewCalendarRefreshTick;
  final ValueChanged<bool> onMemoryPlanChanged;
  final VoidCallback onOpenAnalytics;
  final VoidCallback onOpenTodayReview;
  final Widget searchField;
  final Widget contentBelowSearch;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);

    final bool isFold = size.width >= 600 && size.shortestSide < 600;
    final bool isLandscape = size.width > size.height;

    final double pagePadding = isFold ? 18 : 26;
    final double gap = isFold ? 12 : 16;

    final double topCardHeight = isLandscape
        ? 160
        : isFold
        ? 158
        : 168;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(pagePadding, 12, pagePadding, 26),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final bool sideBySide = constraints.maxWidth >= 700;

              if (!sideBySide) {
                return Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: topCardHeight,
                      child: const ZekrDailyJourneyCard(),
                    ),
                    SizedBox(height: gap),
                    SizedBox(
                      width: double.infinity,
                      height: topCardHeight,
                      child: memoryPlanLoading
                          ? const _LargeLoadingCard()
                          : memory_plan.ZekrMemoryPlanCard(
                              enabled: memoryPlanEnabled,
                              isChanging: memoryPlanChanging,
                              onChanged: onMemoryPlanChanged,
                            ),
                    ),
                  ],
                );
              }

              return SizedBox(
                height: topCardHeight,
                child: Row(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Expanded(child: ZekrDailyJourneyCard()),
                    SizedBox(width: gap),
                    Expanded(
                      child: memoryPlanLoading
                          ? const _LargeLoadingCard()
                          : memory_plan.ZekrMemoryPlanCard(
                              enabled: memoryPlanEnabled,
                              isChanging: memoryPlanChanging,
                              onChanged: onMemoryPlanChanged,
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (memoryPlanEnabled) ...[
            SizedBox(height: gap),
            _MemoryPlanActionsGrid(
              gap: gap,
              onOpenAnalytics: onOpenAnalytics,
              onOpenTodayReview: onOpenTodayReview,
            ),
            SizedBox(height: gap),
            ZekrReviewCalendarCard(
              refreshTick: reviewCalendarRefreshTick,
              onOpenTodayReview: onOpenTodayReview,
            ),
          ],
          SizedBox(height: gap),
          searchField,
          SizedBox(height: gap),
          contentBelowSearch,
        ],
      ),
    );
  }
}

class _LargeLoadingCard extends StatelessWidget {
  const _LargeLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const CircularProgressIndicator(),
    );
  }
}

class _MemoryPlanActionsGrid extends StatelessWidget {
  const _MemoryPlanActionsGrid({
    required this.gap,
    required this.onOpenAnalytics,
    required this.onOpenTodayReview,
  });

  final double gap;
  final VoidCallback onOpenAnalytics;
  final VoidCallback onOpenTodayReview;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final bool isFold = size.width >= 600 && size.shortestSide < 600;
    final bool isLandscape = size.width > size.height;

    final double cardHeight = isLandscape
        ? 150
        : isFold
        ? 150
        : 160;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool sideBySide = constraints.maxWidth >= 680;

        if (!sideBySide) {
          return Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: cardHeight,
                child: _LargeActionCard(
                  title: 'تحليل الحفظ',
                  subtitle: 'تابع الأذكار المحفوظة واللي محتاجة مراجعة.',
                  icon: Icons.insights_rounded,
                  onTap: onOpenAnalytics,
                ),
              ),
              SizedBox(height: gap),
              SizedBox(
                width: double.infinity,
                height: cardHeight,
                child: _LargeActionCard(
                  title: 'مراجعة اليوم',
                  subtitle: 'افتح مراجعات اليوم واختبر حفظك بسرعة.',
                  icon: Icons.task_alt_rounded,
                  onTap: onOpenTodayReview,
                ),
              ),
            ],
          );
        }

        return SizedBox(
          height: cardHeight,
          child: Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _LargeActionCard(
                  title: 'تحليل الحفظ',
                  subtitle: 'تابع الأذكار المحفوظة واللي محتاجة مراجعة.',
                  icon: Icons.insights_rounded,
                  onTap: onOpenAnalytics,
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: _LargeActionCard(
                  title: 'مراجعة اليوم',
                  subtitle: 'افتح مراجعات اليوم واختبر حفظك بسرعة.',
                  icon: Icons.task_alt_rounded,
                  onTap: onOpenTodayReview,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LargeActionCard extends StatelessWidget {
  const _LargeActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          splashColor: theme.colorScheme.primary.withOpacity(0.10),
          highlightColor: theme.colorScheme.primary.withOpacity(0.06),
          child: Ink(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(
                  isDark ? 0.18 : 0.36,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.10 : 0.035),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(
                      isDark ? 0.24 : 0.10,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary, size: 23),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          title,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          locale: const Locale('ar'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body(context).copyWith(
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.surface,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          subtitle,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          locale: const Locale('ar'),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption(context).copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.surface.withOpacity(0.66),
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
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
