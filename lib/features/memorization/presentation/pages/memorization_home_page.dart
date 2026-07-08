import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_active_plan_model.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_plan_storage.dart';
import 'package:islamic_app/features/memorization/presentation/pages/memorization_analytics_page.dart';
import 'package:islamic_app/features/memorization/presentation/pages/memorization_completed_plans_page.dart';
import 'package:islamic_app/features/memorization/presentation/pages/memorization_current_plan_page.dart';
import 'package:islamic_app/features/memorization/presentation/pages/memorization_manual_test_page.dart';
import 'package:islamic_app/features/memorization/presentation/pages/memorization_review_schedule_page.dart';
import 'package:islamic_app/features/memorization/presentation/pages/memorization_user_type_page.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/mastery_hero_card.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/quick_mastery_overview_card.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/session_tools_section.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/today_mastery_task_card.dart';
import '../../../home/presentation/phone/widgets/phone_home_bottom_navigation.dart';
import '../../../home/presentation/phone/widgets/phone_tab_scaffold.dart';

class MemorizationHomePage extends StatefulWidget {
  const MemorizationHomePage({super.key});

  @override
  State<MemorizationHomePage> createState() => _MemorizationHomePageState();
}

class _MemorizationHomePageState extends State<MemorizationHomePage> {
  int refreshKey = 0;

  void _refreshPage() {
    if (!mounted) return;

    setState(() {
      refreshKey++;
    });
  }

  Future<void> _openCreatePlan() async {
    final activePlan = await MemorizationPlanStorage.getActivePlan();
    if (!mounted) return;

    if (activePlan != null && !activePlan.isCompleted) {
      final shouldCreateNewPlan = await _confirmCreatePlan(activePlan);
      if (shouldCreateNewPlan != true) return;
    }

    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MemorizationUserTypePage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );

    _refreshPage();
  }

  Future<void> _openAnalyticsPage() async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MemorizationAnalyticsPage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );

    _refreshPage();
  }

  Future<bool?> _confirmCreatePlan(MemorizationActivePlanModel activePlan) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: colors.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22.r),
            ),
            title: Text(
              'إنشاء خطة جديدة؟',
              textAlign: TextAlign.right,
              style: AppTextStyles.body(context).copyWith(
                color: colors.surface,
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Text(
              'لديك خطة حالية باسم "${activePlan.planName}". عند إنشاء خطة جديدة، ستتوقف الخطة الحالية بدون حذف تقدمك، ويمكنك استرجاعها لاحقًا من الخطط المتوقفة.',
              textAlign: TextAlign.right,
              style: AppTextStyles.caption(context).copyWith(
                color: colors.surface.withOpacity(0.68),
                fontSize: 9.5.sp,
                fontWeight: FontWeight.w600,
                height: 1.55,
              ),
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'استكمال الحالية',
                  style: AppTextStyles.caption(context).copyWith(
                    color: colors.surface.withOpacity(0.58),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'إنشاء جديدة',
                  style: AppTextStyles.caption(context).copyWith(
                    color: colors.primary,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openCurrentPlanPage() async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MemorizationCurrentPlanPage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );

    _refreshPage();
  }

  Future<void> _openCompletedPlansPage() async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MemorizationCompletedPlansPage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );

    _refreshPage();
  }

  Future<void> _openReviewSchedulePage() async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MemorizationReviewSchedulePage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );

    _refreshPage();
  }

  Future<void> _openManualTestPage() async {
    final result = await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MemorizationManualTestPage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );

    if (result == true) {
      _refreshPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PhoneTabScaffold(
      currentTab: PhoneHomeTab.memorization,
      backgroundColor: theme.colorScheme.background,
      body: ColoredBox(
        color: theme.colorScheme.background,
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 96.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MasteryHeroCard(key: ValueKey('masteryHero_$refreshKey')),
                SizedBox(height: 12.h),
                TodayMasteryTaskCard(key: ValueKey('todayTask_$refreshKey')),
                SizedBox(height: 12.h),
                QuickMasteryOverviewCard(
                  key: ValueKey('quickOverview_$refreshKey'),
                ),
                SizedBox(height: 16.h),
                SessionToolsSection(
                  onOpenReviewSchedule: _openReviewSchedulePage,
                  onOpenAnalytics: _openAnalyticsPage,
                  onOpenCurrentPlan: _openCurrentPlanPage,
                  onOpenCompletedPlans: _openCompletedPlansPage,
                  onCreatePlan: _openCreatePlan,
                  onOpenManualTest: _openManualTestPage,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
