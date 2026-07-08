import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/services/app_haptics.dart';
import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_active_plan_model.dart';
import 'package:islamic_app/features/memorization/data/services/planning/memorization_plan_rescheduler.dart';
import 'package:islamic_app/features/memorization/presentation/dialogs/memorization_edit_plan_dialog.dart';
import 'package:islamic_app/features/memorization/presentation/pages/memorization_completed_plans_page.dart';
import 'package:islamic_app/features/memorization/presentation/pages/memorization_user_type_page.dart';
import 'package:islamic_app/features/memorization/presentation/pages/memorization_weak_spots_page.dart';
import 'package:islamic_app/features/memorization/presentation/pages/results/memorization_course_certificate_page.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_plan_storage.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_plan_completion_service.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_plan_progress_resolver.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_session_result_storage.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/current_plan/current_plan_actions_card.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/current_plan/current_plan_certificate_card.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/current_plan/current_plan_archived_plans_card.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/current_plan/current_plan_hero_card.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/current_plan/current_plan_hero_data.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/current_plan/current_plan_next_session_card.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/current_plan/current_plan_today_review_card.dart';
import 'package:islamic_app/features/quran/reader/qpc_connected_mushaf_page.dart';
import 'package:islamic_app/features/quran/reader/quran_page_mapper.dart';
import 'package:islamic_app/shared/widgets/app_main_components/custom_app_bar.dart';

import '../widgets/analytics/analytics_ui.dart';

class MemorizationCurrentPlanPage extends StatefulWidget {
  const MemorizationCurrentPlanPage({super.key});

  @override
  State<MemorizationCurrentPlanPage> createState() =>
      _MemorizationCurrentPlanPageState();
}

