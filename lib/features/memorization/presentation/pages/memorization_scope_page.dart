import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/shared/widgets/app_main_components/custom_app_bar.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import 'package:islamic_app/features/memorization/presentation/widgets/mastery_primary_button.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/mastery_snack_bar.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/memorization_scope_option_card.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_action_type.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_scope_option.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_user_type.dart';
import 'memorization_scope_detail_page.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class MemorizationScopePage extends StatefulWidget {
  const MemorizationScopePage({
    super.key,
    required this.userType,
    required this.actionType,
  });

  final MemorizationUserType userType;
  final MemorizationActionType actionType;

  @override
  State<MemorizationScopePage> createState() => _MemorizationScopePageState();
}

class _MemorizationScopePageState extends State<MemorizationScopePage> {
  MemorizationScopeOption? selectedScope;

  List<MemorizationScopeOption> get options {
    return MemorizationScopeOption.optionsFor(
      userType: widget.userType,
      actionType: widget.actionType,
    );
  }

  String get _title {
    final bool review = widget.actionType == MemorizationActionType.reviewOnly ||
        widget.actionType == MemorizationActionType.strengthenAndTest;

    return review ? 'عايز تراجع إيه؟' : 'عايز تحفظ إيه؟';
  }

  String get _subtitle {
    return 'اختار النطاق أولًا، وبعدها هنحدد السورة أو الجزء أو الصفحات بدقة.';
  }

  void _selectScope(MemorizationScopeOption option) {
    AppHaptics.tap(context);
    setState(() => selectedScope = option);
  }

  void _goNext() {
    AppHaptics.tap(context);

    final scope = selectedScope;
    if (scope == null) {
      MasterySnackBar.show(
        context,
        message: 'اختار نطاق الخطة أولًا',
      );
      return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => MemorizationScopeDetailPage(
          userType: widget.userType,
          actionType: widget.actionType,
          scopeOption: scope,
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
                      stepText: '٣ من ٦',
                    ),
                    SizedBox(height: 16.h),
                    ...options.map(
                      (option) => Padding(
                        padding: EdgeInsets.only(bottom: 10.h),
                        child: MemorizationScopeOptionCard(
                          option: option,
                          isSelected: selectedScope?.type == option.type,
                          onTap: () => _selectScope(option),
                        ),
                      ),
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
