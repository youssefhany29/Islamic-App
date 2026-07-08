import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/shared/widgets/app_main_components/custom_app_bar.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import 'package:islamic_app/features/memorization/presentation/widgets/mastery_primary_button.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/mastery_snack_bar.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/memorization_plan_name_card.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/memorization_plan_summary_card.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_plan_preview_model.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_plan_request.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_plan_preview_builder.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_plan_storage.dart';
import 'memorization_goal_page.dart';
import 'memorization_home_page.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';

class MemorizationPlanPreviewPage extends StatefulWidget {
  const MemorizationPlanPreviewPage({super.key, required this.request});

  final MemorizationPlanRequest request;

  @override
  State<MemorizationPlanPreviewPage> createState() =>
      _MemorizationPlanPreviewPageState();
}

class _MemorizationPlanPreviewPageState
    extends State<MemorizationPlanPreviewPage> {
  String planName = '';
  bool showPlanNameError = false;
  int weeklyRestDays = 0;

  final ScrollController scrollController = ScrollController();
  final FocusNode planNameFocusNode = FocusNode();
  final GlobalKey planNameCardKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    weeklyRestDays = widget.request.safeWeeklyRestDays;
  }

  @override
  void dispose() {
    scrollController.dispose();
    planNameFocusNode.dispose();
    super.dispose();
  }

  MemorizationPlanRequest get _effectiveRequest {
    return widget.request.copyWith(weeklyRestDays: weeklyRestDays);
  }

  String _suggestPlanName(MemorizationPlanPreviewModel plan) {
    final path = plan.pathTitle.trim();
    final scope = plan.scopeTitle.trim();

    if (path.isEmpty && scope.isEmpty) return 'خطة حفظ جديدة';
    if (path.isEmpty) return scope;
    if (scope.isEmpty) return path;

    return '$path - $scope';
  }

  void _openAdvancedEdit() {
    AppHaptics.tap(context);

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => MemorizationGoalPage(
          userType: widget.request.userType,
          actionType: widget.request.actionType,
          scopeSelection: widget.request.scope,
          reviewScope: widget.request.reviewScope,
          reviewFromLearnedOnly: widget.request.reviewFromLearnedOnly,
          reviewEveryDays: widget.request.reviewEveryDays,
          reviewTargetDays: widget.request.reviewTargetDays,
          reviewDailyPages: widget.request.reviewDailyPages,
          plannedTestsCount: widget.request.plannedTestsCount,
          includeTests: widget.request.includesPlannedTests,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  Future<void> _focusPlanNameField() async {
    setState(() => showPlanNameError = true);

    final context = planNameCardKey.currentContext;
    if (context != null) {
      await Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        alignment: 0.12,
      );
    }

    if (!mounted) return;
    planNameFocusNode.requestFocus();
  }

  Future<void> _startPlan(
    BuildContext context,
    MemorizationPlanPreviewModel plan,
  ) async {
    AppHaptics.tap(context);

    final cleanPlanName = planName.trim();

    if (cleanPlanName.isEmpty) {
      await _focusPlanNameField();

      if (!context.mounted) return;

      MasterySnackBar.show(context, message: 'اكتب اسم الخطة هنا أولًا');
      return;
    }

    await MemorizationPlanStorage.activatePlan(
      request: _effectiveRequest,
      preview: plan,
      planName: cleanPlanName,
    );

    if (!context.mounted) return;

    MasterySnackBar.show(context, message: 'تم حفظ الخطة وتجهيز مهمة اليوم');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MemorizationHomePage()),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final request = _effectiveRequest;
    final plan = const MemorizationPlanPreviewBuilder().build(request);
    final suggestedName = _suggestPlanName(plan);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(category: CustomAppBarCategory(text: 'حلقة الحفظ')),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _StepHeader(
                      title: 'خطتك المقترحة',
                      subtitle: 'راجع الملخص، ثم احفظ الخطة وابدأ بهدوء.',
                      stepText: '٧ من ٧',
                    ),
                    SizedBox(height: 16.h),
                    MemorizationPlanNameCard(
                      key: planNameCardKey,
                      initialName: suggestedName,
                      focusNode: planNameFocusNode,
                      showErrorHighlight: showPlanNameError,
                      onChanged: (value) {
                        planName = value;
                        if (showPlanNameError && value.trim().isNotEmpty) {
                          setState(() => showPlanNameError = false);
                        }
                      },
                    ),
                    SizedBox(height: 16.h),
                    MemorizationPlanSummaryCard(plan: plan),
                    SizedBox(height: 12.h),
                    const _AutomaticTestsCard(),
                    SizedBox(height: 12.h),
                    _WeeklyRestDaysCard(
                      value: weeklyRestDays,
                      onChanged: (value) {
                        AppHaptics.tap(context);
                        setState(() => weeklyRestDays = value);
                      },
                    ),
                    SizedBox(height: 16.h),
                    _AdvancedEditCard(onTap: _openAdvancedEdit),
                    SizedBox(height: 16.h),
                    MasteryPrimaryButton(
                      text: 'احفظ الخطة',
                      icon: Icons.arrow_back_rounded,
                      onTap: () => _startPlan(context, plan),
                      iconAfterText: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.title,
    required this.subtitle,
    required this.stepText,
  });

  final String title;
  final String subtitle;
  final String stepText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _StepBadge(text: stepText),
          SizedBox(height: 12.h),
          Text(
            title,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: AppTextStyles.body(context).copyWith(
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.25,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            subtitle,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: AppTextStyles.caption(context).copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.74),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Text(
        text,
        textDirection: TextDirection.rtl,
        style: AppTextStyles.caption(
          context,
        ).copyWith(fontWeight: FontWeight.w900, color: Colors.white, height: 1),
      ),
    );
  }
}

