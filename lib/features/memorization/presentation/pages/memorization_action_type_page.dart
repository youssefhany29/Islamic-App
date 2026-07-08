import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/shared/widgets/app_main_components/custom_app_bar.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import 'package:islamic_app/features/memorization/presentation/widgets/mastery_primary_button.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/mastery_snack_bar.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_action_type.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_user_type.dart';
import 'memorization_scope_page.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class MemorizationActionTypePage extends StatefulWidget {
  const MemorizationActionTypePage({
    super.key,
    required this.userType,
  });

  final MemorizationUserType userType;

  @override
  State<MemorizationActionTypePage> createState() =>
      _MemorizationActionTypePageState();
}

class _MemorizationActionTypePageState
    extends State<MemorizationActionTypePage> {
  MemorizationActionType? selectedAction;

  List<MemorizationActionType> get options {
    switch (widget.userType) {
      case MemorizationUserType.beginner:
        return const [
          MemorizationActionType.newMemorization,
          MemorizationActionType.newWithReview,
        ];
      case MemorizationUserType.returning:
        return const [
          MemorizationActionType.reviewOnly,
          MemorizationActionType.newWithReview,
        ];
      case MemorizationUserType.strong:
        return const [
          MemorizationActionType.reviewOnly,
          MemorizationActionType.strengthenAndTest,
        ];
    }
  }

  String get _title {
    switch (widget.userType) {
      case MemorizationUserType.beginner:
        return 'تحب تبدأ بإيه؟';
      case MemorizationUserType.returning:
        return 'تحب تثبت محفوظك إزاي؟';
      case MemorizationUserType.strong:
        return 'تحب تحافظ على مستواك إزاي؟';
    }
  }

  String get _subtitle {
    switch (widget.userType) {
      case MemorizationUserType.beginner:
        return 'اختيار بسيط يساعدنا نحدد هل اليوم فيه حفظ فقط أم حفظ مع مراجعة.';
      case MemorizationUserType.returning:
        return 'الأفضل نبدأ بالمراجعة، ويمكن إضافة حفظ بسيط لاحقًا.';
      case MemorizationUserType.strong:
        return 'اختر بين دورة مراجعة ثابتة أو اختبار وتقوية للضعيف.';
    }
  }

  void _selectAction(MemorizationActionType action) {
    AppHaptics.tap(context);
    setState(() => selectedAction = action);
  }

  void _goNext() {
    AppHaptics.tap(context);

    final action = selectedAction;
    if (action == null) {
      MasterySnackBar.show(
        context,
        message: 'اختار نوع العمل أولًا',
      );
      return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => MemorizationScopePage(
          userType: widget.userType,
          actionType: action,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
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
            CustomAppBar(
              category: CustomAppBarCategory(text: 'حلقة الحفظ'),
            ),
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
                      stepText: '٢ من ٦',
                    ),
                    SizedBox(height: 16.h),
                    ...options.map(
                          (action) => Padding(
                        padding: EdgeInsets.only(bottom: 10.h),
                        child: _ActionTypeCard(
                          action: action,
                          userType: widget.userType,
                          isSelected: selectedAction == action,
                          onTap: () => _selectAction(action),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _BottomActionBar(
              onNext: _goNext,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTypeCard extends StatelessWidget {
  const _ActionTypeCard({
    required this.action,
    required this.userType,
    required this.isSelected,
    required this.onTap,
  });

  final MemorizationActionType action;
  final MemorizationUserType userType;
  final bool isSelected;
  final VoidCallback onTap;

  IconData get _icon {
    switch (action) {
      case MemorizationActionType.newMemorization:
        return Icons.menu_book_rounded;
      case MemorizationActionType.reviewOnly:
        return Icons.repeat_rounded;
      case MemorizationActionType.newWithReview:
        return Icons.sync_rounded;
      case MemorizationActionType.strengthenAndTest:
        return Icons.quiz_rounded;
    }
  }

  String get _title {
    if (userType == MemorizationUserType.strong &&
        action == MemorizationActionType.reviewOnly) {
      return 'المراجعة';
    }

    return action.title;
  }

  String get _subtitle {
    if (userType == MemorizationUserType.strong &&
        action == MemorizationActionType.reviewOnly) {
      return 'راجع محفوظك بورد ثابت واختبارات متابعة عند الحاجة.';
    }

    if (userType == MemorizationUserType.strong &&
        action == MemorizationActionType.strengthenAndTest) {
      return 'اختبارات أقوى تكشف المواضع الضعيفة وتبني لك مراجعة مناسبة.';
    }

    return action.subtitle;
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
                width: 46.w,
                height: 46.w,
                decoration: BoxDecoration(
                  color: primary.withOpacity(isSelected ? 0.16 : 0.08),
                  borderRadius: BorderRadius.circular(17.r),
                ),
                child: Icon(_icon, color: primary, size: 24.sp),
              ),
              SizedBox(width: 11.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _title,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
                        color: theme.colorScheme.surface,
                        height: 1.25
),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      _subtitle,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w600,
                        color: theme.colorScheme.surface.withOpacity(0.62),
                        height: 1.45
),
                    ),
                    SizedBox(height: 9.h),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 9.w,
                          vertical: 4.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                        child: Text(
                          action.badge,
                          textDirection: TextDirection.rtl,
                          style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
                            color: primary,
                            height: 1
),
                        ),
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
                    ? Icon(Icons.check_rounded, color: Colors.white, size: 14.sp)
                    : null,
              ),
            ],
          ),
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
              height: 1.25
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
              height: 1.45
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
        style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
          color: Colors.white,
          height: 1
),
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
