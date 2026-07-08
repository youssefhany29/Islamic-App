part of 'ahadeth_page.dart';

class _PhoneHadithBody extends StatelessWidget {
  const _PhoneHadithBody({
    required this.memoryPlanLoading,
    required this.memoryPlanEnabled,
    required this.memoryPlanChanging,
    required this.reviewCalendarRefreshTick,
    required this.onMemoryPlanChanged,
    required this.onOpenAnalytics,
    required this.onOpenTodayReview,
    required this.onOpenApiBooks,
    required this.isSearching,
    required this.searchResults,
    required this.categories,
    required this.searchField,
    required this.searchQuery,
    required this.onOpenSearchResult,
    required this.onOpenCategory,
  });

  final bool memoryPlanLoading;
  final bool memoryPlanEnabled;
  final bool memoryPlanChanging;
  final int reviewCalendarRefreshTick;
  final ValueChanged<bool> onMemoryPlanChanged;
  final VoidCallback onOpenAnalytics;
  final VoidCallback onOpenTodayReview;
  final VoidCallback onOpenApiBooks;
  final bool isSearching;
  final List<_HadithSearchResult> searchResults;
  final List<HadithCategoryModel> categories;
  final Widget searchField;
  final String searchQuery;
  final ValueChanged<_HadithSearchResult> onOpenSearchResult;
  final ValueChanged<HadithCategoryModel> onOpenCategory;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 18.h),
      physics: const BouncingScrollPhysics(),
      children: [
        const HadithDailyJourneyCard(),
        SizedBox(height: 12.h),
        _HadithApiEntryCard(onTap: onOpenApiBooks),
        SizedBox(height: 12.h),
        if (memoryPlanLoading)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 18.h),
            child: const Center(child: CircularProgressIndicator()),
          )
        else ...[
          HadithMemoryPlanCard(
            enabled: memoryPlanEnabled,
            isChanging: memoryPlanChanging,
            onChanged: onMemoryPlanChanged,
          ),
          if (memoryPlanEnabled) ...[
            SizedBox(height: 12.h),
            _MemoryAnalyticsEntryCard(onTap: onOpenAnalytics),
            SizedBox(height: 12.h),
            HadithTodayReviewCard(onTap: onOpenTodayReview),
            SizedBox(height: 12.h),
            HadithReviewCalendarCard(
              refreshTick: reviewCalendarRefreshTick,
              onOpenTodayReview: onOpenTodayReview,
            ),
          ],
        ],
        SizedBox(height: 12.h),
        Text(
          'رحلة الحديث',
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: AppTypography.pageHeader(
            context,
            color: Theme.of(context).colorScheme.surface,
          ),
        ),
        SizedBox(height: 8.h),
        searchField,
        SizedBox(height: 10.h),
        if (isSearching) ...[
          if (searchResults.isEmpty)
            _NoSearchResultsCard(query: searchQuery)
          else ...[
            _SearchResultsHeader(
              query: searchQuery,
              count: searchResults.length,
            ),
            SizedBox(height: 8.h),
            ...searchResults.map((result) {
              return Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: _HadithSearchResultCard(
                  result: result,
                  onTap: () => onOpenSearchResult(result),
                ),
              );
            }),
          ],
        ] else
          ...categories.map((category) {
            return Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: HadithCategoryCard(
                category: category,
                onTap: () => onOpenCategory(category),
              ),
            );
          }),
      ],
    );
  }
}

class _SearchResultsHeader extends StatelessWidget {
  const _SearchResultsHeader({
    required this.query,
    required this.count,
    this.large = false,
  });

