import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/shared/widgets/app_main_components/custom_app_bar.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import 'package:islamic_app/features/memorization/presentation/widgets/mastery_primary_button.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/mastery_snack_bar.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_action_type.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_calculation_method.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_plan_request.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_scope_selection.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_user_type.dart';
import 'memorization_plan_preview_page.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';

class MemorizationGoalPage extends StatefulWidget {
  const MemorizationGoalPage({
    super.key,
    required this.userType,
    required this.actionType,
    required this.scopeSelection,
    this.reviewScope,
    this.reviewFromLearnedOnly = true,
    this.smartReviewDistribution = true,
    this.reviewEveryDays = 1,
    this.reviewTargetDays,
    this.reviewDailyPages,
    this.plannedTestsCount = 0,
    this.includeTests = true,
    this.weeklyRestDays = 0,
  });

  final MemorizationUserType userType;
  final MemorizationActionType actionType;
  final MemorizationScopeSelection scopeSelection;
  final MemorizationScopeSelection? reviewScope;
  final bool reviewFromLearnedOnly;
  final bool smartReviewDistribution;
  final int reviewEveryDays;
  final int? reviewTargetDays;
  final double? reviewDailyPages;
  final int plannedTestsCount;
  final bool includeTests;
  final int weeklyRestDays;

  @override
  State<MemorizationGoalPage> createState() => _MemorizationGoalPageState();
}

class _MemorizationGoalPageState extends State<MemorizationGoalPage> {
  MemorizationCalculationMethod? selectedMethod;
  late bool includeTests;

  final TextEditingController dailyAyahsController = TextEditingController(
    text: '3',
  );
  final TextEditingController dailyPagesController = TextEditingController(
    text: '1',
  );
  final TextEditingController targetDaysController = TextEditingController(
    text: '30',
  );

  @override
  void initState() {
    super.initState();
    includeTests = widget.includeTests;
  }

  @override
  void dispose() {
    dailyAyahsController.dispose();
    dailyPagesController.dispose();
    targetDaysController.dispose();
    super.dispose();
  }

  bool get _isReviewPlan {
    return widget.actionType == MemorizationActionType.reviewOnly ||
        widget.actionType == MemorizationActionType.strengthenAndTest;
  }

  bool get _usesAyahs {
    return widget.scopeSelection.totalAyahs > 0 &&
        widget.scopeSelection.totalPages <= 3;
  }

  String get _title {
    return 'تحب الخطة تتحسب إزاي؟';
  }

  String get _subtitle {
    return 'اختر مقدار يومي، أو مدة نهاية، أو اترك التطبيق يقترح خطة مريحة.';
  }

  void _selectMethod(MemorizationCalculationMethod method) {
    AppHaptics.tap(context);
    setState(() => selectedMethod = method);
  }

  int? _intValue(TextEditingController controller) {
    final value = int.tryParse(controller.text.trim());
    if (value == null || value <= 0) return null;
    return value;
  }

  double? _doubleValue(TextEditingController controller) {
    final normalized = controller.text.trim().replaceAll(',', '.');
    final value = double.tryParse(normalized);
    if (value == null || value <= 0) return null;
    return value;
  }

