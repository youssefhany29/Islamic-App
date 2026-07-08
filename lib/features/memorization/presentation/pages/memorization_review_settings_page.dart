import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/shared/widgets/app_main_components/custom_app_bar.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import 'package:islamic_app/features/memorization/presentation/widgets/mastery_primary_button.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/mastery_snack_bar.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_action_type.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_scope_selection.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_user_type.dart';
import 'package:islamic_app/features/memorization/data/services/quran_memorization_scope_calculator.dart';
import 'memorization_goal_page.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
part 'memorization_review_settings_widgets.dart';

class MemorizationReviewSettingsPage extends StatefulWidget {
  const MemorizationReviewSettingsPage({
    super.key,
    required this.userType,
    required this.actionType,
    required this.mainScopeSelection,
  });

  final MemorizationUserType userType;
  final MemorizationActionType actionType;
  final MemorizationScopeSelection mainScopeSelection;

  @override
  State<MemorizationReviewSettingsPage> createState() =>
      _MemorizationReviewSettingsPageState();
}

class _MemorizationReviewSettingsPageState
    extends State<MemorizationReviewSettingsPage> {
  final QuranScopeCalculator calculator = const QuranScopeCalculator();

  int reviewEveryDays = 2;
  bool smartReviewDistribution = true;

  _ReviewScopeKind reviewScopeKind = _ReviewScopeKind.juz;
  int selectedReviewSurah = 1;
  int selectedReviewJuz = 30;
  int selectedReviewHizb = 60;

  _ReviewDistributionMode distributionMode = _ReviewDistributionMode.sessions;
  final TextEditingController reviewSessionsController = TextEditingController(
    text: '5',
  );
  final TextEditingController reviewPagesController = TextEditingController(
    text: '1',
  );

  @override
  void dispose() {
    reviewSessionsController.dispose();
    reviewPagesController.dispose();
    super.dispose();
  }

  int? _reviewTargetSessionsValue() {
    if (distributionMode != _ReviewDistributionMode.sessions) return null;

    final value = int.tryParse(reviewSessionsController.text.trim());
    if (value == null || value <= 0) return null;

    return value.clamp(1, 999).toInt();
  }

  double? _reviewDailyPagesValue() {
    if (distributionMode != _ReviewDistributionMode.pagesPerSession) {
      return null;
    }

    final normalized = reviewPagesController.text.trim().replaceAll(',', '.');
    final value = double.tryParse(normalized);
    if (value == null || value <= 0) return null;

    return value.clamp(0.25, 30).toDouble();
  }

  bool get isBeginner {
    return widget.userType == MemorizationUserType.beginner;
  }

  bool get isBeginnerNewWithReview {
    return isBeginner &&
        widget.actionType == MemorizationActionType.newWithReview;
  }

  bool get needsSeparateReviewScope {
    return widget.actionType == MemorizationActionType.newWithReview &&
        !isBeginner;
  }

  bool get _reviewFromLearnedOnly {
    // المبتدئ يراجع ما حفظه داخل الخطة فقط.
    // من حفظ سابقًا يختار نطاق مراجعة مستقل؛ لا نعرض اختيارًا يربكه.
    return !needsSeparateReviewScope;
  }

  String get _title {
    if (widget.actionType == MemorizationActionType.newWithReview) {
      return isBeginner ? 'إعداد المراجعة' : 'تحديد محفوظ المراجعة';
    }

    return 'إعداد المراجعة';
  }

  String get _subtitle {
    if (isBeginner) {
      return 'المراجعة ستكون مما تحفظه داخل الخطة، وبإيقاع خفيف يناسب بداية الرحلة.';
    }

    return 'حدد المحفوظ الذي تريد مراجعته مع الحفظ، ثم اختر وتيرة واضحة لجلسات المراجعة.';
  }

  MemorizationScopeSelection? _selectedReviewScope() {
    if (_reviewFromLearnedOnly) return null;

    switch (reviewScopeKind) {
      case _ReviewScopeKind.surah:
        return calculator.buildSurah(surahNumber: selectedReviewSurah);
      case _ReviewScopeKind.juz:
        return calculator.buildJuz(selectedReviewJuz);
      case _ReviewScopeKind.hizb:
        return calculator.buildHizb(selectedReviewHizb);
      case _ReviewScopeKind.wholeQuran:
        return calculator.buildWholeQuran();
    }
  }

  int _selectedReviewTotalPages() {
    if (_reviewFromLearnedOnly) {
      return _safePages(widget.mainScopeSelection.totalPages);
    }

    switch (reviewScopeKind) {
      case _ReviewScopeKind.surah:
        return _safePages(
          calculator.buildSurah(surahNumber: selectedReviewSurah).totalPages,
        );
      case _ReviewScopeKind.juz:
        return 20;
      case _ReviewScopeKind.hizb:
        return 10;
      case _ReviewScopeKind.wholeQuran:
        return 604;
    }
  }

  int _safePages(int pages) {
    return pages <= 0 ? 1 : pages;
  }

  int _plannedTestsCount() {
    final totalAyahs = widget.mainScopeSelection.totalAyahs;
    final totalPages = widget.mainScopeSelection.totalPages;

    if (widget.actionType != MemorizationActionType.strengthenAndTest &&
        widget.actionType != MemorizationActionType.reviewOnly) {
      return 0;
    }

    if (totalAyahs > 0 && totalAyahs <= 10) return 1;
    if (totalPages <= 3) return 1;
    if (totalPages <= 10) return 2;
    if (totalPages <= 30) return 3;
    if (totalPages <= 100) return 5;
    return 8;
  }

  void _goNext() {
    AppHaptics.tap(context);

    final effectiveSmartDistribution = isBeginnerNewWithReview
        ? true
        : smartReviewDistribution;

    final reviewTargetSessions =
        (isBeginnerNewWithReview || effectiveSmartDistribution)
        ? null
        : _reviewTargetSessionsValue();
    final reviewDailyPages =
        (isBeginnerNewWithReview || effectiveSmartDistribution)
        ? null
        : _reviewDailyPagesValue();
    final effectiveReviewEveryDays = isBeginnerNewWithReview
        ? 3
        : reviewEveryDays;

    if (!isBeginnerNewWithReview &&
        !effectiveSmartDistribution &&
        distributionMode == _ReviewDistributionMode.sessions &&
        reviewTargetSessions == null) {
      MasterySnackBar.show(context, message: 'اكتب عدد جلسات مراجعة صحيح');
      return;
    }

    if (!isBeginnerNewWithReview &&
        !effectiveSmartDistribution &&
        distributionMode == _ReviewDistributionMode.pagesPerSession &&
        reviewDailyPages == null) {
      MasterySnackBar.show(context, message: 'اكتب عدد صفحات مراجعة صحيح');
      return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => MemorizationGoalPage(
          userType: widget.userType,
          actionType: widget.actionType,
          scopeSelection: widget.mainScopeSelection,
          reviewScope: _selectedReviewScope(),
          reviewFromLearnedOnly: _reviewFromLearnedOnly,
          smartReviewDistribution: effectiveSmartDistribution,
          reviewEveryDays: effectiveReviewEveryDays,
          reviewTargetDays: reviewTargetSessions,
          reviewDailyPages: reviewDailyPages,
          plannedTestsCount: _plannedTestsCount(),
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
                      stepText: '٥ من ٧',
                    ),
                    SizedBox(height: 14.h),
                    _InfoSummary(
                      title: 'نطاق الحفظ',
                      subtitle: widget.mainScopeSelection.rangeText,
                      icon: Icons.menu_book_rounded,
                    ),
                    SizedBox(height: 12.h),
                    if (isBeginnerNewWithReview) ...[
                      const _InfoSummary(
                        title: 'المراجعة الذكية',
                        subtitle:
                            'هنراجع آخر ما حفظته بوتيرة ثابتة، ومع كل أسبوعين نرجع على كل ما سبق بهدوء.',
                        icon: Icons.auto_awesome_rounded,
                      ),
                    ] else ...[
                      _FrequencyCard(
                        value: reviewEveryDays,
                        smartValue: smartReviewDistribution,
                        onSmartChanged: (value) {
                          AppHaptics.tap(context);
                          setState(() => smartReviewDistribution = value);
                        },
                        onChanged: (value) {
                          AppHaptics.tap(context);
                          setState(() {
                            smartReviewDistribution = false;
                            reviewEveryDays = value;
                          });
                        },
                      ),
                    ],
                    SizedBox(height: 12.h),
                    if (needsSeparateReviewScope) ...[
                      _ReviewScopeCard(
                        calculator: calculator,
                        kind: reviewScopeKind,
                        selectedSurah: selectedReviewSurah,
                        selectedJuz: selectedReviewJuz,
                        selectedHizb: selectedReviewHizb,
                        onKindChanged: (value) {
                          AppHaptics.tap(context);
                          setState(() => reviewScopeKind = value);
                        },
                        onSurahChanged: (value) {
                          AppHaptics.tap(context);
                          setState(() => selectedReviewSurah = value);
                        },
                        onJuzChanged: (value) {
                          AppHaptics.tap(context);
                          setState(() => selectedReviewJuz = value);
                        },
                        onHizbChanged: (value) {
                          AppHaptics.tap(context);
                          setState(() => selectedReviewHizb = value);
                        },
                      ),
                    ] else
                      _InfoSummary(
                        title: 'مصدر المراجعة',
                        subtitle:
                            'ستكون المراجعة من الآيات التي تحفظها داخل هذه الخطة، وبمقدار خفيف يناسب البداية.',
                        icon: Icons.repeat_rounded,
                      ),
                    if (!isBeginnerNewWithReview &&
                        !smartReviewDistribution) ...[
                      SizedBox(height: 12.h),
                      _ReviewDistributionCard(
                        mode: distributionMode,
                        sessionsController: reviewSessionsController,
                        pagesController: reviewPagesController,
                        reviewEveryDays: reviewEveryDays,
                        reviewTotalPages: _selectedReviewTotalPages(),
                        onModeChanged: (value) {
                          AppHaptics.tap(context);
                          setState(() => distributionMode = value);
                        },
                      ),
                    ] else if (!isBeginnerNewWithReview) ...[
                      SizedBox(height: 12.h),
                      const _InfoSummary(
                        title: 'توزيع المراجعة',
                        subtitle:
                            'سنوزع جلسات المراجعة تلقائيًا حسب حجم الخطة وعدد أيام الحفظ، مع مراجعة شاملة كل فترة.',
                        icon: Icons.auto_awesome_rounded,
                      ),
                    ],
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
