part of 'hadith_api_books_page.dart';

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.selectedBook});

  final HadithApiBookModel selectedBook;

  void _showLibraryInfo(BuildContext context) {
    AppHaptics.tap(context);

    final theme = Theme.of(context);
    final bool isLargeScreen = _hadithLibraryLargeScreen(context);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: theme.colorScheme.secondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isLargeScreen ? 24 : 20.r),
            ),
            title: Text(
              'ماذا يحدث عند إضافة الحديث؟',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.body(context).copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.surface,
                height: 1.35,
              ),
            ),
            content: Text(
              'عند إضافة الحديث إلى الكروت، سيظهر داخل القسم الذي تختاره، ويمكنك حفظه ومراجعته من خلال خطة الحفظ، درّبني على الحفظ، مراجعة اليوم، تحليل الحفظ، وتقويم المراجعة.',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.caption(context).copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.surface.withOpacity(0.72),
                height: 1.65,
              ),
            ),
            actionsAlignment: MainAxisAlignment.start,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'فهمت',
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isLargeScreen = _hadithLibraryLargeScreen(context);
    final double radius = isLargeScreen ? 22 : 20.r;
    final double padding = isLargeScreen ? 14 : 13.w;
    final double iconBox = isLargeScreen ? 40 : 38.w;
    final double iconSize = isLargeScreen ? 21 : 20.sp;
    final double actionBox = isLargeScreen ? 32 : 30.w;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.18),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: iconBox,
              height: iconBox,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(isLargeScreen ? 14 : 13.r),
              ),
              child: Icon(
                Icons.menu_book_rounded,
                color: Colors.white,
                size: iconSize,
              ),
            ),
            SizedBox(width: isLargeScreen ? 10 : 9.w),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      'مكتبة الأحاديث',
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      locale: const Locale('ar'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body(context).copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.3,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  SizedBox(height: isLargeScreen ? 3 : 3.h),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      'تصفح الكتب وابحث داخل الأحاديث وأضف المناسب لك.',
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      locale: const Locale('ar'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.78),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: isLargeScreen ? 8 : 8.w),
            InkWell(
              onTap: () => _showLibraryInfo(context),
              borderRadius: BorderRadius.circular(isLargeScreen ? 11 : 10.r),
              child: Container(
                width: actionBox,
                height: actionBox,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(
                    isLargeScreen ? 11 : 10.r,
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.18),
                    width: 0.8,
                  ),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white,
                  size: isLargeScreen ? 17 : 16.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BooksStrip extends StatelessWidget {
  const _BooksStrip({
    required this.books,
    required this.selectedBook,
    required this.onSelected,
  });

  final List<HadithApiBookModel> books;
  final HadithApiBookModel selectedBook;
  final ValueChanged<HadithApiBookModel> onSelected;

  @override
  Widget build(BuildContext context) {
    final bool isLargeScreen = _hadithLibraryLargeScreen(context);

    return SizedBox(
      height: isLargeScreen ? 38 : 36.h,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: books.length,
          separatorBuilder: (_, __) => SizedBox(width: isLargeScreen ? 8 : 7.w),
          itemBuilder: (context, index) {
            final book = books[index];
            final selected = book.bookSlug == selectedBook.bookSlug;

            return _BookChip(
              title: book.bookName,
              selected: selected,
              onTap: () => onSelected(book),
            );
          },
        ),
      ),
    );
  }
}

class _BookChip extends StatelessWidget {
  const _BookChip({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isLargeScreen = _hadithLibraryLargeScreen(context);

    return InkWell(
      borderRadius: BorderRadius.circular(isLargeScreen ? 12 : 12.r),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(horizontal: isLargeScreen ? 12 : 10.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.secondary,
          borderRadius: BorderRadius.circular(isLargeScreen ? 12 : 12.r),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.30),
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption(context).copyWith(
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : theme.colorScheme.surface,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

class _HadithApiSearchField extends StatelessWidget {
  const _HadithApiSearchField({
    required this.controller,
    required this.value,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isLargeScreen = _hadithLibraryLargeScreen(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        cursorColor: theme.colorScheme.primary,
        style: AppTextStyles.caption(context).copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.surface,
          height: 1.4,
        ),
        decoration: InputDecoration(
          hintText: 'ابحث داخل الكتاب المختار...',
          hintTextDirection: TextDirection.rtl,
          prefixIcon: value.trim().isEmpty
              ? Icon(
                  Icons.search_rounded,
                  color: theme.colorScheme.primary,
                  size: isLargeScreen ? 26 : 21.sp,
                )
              : IconButton(
                  onPressed: onClear,
                  icon: Icon(
                    Icons.close_rounded,
                    color: theme.colorScheme.primary,
                    size: isLargeScreen ? 24 : 20.sp,
                  ),
                ),
          filled: true,
          fillColor: theme.colorScheme.secondary,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isLargeScreen ? 18 : 12.w,
            vertical: isLargeScreen ? 16 : 11.h,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isLargeScreen ? 22 : 16.r),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withOpacity(
                isDark ? 0.20 : 0.34,
              ),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isLargeScreen ? 22 : 16.r),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withOpacity(
                isDark ? 0.20 : 0.34,
              ),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isLargeScreen ? 22 : 16.r),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isLargeScreen = _hadithLibraryLargeScreen(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: isLargeScreen ? 34 : 30.w,
            height: isLargeScreen ? 34 : 30.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.09),
              borderRadius: BorderRadius.circular(isLargeScreen ? 12 : 10.r),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: isLargeScreen ? 18 : 16.sp,
            ),
          ),
          SizedBox(width: isLargeScreen ? 8 : 7.w),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              locale: const Locale('ar'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body(context).copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.surface,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
