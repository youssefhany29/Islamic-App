part of 'zekr_page.dart';

class ZekrLargeCategoriesGrid extends StatelessWidget {
  const ZekrLargeCategoriesGrid({
    super.key,
    required this.categories,
    required this.onOpenCategory,
  });

  final List<ZekrCategoryModel> categories;
  final ValueChanged<ZekrCategoryModel> onOpenCategory;

  bool _isPrivateCategory(ZekrCategoryModel category) {
    return category.id.contains('custom') ||
        category.id.contains('private') ||
        category.title.contains('خاص');
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final bool isFold = size.width >= 600 && size.shortestSide < 600;
    final bool isLandscape = size.width > size.height;

    const int columns = 3;
    final double gap = isFold ? 12 : 16;

    final double cardHeight = isLandscape
        ? 168
        : isFold
        ? 174
        : 186;

    final ZekrCategoryModel? privateCategory = categories
        .where(_isPrivateCategory)
        .cast<ZekrCategoryModel?>()
        .firstWhere((category) => category != null, orElse: () => null);

    final List<ZekrCategoryModel> normalCategories = categories
        .where((category) => !_isPrivateCategory(category))
        .toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth =
            (constraints.maxWidth - (gap * (columns - 1))) / columns;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              textDirection: TextDirection.rtl,
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final category in normalCategories)
                  SizedBox(
                    width: cardWidth,
                    height: cardHeight,
                    child: _LargeZekrCategoryCard(
                      category: category,
                      onTap: () => onOpenCategory(category),
                    ),
                  ),
              ],
            ),
            if (privateCategory != null) ...[
              SizedBox(height: gap),
              SizedBox(
                height: cardHeight,
                child: Row(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: _LargeZekrCategoryCard(
                        category: privateCategory,
                        onTap: () => onOpenCategory(privateCategory),
                      ),
                    ),
                    SizedBox(width: gap),
                    const Expanded(child: _LargeQuickTasbeehCard()),
                  ],
                ),
              ),
            ] else ...[
              SizedBox(height: gap),
              SizedBox(
                width: double.infinity,
                height: cardHeight,
                child: const _LargeQuickTasbeehCard(),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _LargeQuickTasbeehCard extends StatefulWidget {
  const _LargeQuickTasbeehCard();

  @override
  State<_LargeQuickTasbeehCard> createState() => _LargeQuickTasbeehCardState();
}

class _LargeQuickTasbeehCardState extends State<_LargeQuickTasbeehCard> {
  int counter = 0;

  void _increment() {
    AppHaptics.tap(context);

    setState(() {
      counter++;
    });
  }

  void _reset() {
    AppHaptics.tap(context);

    setState(() {
      counter = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(
                isDark ? 0.18 : 0.36,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.10 : 0.035),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Row(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(
                          isDark ? 0.24 : 0.10,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.radio_button_checked_rounded,
                        color: theme.colorScheme.primary,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              'تسبيح سريع',
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              locale: const Locale('ar'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.cardTitle(
                                context,
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.surface,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              'اضغط على الزر للتسبيح بسرعة من الصفحة.',
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              locale: const Locale('ar'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.cardSubtitle(
                                context,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.surface.withOpacity(
                                  0.62,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  '$counter',
                  textDirection: TextDirection.rtl,
                  style: AppTextStyles.display(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                    height: 1.0,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  textDirection: TextDirection.rtl,
                  children: [
                    ElevatedButton(
                      onPressed: _increment,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 10,
                        ),
                        minimumSize: const Size(0, 42),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'سبحان الله',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: 'cairo',
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: _reset,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        side: BorderSide(
                          color: theme.colorScheme.primary.withOpacity(0.45),
                          width: 1,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        minimumSize: const Size(0, 42),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'تصفير',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: 'cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LargeZekrCategoryCard extends StatelessWidget {
  const _LargeZekrCategoryCard({required this.category, required this.onTap});

  final ZekrCategoryModel category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          splashColor: theme.colorScheme.primary.withOpacity(0.10),
          highlightColor: theme.colorScheme.primary.withOpacity(0.06),
          child: Ink(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(
                  isDark ? 0.18 : 0.36,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.10 : 0.035),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(
                          isDark ? 0.24 : 0.10,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        category.icon,
                        color: theme.colorScheme.primary,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              width: double.infinity,
                              child: Text(
                                category.title,
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.rtl,
                                locale: const Locale('ar'),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.cardTitle(
                                  context,
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.surface,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              width: double.infinity,
                              child: Text(
                                category.subtitle,
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.rtl,
                                locale: const Locale('ar'),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.cardSubtitle(
                                  context,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.surface.withOpacity(
                                    0.66,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: theme.colorScheme.primary,
                    size: 17,
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
