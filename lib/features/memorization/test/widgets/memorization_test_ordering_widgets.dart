part of '../pages/memorization_test_session_page.dart';

class _OrderingQuestionPanel extends StatelessWidget {
  const _OrderingQuestionPanel({
    required this.question,
    required this.orderedOptionIds,
    required this.isAnswered,
    required this.onOptionTap,
    required this.onSelectedOptionTap,
    required this.onReorder,
    required this.onClear,
    required this.onSubmit,
  });

  final MemorizationTestQuestionModel question;
  final List<String> orderedOptionIds;
  final bool isAnswered;
  final ValueChanged<MemorizationQuestionOption> onOptionTap;
  final ValueChanged<MemorizationQuestionOption> onSelectedOptionTap;
  final void Function(int oldIndex, int newIndex) onReorder;
  final VoidCallback onClear;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final optionById = <String, MemorizationQuestionOption>{
      for (final option in question.options) option.id: option,
    };
    final selectedOptions = orderedOptionIds
        .map((id) => optionById[id])
        .whereType<MemorizationQuestionOption>()
        .toList(growable: false);
    final remainingOptions = question.options
        .where((option) => !orderedOptionIds.contains(option.id))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OrderingBox(
          title: 'ترتيبك',
          emptyText: 'اضغط العناصر بالترتيب الصحيح',
          options: selectedOptions,
          isAnswered: isAnswered,
          showOrderNumbers: true,
          onOptionTap: onSelectedOptionTap,
          onReorder: onReorder,
        ),
        SizedBox(height: 10.h),
        _OrderingBox(
          title: 'العناصر',
          emptyText: 'تم اختيار كل العناصر',
          options: remainingOptions,
          isAnswered: isAnswered,
          showOrderNumbers: false,
          onOptionTap: onOptionTap,
          onReorder: null,
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: _SmallOrderingButton(
                text: 'اعتماد الترتيب',
                icon: Icons.check_circle_rounded,
                isPrimary: true,
                isDisabled:
                    isAnswered ||
                    orderedOptionIds.length != question.options.length,
                onTap: onSubmit,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _SmallOrderingButton(
                text: 'إعادة',
                icon: Icons.refresh_rounded,
                isPrimary: false,
                isDisabled: isAnswered || orderedOptionIds.isEmpty,
                onTap: onClear,
              ),
            ),
          ],
        ),
        if (isAnswered) ...[
          SizedBox(height: 10.h),
          Text(
            'الإجابة الصحيحة تظهر تحت السؤال بعد الاعتماد.',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: AppTextStyles.caption(context).copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.surface.withOpacity(0.55),
            ),
          ),
        ],
      ],
    );
  }
}

class _OrderingBox extends StatelessWidget {
  const _OrderingBox({
    required this.title,
    required this.emptyText,
    required this.options,
    required this.isAnswered,
    required this.showOrderNumbers,
    required this.onOptionTap,
    required this.onReorder,
  });