  final String query;
  final int count;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: large ? 16 : 12.w,
          vertical: large ? 12 : 9.h,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.07),
          borderRadius: BorderRadius.circular(large ? 18 : 14.r),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.12),
          ),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Icon(
              Icons.search_rounded,
              color: theme.colorScheme.primary,
              size: large ? 24 : 18.sp,
            ),
            SizedBox(width: large ? 10 : 8.w),
            Expanded(
              child: Text(
                'نتائج البحث عن "$query" — $count نتيجة',
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.surface.withOpacity(0.70),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HadithSearchResultCard extends StatelessWidget {
  const _HadithSearchResultCard({
    required this.result,
    required this.onTap,
    this.large = false,
  });

  final _HadithSearchResult result;
  final VoidCallback onTap;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final item = result.item;
    final category = result.category;

    final double radius = large ? 22 : 18.r;
    final double padding = large ? 16 : 12.w;
    final double iconSize = large ? 52 : 42.w;
    final double titleSize = large ? 18 : 12.sp;
    final double categorySize = large ? 13 : 9.2.sp;
    final double bodySize = large ? 14 : 10.5.sp;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          splashColor: theme.colorScheme.primary.withOpacity(0.10),
          highlightColor: theme.colorScheme.primary.withOpacity(0.06),
          child: Ink(
            width: double.infinity,
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(
                  isDark ? 0.18 : 0.38,
                ),
              ),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(
                      isDark ? 0.22 : 0.09,
                    ),
                    borderRadius: BorderRadius.circular(large ? 16 : 14.r),
                  ),
                  child: Icon(
                    item.isQuranVerse
                        ? Icons.auto_stories_rounded
                        : Icons.menu_book_rounded,
                    color: theme.colorScheme.primary,
                    size: large ? 28 : 21.sp,
                  ),
                ),
                SizedBox(width: large ? 12 : 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item.title ?? category.title,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        locale: const Locale('ar'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'cairo',
                          fontSize: titleSize,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.surface,
                          height: 1.35,
                          letterSpacing: 0,
                        ),
                      ),
                      SizedBox(height: large ? 4 : 3.h),
                      Text(
                        category.title,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        locale: const Locale('ar'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'cairo',
                          fontSize: categorySize,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                          height: 1.35,
                          letterSpacing: 0,
                        ),
                      ),
                      SizedBox(height: large ? 8 : 5.h),
                      Text(
                        item.text,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        locale: const Locale('ar'),
                        maxLines: large ? 4 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'cairo',
                          fontSize: bodySize,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.surface.withOpacity(0.70),
                          height: 1.55,
                          letterSpacing: 0,
                        ),
                      ),
                      SizedBox(height: large ? 10 : 8.h),
                      Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          _SearchBadge(
                            text: '${item.count <= 0 ? 1 : item.count} مرة',
                            icon: Icons.repeat_rounded,
                            large: large,
                          ),
                          if (item.reference != null &&
                              item.reference!.trim().isNotEmpty) ...[
                            SizedBox(width: large ? 9 : 7.w),
                            Expanded(
                              child: Text(
                                item.reference!,
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.rtl,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption(context).copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.surface.withOpacity(
                                    0.48,
                                  ),
                                ),
                              ),
                            ),
                          ] else
                            const Spacer(),
                          SizedBox(width: large ? 10 : 8.w),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: theme.colorScheme.primary,
                            size: large ? 16 : 13.sp,
                          ),
                        ],
                      ),
                    ],
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

class _SearchBadge extends StatelessWidget {
  const _SearchBadge({
    required this.text,
    required this.icon,
    this.large = false,
  });

  final String text;
  final IconData icon;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 10 : 8.w,
        vertical: large ? 5 : 4.h,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: large ? 15 : 12.sp),
          SizedBox(width: large ? 5 : 4.w),
          Text(
            text,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.caption(context).copyWith(
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _HadithSearchField extends StatelessWidget {
  const _HadithSearchField({
    required this.controller,
    required this.value,
    required this.onChanged,
    required this.onClear,
    this.large = false,
  });

  final TextEditingController controller;
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        cursorColor: theme.colorScheme.primary,
        style: AppTypography.searchField(
          context,
          color: theme.colorScheme.surface,
        ),
        decoration: InputDecoration(
          hintText: 'ابحث عن حديث أو باب...',
          hintTextDirection: TextDirection.rtl,
          prefixIcon: value.trim().isEmpty
              ? Icon(
                  Icons.search_rounded,
                  color: theme.colorScheme.primary,
                  size: large ? 26 : 21.sp,
                )
              : IconButton(
                  onPressed: onClear,
                  icon: Icon(
                    Icons.close_rounded,
                    color: theme.colorScheme.primary,
                    size: large ? 24 : 20.sp,
                  ),
                ),
          filled: true,
          fillColor: theme.colorScheme.secondary,
          contentPadding: EdgeInsets.symmetric(
            horizontal: large ? 18 : 12.w,
            vertical: large ? 16 : 11.h,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(large ? 22 : 16.r),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withOpacity(
                isDark ? 0.20 : 0.34,
              ),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(large ? 22 : 16.r),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withOpacity(
                isDark ? 0.20 : 0.34,
              ),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(large ? 22 : 16.r),
            borderSide: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.70),
              width: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _NoSearchResultsCard extends StatelessWidget {
  const _NoSearchResultsCard({required this.query, this.large = false});

  final String query;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(large ? 18 : 14.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary,
          borderRadius: BorderRadius.circular(large ? 22 : 18.r),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.30),
          ),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Icon(
              Icons.search_off_rounded,
              color: theme.colorScheme.primary,
              size: large ? 28 : 24.sp,
            ),
            SizedBox(width: large ? 12 : 10.w),
            Expanded(
              child: Text(
                'لا توجد نتائج لـ "$query"',
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: AppTextStyles.body(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.surface.withOpacity(0.70),
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
