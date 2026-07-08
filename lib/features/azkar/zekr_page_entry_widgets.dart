part of 'zekr_page.dart';

class _MemoryAnalyticsEntryCard extends StatelessWidget {
  const _MemoryAnalyticsEntryCard({required this.onTap, this.large = false});

  final VoidCallback onTap;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final double radius = large ? 22 : 18.r;
    final double padding = large ? 15 : 13.w;
    final double iconBox = large ? 38 : 39.w;
    final double iconSize = large ? 20 : 21.sp;
    final double arrowBox = large ? 27 : 28.w;
    final double arrowSize = large ? 15 : 17.sp;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Ink(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.30),
              ),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: iconBox,
                  height: iconBox,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(large ? 14 : 14.r),
                  ),
                  child: Icon(
                    Icons.insights_rounded,
                    color: theme.colorScheme.primary,
                    size: iconSize,
                  ),
                ),
                SizedBox(width: large ? 10 : 10.w),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          'تحليل الحفظ',
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          locale: const Locale('ar'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.cardTitle(
                            context,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.surface,
                          ),
                        ),
                      ),
                      SizedBox(height: large ? 4 : 3.h),
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          'تابع الأذكار المحفوظة واللي محتاجة مراجعة.',
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          locale: const Locale('ar'),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.cardSubtitle(
                            context,
                            fontWeight: FontWeight.w400,
                            color: theme.colorScheme.surface.withOpacity(0.62),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: large ? 8 : 8.w),
                Container(
                  width: arrowBox,
                  height: arrowBox,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(large ? 10 : 9.r),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: theme.colorScheme.primary,
                    size: arrowSize,
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

class _ZekrLargeSearchResultsSection extends StatelessWidget {
  const _ZekrLargeSearchResultsSection({
    required this.query,
    required this.searchResults,
    required this.onOpenSearchResult,
  });

  final String query;
  final List<_ZekrSearchResult> searchResults;
  final ValueChanged<_ZekrSearchResult> onOpenSearchResult;

  @override
  Widget build(BuildContext context) {
    if (searchResults.isEmpty) {
      return _NoSearchResultsCard(query: query, large: true);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SearchResultsHeader(
          query: query,
          count: searchResults.length,
          large: true,
        ),
        const SizedBox(height: 12),
        for (final result in searchResults)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ZekrSearchResultCard(
              result: result,
              large: true,
              onTap: () => onOpenSearchResult(result),
            ),
          ),
      ],
    );
  }
}
