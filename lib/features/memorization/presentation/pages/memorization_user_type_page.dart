import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/shared/widgets/app_main_components/custom_app_bar.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import 'package:islamic_app/features/memorization/presentation/widgets/mastery_primary_button.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/mastery_snack_bar.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/memorization_user_type_card.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_user_type.dart';
import 'memorization_action_type_page.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class MemorizationUserTypePage extends StatefulWidget {
  const MemorizationUserTypePage({super.key});

  @override
  State<MemorizationUserTypePage> createState() =>
      _MemorizationUserTypePageState();
}

class _MemorizationUserTypePageState extends State<MemorizationUserTypePage> {
  MemorizationUserType? selectedType;

  void _selectType(MemorizationUserType type) {
    AppHaptics.tap(context);
    setState(() => selectedType = type);
  }

  void _goNext() {
    AppHaptics.tap(context);

    final type = selectedType;
    if (type == null) {
      MasterySnackBar.show(
        context,
        message: 'اختار نوع رحلتك أولًا',
      );
      return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => MemorizationActionTypePage(
          userType: type,
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
                padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 100.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _StepHeader(
                      title: 'أنت فين في رحلة الحفظ؟',
                      subtitle:
                          'اختار أقرب وصف ليك عشان نبني خطة مناسبة بدون ضغط.',
                      stepText: '١ من ٦',
                    ),
                    SizedBox(height: 16.h),
                    MemorizationUserTypeCard(
                      type: MemorizationUserType.beginner,
                      isSelected: selectedType == MemorizationUserType.beginner,
                      onTap: () => _selectType(MemorizationUserType.beginner),
                    ),
                    SizedBox(height: 10.h),
                    MemorizationUserTypeCard(
                      type: MemorizationUserType.returning,
                      isSelected:
                          selectedType == MemorizationUserType.returning,
                      onTap: () => _selectType(MemorizationUserType.returning),
                    ),
                    SizedBox(height: 10.h),
                    MemorizationUserTypeCard(
                      type: MemorizationUserType.strong,
                      isSelected: selectedType == MemorizationUserType.strong,
                      onTap: () => _selectType(MemorizationUserType.strong),
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
