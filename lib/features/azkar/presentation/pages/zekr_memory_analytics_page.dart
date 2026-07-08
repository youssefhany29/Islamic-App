import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/shared/widgets/app_main_components/custom_app_bar.dart';

import 'package:islamic_app/features/azkar/data/models/zekr_memory_attempt_model.dart';
import 'package:islamic_app/features/azkar/data/models/zekr_memory_item_state_model.dart';
import 'package:islamic_app/features/azkar/data/services/zekr_memory_progress_service.dart';
import 'zekr_today_review_page.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
part 'zekr_memory_analytics_widgets.dart';
part 'zekr_memory_analytics_overview_widgets.dart';
part 'zekr_memory_analytics_chart_widgets.dart';
part 'zekr_memory_analytics_list_widgets.dart';

bool _analyticsLargeScreen(BuildContext context) {
  final Size size = MediaQuery.sizeOf(context);
  return size.shortestSide >= 600 || (size.width >= 700 && size.height >= 500);
}

class _AnalyticsMetrics {
  const _AnalyticsMetrics({
    required this.large,
    required this.pageHorizontalPadding,
    required this.pageTopPadding,
    required this.pageBottomPadding,
    required this.gap,
    required this.cardPadding,
    required this.cardRadius,
    required this.headerIconBox,
    required this.headerIconSize,
    required this.headerTitleSize,
    required this.headerSubtitleSize,
    required this.bodyTextSize,
    required this.smallTextSize,
    required this.chartHeight,
    required this.statCardHeight,
    required this.statValueSize,
    required this.statTitleSize,
    required this.tilePadding,
    required this.tileRadius,
    required this.tileIconBox,
    required this.tileTitleSize,
    required this.tileSubtitleSize,
  });

  final bool large;
  final double pageHorizontalPadding;
  final double pageTopPadding;
  final double pageBottomPadding;
  final double gap;
  final double cardPadding;
  final double cardRadius;
  final double headerIconBox;
  final double headerIconSize;
  final double headerTitleSize;
  final double headerSubtitleSize;
  final double bodyTextSize;
  final double smallTextSize;
  final double chartHeight;
  final double statCardHeight;
  final double statValueSize;
  final double statTitleSize;
  final double tilePadding;
  final double tileRadius;
  final double tileIconBox;
  final double tileTitleSize;
  final double tileSubtitleSize;

  static _AnalyticsMetrics of(BuildContext context) {
    final bool large = _analyticsLargeScreen(context);
    final Size size = MediaQuery.sizeOf(context);
    final bool compactLarge = large && size.width < 900;

    if (large) {
      return _AnalyticsMetrics(
        large: true,
        pageHorizontalPadding: compactLarge ? 20 : 28,
        pageTopPadding: compactLarge ? 12 : 14,
        pageBottomPadding: 30,
        gap: compactLarge ? 12 : 16,
        cardPadding: compactLarge ? 14 : 16,
        cardRadius: 22,
        headerIconBox: compactLarge ? 40 : 42,
        headerIconSize: compactLarge ? 20 : 22,
        headerTitleSize: compactLarge ? 14 : 15,
        headerSubtitleSize: compactLarge ? 10 : 10.5,
        bodyTextSize: compactLarge ? 11.5 : 12,
        smallTextSize: compactLarge ? 9.5 : 10,
        chartHeight: compactLarge ? 170 : 185,
        statCardHeight: compactLarge ? 82 : 88,
        statValueSize: compactLarge ? 19 : 21,
        statTitleSize: compactLarge ? 10 : 10.5,
        tilePadding: compactLarge ? 10 : 11,
        tileRadius: 16,
        tileIconBox: compactLarge ? 36 : 38,
        tileTitleSize: compactLarge ? 11 : 11.5,
        tileSubtitleSize: compactLarge ? 9 : 9.5,
      );
    }

    return _AnalyticsMetrics(
      large: false,
      pageHorizontalPadding: 14.w,
      pageTopPadding: 8.h,
      pageBottomPadding: 18.h,
      gap: 12.h,
      cardPadding: 14.w,
      cardRadius: 20.r,
      headerIconBox: 40.w,
      headerIconSize: 21.sp,
      headerTitleSize: 14.sp,
      headerSubtitleSize: 10.sp,
      bodyTextSize: 11.sp,
      smallTextSize: 9.sp,
      chartHeight: 170.h,
      statCardHeight: 90.h,
      statValueSize: 17.sp,
      statTitleSize: 9.sp,
      tilePadding: 10.w,
      tileRadius: 14.r,
      tileIconBox: 38.w,
      tileTitleSize: 11.sp,
      tileSubtitleSize: 9.sp,
    );
  }
}

class ZekrMemoryAnalyticsPage extends StatefulWidget {
  const ZekrMemoryAnalyticsPage({super.key});

  @override
  State<ZekrMemoryAnalyticsPage> createState() =>
      _ZekrMemoryAnalyticsPageState();
}

class _ZekrMemoryAnalyticsPageState extends State<ZekrMemoryAnalyticsPage> {
  final ZekrMemoryProgressService _service = const ZekrMemoryProgressService();
  late Future<ZekrMemoryDashboardStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _service.getDashboardStats();
  }

  Future<void> _rebuildAnalysis() async {
    await _service.rebuildStatesFromAttempts();
    if (!mounted) return;

    setState(() {
      _statsFuture = _service.getDashboardStats();
    });
  }

  Future<void> _resetAnalysis() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);

        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: theme.colorScheme.secondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: Text(
              'إعادة ضبط خطة الحفظ؟',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.body(context).copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.surface,
              ),
            ),
            content: Text(
              'سيتم حذف محاولات الحفظ والتحليل ومواعيد المراجعة. لن يتم حذف الأذكار نفسها.',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.caption(context).copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.surface.withOpacity(0.70),
                height: 1.6,
              ),
            ),
            actionsAlignment: MainAxisAlignment.start,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: const Text('إعادة الضبط'),
              ),
            ],
          ),
        );
      },
    );

    if (shouldReset != true) return;

    await _service.clearAll();

    if (!mounted) return;

    setState(() {
      _statsFuture = _service.getDashboardStats();
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
        margin: EdgeInsets.only(left: 24.w, right: 24.w, bottom: 18.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        content: Text(
          'تمت إعادة ضبط خطة الحفظ',
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: AppTextStyles.caption(
            context,
          ).copyWith(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _openTodayReview() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ZekrTodayReviewPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool large = _analyticsLargeScreen(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: const CustomAppBar(
        category: CustomAppBarCategory(text: 'تحليل الحفظ'),
      ),
      body: SafeArea(
        child: FutureBuilder<ZekrMemoryDashboardStats>(
          future: _statsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final stats = snapshot.data ?? ZekrMemoryDashboardStats.empty();

            return RefreshIndicator(
              onRefresh: _rebuildAnalysis,
              child: large
                  ? _LargeAnalyticsBody(
                      stats: stats,
                      onOpenTodayReview: _openTodayReview,
                      onRebuildAnalysis: _rebuildAnalysis,
                      onResetAnalysis: _resetAnalysis,
                    )
                  : _PhoneAnalyticsBody(
                      stats: stats,
                      onOpenTodayReview: _openTodayReview,
                      onRebuildAnalysis: _rebuildAnalysis,
                      onResetAnalysis: _resetAnalysis,
                    ),
            );
          },
        ),
      ),
    );
  }
}
