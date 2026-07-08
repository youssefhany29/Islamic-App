part of '../pages/memorization_test_session_page.dart';

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.currentQuestionNumber,
    required this.totalQuestions,
    required this.quranFontSize,
    required this.optionQuranFontSize,
    required this.isAnswered,
    required this.isCorrect,
    required this.isTextRevealed,
    required this.selectedOptionId,
    required this.orderedOptionIds,
    required this.onOptionTap,
    required this.onOrderingOptionTap,
    required this.onRemoveOrderingOption,
    required this.onReorderOrderingOptions,
    required this.onClearOrdering,
    required this.onSubmitOrdering,
    required this.onRevealText,
    required this.onOpenHiddenMushaf,
    required this.onSelfEvaluation,
  });

  final MemorizationTestQuestionModel question;
  final int currentQuestionNumber;
  final int totalQuestions;
  final double quranFontSize;
  final double optionQuranFontSize;
  final bool isAnswered;
  final bool isCorrect;
  final bool isTextRevealed;
  final String? selectedOptionId;
  final List<String> orderedOptionIds;
  final ValueChanged<MemorizationQuestionOption> onOptionTap;
  final ValueChanged<MemorizationQuestionOption> onOrderingOptionTap;
  final ValueChanged<MemorizationQuestionOption> onRemoveOrderingOption;
  final void Function(int oldIndex, int newIndex) onReorderOrderingOptions;
  final VoidCallback onClearOrdering;
  final VoidCallback onSubmitOrdering;
  final VoidCallback onRevealText;
  final VoidCallback onOpenHiddenMushaf;
  final ValueChanged<String> onSelfEvaluation;

  bool get isSelfEvaluationQuestion {
    return !question.hasOptions;
  }

  bool get shouldShowAnswer {
    if (question.hasOptions) return isAnswered;
    return isTextRevealed || isAnswered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(26.r),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.10)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(child: _QuestionBadge(text: question.type.title)),
                SizedBox(width: 8.w),
                _QuestionCounterBadge(
                  current: currentQuestionNumber,
                  total: totalQuestions,
                ),
              ],
            ),
            SizedBox(height: 14.h),
            _AdaptiveQuranText(
              text: question.prompt,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              maxLines: null,
              quranFontSize: quranFontSize,
              style: AppTextStyles.body(context).copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.surface,
                height: 1.65,
              ),
            ),
            SizedBox(height: 12.h),
            _HintBox(text: question.hint),
            if (question.isOrderingQuestion) ...[
              SizedBox(height: 14.h),
              _OrderingQuestionPanel(
                question: question,
                orderedOptionIds: orderedOptionIds,
                isAnswered: isAnswered,
                onOptionTap: onOrderingOptionTap,
                onSelectedOptionTap: onRemoveOrderingOption,
                onReorder: onReorderOrderingOptions,
                onClear: onClearOrdering,
                onSubmit: onSubmitOrdering,
              ),
            ] else if (question.hasOptions) ...[
              SizedBox(height: 14.h),
              ...question.options.map((option) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: _OptionTile(
                    option: option,
                    isAnswered: isAnswered,
                    isSelected: selectedOptionId == option.id,
                    quranFontSize: optionQuranFontSize,
                    onTap: () => onOptionTap(option),
                  ),
                );
              }),
            ],
            if (isSelfEvaluationQuestion) ...[
              SizedBox(height: 14.h),
              if (question.type ==
                  MemorizationQuestionType.hiddenMushafRecitation) ...[
                _HiddenMushafButton(onTap: onOpenHiddenMushaf),
                SizedBox(height: 10.h),
              ],
              if (!isTextRevealed && !isAnswered)
                _RevealTextButton(onTap: onRevealText),
              if (isTextRevealed || isAnswered) ...[
                _AnswerBox(
                  correctAnswerText: question.correctAnswerText,
                  fullAyahText: question.fullAyahText,
                  sourceLabel: isAnswered ? question.sourceLabel : '',
                  pageLabel: isAnswered ? question.pageLabel : '',
                  quranFontSize: optionQuranFontSize,
                ),
                SizedBox(height: 12.h),
                _SelfEvaluationPanel(
                  isAnswered: isAnswered,
                  isCorrect: isCorrect,
                  onExcellentTap: () => onSelfEvaluation('excellent'),
                  onGoodTap: () => onSelfEvaluation('good'),
                  onReviewTap: () => onSelfEvaluation('needsReview'),
                  onMistakesTap: () => onSelfEvaluation('fewMistakes'),
                ),
              ],
            ],
            if (!isSelfEvaluationQuestion) ...[
              SizedBox(height: 16.h),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: shouldShowAnswer
                    ? Column(
                        key: const ValueKey('shown_answer_column'),
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _AnswerStatusBox(isCorrect: isCorrect),
                          SizedBox(height: 10.h),
                          _AnswerBox(
                            correctAnswerText: question.correctAnswerText,
                            fullAyahText: question.fullAyahText,
                            sourceLabel: question.sourceLabel,
                            pageLabel: question.pageLabel,
                            quranFontSize: optionQuranFontSize,
                          ),
                        ],
                      )
                    : const _HiddenAnswerBox(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HiddenMushafButton extends StatelessWidget {
  const _HiddenMushafButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primary,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.menu_book_rounded,
                color: theme.colorScheme.onPrimary,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  'ابدأ التسميع الذاتي',
                  maxLines: 3,
                  softWrap: true,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption(context).copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w900,
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

class _StandaloneTimerBanner extends StatelessWidget {
  const _StandaloneTimerBanner({
    required this.label,
    required this.modeLabel,
    required this.isLastWarning,
  });

  final String label;
  final String modeLabel;
  final bool isLastWarning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isLastWarning ? Colors.orange : theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(Icons.timer_rounded, color: color, size: 19.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  modeLabel,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.surface.withOpacity(0.76),
                  ),
                ),
                if (isLastWarning) ...[
                  SizedBox(height: 2.h),
                  Text(
                    'آخر ثواني، بهدوء اختار إجابتك.',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: AppTextStyles.caption(
                      context,
                    ).copyWith(fontWeight: FontWeight.w700, color: color),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            label,
            textDirection: TextDirection.ltr,
            style: AppTextStyles.body(
              context,
            ).copyWith(fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }
}

class _QuestionCounterBadge extends StatelessWidget {
  const _QuestionCounterBadge({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.09),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.10)),
      ),
      child: Text(
        '$current من $total',
        textDirection: TextDirection.rtl,
        style: AppTextStyles.caption(context).copyWith(
          fontWeight: FontWeight.w900,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _QuestionBadge extends StatelessWidget {
  const _QuestionBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.10),
          borderRadius: BorderRadius.circular(30.r),
        ),
        child: Text(
          text,
          textDirection: TextDirection.rtl,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption(context).copyWith(
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _AdaptiveQuranText extends StatelessWidget {
  const _AdaptiveQuranText({
    required this.text,
    required this.style,
    this.textDirection = TextDirection.rtl,
    this.textAlign = TextAlign.right,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
    this.quranFontSize,
  });

  final String text;
  final TextStyle style;
  final TextDirection textDirection;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;
  final double? quranFontSize;

  @override
  Widget build(BuildContext context) {
    final parts = text.split('\n');
    return RichText(
      textDirection: textDirection,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: maxLines == null ? TextOverflow.visible : overflow,
      softWrap: true,
      text: TextSpan(
        style: style,
        children: [
          for (int index = 0; index < parts.length; index++) ...[
            TextSpan(
              text: parts[index],
              style: _containsHafsGlyphs(parts[index])
                  ? style.copyWith(
                      fontFamily: 'quran',
                      fontWeight: FontWeight.w400,
                      fontSize: quranFontSize ?? 16.sp,
                      height: 1.8,
                    )
                  : style,
            ),
            if (index < parts.length - 1) const TextSpan(text: '\n'),
          ],
        ],
      ),
    );
  }

  bool _containsHafsGlyphs(String value) {
    return value.runes.any(
      (rune) =>
          (rune >= 0xE000 && rune <= 0xF8FF) ||
          (rune >= 0xF0000 && rune <= 0xFFFFD),
    );
  }
}

class _HintBox extends StatelessWidget {
  const _HintBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(13.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.background.withOpacity(0.36),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: _AdaptiveQuranText(
        text: text,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        maxLines: 3,
        style: AppTextStyles.caption(context).copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.surface.withOpacity(0.72),
          height: 1.5,
        ),
      ),
    );
  }
}

class _RevealTextButton extends StatelessWidget {
  const _RevealTextButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.primary,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 13.h, horizontal: 12.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: TextDirection.rtl,
            children: [
              Icon(Icons.visibility_rounded, color: Colors.white, size: 18.sp),
              SizedBox(width: 8.w),
              Text(
                'عرض النص',
                textDirection: TextDirection.rtl,
                style: AppTextStyles.caption(
                  context,
                ).copyWith(fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
