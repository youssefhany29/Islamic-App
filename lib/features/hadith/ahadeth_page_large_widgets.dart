part of 'ahadeth_page.dart';

class HadithLargeCategoriesGrid extends StatelessWidget {
  const HadithLargeCategoriesGrid({
    super.key,
    required this.categories,
    required this.onOpenCategory,
  });

  final List<HadithCategoryModel> categories;
  final ValueChanged<HadithCategoryModel> onOpenCategory;

  bool _isPrivateCategory(HadithCategoryModel category) {
    return category.id == HadithLocalData.customId ||
        category.id.contains('custom') ||
        category.id.contains('private') ||
        category.title.contains('خاص');
  }

  bool _isQudsiCategory(HadithCategoryModel category) {
    return category.id == HadithLocalData.qudsiId ||
        category.title.contains('قدسية');
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

    final HadithCategoryModel? privateCategory = categories
        .where(_isPrivateCategory)
        .cast<HadithCategoryModel?>()
        .firstWhere((category) => category != null, orElse: () => null);

    final HadithCategoryModel? qudsiCategory = categories
        .where(_isQudsiCategory)
        .cast<HadithCategoryModel?>()
        .firstWhere((category) => category != null, orElse: () => null);

    final List<HadithCategoryModel> normalCategories = categories
        .where((category) => !_isPrivateCategory(category))
        .where((category) => !_isQudsiCategory(category))
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
                    child: _LargeHadithCategoryCard(
                      category: category,
                      onTap: () => onOpenCategory(category),
                    ),
                  ),
              ],
            ),
            if (qudsiCategory != null || privateCategory != null) ...[
              SizedBox(height: gap),
              SizedBox(
                height: cardHeight,
                child: Row(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (qudsiCategory != null)
                      SizedBox(
                        width: cardWidth,
                        child: _LargeHadithCategoryCard(
                          category: qudsiCategory,
                          onTap: () => onOpenCategory(qudsiCategory),
                        ),
                      ),
                    if (qudsiCategory != null && privateCategory != null)
                      SizedBox(width: gap),
                    if (privateCategory != null)
                      Expanded(
                        child: _LargeHadithCategoryCard(
                          category: privateCategory,
                          onTap: () => onOpenCategory(privateCategory),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _LargeHadithCategoryCard extends StatelessWidget {
  const _LargeHadithCategoryCard({required this.category, required this.onTap});

  final HadithCategoryModel category;
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
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 54),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
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
                        const SizedBox(height: 4),
                        SizedBox(
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
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
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
                ),
                Align(
                  alignment: Alignment.bottomLeft,
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
