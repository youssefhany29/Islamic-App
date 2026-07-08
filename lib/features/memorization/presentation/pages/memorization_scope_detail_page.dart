import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/shared/widgets/app_main_components/custom_app_bar.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import 'package:islamic_app/features/memorization/presentation/widgets/mastery_primary_button.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/mastery_snack_bar.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_action_type.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_scope_option.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_scope_selection.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_user_type.dart';
import 'package:islamic_app/features/memorization/data/services/quran_memorization_scope_calculator.dart';
import 'memorization_goal_page.dart';
import 'memorization_review_settings_page.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class MemorizationScopeDetailPage extends StatefulWidget {
  const MemorizationScopeDetailPage({
    super.key,
    required this.userType,
    required this.actionType,
    required this.scopeOption,
  });

  final MemorizationUserType userType;
  final MemorizationActionType actionType;
  final MemorizationScopeOption scopeOption;

  @override
  State<MemorizationScopeDetailPage> createState() =>
      _MemorizationScopeDetailPageState();
}

class _MemorizationScopeDetailPageState
    extends State<MemorizationScopeDetailPage> {
  final QuranScopeCalculator calculator = const QuranScopeCalculator();

  int selectedSurah = 1;
  int selectedJuz = 1;
  int selectedHizb = 1;

  final TextEditingController fromPageController =
  TextEditingController(text: '1');
  final TextEditingController toPageController =
  TextEditingController(text: '1');

  @override
  void dispose() {
    fromPageController.dispose();
    toPageController.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.scopeOption.type) {
      case MemorizationScopeType.surah:
        return 'اختار السورة';
      case MemorizationScopeType.juz:
        return 'اختار الجزء';
      case MemorizationScopeType.hizb:
        return 'اختار الحزب';
      case MemorizationScopeType.pages:
        return 'حدد الصفحات';
      case MemorizationScopeType.ayahs:
        return 'اختار السورة';
      case MemorizationScopeType.wholeQuran:
        return 'القرآن كامل';
      case MemorizationScopeType.knownMemorized:
        return 'حدد محفوظك';
      case MemorizationScopeType.weakSpots:
        return 'المواضع الضعيفة';
    }
  }

  String get _subtitle {
    switch (widget.scopeOption.type) {
      case MemorizationScopeType.surah:
        return 'اختر السورة كاملة، والتطبيق سيقسمها تلقائيًا حسب خطتك اليومية.';
      case MemorizationScopeType.juz:
        return 'اختر رقم الجزء، وسيتم توزيعه على أيام الخطة بشكل متوازن.';
      case MemorizationScopeType.hizb:
        return 'اختر رقم الحزب، والخطة ستتعامل معه كنطاق متوسط.';
      case MemorizationScopeType.pages:
        return 'حدد صفحة البداية والنهاية بين ١ و٦٠٤.';
      case MemorizationScopeType.ayahs:
        return 'اختر السورة كاملة، والتطبيق سيقسمها تلقائيًا.';
      case MemorizationScopeType.wholeQuran:
        return 'سيتم بناء خطة طويلة موزعة على ٦٠٤ صفحة.';
      case MemorizationScopeType.knownMemorized:
        return 'سنبدأ بتحديد المحفوظ بالتفصيل في التعديل المتقدم.';
      case MemorizationScopeType.weakSpots:
        return 'سيتم استخدام المواضع الضعيفة المسجلة لاحقًا.';
    }
  }

  void _updateSurahDefaults(int surahNumber) {
    final safeSurah = surahNumber.clamp(1, 114).toInt();

    setState(() {
      selectedSurah = safeSurah;
    });
  }

  int _intFrom(TextEditingController controller, int fallback) {
    return int.tryParse(controller.text.trim()) ?? fallback;
  }

  MemorizationScopeSelection? _buildSelection() {
    switch (widget.scopeOption.type) {
      case MemorizationScopeType.surah:
        return calculator.buildSurah(
          surahNumber: selectedSurah,
        );

      case MemorizationScopeType.ayahs:
        return calculator.buildSurah(
          surahNumber: selectedSurah,
        );

      case MemorizationScopeType.juz:
        return calculator.buildJuz(selectedJuz);

      case MemorizationScopeType.hizb:
        return calculator.buildHizb(selectedHizb);

      case MemorizationScopeType.pages:
        final int fromPage = _intFrom(fromPageController, 1);
        final int toPage = _intFrom(toPageController, fromPage);

        if (fromPage < 1 || toPage > 604 || fromPage > toPage) {
          MasterySnackBar.show(
            context,
            message: 'حدد صفحات صحيحة بين ١ و٦٠٤',
          );
          return null;
        }

        return calculator.buildPages(
          fromPage: fromPage,
          toPage: toPage,
        );

      case MemorizationScopeType.wholeQuran:
        return calculator.buildWholeQuran();

      case MemorizationScopeType.knownMemorized:
        return calculator.buildWholeQuran();

      case MemorizationScopeType.weakSpots:
        return calculator.buildWeakSpots();
    }
  }

  void _goNext() {
    AppHaptics.tap(context);

    final selection = _buildSelection();
    if (selection == null) return;

    final needsReviewSettings =
        widget.actionType == MemorizationActionType.newWithReview;

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) {
          if (needsReviewSettings) {
            return MemorizationReviewSettingsPage(
              userType: widget.userType,
              actionType: widget.actionType,
              mainScopeSelection: selection,
            );
          }

          return MemorizationGoalPage(
            userType: widget.userType,
            actionType: widget.actionType,
            scopeSelection: selection,
            reviewFromLearnedOnly: true,
            reviewEveryDays: 1,
            plannedTestsCount: widget.actionType ==
                MemorizationActionType.strengthenAndTest
                ? 3
                : 0,
          );
        },
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  Widget _buildBody() {
    switch (widget.scopeOption.type) {
      case MemorizationScopeType.surah:
        return Column(
          children: [
            _SurahSelector(
              selectedSurah: selectedSurah,
              onChanged: _updateSurahDefaults,
            ),
            SizedBox(height: 12.h),
          ],
        );

      case MemorizationScopeType.ayahs:
        return Column(
          children: [
            _SurahSelector(
              selectedSurah: selectedSurah,
              onChanged: _updateSurahDefaults,
            ),
            SizedBox(height: 12.h),
          ],
        );

      case MemorizationScopeType.juz:
        return _NumberPickerCard(
          title: 'رقم الجزء',
          value: selectedJuz,
          min: 1,
          max: 30,
          onChanged: (value) {
            AppHaptics.tap(context);
            setState(() => selectedJuz = value);
          },
        );

      case MemorizationScopeType.hizb:
        return _NumberPickerCard(
          title: 'رقم الحزب',
          value: selectedHizb,
          min: 1,
          max: 60,
          onChanged: (value) {
            AppHaptics.tap(context);
            setState(() => selectedHizb = value);
          },
        );

      case MemorizationScopeType.pages:
        return _PageRangeInputs(
          fromController: fromPageController,
          toController: toPageController,
        );

      case MemorizationScopeType.wholeQuran:
        return _InfoCard(
          title: 'نطاق الخطة',
          subtitle: 'سيتم حساب الخطة على ٦٠٤ صفحة كاملة.',
          icon: Icons.auto_stories_rounded,
        );

      case MemorizationScopeType.knownMemorized:
        return _InfoCard(
          title: 'محفوظي كاملًا',
          subtitle:
          'سنبدأ مؤقتًا بدورة كاملة، وبعدها نضيف اختيار السور/الأجزاء المحفوظة بالتفصيل.',
          icon: Icons.verified_rounded,
        );

      case MemorizationScopeType.weakSpots:
        return _InfoCard(
          title: 'المواضع الضعيفة',
          subtitle:
          'سيتم ربطها لاحقًا بتقييماتك بعد كل جلسة. لا نفتحها كالفاتحة افتراضيًا.',
          icon: Icons.flag_rounded,
        );
    }
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
                      stepText: '٤ من ٦',
                    ),
                    SizedBox(height: 16.h),
                    _buildBody(),
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

