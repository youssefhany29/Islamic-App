import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/shared/widgets/app_main_components/custom_app_bar.dart';
import 'package:islamic_app/core/theme/app_typography.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import 'package:islamic_app/features/azkar/presentation/widgets/zekr_category_card.dart';
import 'package:islamic_app/features/azkar/presentation/widgets/zekr_daily_journey_card.dart';
import 'package:islamic_app/features/azkar/presentation/widgets/zekr_memory_plan_card.dart';
import 'package:islamic_app/features/azkar/presentation/widgets/zekr_review_calendar_card.dart';
import 'package:islamic_app/features/azkar/presentation/widgets/zekr_tasbeeh_preview_card.dart';
import 'package:islamic_app/features/azkar/presentation/widgets/zekr_today_review_card.dart';
import 'package:islamic_app/features/azkar/presentation/pages/zekr_item_details_page.dart';
import 'package:islamic_app/features/azkar/presentation/pages/zekr_memory_analytics_page.dart';
import 'package:islamic_app/features/azkar/presentation/pages/zekr_reading_page.dart';
import 'package:islamic_app/features/azkar/presentation/pages/zekr_today_review_page.dart';
import 'package:islamic_app/features/azkar/presentation/adaptive/zekr_tablet_fold_layout.dart'
    as zekr_adaptive;
import 'package:islamic_app/features/azkar/data/datasources/zekr_local_data.dart';
import 'package:islamic_app/features/azkar/data/models/zekr_category_model.dart';
import 'package:islamic_app/features/azkar/data/models/zekr_item_model.dart';
import 'package:islamic_app/features/azkar/data/services/zekr_memory_plan_preferences.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
part 'zekr_page_widgets.dart';
part 'zekr_page_search_widgets.dart';
part 'zekr_page_entry_widgets.dart';
part 'zekr_page_large_widgets.dart';

class ZekrPage extends StatefulWidget {
  const ZekrPage({super.key});

  @override
  State<ZekrPage> createState() => _ZekrPageState();
}

class _ZekrSearchResult {
  const _ZekrSearchResult({
    required this.category,
    required this.item,
    required this.score,
  });

  final ZekrCategoryModel category;
  final ZekrItemModel item;
  final int score;
}

class _ZekrPageState extends State<ZekrPage> {
  final ZekrMemoryPlanPreferences _memoryPlanPreferences =
      const ZekrMemoryPlanPreferences();

  final TextEditingController _searchController = TextEditingController();

  bool _memoryPlanEnabled = false;
  bool _memoryPlanLoading = true;
  bool _memoryPlanChanging = false;
  String _searchQuery = '';
  int _reviewCalendarRefreshTick = 0;