class _MemorizationCurrentPlanPageState
    extends State<MemorizationCurrentPlanPage> {
  late Future<CurrentPlanHeroData?> pageFuture;
  bool isPlanActionBusy = false;
  bool missedDayCheckDone = false;

  @override
  void initState() {
    super.initState();
    pageFuture = CurrentPlanHeroData.load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkMissedDays());
  }

  void _refreshPage() {
    if (!mounted) return;

    setState(() {
      pageFuture = CurrentPlanHeroData.load();
    });
  }

  Future<void> _pauseCurrentPlan(MemorizationActivePlanModel plan) async {
    if (isPlanActionBusy) return;

    AppHaptics.tap(context);

    final confirmed = await _showPlanActionDialog(
      title: 'إيقاف الخطة مؤقتًا؟',
      message:
          'سيتم نقل "${plan.planName}" إلى الخطط المتوقفة، ويمكنك استرجاعها لاحقًا بدون حذف تقدمك.',
      confirmText: 'إيقاف',
      confirmColor: Theme.of(context).colorScheme.primary,
    );

    if (confirmed != true || !mounted) return;

    setState(() => isPlanActionBusy = true);

    try {
      await MemorizationPlanStorage.stopActivePlan();
    } finally {
      if (mounted) {
        setState(() {
          isPlanActionBusy = false;
          pageFuture = CurrentPlanHeroData.load();
        });
      }
    }
  }

  Future<void> _deleteCurrentPlan(MemorizationActivePlanModel plan) async {
    if (isPlanActionBusy) return;

    AppHaptics.tap(context);

    final confirmed = await _showPlanActionDialog(
      title: 'حذف الخطة الحالية نهائيًا؟',
      message:
          'سيتم حذف "${plan.planName}" من الخطة الحالية ومن قوائم الحفظ. هذا الإجراء لا يمكن التراجع عنه.',
      confirmText: 'حذف',
      confirmColor: Colors.redAccent,
    );

    if (confirmed != true || !mounted) return;

    setState(() => isPlanActionBusy = true);

    try {
      await MemorizationPlanStorage.deletePlan(plan.id);
    } finally {
      if (mounted) {
        setState(() {
          isPlanActionBusy = false;
          pageFuture = CurrentPlanHeroData.load();
        });
      }
    }
  }

  Future<void> _rescheduleCurrentPlan(MemorizationActivePlanModel plan) async {
    if (isPlanActionBusy) return;
    AppHaptics.tap(context);

    final request = await showDialog<MemorizationPlanRescheduleRequest>(
      context: context,
      builder: (_) => MemorizationEditPlanDialog(plan: plan),
    );

    if (request == null || !mounted) return;

    setState(() => isPlanActionBusy = true);
    try {
      await const MemorizationPlanRescheduler().rescheduleActivePlan(request);
    } finally {
      if (mounted) {
        setState(() {
          isPlanActionBusy = false;
          pageFuture = CurrentPlanHeroData.load();
        });
      }
    }
  }

  Future<void> _checkMissedDays() async {
    if (missedDayCheckDone || !mounted) return;
    missedDayCheckDone = true;

    final plan = await MemorizationPlanStorage.getActivePlan();
    if (plan == null || !mounted || plan.currentPlanDay <= 1) return;
    if (plan.isCompleted) return;
    final results = await MemorizationSessionResultStorage.getResults();
    final completion = const MemorizationPlanCompletionService().evaluate(
      plan: plan,
      results: results,
    );
    if (completion.isCompleted) return;
    final progress = const MemorizationPlanProgressResolver().resolve(
      plan: plan,
      results: results,
      today: DateTime.now(),
    );
    final completed =
        plan.actionTypeName == 'newMemorization' ||
            plan.actionTypeName == 'newWithReview'
        ? progress.completedNewCount
        : progress.completedReviewCount;
    final safeTargetDays = plan.targetLearningDays.clamp(1, 3650).toInt();
    final learningDay = plan.currentPlanDay.clamp(1, safeTargetDays).toInt();
    final expectedByNow =
        ((learningDay / safeTargetDays) * plan.learningSessionsCount).floor();
    final missed = expectedByNow - completed;
    if (missed <= 0 || !mounted) return;

    final strategy = await showDialog<MemorizationMissedDayStrategy>(
      context: context,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SimpleDialog(
            backgroundColor:
                Theme.of(dialogContext).brightness == Brightness.dark
                ? colors.secondary
                : Colors.white,
            title: Text(
              'فاتك $missed من مهام الخطة',
              style: AppTextStyles.body(
                dialogContext,
              ).copyWith(color: colors.surface, fontWeight: FontWeight.w900),
            ),
            children: [
              _missedDayOption(
                dialogContext,
                title: 'إعادة توزيع تلقائي',
                subtitle: 'نوزع المتبقي بدون تكديس اليوم.',
                value: MemorizationMissedDayStrategy.automatic,
              ),
              _missedDayOption(
                dialogContext,
                title: 'ضغط خفيف',
                subtitle: 'زيادة بسيطة في الحمل مع سقف يومي.',
                value: MemorizationMissedDayStrategy.lightCompression,
              ),
              _missedDayOption(
                dialogContext,
                title: 'ضغط قوي',
                subtitle: 'تقليل المدة مع جلسات أكثر، بدون تجاوز السقف.',
                value: MemorizationMissedDayStrategy.strongCompression,
              ),
              _missedDayOption(
                dialogContext,
                title: 'تأجيل نهاية الخطة',
                subtitle: 'نضيف الأيام الفائتة إلى نهاية التقويم.',
                value: MemorizationMissedDayStrategy.extendPlan,
              ),
            ],
          ),
        );
      },
    );
    if (strategy == null || !mounted) return;

    setState(() => isPlanActionBusy = true);
    try {
      await const MemorizationPlanRescheduler().handleMissedDays(
        missedDays: missed,
        strategy: strategy,
      );
    } finally {
      if (mounted) {
        setState(() {
          isPlanActionBusy = false;
          pageFuture = CurrentPlanHeroData.load();
        });
      }
    }
  }

  Widget _missedDayOption(
    BuildContext dialogContext, {
    required String title,
    required String subtitle,
    required MemorizationMissedDayStrategy value,
  }) {
    return SimpleDialogOption(
      onPressed: () => Navigator.pop(dialogContext, value),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          SizedBox(height: 3.h),
          Text(subtitle, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Future<bool?> _showPlanActionDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: theme.brightness == Brightness.dark
                ? colors.secondary
                : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22.r),
            ),
            title: Text(
              title,
              textAlign: TextAlign.right,
              style: AppTextStyles.body(context).copyWith(
                color: colors.surface,
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Text(
              message,
              textAlign: TextAlign.right,
              style: AppTextStyles.caption(context).copyWith(
                color: colors.surface.withOpacity(0.68),
                fontSize: 9.5.sp,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'إلغاء',
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
                  confirmText,
                  style: AppTextStyles.caption(context).copyWith(
                    color: confirmColor,
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

  Future<void> _openCreatePlanPage() async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MemorizationUserTypePage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
    _refreshPage();
  }

  Future<void> _openWeakSpotsPage() async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MemorizationWeakSpotsPage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
    _refreshPage();
  }

  Future<void> _openCompletedPlansPage() async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MemorizationCompletedPlansPage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
    _refreshPage();
  }

  Future<void> _openQuranAtPlanStart(MemorizationActivePlanModel plan) async {
    await QuranPageMapper.load();
    final pageNumber = QuranPageMapper.getPageNumberForGlobalAyah(
      plan.scopeStartGlobalAyahIndex,
    );
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QpcConnectedMushafPage(
          initialPage: pageNumber,
          initialGlobalAyahIndex: plan.scopeStartGlobalAyahIndex,
          saveAsMushafOpenProgress: true,
        ),
      ),
    );
    _refreshPage();
  }

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
                category: CustomAppBarCategory(text: 'الخطة الحالية'),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 16.h),
                child: FutureBuilder<CurrentPlanHeroData?>(
                  future: pageFuture,
                  builder: (context, snapshot) {
                    final data = snapshot.data;

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const _CurrentPlanLoadingHero();
                    }

                    if (data == null) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const CurrentPlanEmptyHeroCard(),
                          CurrentPlanArchivedPlansCard(
                            onPlanReactivated: _refreshPage,
                            topSpacing: 12.h,
                          ),
                        ],
                      );
                    }

                    if (data.isCompleted) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CurrentPlanHeroCard(data: data),
                          SizedBox(height: 12.h),
                          _CompletedPlanStateCard(
                            onCertificateTap: data.certificate == null
                                ? null
                                : () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            MemorizationCourseCertificatePage(
                                              certificate: data.certificate!,
                                              onOpenCompletedPlans:
                                                  _openCompletedPlansPage,
                                            ),
                                      ),
                                    );
                                  },
                            onWeakSpotsTap: _openWeakSpotsPage,
                            onCreatePlanTap: _openCreatePlanPage,
                            onOpenQuranTap: () =>
                                _openQuranAtPlanStart(data.plan),
                            onCompletedPlansTap: _openCompletedPlansPage,
                          ),
                          if (data.certificate != null) ...[
                            SizedBox(height: 12.h),
                            CurrentPlanCertificateCard(
                              certificate: data.certificate!,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        MemorizationCourseCertificatePage(
                                          certificate: data.certificate!,
                                          onOpenCompletedPlans:
                                              _openCompletedPlansPage,
                                        ),
                                  ),
                                );
                              },
                            ),
                          ],
                          CurrentPlanArchivedPlansCard(
                            onPlanReactivated: _refreshPage,
                            topSpacing: 12.h,
                          ),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CurrentPlanHeroCard(data: data),
                        SizedBox(height: 12.h),
                        CurrentPlanActionsCard(
                          planName: data.plan.planName,
                          isBusy: isPlanActionBusy,
                          onRescheduleTap: () =>
                              _rescheduleCurrentPlan(data.plan),
                          onPauseTap: () => _pauseCurrentPlan(data.plan),
                          onDeleteTap: () => _deleteCurrentPlan(data.plan),
                        ),
                        SizedBox(height: 12.h),
                        CurrentPlanNextSessionCard(
                          task: data.nextTask,
                          onSessionFinished: _refreshPage,
                        ),
                        if (data.certificate != null) ...[
                          SizedBox(height: 12.h),
                          CurrentPlanCertificateCard(
                            certificate: data.certificate!,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      MemorizationCourseCertificatePage(
                                        certificate: data.certificate!,
                                      ),
                                ),
                              );
                            },
                          ),
                        ],
                        if (data.todayReviewPageLabels.isNotEmpty) ...[
                          SizedBox(height: 12.h),
                          CurrentPlanTodayReviewCard(
                            pageLabels: data.todayReviewPageLabels,
                          ),
                        ],
                        CurrentPlanArchivedPlansCard(
                          onPlanReactivated: _refreshPage,
                          topSpacing: 12.h,
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

class _CompletedPlanStateCard extends StatelessWidget {
  const _CompletedPlanStateCard({
    required this.onCertificateTap,
    required this.onWeakSpotsTap,
    required this.onCreatePlanTap,
    required this.onOpenQuranTap,
    required this.onCompletedPlansTap,
  });

  final VoidCallback? onCertificateTap;
  final VoidCallback onWeakSpotsTap;
  final VoidCallback onCreatePlanTap;
  final VoidCallback onOpenQuranTap;
  final VoidCallback onCompletedPlansTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? colors.secondary : Colors.white;
    final textColor = isDark ? colors.surface : const Color(0xFF18385F);
    final borderColor = isDark
        ? colors.outline.withOpacity(0.14)
        : const Color(0xFFE7EDF5);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: borderColor, width: 0.8.w),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.verified_rounded,
                    color: colors.primary,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'تم إتمام خطة الحفظ',
                        textAlign: TextAlign.right,
                        style: AppTextStyles.body(context).copyWith(
                          color: textColor,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'أحسنت، أتممت خطة الحفظ بنجاح. يمكنك الآن عرض شهادة الإتمام الرمزية أو بدء خطة جديدة.',
                        textAlign: TextAlign.right,
                        softWrap: true,
                        style: AppTextStyles.caption(context).copyWith(
                          color: textColor.withOpacity(0.68),
                          fontSize: 13.sp,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              alignment: WrapAlignment.end,
              children: [
                _CompletedPlanButton(
                  label: 'عرض الشهادة',
                  icon: Icons.workspace_premium_rounded,
                  onTap: onCertificateTap,
                  color: colors.primary,
                  borderColor: borderColor,
                ),
                _CompletedPlanButton(
                  label: 'مراجعة المواضع الضعيفة',
                  icon: Icons.healing_rounded,
                  onTap: onWeakSpotsTap,
                  color: colors.primary,
                  borderColor: borderColor,
                ),
                _CompletedPlanButton(
                  label: 'بدء خطة جديدة',
                  icon: Icons.add_task_rounded,
                  onTap: onCreatePlanTap,
                  color: colors.primary,
                  borderColor: borderColor,
                ),
                _CompletedPlanButton(
                  label: 'فتح القرآن',
                  icon: Icons.menu_book_rounded,
                  onTap: onOpenQuranTap,
                  color: colors.primary,
                  borderColor: borderColor,
                ),
                _CompletedPlanButton(
                  label: 'الخطط المكتملة',
                  icon: Icons.workspace_premium_rounded,
                  onTap: onCompletedPlansTap,
                  color: colors.primary,
                  borderColor: borderColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedPlanButton extends StatelessWidget {
  const _CompletedPlanButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.color,
    required this.borderColor,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final effectiveColor = enabled ? color : color.withOpacity(0.34);

    return Material(
      color: color.withOpacity(enabled ? 0.08 : 0.04),
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 9.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: borderColor, width: 0.8.w),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: [
              Icon(icon, color: effectiveColor, size: 16.sp),
              SizedBox(width: 6.w),
              Text(
                label,
                textDirection: TextDirection.rtl,
                style: AppTextStyles.caption(context).copyWith(
                  color: effectiveColor,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentPlanLoadingHero extends StatelessWidget {
  const _CurrentPlanLoadingHero();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      height: 172.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withOpacity(0.20), width: 0.9.w),
      ),
      child: Center(
        child: SizedBox(
          width: 22.w,
          height: 22.w,
          child: CircularProgressIndicator(
            strokeWidth: 2.4.w,
            valueColor: AlwaysStoppedAnimation<Color>(
              colors.onPrimary.withOpacity(0.78),
            ),
          ),
        ),
      ),
    );
  }
}
