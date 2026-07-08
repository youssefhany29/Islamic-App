import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import 'package:islamic_app/features/hadith/data/models/hadith_item_model.dart';
import 'package:islamic_app/features/hadith/data/models/hadith_memory_attempt_model.dart';
import 'package:islamic_app/features/hadith/data/services/hadith_memory_progress_service.dart';
import 'package:islamic_app/features/hadith/data/notifications/hadith_notification_scheduler.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';

enum HadithMemoryMode { read, train, test }

class HadithMemoryTrainingCard extends StatefulWidget {
  const HadithMemoryTrainingCard({
    super.key,
    required this.item,
    this.categoryId,
    this.categoryTitle,
    this.initiallyExpanded = false,
  });

  final HadithItemModel item;
  final String? categoryId;
  final String? categoryTitle;
  final bool initiallyExpanded;

  @override
  State<HadithMemoryTrainingCard> createState() =>
      _HadithMemoryTrainingCardState();
}

class _HadithMemoryTrainingCardState extends State<HadithMemoryTrainingCard> {
  final HadithMemoryProgressService _memoryProgressService =
      const HadithMemoryProgressService();

  late bool _isExpanded;

  HadithMemoryMode _mode = HadithMemoryMode.read;
  bool _showAnswer = false;
  bool _isSavingRating = false;
  HadithMemoryRating? _lastRating;

  bool get _canSaveRating {
    return widget.categoryId != null && widget.categoryTitle != null;
  }

