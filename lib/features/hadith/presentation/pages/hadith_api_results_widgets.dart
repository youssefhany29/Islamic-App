part of 'hadith_api_books_page.dart';

class _HadithResultsLayout extends StatelessWidget {
  const _HadithResultsLayout({
    required this.hadiths,
    required this.onAddToCards,
  });

  final List<HadithApiHadithModel> hadiths;
  final Future<void> Function(HadithApiHadithModel hadith) onAddToCards;

  @override
  Widget build(BuildContext context) {
    final bool isLargeScreen = _hadithLibraryLargeScreen(context);

    if (!isLargeScreen) {
      return Column(
        children: [
          for (int i = 0; i < hadiths.length; i++) ...[
            _ApiHadithCard(
              hadith: hadiths[i],
              onAddToCards: () => onAddToCards(hadiths[i]),
            ),
            if (i != hadiths.length - 1) SizedBox(height: 10.h),
          ],
        ],
      );
    }

    final List<HadithApiHadithModel> rightColumn = <HadithApiHadithModel>[];
    final List<HadithApiHadithModel> leftColumn = <HadithApiHadithModel>[];

    for (int i = 0; i < hadiths.length; i++) {
      if (i.isEven) {
        rightColumn.add(hadiths[i]);
      } else {
        leftColumn.add(hadiths[i]);
      }
    }

    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              for (int i = 0; i < rightColumn.length; i++) ...[
                _ApiHadithCard(
                  hadith: rightColumn[i],
                  onAddToCards: () => onAddToCards(rightColumn[i]),
                ),
                if (i != rightColumn.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              for (int i = 0; i < leftColumn.length; i++) ...[
                _ApiHadithCard(
                  hadith: leftColumn[i],
                  onAddToCards: () => onAddToCards(leftColumn[i]),
                ),
                if (i != leftColumn.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ApiHadithCard extends StatelessWidget {
  const _ApiHadithCard({required this.hadith, required this.onAddToCards});

  final HadithApiHadithModel hadith;
  final VoidCallback onAddToCards;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isLargeScreen = _hadithLibraryLargeScreen(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final double radius = isLargeScreen ? 22 : 18.r;
    final double padding = isLargeScreen ? 16 : 13.w;
    final double iconBox = isLargeScreen ? 38 : 34.w;
    final double metaFontSize = isLargeScreen ? 11 : 9.5.sp;
    final double bodyFontSize = isLargeScreen ? 14 : 12.sp;

    final String metaText = [
      if (hadith.bookName != null && hadith.bookName!.trim().isNotEmpty)
        hadith.bookName!,
      if (hadith.status != null && hadith.status!.trim().isNotEmpty)
        hadith.status!,
    ].join(' • ');

    final String detailsText = [
      if (hadith.chapter != null && hadith.chapter!.trim().isNotEmpty)
        hadith.chapter!,
      if (hadith.hadithNumber != null && hadith.hadithNumber!.trim().isNotEmpty)
        'رقم الحديث: ${hadith.hadithNumber}',
    ].join(' • ');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(isDark ? 0.18 : 0.30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.10 : 0.025),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Stack(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: iconBox,
                    height: iconBox,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(
                        isLargeScreen ? 13 : 12.r,
                      ),
                    ),
                    child: Icon(
                      Icons.verified_rounded,
                      color: theme.colorScheme.primary,
                      size: isLargeScreen ? 18 : 16.sp,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: isLargeScreen ? 48 : 44.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (metaText.isNotEmpty)
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              metaText,
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              locale: const Locale('ar'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'cairo',
                                fontSize: metaFontSize,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.primary,
                                height: 1.35,
                              ),
                            ),
                          ),
                        if (detailsText.isNotEmpty) ...[
                          SizedBox(height: isLargeScreen ? 3 : 2.h),
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              detailsText,
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              locale: const Locale('ar'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption(context).copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.surface.withOpacity(
                                  0.55,
                                ),
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isLargeScreen ? 10 : 8.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isLargeScreen ? 13 : 11.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(
                  isDark ? 0.13 : 0.055,
                ),
                borderRadius: BorderRadius.circular(isLargeScreen ? 16 : 15.r),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(
                    isDark ? 0.16 : 0.08,
                  ),
                ),
              ),
              child: Text(
                hadith.textArabic,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                locale: const Locale('ar'),
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.surface,
                  height: 1.8,
                  letterSpacing: 0,
                ),
              ),
            ),
            SizedBox(height: isLargeScreen ? 11 : 10.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onAddToCards,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  side: BorderSide(
                    color: theme.colorScheme.primary.withOpacity(0.38),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: isLargeScreen ? 11 : 9.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      isLargeScreen ? 15 : 14.r,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  textDirection: TextDirection.rtl,
                  children: [
                    Icon(Icons.add_rounded, size: isLargeScreen ? 18 : 17.sp),
                    SizedBox(width: isLargeScreen ? 6 : 5.w),
                    Text(
                      'إضافة للكروت',
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: AppTextStyles.caption(
                        context,
                      ).copyWith(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.details,
    required this.onRetry,
  });

  final String message;
  final String details;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isLargeScreen = _hadithLibraryLargeScreen(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isLargeScreen ? 16 : 14.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary,
          borderRadius: BorderRadius.circular(isLargeScreen ? 22 : 18.r),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.30),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.caption(context).copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.surface,
              ),
            ),
            SizedBox(height: isLargeScreen ? 7 : 6.h),
            Text(
              details,
              textAlign: TextAlign.right,
              textDirection: TextDirection.ltr,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.surface.withOpacity(0.50),
              ),
            ),
            SizedBox(height: isLargeScreen ? 11 : 10.h),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  textDirection: TextDirection.rtl,
                  children: [
                    const Icon(Icons.refresh_rounded),
                    SizedBox(width: isLargeScreen ? 7 : 6.w),
                    const Text('إعادة المحاولة'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyResultsCard extends StatelessWidget {
  const _EmptyResultsCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isLargeScreen = _hadithLibraryLargeScreen(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isLargeScreen ? 16 : 14.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(isLargeScreen ? 22 : 18.r),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.30)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        style: AppTextStyles.caption(context).copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.surface.withOpacity(0.64),
        ),
      ),
    );
  }
}