class _SurahSelector extends StatelessWidget {
  const _SurahSelector({
    required this.selectedSurah,
    required this.onChanged,
  });

  final int selectedSurah;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const calculator = QuranScopeCalculator();

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
            'السورة',
            textDirection: TextDirection.rtl,
            style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
              color: theme.colorScheme.surface
),
          ),
          SizedBox(height: 10.h),
          DropdownButtonFormField<int>(
            value: selectedSurah,
            isExpanded: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 10.h,
              ),
            ),
            items: List.generate(114, (index) {
              final number = index + 1;
              return DropdownMenuItem(
                value: number,
                child: Text(
                  '$number - ${calculator.surahName(number)}',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                ),
              );
            }),
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
        ],
      ),
    );
  }
}

class _PageRangeInputs extends StatelessWidget {
  const _PageRangeInputs({
    required this.fromController,
    required this.toController,
  });

  final TextEditingController fromController;
  final TextEditingController toController;

  @override
  Widget build(BuildContext context) {
    return _TwoInputsCard(
      title: 'نطاق الصفحات',
      firstLabel: 'من صفحة',
      secondLabel: 'إلى صفحة',
      firstController: fromController,
      secondController: toController,
      helper: 'الصفحات من ١ إلى ٦٠٤',
    );
  }
}

class _TwoInputsCard extends StatelessWidget {
  const _TwoInputsCard({
    required this.title,
    required this.firstLabel,
    required this.secondLabel,
    required this.firstController,
    required this.secondController,
    required this.helper,
  });

  final String title;
  final String firstLabel;
  final String secondLabel;
  final TextEditingController firstController;
  final TextEditingController secondController;
  final String helper;

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
              color: theme.colorScheme.surface
),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: secondController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(labelText: secondLabel),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: TextField(
                  controller: firstController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(labelText: firstLabel),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            helper,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: AppTextStyles.caption(context).copyWith(
color: theme.colorScheme.surface.withOpacity(0.58)
),
          ),
        ],
      ),
    );
  }
}

class _NumberPickerCard extends StatelessWidget {
  const _NumberPickerCard({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String title;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

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
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Text(
              title,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
                color: theme.colorScheme.surface
),
            ),
          ),
          DropdownButton<int>(
            value: value,
            items: List.generate(max - min + 1, (index) {
              final number = min + index;
              return DropdownMenuItem(
                value: number,
                child: Text('$number'),
              );
            }),
            onChanged: (newValue) {
              if (newValue != null) onChanged(newValue);
            },
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

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
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 26.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  textDirection: TextDirection.rtl,
                  style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
                    color: theme.colorScheme.surface
),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.caption(context).copyWith(
color: theme.colorScheme.surface.withOpacity(0.58),
                    height: 1.45
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