  bool _isLargeScreen(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    return size.shortestSide >= 600 ||
        (size.width >= 700 && size.height >= 500);
  }

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  void _toggleExpanded() {
    AppHaptics.tap(context);

    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _changeMode(HadithMemoryMode mode) {
    AppHaptics.tap(context);

    setState(() {
      _mode = mode;
      _showAnswer = false;
    });
  }

  HadithPracticeMode _practiceMode() {
    switch (_mode) {
      case HadithMemoryMode.read:
        return HadithPracticeMode.read;
      case HadithMemoryMode.train:
        return HadithPracticeMode.train;
      case HadithMemoryMode.test:
        return HadithPracticeMode.test;
    }
  }

  Future<void> _saveRating(HadithMemoryRating rating) async {
    if (_isSavingRating || !_canSaveRating) return;

    AppHaptics.tap(context);

    setState(() {
      _isSavingRating = true;
    });

    await _memoryProgressService.saveAttempt(
      HadithMemoryAttemptModel(
        id: 'training_${DateTime.now().millisecondsSinceEpoch}',
        itemId: widget.item.id,
        categoryId: widget.categoryId!,
        itemTitle: widget.item.title ?? 'حديث',
        categoryTitle: widget.categoryTitle!,
        rating: rating,
        createdAt: DateTime.now(),
        repetitionCount: widget.item.count <= 0 ? 1 : widget.item.count,
        practiceMode: _practiceMode(),
      ),
    );

    await const HadithNotificationScheduler()
        .refreshMemoryReviewReminderFromPrefs();

    if (!mounted) return;

    setState(() {
      _isSavingRating = false;
      _lastRating = rating;
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xff171B26),
        duration: const Duration(milliseconds: 1200),
        margin: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            _isLargeScreen(context) ? 18 : 16.r,
          ),
        ),
        content: Text(
          rating == HadithMemoryRating.mastered
              ? 'ممتاز، اتسجل كمحفوظ بثقة.'
              : rating == HadithMemoryRating.partial
              ? 'تمام، هنراجعه قريب للتثبيت.'
              : 'ولا يهمك، هيفضل قريب في خطة المراجعة.',
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: AppTextStyles.caption(
            context,
          ).copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  String _maskedTrainingText(String text) {
    final List<String> parts = text
        .split(RegExp(r'\n\s*\n'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length <= 1) {
      return _maskSinglePart(text);
    }

    return parts.map(_maskSinglePart).join('\n\n');
  }

  String _maskSinglePart(String text) {
    final List<String> words = text.trim().split(RegExp(r'\s+'));

    if (words.length <= 6) {
      return text;
    }

    final int visibleCount = (words.length * 0.65).floor().clamp(
      3,
      words.length,
    );
    final int hiddenCount = words.length - visibleCount;

    if (hiddenCount <= 0) {
      return text;
    }

    final String visibleWords = words.take(visibleCount).join(' ');
    final String hiddenWords = List.generate(
      hiddenCount,
      (_) => '____',
    ).join(' ');

    return '$visibleWords $hiddenWords';
  }

  String _testText(String text) {
    final List<String> parts = text
        .split(RegExp(r'\n\s*\n'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length <= 1) {
      return _hiddenTestBlock(text);
    }

    return parts.map(_hiddenTestBlock).join('\n\n');
  }

  String _hiddenTestBlock(String text) {
    final List<String> words = text.trim().split(RegExp(r'\s+'));

    if (words.isEmpty) {
      return 'حاول تسترجع النص من حفظك...';
    }

    final int hiddenCount = words.length.clamp(3, 18);

    return List.generate(hiddenCount, (_) => '____').join(' ');
  }

  String _displayedText() {
    final text = widget.item.text;

    switch (_mode) {
      case HadithMemoryMode.read:
        return text;
      case HadithMemoryMode.train:
        return _maskedTrainingText(text);
      case HadithMemoryMode.test:
        return _showAnswer ? text : _testText(text);
    }
  }

  String _modeTitle() {
    switch (_mode) {
      case HadithMemoryMode.read:
        return 'اقرأ الحديث كاملًا بهدوء';
      case HadithMemoryMode.train:
        return 'حاول تكمل الكلمات المخفية';
      case HadithMemoryMode.test:
        return _showAnswer ? 'راجع الإجابة' : 'اختبر نفسك بدون ضغط';
    }
  }

  String _ratingHint() {
    if (_lastRating == null) {
      return 'بعد التدريب قيّم حفظك، والتطبيق هيحدد ميعاد المراجعة القادمة.';
    }

    return 'تم تسجيل آخر تقييم: ${_lastRating!.label}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final bool isLargeScreen = _isLargeScreen(context);

    final double cardPadding = isLargeScreen ? 14 : 14.w;
    final double cardRadius = isLargeScreen ? 22 : 20.r;
    final double headerMinHeight = isLargeScreen ? 62 : 64.h;
    final double iconBox = isLargeScreen ? 42 : 40.w;
    final double iconSize = isLargeScreen ? 22 : 21.sp;
    final double arrowSize = isLargeScreen ? 24 : 23.sp;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary,
          borderRadius: BorderRadius.circular(cardRadius),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(isDark ? 0.18 : 0.42),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.10 : 0.035),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(isLargeScreen ? 18 : 16.r),
              child: InkWell(
                borderRadius: BorderRadius.circular(isLargeScreen ? 18 : 16.r),
                onTap: _toggleExpanded,
                splashColor: theme.colorScheme.primary.withOpacity(0.10),
                highlightColor: theme.colorScheme.primary.withOpacity(0.06),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: headerMinHeight),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: iconBox,
                        height: iconBox,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(
                            isDark ? 0.20 : 0.10,
                          ),
                          borderRadius: BorderRadius.circular(
                            isLargeScreen ? 14 : 14.r,
                          ),
                        ),
                        child: Icon(
                          Icons.psychology_alt_outlined,
                          color: theme.colorScheme.primary,
                          size: iconSize,
                        ),
                      ),
                      SizedBox(width: isLargeScreen ? 12 : 10.w),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: Text(
                                'درّبني على حفظ الحديث',
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.rtl,
                                locale: const Locale('ar'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.body(context).copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.surface,
                                  height: 1.25,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                            SizedBox(height: isLargeScreen ? 3 : 4.h),
                            SizedBox(
                              width: double.infinity,
                              child: Text(
                                _modeTitle(),
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.rtl,
                                locale: const Locale('ar'),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption(context).copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.surface.withOpacity(
                                    0.64,
                                  ),
                                  height: 1.35,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: isLargeScreen ? 10 : 8.w),
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: theme.colorScheme.surface.withOpacity(0.82),
                          size: arrowSize,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: ClipRect(
                child: _isExpanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizedBox(height: isLargeScreen ? 14 : 13.h),
                          _ModeButtonsContainer(
                            isLargeScreen: isLargeScreen,
                            mode: _mode,
                            onRead: () => _changeMode(HadithMemoryMode.read),
                            onTrain: () => _changeMode(HadithMemoryMode.train),
                            onTest: () => _changeMode(HadithMemoryMode.test),
                          ),
                          SizedBox(height: isLargeScreen ? 12 : 11.h),
                          _TrainingTextContainer(
                            isLargeScreen: isLargeScreen,
                            isDark: isDark,
                            text: _displayedText(),
                            isQuranVerse: widget.item.isQuranVerse,
                          ),
                          if (_mode == HadithMemoryMode.test) ...[
                            SizedBox(height: isLargeScreen ? 10 : 9.h),
                            _AnswerToggleButton(
                              isLargeScreen: isLargeScreen,
                              showAnswer: _showAnswer,
                              onTap: () {
                                AppHaptics.tap(context);

                                setState(() {
                                  _showAnswer = !_showAnswer;
                                });
                              },
                            ),
                          ],
                          if (_canSaveRating) ...[
                            SizedBox(height: isLargeScreen ? 12 : 11.h),
                            _RatingHintContainer(
                              isLargeScreen: isLargeScreen,
                              hint: _ratingHint(),
                            ),
                            SizedBox(height: isLargeScreen ? 9 : 8.h),
                            _InlineRatingButtons(
                              isLargeScreen: isLargeScreen,
                              isSaving: _isSavingRating,
                              selectedRating: _lastRating,
                              onMastered: () =>
                                  _saveRating(HadithMemoryRating.mastered),
                              onPartial: () =>
                                  _saveRating(HadithMemoryRating.partial),
                              onReview: () =>
                                  _saveRating(HadithMemoryRating.review),
                            ),
                          ],
                        ],
                      )
                    : const SizedBox(width: double.infinity, height: 0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeButtonsContainer extends StatelessWidget {
  const _ModeButtonsContainer({
    required this.isLargeScreen,
    required this.mode,
    required this.onRead,
    required this.onTrain,
    required this.onTest,
  });

  final bool isLargeScreen;
  final HadithMemoryMode mode;
  final VoidCallback onRead;
  final VoidCallback onTrain;
  final VoidCallback onTest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isLargeScreen ? 6 : 5.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(isDark ? 0.12 : 0.055),
        borderRadius: BorderRadius.circular(isLargeScreen ? 18 : 16.r),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(isDark ? 0.16 : 0.09),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          _ModeButton(
            text: 'قراءة',
            icon: Icons.menu_book_rounded,
            selected: mode == HadithMemoryMode.read,
            isLargeScreen: isLargeScreen,
            onTap: onRead,
          ),
          SizedBox(width: isLargeScreen ? 7 : 6.w),
          _ModeButton(
            text: 'تدريب',
            icon: Icons.psychology_alt_outlined,
            selected: mode == HadithMemoryMode.train,
            isLargeScreen: isLargeScreen,
            onTap: onTrain,
          ),
          SizedBox(width: isLargeScreen ? 7 : 6.w),
          _ModeButton(
            text: 'اختبار',
            icon: Icons.quiz_outlined,
            selected: mode == HadithMemoryMode.test,
            isLargeScreen: isLargeScreen,
            onTap: onTest,
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.text,
    required this.icon,
    required this.selected,
    required this.isLargeScreen,
    required this.onTap,
  });

  final String text;
  final IconData icon;
  final bool selected;
  final bool isLargeScreen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final double radius = isLargeScreen ? 14 : 13.r;
    final double iconSize = isLargeScreen ? 15 : 14.sp;
    final double fontSize = isLargeScreen ? 12 : 10.5.sp;
    final double verticalPadding = isLargeScreen ? 9 : 8.h;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          splashColor: theme.colorScheme.primary.withOpacity(0.10),
          highlightColor: theme.colorScheme.primary.withOpacity(0.06),
          child: Ink(
            padding: EdgeInsets.symmetric(
              horizontal: isLargeScreen ? 8 : 5.w,
              vertical: verticalPadding,
            ),
            decoration: BoxDecoration(
              color: selected ? theme.colorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primary.withOpacity(0.16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              textDirection: TextDirection.rtl,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: iconSize,
                  color: selected ? Colors.white : theme.colorScheme.primary,
                ),
                SizedBox(width: isLargeScreen ? 5 : 4.w),
                Flexible(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    locale: const Locale('ar'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontFamily: 'cairo',
                      fontWeight: FontWeight.w900,
                      color: selected
                          ? Colors.white
                          : theme.colorScheme.primary,
                      letterSpacing: 0,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrainingTextContainer extends StatelessWidget {
  const _TrainingTextContainer({
    required this.isLargeScreen,
    required this.isDark,
    required this.text,
    required this.isQuranVerse,
  });

  final bool isLargeScreen;
  final bool isDark;
  final String text;
  final bool isQuranVerse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Container(
        key: ValueKey(text),
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isLargeScreen ? 16 : 12.w,
          vertical: isLargeScreen ? 14 : 12.h,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(isDark ? 0.13 : 0.055),
          borderRadius: BorderRadius.circular(isLargeScreen ? 18 : 16.r),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(isDark ? 0.15 : 0.08),
          ),
        ),
        child: Text(
          text,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          softWrap: true,
          locale: const Locale('ar'),
          style: AppTextStyles.body(context).copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.surface,
            height: isQuranVerse ? 1.95 : 1.75,
            letterSpacing: 0,
            wordSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _AnswerToggleButton extends StatelessWidget {
  const _AnswerToggleButton({
    required this.isLargeScreen,
    required this.showAnswer,
    required this.onTap,
  });

  final bool isLargeScreen;
  final bool showAnswer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.primary,
          side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.55)),
          padding: EdgeInsets.symmetric(vertical: isLargeScreen ? 11 : 10.h),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isLargeScreen ? 15 : 14.r),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          textDirection: TextDirection.rtl,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              showAnswer
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: isLargeScreen ? 18 : 18.sp,
            ),
            SizedBox(width: isLargeScreen ? 6 : 6.w),
            Text(
              showAnswer ? 'إخفاء الإجابة' : 'إظهار الإجابة',
              textDirection: TextDirection.rtl,
              style: AppTextStyles.caption(
                context,
              ).copyWith(fontWeight: FontWeight.w900, letterSpacing: 0),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingHintContainer extends StatelessWidget {
  const _RatingHintContainer({required this.isLargeScreen, required this.hint});

  final bool isLargeScreen;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isLargeScreen ? 12 : 10.w,
        vertical: isLargeScreen ? 9 : 8.h,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(
          theme.brightness == Brightness.dark ? 0.05 : 0.035,
        ),
        borderRadius: BorderRadius.circular(isLargeScreen ? 15 : 14.r),
      ),
      child: Text(
        hint,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        locale: const Locale('ar'),
        style: AppTextStyles.caption(context).copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.surface.withOpacity(0.62),
          height: 1.45,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _InlineRatingButtons extends StatelessWidget {
  const _InlineRatingButtons({
    required this.isLargeScreen,
    required this.isSaving,
    required this.selectedRating,
    required this.onMastered,
    required this.onPartial,
    required this.onReview,
  });

  final bool isLargeScreen;
  final bool isSaving;
  final HadithMemoryRating? selectedRating;
  final VoidCallback onMastered;
  final VoidCallback onPartial;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool stackButtons = constraints.maxWidth < 330;

        final buttons = <Widget>[
          _RatingChipButton(
            title: 'تمام',
            icon: Icons.verified_rounded,
            color: const Color(0xff21C58E),
            selected: selectedRating == HadithMemoryRating.mastered,
            enabled: !isSaving,
            isLargeScreen: isLargeScreen,
            onTap: onMastered,
          ),
          _RatingChipButton(
            title: 'نص نص',
            icon: Icons.adjust_rounded,
            color: const Color(0xffF59E0B),
            selected: selectedRating == HadithMemoryRating.partial,
            enabled: !isSaving,
            isLargeScreen: isLargeScreen,
            onTap: onPartial,
          ),
          _RatingChipButton(
            title: 'مراجعة',
            icon: Icons.refresh_rounded,
            color: Theme.of(context).colorScheme.primary,
            selected: selectedRating == HadithMemoryRating.review,
            enabled: !isSaving,
            isLargeScreen: isLargeScreen,
            onTap: onReview,
          ),
        ];

        if (stackButtons) {
          return Column(
            children: [
              SizedBox(width: double.infinity, child: buttons[0]),
              SizedBox(height: 7.h),
              SizedBox(width: double.infinity, child: buttons[1]),
              SizedBox(height: 7.h),
              SizedBox(width: double.infinity, child: buttons[2]),
            ],
          );
        }

        return Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(child: buttons[0]),
            SizedBox(width: isLargeScreen ? 8 : 6.w),
            Expanded(child: buttons[1]),
            SizedBox(width: isLargeScreen ? 8 : 6.w),
            Expanded(child: buttons[2]),
          ],
        );
      },
    );
  }
}

class _RatingChipButton extends StatelessWidget {
  const _RatingChipButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.selected,
    required this.enabled,
    required this.isLargeScreen,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final bool selected;
  final bool enabled;
  final bool isLargeScreen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color effectiveColor = enabled ? color : color.withOpacity(0.35);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(isLargeScreen ? 14 : 13.r),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(isLargeScreen ? 14 : 13.r),
        splashColor: effectiveColor.withOpacity(0.10),
        highlightColor: effectiveColor.withOpacity(0.06),
        child: Ink(
          height: isLargeScreen ? 40 : 38.h,
          padding: EdgeInsets.symmetric(horizontal: isLargeScreen ? 8 : 6.w),
          decoration: BoxDecoration(
            color: selected ? effectiveColor : effectiveColor.withOpacity(0.10),
            borderRadius: BorderRadius.circular(isLargeScreen ? 14 : 13.r),
            border: Border.all(
              color: selected
                  ? effectiveColor
                  : effectiveColor.withOpacity(0.28),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : effectiveColor,
                size: isLargeScreen ? 16 : 15.sp,
              ),
              SizedBox(width: isLargeScreen ? 5 : 4.w),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.rtl,
                  locale: const Locale('ar'),
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: selected ? Colors.white : effectiveColor,
                    letterSpacing: 0,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