  void _goNext() {
    AppHaptics.tap(context);

    final method = selectedMethod;
    if (method == null) {
      MasterySnackBar.show(context, message: 'اختار طريقة حساب الخطة أولًا');
      return;
    }

    int? dailyAyahs;
    double? dailyPages;
    int? targetDays;

    if (method == MemorizationCalculationMethod.dailyAmount) {
      if (_usesAyahs && !_isReviewPlan) {
        dailyAyahs = _intValue(dailyAyahsController);
        if (dailyAyahs == null) {
          MasterySnackBar.show(context, message: 'اكتب عدد آيات صحيح');
          return;
        }
      } else {
        dailyPages = _doubleValue(dailyPagesController);
        if (dailyPages == null) {
          MasterySnackBar.show(context, message: 'اكتب عدد صفحات صحيح');
          return;
        }
      }
    }

    if (method == MemorizationCalculationMethod.finishByDuration) {
      targetDays = _intValue(targetDaysController);
      if (targetDays == null) {
        MasterySnackBar.show(context, message: 'اكتب عدد أيام صحيح');
        return;
      }
    }

    final request = MemorizationPlanRequest(
      userType: widget.userType,
      actionType: widget.actionType,
      scope: widget.scopeSelection,
      calculationMethod: method,
      dailyAyahs: dailyAyahs,
      dailyPages: dailyPages,
      targetDays: targetDays,
      reviewScope: widget.reviewScope,
      reviewFromLearnedOnly: widget.reviewFromLearnedOnly,
      smartReviewDistribution: widget.smartReviewDistribution,
      reviewEveryDays: widget.reviewEveryDays,
      reviewTargetDays: widget.reviewTargetDays,
      reviewDailyPages: widget.reviewDailyPages,
      plannedTestsCount: widget.plannedTestsCount,
      includeTests: includeTests,
      weeklyRestDays: widget.weeklyRestDays,
    );

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            MemorizationPlanPreviewPage(request: request),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  Widget _detailsForSelectedMethod() {
    final method = selectedMethod;

    if (method == null ||
        method == MemorizationCalculationMethod.smartSuggestion) {
      return const SizedBox.shrink();
    }

    if (method == MemorizationCalculationMethod.finishByDuration) {
      return _InputCard(
        title: 'مدة الخطة',
        subtitle: 'اكتب عدد الأيام التي تريد إنهاء النطاق خلالها.',
        label: 'عدد الأيام',
        controller: targetDaysController,
      );
    }

    if (_usesAyahs && !_isReviewPlan) {
      return _InputCard(
        title: 'المقدار اليومي',
        subtitle: 'اكتب عدد الآيات التي تريد حفظها يوميًا.',
        label: 'آيات يوميًا',
        controller: dailyAyahsController,
      );
    }

    return _InputCard(
      title: 'المقدار اليومي',
      subtitle: _isReviewPlan
          ? 'اكتب عدد الصفحات التي تريد مراجعتها يوميًا.'
          : 'اكتب عدد الصفحات التي تريد حفظها يوميًا.',
      label: 'صفحات يوميًا',
      controller: dailyPagesController,
      allowDecimal: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(category: CustomAppBarCategory(text: 'حلقة الحفظ')),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _StepHeader(
                      title: _title,
                      subtitle: _subtitle,
                      stepText: '٦ من ٧',
                    ),
                    SizedBox(height: 16.h),
                    _ScopeMiniSummary(scope: widget.scopeSelection),
                    SizedBox(height: 12.h),
                    _MethodCard(
                      method: MemorizationCalculationMethod.smartSuggestion,
                      isSelected:
                          selectedMethod ==
                          MemorizationCalculationMethod.smartSuggestion,
                      onTap: () => _selectMethod(
                        MemorizationCalculationMethod.smartSuggestion,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    _MethodCard(
                      method: MemorizationCalculationMethod.dailyAmount,
                      isSelected:
                          selectedMethod ==
                          MemorizationCalculationMethod.dailyAmount,
                      onTap: () => _selectMethod(
                        MemorizationCalculationMethod.dailyAmount,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    _MethodCard(
                      method: MemorizationCalculationMethod.finishByDuration,
                      isSelected:
                          selectedMethod ==
                          MemorizationCalculationMethod.finishByDuration,
                      onTap: () => _selectMethod(
                        MemorizationCalculationMethod.finishByDuration,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    _detailsForSelectedMethod(),
                    SizedBox(height: 12.h),
                    _TestsToggleCard(
                      value: includeTests,
                      onChanged: (value) {
                        AppHaptics.tap(context);
                        setState(() => includeTests = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            _BottomActionBar(onNext: _goNext),
          ],
        ),
      ),
    );
  }
}

class _TestsToggleCard extends StatelessWidget {
  const _TestsToggleCard({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.12)),
      ),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
        title: Text(
          'إضافة اختبارات للخطة',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          maxLines: 3,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption(context).copyWith(
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.surface,
          ),
        ),
        subtitle: Text(
          value
              ? 'النظام يوزع الاختبارات تلقائيًا، وأنت تختار شكلها وعدد أسئلتها لاحقًا.'
              : 'ستبقى المراجعات كما هي، ولن تُنشأ اختبارات أسبوعية أو ختامية.',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          maxLines: 3,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption(context).copyWith(
            color: theme.colorScheme.surface.withOpacity(0.60),
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _ScopeMiniSummary extends StatelessWidget {
  const _ScopeMiniSummary({required this.scope});

  final MemorizationScopeSelection scope;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.14)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: theme.colorScheme.primary,
            size: 22.sp,
          ),
          SizedBox(width: 9.w),
          Expanded(
            child: Text(
              '${scope.rangeText} • ${scope.sizeText}',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: AppTextStyles.caption(context).copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.surface,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  final MemorizationCalculationMethod method;
  final bool isSelected;
  final VoidCallback onTap;

  IconData get _icon {
    switch (method) {
      case MemorizationCalculationMethod.smartSuggestion:
        return Icons.psychology_alt_rounded;
      case MemorizationCalculationMethod.dailyAmount:
        return Icons.format_list_numbered_rtl_rounded;
      case MemorizationCalculationMethod.finishByDuration:
        return Icons.event_available_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22.r),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary,
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(
              color: isSelected
                  ? primary.withOpacity(0.85)
                  : theme.colorScheme.outline.withOpacity(0.20),
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: primary.withOpacity(isSelected ? 0.16 : 0.08),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(_icon, color: primary, size: 23.sp),
              ),
              SizedBox(width: 11.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      method.title,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.caption(context).copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.surface,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      method.subtitle,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.caption(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.surface.withOpacity(0.62),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 20.w,
                height: 20.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? primary
                        : theme.colorScheme.outline.withOpacity(0.45),
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 14.sp,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.title,
    required this.subtitle,
    required this.label,
    required this.controller,
    this.allowDecimal = false,
  });

  final String title;
  final String subtitle;
  final String label;
  final TextEditingController controller;
  final bool allowDecimal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(22.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.caption(context).copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.surface,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            subtitle,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: AppTextStyles.caption(context).copyWith(
              color: theme.colorScheme.surface.withOpacity(0.58),
              height: 1.45,
            ),
          ),
          SizedBox(height: 10.h),
          TextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(
              decimal: allowDecimal,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
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

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 14.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.12)),
        ),
      ),
      child: MasteryPrimaryButton(
        text: 'التالي',
        icon: Icons.arrow_back_rounded,
        onTap: onNext,
        iconAfterText: true,
      ),
    );
  }
}