class _AutomaticTestsCard extends StatelessWidget {
  const _AutomaticTestsCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.12)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(
              Icons.fact_check_rounded,
              color: theme.colorScheme.primary,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'إعدادات الاختبارات',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.surface,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'سيتم توزيع الاختبارات تلقائيًا حسب مدة الخطة وتقدمك. يوم الاختبار لا يحتوي على حفظ جديد.',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.surface.withOpacity(0.58),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyRestDaysCard extends StatelessWidget {
  const _WeeklyRestDaysCard({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  String _subtitle() {
    if (value <= 0) {
      return 'بدون أيام راحة ثابتة. تقدر تضيف راحة لو عايز الرحلة أهدى.';
    }

    if (value == 1) {
      return 'يوم راحة واحد أسبوعيًا، والتطبيق يوزعه تلقائيًا.';
    }

    return '$value أيام راحة أسبوعيًا، ولن تكون وراء بعض.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  Icons.self_improvement_rounded,
                  color: theme.colorScheme.primary,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'أيام الراحة',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.caption(context).copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.surface,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      _subtitle(),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.surface.withOpacity(0.58),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            textDirection: TextDirection.rtl,
            children: List.generate(4, (index) {
              final selected = value == index;
              final label = index == 0 ? 'بدون' : '$index يوم';

              return Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: index == 0 ? 0 : 6.w,
                  ),
                  child: Material(
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.background.withOpacity(0.34),
                    borderRadius: BorderRadius.circular(14.r),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14.r),
                      onTap: () => onChanged(index),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 9.h),
                        child: Text(
                          label,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption(context).copyWith(
                            fontWeight: FontWeight.w900,
                            color: selected
                                ? Colors.white
                                : theme.colorScheme.surface.withOpacity(0.68),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _AdvancedEditCard extends StatelessWidget {
  const _AdvancedEditCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.16),
            ),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                Icons.tune_rounded,
                color: theme.colorScheme.primary,
                size: 21.sp,
              ),
              SizedBox(width: 9.w),
              Expanded(
                child: Text(
                  'تغيير الخطة',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.surface,
                  ),
                ),
              ),
              SizedBox(width: 7.w),
              Icon(
                Icons.arrow_back_ios_new_rounded,
                color: theme.colorScheme.surface.withOpacity(0.45),
                size: 14.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
