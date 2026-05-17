import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/App%20Main%20Screens/App%20Main%20Screens%20Components/custom_app_bar.dart';
import 'package:islamic_app/App%20Main%20Screens/kuran/main_quraan_components/to_arabic_no_converter.dart';

import '../reader/quran_bookmark_storage.dart';
import '../reader/quran_reader_helpers.dart';
import '../reader/quran_reader_page.dart';
import 'constant.dart';

class QuranBookmarksPage extends StatefulWidget {
  const QuranBookmarksPage({super.key});

  @override
  State<QuranBookmarksPage> createState() => _QuranBookmarksPageState();
}

class _QuranBookmarksPageState extends State<QuranBookmarksPage> {
  late Future<List<QuranBookmark>> bookmarksFuture;

  @override
  void initState() {
    super.initState();
    bookmarksFuture = QuranBookmarkStorage.getBookmarks();
  }

  QuranReaderViewMode parseViewMode(String savedMode) {
    return QuranReaderViewMode.values.firstWhere(
          (mode) => mode.name == savedMode,
      orElse: () => QuranReaderViewMode.continuous,
    );
  }

  Future<void> refreshBookmarks() async {
    setState(() {
      bookmarksFuture = QuranBookmarkStorage.getBookmarks();
    });
  }

  Future<void> openBookmark(QuranBookmark bookmark) async {
    final quranData = await readJson();

    if (!mounted) return;

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            QuranReaderPage(
              arabic: quranData[0],
              initialSuraIndex: bookmark.suraIndex,
              initialAyahIndex: bookmark.ayahIndex,
              initialViewMode: parseViewMode(bookmark.viewMode),
              initialMushafPageNumber: bookmark.mushafPageNumber,
            ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  Future<void> deleteBookmark(QuranBookmark bookmark) async {
    await QuranBookmarkStorage.deleteBookmark(bookmark.id);
    await refreshBookmarks();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              category: CustomAppBarCategory(text: 'علامات القرآن'),
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: FutureBuilder<List<QuranBookmark>>(
                future: bookmarksFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                    );
                  }

                  final bookmarks = snapshot.data ?? [];

                  if (bookmarks.isEmpty) {
                    return Center(
                      child: Text(
                        'لا توجد علامات محفوظة حتى الآن',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: 'cairo',
                          fontSize: 12.sp,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 10.h,
                    ),
                    itemCount: bookmarks.length,
                    separatorBuilder: (_, __) => SizedBox(height: 8.h),
                    itemBuilder: (context, index) {
                      final bookmark = bookmarks[index];

                      return _BookmarkTile(
                        bookmark: bookmark,
                        isDark: isDark,
                        onTap: () => openBookmark(bookmark),
                        onDelete: () => deleteBookmark(bookmark),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  final QuranBookmark bookmark;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BookmarkTile({
    required this.bookmark,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
  });

  String get viewModeText {
    if (bookmark.viewMode == QuranReaderViewMode.pngMushaf.name) {
      return 'مصحف';
    }

    if (bookmark.viewMode == QuranReaderViewMode.mushafText.name) {
      return 'نصي';
    }

    return 'متصل';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final backgroundColor =
    isDark ? const Color(0xff171B26) : theme.colorScheme.secondary;

    final textColor = isDark ? Colors.white : Colors.black87;

    final suraName = QuranReaderHelpers.getSuraName(bookmark.suraIndex);
    final ayahNumber = bookmark.ayahIndex + 1;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Container(
          height: 54.h,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                Icons.bookmark_rounded,
                size: 18.sp,
                color: theme.colorScheme.primary,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'سورة $suraName',
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      'آية ${ayahNumber.toString().toArabicNumbers} | ص ${bookmark.mushafPageNumber.toString().toArabicNumbers} | $viewModeText',
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: 8.sp,
                        color: textColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              IconButton(
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 18.sp,
                  color: textColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}