  @override
  void initState() {
    super.initState();
    _loadMemoryPlanState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMemoryPlanState() async {
    final enabled = await _memoryPlanPreferences.isEnabled();

    if (!mounted) return;

    setState(() {
      _memoryPlanEnabled = enabled;
      _memoryPlanLoading = false;
      _reviewCalendarRefreshTick++;
    });
  }

  void _refreshReviewCalendar() {
    if (!mounted) return;

    setState(() {
      _reviewCalendarRefreshTick++;
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  String _normalizeArabic(String input) {
    return input
        .toLowerCase()
        .replaceAll(
          RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]'),
          '',
        )
        .replaceAll('ـ', '')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ٱ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ئ', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<String> _normalizedWords(String input) {
    return _normalizeArabic(
      input,
    ).split(' ').where((word) => word.trim().isNotEmpty).toList();
  }

  int _searchScore({
    required ZekrCategoryModel category,
    required ZekrItemModel item,
    required String query,
  }) {
    final normalizedQuery = _normalizeArabic(query);
    if (normalizedQuery.isEmpty) return 999;

    final title = _normalizeArabic(item.title ?? '');
    final categoryTitle = _normalizeArabic(category.title);
    final text = _normalizeArabic(item.text);
    final benefit = _normalizeArabic(item.benefit ?? '');
    final reference = _normalizeArabic(item.reference ?? '');
    final source = _normalizeArabic(item.source ?? '');

    final allText = '$title $categoryTitle $text $benefit $reference $source';

    if (title.startsWith(normalizedQuery) ||
        categoryTitle.startsWith(normalizedQuery)) {
      return 0;
    }

    final words = _normalizedWords(allText);
    if (words.any((word) => word.startsWith(normalizedQuery))) {
      return 1;
    }

    if (allText.contains(normalizedQuery)) {
      return 2;
    }

    return 999;
  }

  List<_ZekrSearchResult> _searchResultsFor(String query) {
    final normalizedQuery = _normalizeArabic(query);
    if (normalizedQuery.isEmpty) return [];

    final List<_ZekrSearchResult> results = [];

    for (final category in ZekrLocalData.categories) {
      final items = ZekrLocalData.getBuiltInItems(category.id);

      for (final item in items) {
        final score = _searchScore(
          category: category,
          item: item,
          query: normalizedQuery,
        );

        if (score == 999) continue;

        results.add(
          _ZekrSearchResult(category: category, item: item, score: score),
        );
      }
    }

    results.sort((a, b) {
      final scoreCompare = a.score.compareTo(b.score);
      if (scoreCompare != 0) return scoreCompare;

      final countCompare = a.item.count.compareTo(b.item.count);
      if (countCompare != 0) return countCompare;

      return (a.item.title ?? a.category.title).compareTo(
        b.item.title ?? b.category.title,
      );
    });

    return results;
  }

  Future<void> _openSearchResult(_ZekrSearchResult result) async {
    AppHaptics.tap(context);

    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return ZekrItemDetailsPage(
            category: result.category,
            item: result.item,
          );
        },
        transitionDuration: const Duration(milliseconds: 240),
        reverseTransitionDuration: const Duration(milliseconds: 190),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curvedAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.045),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            ),
          );
        },
      ),
    );

    if (!mounted) return;

    _refreshReviewCalendar();
  }

  Future<void> _setMemoryPlanEnabled(bool value) async {
    if (_memoryPlanChanging) return;

    setState(() {
      _memoryPlanChanging = true;
    });

    await _memoryPlanPreferences.setEnabled(value);

    if (!mounted) return;

    setState(() {
      _memoryPlanEnabled = value;
      _memoryPlanChanging = false;
      _reviewCalendarRefreshTick++;
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        margin: EdgeInsets.only(left: 24.w, right: 24.w, bottom: 18.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        content: Text(
          value ? 'تم تفعيل خطة الحفظ' : 'تم إيقاف خطة الحفظ',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption(
            context,
          ).copyWith(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  Future<void> _openCategory(ZekrCategoryModel category) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return ZekrReadingPage(category: category);
        },
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );

    if (!mounted) return;

    _refreshReviewCalendar();
  }

  Future<void> _openTodayReview() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ZekrTodayReviewPage()),
    );

    if (!mounted) return;

    _refreshReviewCalendar();
  }

  Future<void> _openAnalytics() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ZekrMemoryAnalyticsPage()),
    );

    if (!mounted) return;

    _refreshReviewCalendar();
  }

  @override
  Widget build(BuildContext context) {
    final List<ZekrCategoryModel> categories = ZekrLocalData.categories;
    final bool isSearching = _searchQuery.trim().isNotEmpty;
    final List<_ZekrSearchResult> searchResults = isSearching
        ? _searchResultsFor(_searchQuery)
        : [];

    final Size size = MediaQuery.sizeOf(context);

    final bool isTablet = size.shortestSide >= 600;
    final bool isUnfoldedFold =
        size.width >= 700 && size.height >= 500 && size.shortestSide < 600;

    final bool isLargeScreen = isTablet || isUnfoldedFold;

    final Widget searchField = _ZekrSearchField(
      controller: _searchController,
      value: _searchQuery,
      onChanged: _onSearchChanged,
      onClear: _clearSearch,
      large: isLargeScreen,
    );

    final Widget largeContentBelowSearch = isSearching
        ? _ZekrLargeSearchResultsSection(
            query: _searchQuery,
            searchResults: searchResults,
            onOpenSearchResult: _openSearchResult,
          )
        : ZekrLargeCategoriesGrid(
            categories: categories,
            onOpenCategory: _openCategory,
          );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: const CustomAppBar(category: CustomAppBarCategory(text: 'أذكار')),
      body: SafeArea(
        child: isLargeScreen
            ? zekr_adaptive.ZekrTabletFoldLayout(
                memoryPlanLoading: _memoryPlanLoading,
                memoryPlanEnabled: _memoryPlanEnabled,
                memoryPlanChanging: _memoryPlanChanging,
                reviewCalendarRefreshTick: _reviewCalendarRefreshTick,
                onMemoryPlanChanged: _setMemoryPlanEnabled,
                onOpenAnalytics: _openAnalytics,
                onOpenTodayReview: _openTodayReview,
                searchField: searchField,
                contentBelowSearch: largeContentBelowSearch,
              )
            : _PhoneZekrBody(
                memoryPlanLoading: _memoryPlanLoading,
                memoryPlanEnabled: _memoryPlanEnabled,
                memoryPlanChanging: _memoryPlanChanging,
                reviewCalendarRefreshTick: _reviewCalendarRefreshTick,
                onMemoryPlanChanged: _setMemoryPlanEnabled,
                onOpenAnalytics: _openAnalytics,
                onOpenTodayReview: _openTodayReview,
                isSearching: isSearching,
                searchResults: searchResults,
                categories: categories,
                searchField: searchField,
                searchQuery: _searchQuery,
                onOpenSearchResult: _openSearchResult,
                onOpenCategory: _openCategory,
              ),
      ),
    );
  }
}
