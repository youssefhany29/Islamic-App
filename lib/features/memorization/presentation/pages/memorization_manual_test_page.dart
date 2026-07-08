import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/services/app_haptics.dart';
import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_manual_test_engine.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/mastery_primary_button.dart';
import 'package:islamic_app/features/memorization/test/models/standalone_test_settings.dart';
import 'package:islamic_app/features/memorization/test/pages/memorization_test_session_page.dart';
import 'package:islamic_app/features/quran/reader/quran_reader_helpers.dart';
import 'package:islamic_app/shared/widgets/app_main_components/custom_app_bar.dart';

class MemorizationManualTestPage extends StatefulWidget {
  const MemorizationManualTestPage({super.key});

  @override
  State<MemorizationManualTestPage> createState() =>
      _MemorizationManualTestPageState();
}

class _MemorizationManualTestPageState
    extends State<MemorizationManualTestPage> {
  StandaloneTestScopeType scopeType = StandaloneTestScopeType.wholeSurah;
  StandaloneQuestionMode questionMode = StandaloneQuestionMode.mixed;
  StandaloneDifficulty difficulty = StandaloneDifficulty.medium;
  StandaloneTimerMode timerMode = StandaloneTimerMode.none;

  int selectedSurah = 1;
  int fromAyah = 1;
  int toAyah = 7;
  int selectedJuz = 1;
  int selectedHizb = 1;
  int fromPage = 1;
  int toPage = 1;
  int questionCount = 10;
  int customQuestionCount = 12;
  int secondsPerQuestion = 60;
  int fullTestMinutes = 10;
  int customMinutes = 7;
  bool useCustomQuestionCount = false;
  bool isBuilding = false;

  int get _effectiveQuestionCount {
    return (useCustomQuestionCount ? customQuestionCount : questionCount)
        .clamp(1, 30)
        .toInt();
  }

  int get _effectiveFullMinutes {
    if (timerMode == StandaloneTimerMode.customMinutes) {
      return customMinutes.clamp(1, 180).toInt();
    }
    return fullTestMinutes.clamp(1, 180).toInt();
  }

  int get _surahAyahs {
    int count = 0;
    final surahIndex = selectedSurah - 1;
    for (int index = 0; index < QuranReaderHelpers.totalAyahs; index++) {
      final position = QuranReaderHelpers.getPositionFromGlobalIndex(index);
      if (position.suraIndex == surahIndex) count++;
      if (count > 0 && position.suraIndex > surahIndex) break;
    }
    return count.clamp(1, 286).toInt();
  }

  String get _scopeLabel {
    switch (scopeType) {
      case StandaloneTestScopeType.wholeSurah:
        return 'سورة ${QuranReaderHelpers.getSuraName(selectedSurah - 1)}';
      case StandaloneTestScopeType.surahRange:
        return 'سورة ${QuranReaderHelpers.getSuraName(selectedSurah - 1)} من آية $fromAyah إلى $toAyah';
      case StandaloneTestScopeType.juz:
        return 'جزء $selectedJuz';
      case StandaloneTestScopeType.hizb:
        return 'حزب $selectedHizb';
      case StandaloneTestScopeType.pages:
        return fromPage == toPage
            ? 'صفحة $fromPage'
            : 'الصفحات $fromPage - $toPage';
      case StandaloneTestScopeType.customRange:
        return 'نطاق مخصص';
      case StandaloneTestScopeType.lastMemorized:
        return 'آخر ما حفظته';
      case StandaloneTestScopeType.weakSpots:
        return 'المواضع الضعيفة';
      case StandaloneTestScopeType.previousMistakes:
        return 'أخطاء الاختبارات السابقة';
      case StandaloneTestScopeType.randomWholeQuran:
        return 'مراجعة عشوائية من القرآن كامل';
    }
  }

  String get _timerLabel {
    switch (timerMode) {
      case StandaloneTimerMode.none:
        return 'بدون وقت';
      case StandaloneTimerMode.perQuestion:
        return '$secondsPerQuestion ثانية لكل سؤال';
      case StandaloneTimerMode.fullTest:
        return '$fullTestMinutes دقائق للاختبار كامل';
      case StandaloneTimerMode.customMinutes:
        return '$customMinutes دقائق مخصصة';
    }
  }

  void _applyQuickMode(_QuickMode mode) {
    AppHaptics.tap(context);
    setState(() {
      switch (mode) {
        case _QuickMode.quick:
          questionCount = 5;
          useCustomQuestionCount = false;
          questionMode = StandaloneQuestionMode.mixed;
          difficulty = StandaloneDifficulty.easy;
          timerMode = StandaloneTimerMode.none;
          break;
        case _QuickMode.review:
          questionCount = 10;
          useCustomQuestionCount = false;
          scopeType = StandaloneTestScopeType.lastMemorized;
          questionMode = StandaloneQuestionMode.mixed;
          difficulty = StandaloneDifficulty.medium;
          timerMode = StandaloneTimerMode.none;
          break;
        case _QuickMode.challenge:
          questionCount = 20;
          useCustomQuestionCount = false;
          questionMode = StandaloneQuestionMode.mixed;
          difficulty = StandaloneDifficulty.hard;
          timerMode = StandaloneTimerMode.fullTest;
          fullTestMinutes = 20;
          break;
        case _QuickMode.mistakes:
          questionCount = 10;
          useCustomQuestionCount = false;
          scopeType = StandaloneTestScopeType.weakSpots;
          questionMode = StandaloneQuestionMode.weakSpotsOnly;
          difficulty = StandaloneDifficulty.medium;
          timerMode = StandaloneTimerMode.none;
          break;
        case _QuickMode.self:
          questionCount = 5;
          useCustomQuestionCount = false;
          questionMode = StandaloneQuestionMode.hiddenMushaf;
          difficulty = StandaloneDifficulty.medium;
          timerMode = StandaloneTimerMode.none;
          break;
      }
    });
  }

  Future<void> _startTest() async {
    if (isBuilding) return;

    AppHaptics.tap(context);
    setState(() => isBuilding = true);

    final safeFromAyah = fromAyah.clamp(1, _surahAyahs).toInt();
    final safeToAyah = toAyah.clamp(safeFromAyah, _surahAyahs).toInt();
    final safeFromPage = fromPage.clamp(1, 604).toInt();
    final safeToPage = toPage.clamp(safeFromPage, 604).toInt();
    final request = MemorizationManualTestRequest(
      scopeType: questionMode == StandaloneQuestionMode.weakSpotsOnly
          ? StandaloneTestScopeType.weakSpots
          : scopeType,
      questionMode: questionMode,
      questionCount: _effectiveQuestionCount,
      difficulty: difficulty,
      timerMode: timerMode,
      surahNumber: selectedSurah,
      fromAyah: safeFromAyah,
      toAyah: safeToAyah,
      juzNumber: selectedJuz,
      hizbNumber: selectedHizb,
      fromPage: safeFromPage,
      toPage: safeToPage,
    );

    final task = await const MemorizationManualTestEngine().buildManualTestTask(
      request,
    );

    if (!mounted) return;
    setState(() => isBuilding = false);

    final settings = StandaloneTestSettings(
      id: task.id,
      scopeType: request.scopeType,
      scopeLabel: task.scopeTitle,
      questionMode: questionMode,
      questionCount: _effectiveQuestionCount,
      difficulty: difficulty,
      timerMode: timerMode,
      secondsPerQuestion: secondsPerQuestion.clamp(10, 600).toInt(),
      fullTestMinutes: _effectiveFullMinutes,
      startedAt: DateTime.now(),
      attemptNumber: 1,
    );

    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MemorizationTestSessionPage(
          task: task,
          standaloneSettings: settings,
        ),
      ),
    );

    if (!mounted) return;
    if (completed == true) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: const CustomAppBar(
        category: CustomAppBarCategory(text: 'اختبرني'),
        subtitle: 'اختبار فردي مستقل عن خطة الحفظ',
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 16.h),
                children: [
                  _HeaderCard(
                    scopeLabel: _scopeLabel,
                    modeLabel: questionMode.questionModeLabel,
                    questionCount: _effectiveQuestionCount,
                    difficultyLabel: difficulty.difficultyLabel,
                    timerLabel: _timerLabel,
                  ),
                  SizedBox(height: 12.h),
                  _QuickModesCard(onTap: _applyQuickMode),
                  SizedBox(height: 12.h),
                  _SectionCard(
                    title: 'نطاق الاختبار',
                    subtitle:
                        'النطاق هنا حر للمستخدم، ولا يغير توزيع اختبارات خطة الحفظ.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _WrapChoices<StandaloneTestScopeType>(
                          value: scopeType,
                          values: StandaloneTestScopeType.values,
                          labelOf: _scopeTypeLabel,
                          onChanged: (value) {
                            AppHaptics.tap(context);
                            setState(() => scopeType = value);
                          },
                        ),
                        SizedBox(height: 10.h),
                        _ScopeInputs(
                          scopeType: scopeType,
                          selectedSurah: selectedSurah,
                          selectedJuz: selectedJuz,
                          selectedHizb: selectedHizb,
                          fromAyah: fromAyah,
                          toAyah: toAyah,
                          fromPage: fromPage,
                          toPage: toPage,
                          surahAyahs: _surahAyahs,
                          onSurahChanged: (value) {
                            setState(() {
                              selectedSurah = value;
                              fromAyah = 1;
                              toAyah = _surahAyahs.clamp(1, 7).toInt();
                            });
                          },
                          onJuzChanged: (value) =>
                              setState(() => selectedJuz = value),
                          onHizbChanged: (value) =>
                              setState(() => selectedHizb = value),
                          onFromAyahChanged: (value) =>
                              setState(() => fromAyah = value),
                          onToAyahChanged: (value) =>
                              setState(() => toAyah = value),
                          onFromPageChanged: (value) =>
                              setState(() => fromPage = value),
                          onToPageChanged: (value) =>
                              setState(() => toPage = value),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _SectionCard(
                    title: 'نوع الاختبار',
                    subtitle:
                        'الوضع المختلط يوزع أكثر من نوع سؤال حسب طول النطاق والصعوبة.',
                    child: _WrapChoices<StandaloneQuestionMode>(
                      value: questionMode,
                      values: StandaloneQuestionMode.values,
                      labelOf: (value) => value.questionModeLabel,
                      onChanged: (value) {
                        AppHaptics.tap(context);
                        setState(() => questionMode = value);
                      },
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _SectionCard(
                    title: 'عدد الأسئلة',
                    subtitle:
                        'اختبارات الخطة لا تطلب عدد اختبارات؛ ده خاص بالاختبار الفردي فقط.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _WrapChoices<int>(
                          value: useCustomQuestionCount ? -1 : questionCount,
                          values: const [5, 10, 15, 20, -1],
                          labelOf: (value) => value == -1 ? 'مخصص' : '$value',
                          onChanged: (value) {
                            AppHaptics.tap(context);
                            setState(() {
                              useCustomQuestionCount = value == -1;
                              if (value != -1) questionCount = value;
                            });
                          },
                        ),
                        if (useCustomQuestionCount) ...[
                          SizedBox(height: 10.h),
                          _NumberField(
                            label: 'عدد الأسئلة المخصص',
                            value: customQuestionCount,
                            min: 1,
                            max: 30,
                            onChanged: (value) =>
                                setState(() => customQuestionCount = value),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _SectionCard(
                    title: 'مستوى الصعوبة',
                    subtitle:
                        'الصعوبة تؤثر على طول النطاق المختار وتنوع الأسئلة.',
                    child: _WrapChoices<StandaloneDifficulty>(
                      value: difficulty,
                      values: StandaloneDifficulty.values,
                      labelOf: (value) => value.difficultyLabel,
                      onChanged: (value) {
                        AppHaptics.tap(context);
                        setState(() => difficulty = value);
                      },
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _SectionCard(
                    title: 'الوقت',
                    subtitle:
                        'بدون وقت للتدريب، أو مؤقت لكل سؤال، أو مؤقت للاختبار كامل.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _WrapChoices<StandaloneTimerMode>(
                          value: timerMode,
                          values: StandaloneTimerMode.values,
                          labelOf: _timerModeLabel,
                          onChanged: (value) {
                            AppHaptics.tap(context);
                            setState(() => timerMode = value);
                          },
                        ),
                        if (timerMode == StandaloneTimerMode.perQuestion) ...[
                          SizedBox(height: 10.h),
                          _WrapChoices<int>(
                            value: secondsPerQuestion,
                            values: const [30, 60, 90],
                            labelOf: (value) => '$value ثانية',
                            onChanged: (value) =>
                                setState(() => secondsPerQuestion = value),
                          ),
                        ],
                        if (timerMode == StandaloneTimerMode.fullTest) ...[
                          SizedBox(height: 10.h),
                          _WrapChoices<int>(
                            value: fullTestMinutes,
                            values: const [5, 10, 20],
                            labelOf: (value) => '$value دقائق',
                            onChanged: (value) =>
                                setState(() => fullTestMinutes = value),
                          ),
                        ],
                        if (timerMode == StandaloneTimerMode.customMinutes) ...[
                          SizedBox(height: 10.h),
                          _NumberField(
                            label: 'الدقائق المخصصة',
                            value: customMinutes,
                            min: 1,
                            max: 180,
                            onChanged: (value) =>
                                setState(() => customMinutes = value),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 14.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.background,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.12),
                  ),
                ),
              ),
              child: Opacity(
                opacity: isBuilding ? 0.55 : 1,
                child: MasteryPrimaryButton(
                  text: isBuilding ? 'جاري تجهيز الاختبار' : 'ابدأ الاختبار',
                  icon: Icons.fact_check_rounded,
                  onTap: _startTest,
                  iconAfterText: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _scopeTypeLabel(StandaloneTestScopeType value) {
    switch (value) {
      case StandaloneTestScopeType.wholeSurah:
        return 'سورة كاملة';
      case StandaloneTestScopeType.surahRange:
        return 'من آية إلى آية';
      case StandaloneTestScopeType.juz:
        return 'جزء';
      case StandaloneTestScopeType.hizb:
        return 'حزب/ربع';
      case StandaloneTestScopeType.pages:
        return 'صفحات';
      case StandaloneTestScopeType.customRange:
        return 'نطاق مخصص';
      case StandaloneTestScopeType.lastMemorized:
        return 'آخر ما حفظته';
      case StandaloneTestScopeType.weakSpots:
        return 'المواضع الضعيفة';
      case StandaloneTestScopeType.previousMistakes:
        return 'أخطاء سابقة';
      case StandaloneTestScopeType.randomWholeQuran:
        return 'عشوائي من القرآن';
    }
  }

  String _timerModeLabel(StandaloneTimerMode value) {
    switch (value) {
      case StandaloneTimerMode.none:
        return 'بدون وقت';
      case StandaloneTimerMode.perQuestion:
        return 'وقت لكل سؤال';
      case StandaloneTimerMode.fullTest:
        return 'وقت للاختبار كامل';
      case StandaloneTimerMode.customMinutes:
        return 'وقت مخصص بالدقائق';
    }
  }
}

enum _QuickMode { quick, review, challenge, mistakes, self }

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.scopeLabel,
    required this.modeLabel,
    required this.questionCount,
    required this.difficultyLabel,
    required this.timerLabel,
  });

  final String scopeLabel;
  final String modeLabel;
  final int questionCount;
  final String difficultyLabel;
  final String timerLabel;

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
          Text(
            'اختبار فردي مستقل',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: AppTextStyles.body(
              context,
            ).copyWith(fontWeight: FontWeight.w900, color: Colors.white),
          ),
          SizedBox(height: 6.h),
          Text(
            'اختار النطاق والنوع والوقت بحرية، من غير ما نغيّر منطق خطة الحفظ.',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: AppTextStyles.caption(context).copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.78),
              height: 1.45,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            '$scopeLabel • $modeLabel • $questionCount سؤال • $difficultyLabel • $timerLabel',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            softWrap: true,
            style: AppTextStyles.caption(context).copyWith(
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickModesCard extends StatelessWidget {
  const _QuickModesCard({required this.onTap});

  final ValueChanged<_QuickMode> onTap;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'أوضاع جاهزة',
      subtitle: 'اختيارات سريعة تغيّر الإعدادات، وتقدر تعدّل بعدها عادي.',
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8.w,
        runSpacing: 8.h,
        children: [
          _QuickModeChip(
            'اختبار سريع',
            Icons.flash_on_rounded,
            () => onTap(_QuickMode.quick),
          ),
          _QuickModeChip(
            'اختبار مراجعة',
            Icons.replay_rounded,
            () => onTap(_QuickMode.review),
          ),
          _QuickModeChip(
            'اختبار تحدي',
            Icons.timer_rounded,
            () => onTap(_QuickMode.challenge),
          ),
          _QuickModeChip(
            'اختبار الأخطاء',
            Icons.error_outline_rounded,
            () => onTap(_QuickMode.mistakes),
          ),
          _QuickModeChip(
            'تسميع ذاتي',
            Icons.visibility_off_rounded,
            () => onTap(_QuickMode.self),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(13.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
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
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.surface.withOpacity(0.58),
              height: 1.45,
            ),
          ),
          SizedBox(height: 12.h),
          child,
        ],
      ),
    );
  }
}

class _WrapChoices<T> extends StatelessWidget {
  const _WrapChoices({
    required this.value,
    required this.values,
    required this.labelOf,
    required this.onChanged,
  });

  final T value;
  final List<T> values;
  final String Function(T value) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        for (final item in values)
          _ChoiceChip(
            label: labelOf(item),
            isSelected: item == value,
            onTap: () => onChanged(item),
          ),
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: isSelected
          ? theme.colorScheme.primary
          : theme.colorScheme.background.withOpacity(0.42),
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          child: Text(
            label,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.caption(context).copyWith(
              fontWeight: FontWeight.w900,
              color: isSelected ? Colors.white : theme.colorScheme.surface,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickModeChip extends StatelessWidget {
  const _QuickModeChip(this.label, this.icon, this.onTap);

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primary.withOpacity(0.10),
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: [
              Icon(icon, size: 15.sp, color: theme.colorScheme.primary),
              SizedBox(width: 6.w),
              Text(
                label,
                textDirection: TextDirection.rtl,
                style: AppTextStyles.caption(context).copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScopeInputs extends StatelessWidget {
  const _ScopeInputs({
    required this.scopeType,
    required this.selectedSurah,
    required this.selectedJuz,
    required this.selectedHizb,
    required this.fromAyah,
    required this.toAyah,
    required this.fromPage,
    required this.toPage,
    required this.surahAyahs,
    required this.onSurahChanged,
    required this.onJuzChanged,
    required this.onHizbChanged,
    required this.onFromAyahChanged,
    required this.onToAyahChanged,
    required this.onFromPageChanged,
    required this.onToPageChanged,
  });

  final StandaloneTestScopeType scopeType;
  final int selectedSurah;
  final int selectedJuz;
  final int selectedHizb;
  final int fromAyah;
  final int toAyah;
  final int fromPage;
  final int toPage;
  final int surahAyahs;
  final ValueChanged<int> onSurahChanged;
  final ValueChanged<int> onJuzChanged;
  final ValueChanged<int> onHizbChanged;
  final ValueChanged<int> onFromAyahChanged;
  final ValueChanged<int> onToAyahChanged;
  final ValueChanged<int> onFromPageChanged;
  final ValueChanged<int> onToPageChanged;

  @override
  Widget build(BuildContext context) {
    if (scopeType == StandaloneTestScopeType.juz) {
      return _NumberDropdown(
        label: 'الجزء',
        value: selectedJuz,
        min: 1,
        max: 30,
        onChanged: onJuzChanged,
      );
    }
    if (scopeType == StandaloneTestScopeType.hizb) {
      return _NumberDropdown(
        label: 'الحزب',
        value: selectedHizb,
        min: 1,
        max: 60,
        onChanged: onHizbChanged,
      );
    }
    if (scopeType == StandaloneTestScopeType.pages ||
        scopeType == StandaloneTestScopeType.customRange) {
      return Row(
        children: [
          Expanded(
            child: _NumberDropdown(
              label: 'إلى صفحة',
              value: toPage,
              min: fromPage,
              max: 604,
              onChanged: onToPageChanged,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _NumberDropdown(
              label: 'من صفحة',
              value: fromPage,
              min: 1,
              max: 604,
              onChanged: onFromPageChanged,
            ),
          ),
        ],
      );
    }
    if (scopeType == StandaloneTestScopeType.wholeSurah ||
        scopeType == StandaloneTestScopeType.surahRange) {
      return Column(
        children: [
          _NumberDropdown(
            label: 'السورة',
            value: selectedSurah,
            min: 1,
            max: 114,
            labelBuilder: (value) =>
                '$value - ${QuranReaderHelpers.getSuraName(value - 1)}',
            onChanged: onSurahChanged,
          ),
          if (scopeType == StandaloneTestScopeType.surahRange) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: _NumberDropdown(
                    label: 'إلى آية',
                    value: toAyah.clamp(fromAyah, surahAyahs).toInt(),
                    min: fromAyah,
                    max: surahAyahs,
                    onChanged: onToAyahChanged,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _NumberDropdown(
                    label: 'من آية',
                    value: fromAyah.clamp(1, surahAyahs).toInt(),
                    min: 1,
                    max: surahAyahs,
                    onChanged: onFromAyahChanged,
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

class _NumberDropdown extends StatelessWidget {
  const _NumberDropdown({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.labelBuilder,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String Function(int value)? labelBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safeMin = min.clamp(1, 9999).toInt();
    final safeMax = max.clamp(safeMin, 9999).toInt();
    final safeValue = value.clamp(safeMin, safeMax).toInt();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DropdownButtonFormField<int>(
        value: safeValue,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyles.caption(
            context,
          ).copyWith(color: theme.colorScheme.surface.withOpacity(0.60)),
          filled: true,
          fillColor: theme.colorScheme.background.withOpacity(0.34),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
        ),
        dropdownColor: theme.colorScheme.secondary,
        items: [
          for (int item = safeMin; item <= safeMax; item++)
            DropdownMenuItem<int>(
              value: item,
              child: Text(
                labelBuilder?.call(item) ?? '$item',
                textDirection: TextDirection.rtl,
              ),
            ),
        ],
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: TextFormField(
        initialValue: value.toString(),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          labelText: label,
          helperText: 'من $min إلى $max',
          filled: true,
          fillColor: theme.colorScheme.background.withOpacity(0.34),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (raw) {
          final parsed = int.tryParse(raw) ?? value;
          onChanged(parsed.clamp(min, max).toInt());
        },
      ),
    );
  }
}
