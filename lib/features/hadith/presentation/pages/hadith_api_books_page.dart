import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/shared/widgets/app_main_components/custom_app_bar.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import 'package:islamic_app/features/hadith/data/datasources/hadith_local_data.dart';
import 'package:islamic_app/features/hadith/data/models/hadith_category_model.dart';
import 'package:islamic_app/features/hadith/data/services/hadith_api_service.dart';
import 'package:islamic_app/features/hadith/data/services/hadith_custom_storage_service.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
part 'hadith_api_books_widgets.dart';
part 'hadith_api_import_sheet.dart';
part 'hadith_api_search_widgets.dart';
part 'hadith_api_results_widgets.dart';

bool _hadithLibraryLargeScreen(BuildContext context) {
  final Size size = MediaQuery.sizeOf(context);
  return size.shortestSide >= 600 || (size.width >= 700 && size.height >= 500);
}

class HadithApiBooksPage extends StatefulWidget {
  const HadithApiBooksPage({super.key});

  @override
  State<HadithApiBooksPage> createState() => _HadithApiBooksPageState();
}

class _HadithApiBooksPageState extends State<HadithApiBooksPage> {
  final HadithApiService _service = const HadithApiService();
  final HadithCustomStorageService _customStorageService =
      const HadithCustomStorageService();

  final TextEditingController _searchController = TextEditingController();

  late Future<List<HadithApiBookModel>> _booksFuture;
  late Future<List<HadithApiHadithModel>> _hadithsFuture;

  HadithApiBookModel _selectedBook = HadithApiService.supportedBooks.first;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    _booksFuture = _service.getBooks();
    _loadHadiths();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadHadiths() {
    _hadithsFuture = _service.getHadiths(
      book: _selectedBook,
      arabicSearch: _searchQuery,
      limit: 80,
    );
  }

  void _selectBook(HadithApiBookModel book) {
    AppHaptics.tap(context);

    setState(() {
      _selectedBook = book;
      _loadHadiths();
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _loadHadiths();
    });
  }

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _searchQuery = '';
      _loadHadiths();
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _loadHadiths();
    });

    await _hadithsFuture;
  }

  Future<void> _addHadithToCards(HadithApiHadithModel hadith) async {
    AppHaptics.tap(context);

    final result = await showModalBottomSheet<_ImportHadithResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _ImportHadithSheet(
          hadith: hadith,
          categories: HadithLocalData.categories
              .where((category) => category.id != HadithLocalData.customId)
              .toList(),
        );
      },
    );

    if (result == null) return;

    await _customStorageService.addCustomHadith(
      categoryId: result.category.id,
      title: hadith.bookName,
      text: hadith.textArabic,
      source: hadith.bookName,
      reference: [
        if (hadith.chapter != null) hadith.chapter!,
        if (hadith.hadithNumber != null) 'رقم الحديث: ${hadith.hadithNumber}',
      ].join(' • '),
      grade: hadith.status,
      book: hadith.bookName,
      chapter: hadith.chapter,
      benefit: result.benefit,
      lesson: result.lesson,
    );

    if (!mounted) return;

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
          'تمت إضافة الحديث إلى ${result.category.title}',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption(
            context,
          ).copyWith(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        duration: const Duration(milliseconds: 1600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLargeScreen = _hadithLibraryLargeScreen(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: const CustomAppBar(
        category: CustomAppBarCategory(text: 'مكتبة الحديث'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              isLargeScreen ? 24 : 14.w,
              isLargeScreen ? 14 : 10.h,
              isLargeScreen ? 24 : 14.w,
              isLargeScreen ? 28 : 18.h,
            ),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: [
              _IntroCard(selectedBook: _selectedBook),
              SizedBox(height: isLargeScreen ? 12 : 12.h),
              FutureBuilder<List<HadithApiBookModel>>(
                future: _booksFuture,
                builder: (context, snapshot) {
                  final books =
                      snapshot.data ?? HadithApiService.supportedBooks;

                  return _BooksStrip(
                    books: books,
                    selectedBook: _selectedBook,
                    onSelected: _selectBook,
                  );
                },
              ),
              SizedBox(height: isLargeScreen ? 12 : 12.h),
              _HadithApiSearchField(
                controller: _searchController,
                value: _searchQuery,
                onChanged: _onSearchChanged,
                onClear: _clearSearch,
              ),
              SizedBox(height: isLargeScreen ? 12 : 12.h),
              _SectionTitle(
                title: 'أحاديث ${_selectedBook.bookName}',
                icon: Icons.menu_book_rounded,
              ),
              SizedBox(height: isLargeScreen ? 10 : 10.h),
              FutureBuilder<List<HadithApiHadithModel>>(
                future: _hadithsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: isLargeScreen ? 30 : 26.h,
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return _ErrorCard(
                      message:
                          'تعذر تحميل الأحاديث. لو كنت فتحت هذا الكتاب قبل كده، سيتم استخدام الكاش تلقائيًا عند توفره.',
                      details: snapshot.error.toString(),
                      onRetry: () {
                        AppHaptics.tap(context);
                        setState(() {
                          _loadHadiths();
                        });
                      },
                    );
                  }

                  final hadiths = snapshot.data ?? [];

                  if (hadiths.isEmpty) {
                    return const _EmptyResultsCard(
                      text: 'لا توجد أحاديث مطابقة للبحث الحالي.',
                    );
                  }

                  return _HadithResultsLayout(
                    hadiths: hadiths,
                    onAddToCards: _addHadithToCards,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
