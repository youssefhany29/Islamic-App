import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/shared/widgets/app_main_components/custom_app_bar.dart';
import 'package:islamic_app/features/quran/main_quraan_components/to_arabic_no_converter.dart';
import 'package:islamic_app/core/services/app_haptics.dart';
import '../reader/quran_bookmark_storage.dart';
import '../reader/quran_reader_helpers.dart';
import '../reader/qpc_connected_mushaf_page.dart';

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

  Future<void> refreshBookmarks() async {
    setState(() {
      bookmarksFuture = QuranBookmarkStorage.getBookmarks();
    });
  }

  Future<void> openBookmark(QuranBookmark bookmark) async {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            QpcConnectedMushafPage(
          initialPage: bookmark.mushafPageNumber,
          initialGlobalAyahIndex: QuranReaderHelpers.getGlobalAyahIndex(
            suraIndex: bookmark.suraIndex,
            ayahIndex: bookmark.ayahIndex,
          ),
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
    final bool isLargeScreen = MediaQuery.sizeOf(context).width >= 600;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
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

            if (isLargeScreen) {
              return _buildLargeScreenContent(context, bookmarks, isDark);
            }

            return _buildPhoneContent(context, bookmarks, isDark);
          },
        ),
      ),
    );
  }

  Widget _buildPhoneContent(
    BuildContext context,
    List<QuranBookmark> bookmarks,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        CustomAppBar(
          category: CustomAppBarCategory(text: 'علامات القرآن'),
        ),
        SizedBox(height: 12.h),
        Expanded(
          child: bookmarks.isEmpty
              ? Center(
                  child: Text(
                    'لا توجد علامات محفوظة حتى الآن',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'cairo',
                      fontSize: 12.sp,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                )
              : ListView.separated(
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
                ),
        ),
      ],
    );
  }

  Widget _buildLargeScreenContent(
    BuildContext context,
    List<QuranBookmark> bookmarks,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final bool isFold = _QuranAdaptiveSizes.isFoldLandscape(context);
    final int crossAxisCount = isFold ? 2 : 3;
    final double horizontalPadding = isFold ? 18 : 26;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding:
            EdgeInsets.fromLTRB(horizontalPadding, 18, horizontalPadding, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LargePageTitle(
              title: 'علامات القرآن',
              subtitle:
                  '${bookmarks.length.toString().toArabicNumbers} علامة محفوظة',
              onBack: () => Navigator.maybePop(context),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: bookmarks.isEmpty
                  ? Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        'لا توجد علامات محفوظة حتى الآن',
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'cairo',
                          fontSize: isFold ? 13 : 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    )
                  : Container(
                      padding: EdgeInsets.all(isFold ? 14 : 18),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              const Text(
                                'العلامات المحفوظة',
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontFamily: 'cairo',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${bookmarks.length.toString().toArabicNumbers} علامة',
                                textDirection: TextDirection.rtl,
                                style: const TextStyle(
                                  fontFamily: 'cairo',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: GridView.builder(
                              physics: const ClampingScrollPhysics(),
                              padding: EdgeInsets.zero,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: isFold ? 8 : 10,
                                crossAxisSpacing: isFold ? 8 : 10,
                                mainAxisExtent: isFold ? 78 : 84,
                              ),
                              itemCount: bookmarks.length,
                              itemBuilder: (context, index) {
                                final bookmark = bookmarks[index];

                                return _BookmarkTile(
                                  bookmark: bookmark,
                                  isDark: isDark,
                                  large: true,
                                  onTap: () => openBookmark(bookmark),
                                  onDelete: () => deleteBookmark(bookmark),
                                );
                              },
                            ),
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

class _BookmarkTile extends StatelessWidget {
  final QuranBookmark bookmark;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool large;

  const _BookmarkTile({
    required this.bookmark,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
    this.large = false,
  });

  String get viewModeText {
    if (bookmark.viewMode == 'pngMushaf') {
      return 'مصحف';
    }

    if (bookmark.viewMode == 'mushafText') {
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
      borderRadius: BorderRadius.circular(large ? 14 : 14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(large ? 14 : 14.r),
        onTap: () {
          AppHaptics.tap(context);
          onTap();
        },
        child: Container(
          height: large ? 78 : 54.h,
          padding: EdgeInsets.symmetric(
            horizontal: large ? 12 : 12.w,
            vertical: large ? 8 : 8.h,
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                Icons.bookmark_rounded,
                size: large ? 20 : 18.sp,
                color: theme.colorScheme.primary,
              ),
              SizedBox(width: large ? 10 : 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'سورة $suraName',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: large ? 12.5 : 11.sp,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: large ? 4 : 3.h),
                    Text(
                      'آية ${ayahNumber.toString().toArabicNumbers} | ص ${bookmark.mushafPageNumber.toString().toArabicNumbers} | $viewModeText',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: large ? 9.5 : 8.sp,
                        color: textColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: large ? 8 : 8.w),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(
                  minWidth: large ? 34 : 32.w,
                  minHeight: large ? 34 : 32.h,
                ),
                onPressed: () {
                  AppHaptics.medium(context);
                  onDelete();
                },
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: large ? 20 : 18.sp,
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

class _LargePageTitle extends StatelessWidget {
  const _LargePageTitle({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                title,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body(context).copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onBackground,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onBackground.withOpacity(0.55),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _RoundBackButton(onTap: onBack),
      ],
    );
  }
}

class _RoundBackButton extends StatelessWidget {
  const _RoundBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xff222837)
              : theme.colorScheme.secondary.withOpacity(0.96),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 18,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _QuranAdaptiveSizes {
  const _QuranAdaptiveSizes._();

  static bool isFoldLandscape(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width >= 600 && size.shortestSide < 600;
  }

  static double pageTitle(BuildContext context) {
    return isFoldLandscape(context) ? 18 : 23;
  }

  static double subtitle(BuildContext context) {
    return isFoldLandscape(context) ? 11 : 13;
  }
}