  final String title;
  final String emptyText;
  final List<MemorizationQuestionOption> options;
  final bool isAnswered;
  final bool showOrderNumbers;
  final ValueChanged<MemorizationQuestionOption> onOptionTap;
  final void Function(int oldIndex, int newIndex)? onReorder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.background.withOpacity(0.28),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.08)),
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
          SizedBox(height: 8.h),
          if (options.isEmpty)
            Text(
              emptyText,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: AppTextStyles.caption(context).copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.surface.withOpacity(0.48),
              ),
            )
          else if (showOrderNumbers)
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: options.length,
              onReorder: isAnswered || onReorder == null
                  ? (_, __) {}
                  : onReorder!,
              proxyDecorator: (child, index, animation) {
                return Material(
                  color: Colors.transparent,
                  elevation: 6,
                  borderRadius: BorderRadius.circular(14.r),
                  child: ScaleTransition(
                    scale: Tween<double>(
                      begin: 1,
                      end: 1.025,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              itemBuilder: (context, index) {
                final option = options[index];
                return Padding(
                  key: ValueKey('selected_order_${option.id}'),
                  padding: EdgeInsets.only(bottom: 7.h),
                  child: ReorderableDelayedDragStartListener(
                    index: index,
                    enabled: !isAnswered,
                    child: _OrderingChip(
                      option: option,
                      orderNumber: index + 1,
                      isDisabled: isAnswered,
                      showDragHandle: !isAnswered,
                      onTap: () => onOptionTap(option),
                    ),
                  ),
                );
              },
            )
          else
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 7.w,
              runSpacing: 7.h,
              children: [
                for (int i = 0; i < options.length; i++)
                  _OrderingChip(
                    option: options[i],
                    orderNumber: showOrderNumbers ? i + 1 : null,
                    isDisabled: isAnswered || showOrderNumbers,
                    showDragHandle: false,
                    onTap: () => onOptionTap(options[i]),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _OrderingChip extends StatelessWidget {
  const _OrderingChip({
    required this.option,
    required this.orderNumber,
    required this.isDisabled,
    required this.showDragHandle,
    required this.onTap,
  });

  final MemorizationQuestionOption option;
  final int? orderNumber;
  final bool isDisabled;
  final bool showDragHandle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: isDisabled ? null : onTap,
        child: Container(
          constraints: BoxConstraints(maxWidth: 260.w),
          padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.14),
            ),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              if (showDragHandle) ...[
                Icon(
                  Icons.drag_indicator_rounded,
                  size: 18.sp,
                  color: theme.colorScheme.primary.withOpacity(0.65),
                ),
                SizedBox(width: 6.w),
              ],
              Expanded(
                child: _AdaptiveQuranText(
                  text: orderNumber == null
                      ? option.text
                      : '$orderNumber. ${option.text}',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: null,
                  quranFontSize: 16.sp,
                  style: AppTextStyles.body(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.surface.withOpacity(0.76),
                    height: 1.75,
                  ),
                ),
              ),
              if (showDragHandle) ...[
                SizedBox(width: 6.w),
                Icon(
                  Icons.close_rounded,
                  size: 17.sp,
                  color: theme.colorScheme.error.withOpacity(0.75),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallOrderingButton extends StatelessWidget {
  const _SmallOrderingButton({
    required this.text,
    required this.icon,
    required this.isPrimary,
    required this.isDisabled,
    required this.onTap,
  });

  final String text;
  final IconData icon;
  final bool isPrimary;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = isPrimary
        ? theme.colorScheme.primary
        : theme.colorScheme.primary.withOpacity(0.10);
    final foreground = isPrimary ? Colors.white : theme.colorScheme.primary;

    return Opacity(
      opacity: isDisabled ? 0.48 : 1,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(15.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(15.r),
          onTap: isDisabled ? null : onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 9.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              textDirection: TextDirection.rtl,
              children: [
                Icon(icon, color: foreground, size: 15.sp),
                SizedBox(width: 5.w),
                Flexible(
                  child: Text(
                    text,
                    textDirection: TextDirection.rtl,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(
                      context,
                    ).copyWith(fontWeight: FontWeight.w900, color: foreground),
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

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.isAnswered,
    required this.isSelected,
    required this.quranFontSize,
    required this.onTap,
  });

  final MemorizationQuestionOption option;
  final bool isAnswered;
  final bool isSelected;
  final double quranFontSize;
  final VoidCallback onTap;

  Color _backgroundColor(BuildContext context) {
    final theme = Theme.of(context);

    if (!isAnswered) return theme.colorScheme.background.withOpacity(0.32);
    if (option.isCorrect) return Colors.green.withOpacity(0.13);
    if (isSelected && !option.isCorrect) {
      return theme.colorScheme.error.withOpacity(0.13);
    }

    return theme.colorScheme.background.withOpacity(0.22);
  }

  Color _borderColor(BuildContext context) {
    final theme = Theme.of(context);

    if (!isAnswered) return theme.colorScheme.outline.withOpacity(0.06);
    if (option.isCorrect) return Colors.green.withOpacity(0.45);
    if (isSelected && !option.isCorrect) {
      return theme.colorScheme.error.withOpacity(0.45);
    }

    return theme.colorScheme.outline.withOpacity(0.06);
  }

  Color _textColor(BuildContext context) {
    final theme = Theme.of(context);

    if (!isAnswered) return theme.colorScheme.surface.withOpacity(0.78);
    if (option.isCorrect) return Colors.green.shade700;
    if (isSelected && !option.isCorrect) return theme.colorScheme.error;

    return theme.colorScheme.surface.withOpacity(0.45);
  }

  IconData? get _icon {
    if (!isAnswered) return null;
    if (option.isCorrect) return Icons.check_circle_rounded;
    if (isSelected && !option.isCorrect) return Icons.cancel_rounded;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final icon = _icon;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: isAnswered ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: double.infinity,
          padding: EdgeInsets.all(11.w),
          decoration: BoxDecoration(
            color: _backgroundColor(context),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: _borderColor(context)),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Padding(
                  padding: EdgeInsets.only(top: 2.h),
                  child: Icon(icon, size: 17.sp, color: _textColor(context)),
                ),
                SizedBox(width: 8.w),
              ],
              Expanded(
                child: _AdaptiveQuranText(
                  text: option.text,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: null,
                  quranFontSize: quranFontSize,
                  style: AppTextStyles.body(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: _textColor(context),
                    height: 1.75,
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
