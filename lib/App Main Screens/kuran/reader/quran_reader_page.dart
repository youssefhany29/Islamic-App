import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/App%20Main%20Screens/App%20Main%20Screens%20Components/custom_app_bar.dart';
import 'package:islamic_app/App%20Main%20Screens/kuran/main_quraan_components/to_arabic_no_converter.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main_quraan_components/constant.dart';
import 'quran_bookmark_storage.dart';
import 'quran_page_mapper.dart';
import 'quran_png_mushaf_view.dart';
import 'quran_reader_helpers.dart';
import 'quran_reader_storage.dart';
import 'quran_text_mushaf_view.dart';

enum QuranReaderViewMode {
  continuous,
  mushafText,
  pngMushaf,
}

class QuranReaderPage extends StatefulWidget {
  final dynamic arabic;
  final int initialSuraIndex;
  final int initialAyahIndex;
  final QuranReaderViewMode initialViewMode;
  final int? initialMushafPageNumber;

  const QuranReaderPage({
    super.key,
    required this.arabic,
    required this.initialSuraIndex,
    required this.initialAyahIndex,
    this.initialViewMode = QuranReaderViewMode.continuous,
    this.initialMushafPageNumber,
  });

  @override
  State<QuranReaderPage> createState() => _QuranReaderPageState();
}

class _QuranReaderPageState extends State<QuranReaderPage> {
  final ItemScrollController itemScrollController = ItemScrollController();

  final ItemPositionsListener itemPositionsListener =
  ItemPositionsListener.create();

  late final PageController pageController;
  late final List<List<int>> quranPages;

  Timer? saveDebounce;

  double readerFontSize = 22.0;
  QuranReaderViewMode viewMode = QuranReaderViewMode.continuous;

  late int currentGlobalAyahIndex;
  int currentMushafPageNumber = 1;

  bool showMushafControls = true;

  static const int maxAyahsPerPage = 10;
  static const String fontSizeKey = 'quran_reader_font_size';

  QuranAyahPosition get currentPosition {
    return QuranReaderHelpers.getPositionFromGlobalIndex(currentGlobalAyahIndex);
  }

  String get basmalaText {
    final rawBasmala = widget.arabic[0]['aya_text'].toString();
    return cleanBasmalaText(rawBasmala);
  }

  String cleanBasmalaText(String text) {
    var cleaned = text.trim();

    cleaned = cleaned.replaceAll(
      RegExp(r'[\u06DD\u06DE\u06E9\uFD3E\uFD3F۝۞۩﴿﴾٠-٩۰-۹0-9]+'),
      ' ',
    );

    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    final words = cleaned.split(' ');

    final quranWords = words.where((word) {
      final hasArabicLetter = RegExp(
        r'[\u0621-\u063A\u0641-\u064A\u0671-\u06D3]',
      ).hasMatch(word);

      final hasNumber = RegExp(r'[٠-٩۰-۹0-9]').hasMatch(word);

      return hasArabicLetter && !hasNumber;
    }).toList();

    if (quranWords.length >= 4) {
      return quranWords.take(4).join(' ');
    }

    final onlyArabic = cleaned
        .replaceAll(
      RegExp(
        r'[^\u0621-\u063A\u0641-\u064A\u064B-\u065F\u0670\u0671-\u06D3\s]',
      ),
      ' ',
    )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final onlyArabicWords = onlyArabic.split(' ').where((word) {
      return word.trim().isNotEmpty;
    }).toList();

    if (onlyArabicWords.length >= 4) {
      return onlyArabicWords.take(4).join(' ');
    }

    return 'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحـِيـمِ';
  }

  @override
  void initState() {
    super.initState();

    loadReaderFontSize();

    quranPages = buildQuranPages();

    viewMode = widget.initialViewMode;

    currentGlobalAyahIndex = QuranReaderHelpers.getGlobalAyahIndex(
      suraIndex: widget.initialSuraIndex,
      ayahIndex: widget.initialAyahIndex,
    );

    currentMushafPageNumber = widget.initialMushafPageNumber ??
        QuranPageMapper.getPageNumberForGlobalAyah(currentGlobalAyahIndex);

    final initialPageIndex = viewMode == QuranReaderViewMode.pngMushaf
        ? currentMushafPageNumber - 1
        : getPageIndexForGlobalAyah(currentGlobalAyahIndex);

    pageController = PageController(
      initialPage: initialPageIndex,
    );

    itemPositionsListener.itemPositions.addListener(handleVisibleAyahChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await loadPageMapAndSync();

      if (viewMode != QuranReaderViewMode.continuous) return;
      if (!itemScrollController.isAttached) return;

      itemScrollController.jumpTo(index: currentGlobalAyahIndex);
    });
  }

  Future<void> loadPageMapAndSync() async {
    await QuranPageMapper.load();

    if (!mounted) return;

    final mappedPageNumber = widget.initialMushafPageNumber ??
        QuranPageMapper.getPageNumberForGlobalAyah(currentGlobalAyahIndex);

    setState(() {
      currentMushafPageNumber = mappedPageNumber;
    });

    if (viewMode == QuranReaderViewMode.pngMushaf && pageController.hasClients) {
      pageController.jumpToPage(currentMushafPageNumber - 1);
    }
  }

  @override
  void dispose() {
    saveDebounce?.cancel();
    pageController.dispose();
    itemPositionsListener.itemPositions.removeListener(handleVisibleAyahChanged);
    super.dispose();
  }

  Future<void> loadReaderFontSize() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      readerFontSize = prefs.getDouble(fontSizeKey) ?? 22.0;
    });
  }

  Future<void> saveReaderFontSize(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(fontSizeKey, value);
  }

  void openFontSizeSheet() {
    double tempFontSize = readerFontSize;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20.r),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;
            final textColor = isDark ? Colors.white : Colors.black87;

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.all(18.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'حجم خط القرآن',
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      basmalaText,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      strutStyle: StrutStyle(
                        fontSize: tempFontSize.sp,
                        height: 2.25,
                        forceStrutHeight: true,
                      ),
                      style: TextStyle(
                        fontFamily: arabicFont,
                        fontSize: tempFontSize.sp,
                        height: 2.25,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Slider(
                      min: 18,
                      max: 34,
                      divisions: 16,
                      value: tempFontSize,
                      onChanged: (value) {
                        setModalState(() {
                          tempFontSize = value;
                        });

                        setState(() {
                          readerFontSize = value;
                        });

                        saveReaderFontSize(value);
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'صغير',
                          style: TextStyle(
                            fontFamily: 'cairo',
                            fontSize: 10.sp,
                            color: textColor.withOpacity(0.65),
                          ),
                        ),
                        Text(
                          tempFontSize.toStringAsFixed(0),
                          style: TextStyle(
                            fontFamily: 'cairo',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'كبير',
                          style: TextStyle(
                            fontFamily: 'cairo',
                            fontSize: 10.sp,
                            color: textColor.withOpacity(0.65),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> saveCurrentBookmark() async {
    final position = currentPosition;

    final bookmark = QuranBookmark(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      suraIndex: position.suraIndex,
      ayahIndex: position.ayahIndex,
      mushafPageNumber: currentMushafPageNumber,
      viewMode: viewMode.name,
      createdAt: DateTime.now().toIso8601String(),
    );

    await QuranBookmarkStorage.addBookmark(bookmark);

    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        margin: EdgeInsets.only(
          left: 24.w,
          right: 24.w,
          bottom: 18.h,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        content: Text(
          'تم حفظ الموضع الحالي',
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: 'cairo',
            fontSize: 11.sp,
            color: Colors.white,
          ),
        ),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  List<List<int>> buildQuranPages() {
    final List<List<int>> pages = [];

    int globalIndex = 0;

    for (int suraIndex = 0; suraIndex < noOfVerses.length; suraIndex++) {
      final int suraAyahCount = noOfVerses[suraIndex];

      int ayahIndex = 0;

      while (ayahIndex < suraAyahCount) {
        final int remainingAyahs = suraAyahCount - ayahIndex;
        final int takeCount =
        remainingAyahs > maxAyahsPerPage ? maxAyahsPerPage : remainingAyahs;

        final pageAyahs = List.generate(
          takeCount,
              (index) => globalIndex + ayahIndex + index,
        );

        pages.add(pageAyahs);

        ayahIndex += takeCount;
      }

      globalIndex += suraAyahCount;
    }

    return pages;
  }

  int getPageIndexForGlobalAyah(int globalAyahIndex) {
    for (int pageIndex = 0; pageIndex < quranPages.length; pageIndex++) {
      final page = quranPages[pageIndex];

      if (page.contains(globalAyahIndex)) {
        return pageIndex;
      }
    }

    return 0;
  }

  int getGlobalAyahIndexFromMushafPage(int pageNumber) {
    return QuranPageMapper.getGlobalAyahIndexForPage(pageNumber);
  }

  int getMushafPageNumberFromGlobalAyah(int globalAyahIndex) {
    return QuranPageMapper.getPageNumberForGlobalAyah(globalAyahIndex);
  }

  void jumpToMushafPage(int pageNumber) {
    final safePageNumber = pageNumber.clamp(1, 604);

    if (!pageController.hasClients) return;

    pageController.jumpToPage(safePageNumber - 1);

    final pageFirstGlobalIndex = getGlobalAyahIndexFromMushafPage(
      safePageNumber,
    );

    final position = QuranReaderHelpers.getPositionFromGlobalIndex(
      pageFirstGlobalIndex,
    );

    setState(() {
      currentMushafPageNumber = safePageNumber;
      currentGlobalAyahIndex = pageFirstGlobalIndex;
    });

    QuranReaderStorage.saveLastRead(
      suraIndex: position.suraIndex,
      ayahIndex: position.ayahIndex,
      viewMode: QuranReaderViewMode.pngMushaf.name,
      mushafPageNumber: safePageNumber,
    );
  }

  void toggleMushafControls() {
    if (viewMode != QuranReaderViewMode.pngMushaf) return;

    setState(() {
      showMushafControls = !showMushafControls;
    });
  }

  void handleVisibleAyahChanged() {
    if (viewMode != QuranReaderViewMode.continuous) return;

    final positions = itemPositionsListener.itemPositions.value;

    if (positions.isEmpty) return;

    final visiblePositions = positions
        .where((position) => position.itemLeadingEdge >= 0)
        .toList();

    if (visiblePositions.isEmpty) return;

    visiblePositions.sort(
          (a, b) => a.itemLeadingEdge.compareTo(b.itemLeadingEdge),
    );

    final firstVisibleIndex = visiblePositions.first.index;

    updateCurrentPosition(firstVisibleIndex);
  }

  void updateCurrentPosition(int globalAyahIndex) {
    saveDebounce?.cancel();

    saveDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;

      if (currentGlobalAyahIndex != globalAyahIndex) {
        setState(() {
          currentGlobalAyahIndex = globalAyahIndex;
          currentMushafPageNumber = getMushafPageNumberFromGlobalAyah(
            globalAyahIndex,
          );
        });
      }

      final position = QuranReaderHelpers.getPositionFromGlobalIndex(
        globalAyahIndex,
      );

      QuranReaderStorage.saveLastRead(
        suraIndex: position.suraIndex,
        ayahIndex: position.ayahIndex,
        viewMode: viewMode.name,
        mushafPageNumber: currentMushafPageNumber,
      );
    });
  }

  void changeViewMode(QuranReaderViewMode mode) {
    if (mode == viewMode) return;

    setState(() {
      viewMode = mode;

      if (mode == QuranReaderViewMode.pngMushaf) {
        showMushafControls = true;
      }
    });

    QuranReaderStorage.saveLastRead(
      suraIndex: currentPosition.suraIndex,
      ayahIndex: currentPosition.ayahIndex,
      viewMode: mode.name,
      mushafPageNumber: currentMushafPageNumber,
    );

    if (mode == QuranReaderViewMode.continuous) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!itemScrollController.isAttached) return;

        itemScrollController.jumpTo(index: currentGlobalAyahIndex);
      });
    }

    if (mode == QuranReaderViewMode.mushafText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!pageController.hasClients) return;

        pageController.jumpToPage(
          getPageIndexForGlobalAyah(currentGlobalAyahIndex),
        );
      });
    }

    if (mode == QuranReaderViewMode.pngMushaf) {
      currentMushafPageNumber = getMushafPageNumberFromGlobalAyah(
        currentGlobalAyahIndex,
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!pageController.hasClients) return;

        pageController.jumpToPage(currentMushafPageNumber - 1);
      });
    }
  }

  String getAyahText(int globalAyahIndex) {
    return widget.arabic[globalAyahIndex]['aya_text'].toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final position = currentPosition;
    final suraName = QuranReaderHelpers.getSuraName(position.suraIndex);

    final juzNumber = QuranReaderHelpers.getJuzNumber(
      suraIndex: position.suraIndex,
      ayahIndex: position.ayahIndex,
    );

    final pageNumber = viewMode == QuranReaderViewMode.pngMushaf
        ? currentMushafPageNumber
        : getMushafPageNumberFromGlobalAyah(currentGlobalAyahIndex);

    final readerTopBar = _ReaderTopBar(
      suraName: suraName,
      ayahNumber: position.ayahIndex + 1,
      juzNumber: juzNumber,
      pageNumber: pageNumber,
      selectedMode: viewMode,
      onModeSelected: changeViewMode,
      onFontSizeTap: openFontSizeSheet,
      onBookmarkTap: saveCurrentBookmark,
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: ColoredBox(
        color: theme.colorScheme.background,
        child: SafeArea(
          child: Column(
            children: [
              CustomAppBar(
                category: CustomAppBarCategory(text: 'القرآن'),
              ),

              // ✅ ثابت في كل الأوضاع: متصل / نصي / مصحف
              SizedBox(height: 8.h),
              readerTopBar,
              SizedBox(height: 8.h),

              Expanded(
                child: viewMode == QuranReaderViewMode.continuous
                    ? _ContinuousQuranView(
                  key: const ValueKey('continuous'),
                  getAyahText: getAyahText,
                  itemScrollController: itemScrollController,
                  itemPositionsListener: itemPositionsListener,
                  isDark: isDark,
                  fontSize: readerFontSize,
                  basmalaText: basmalaText,
                )
                    : viewMode == QuranReaderViewMode.mushafText
                    ? QuranTextMushafView(
                  key: const ValueKey('mushafText'),
                  pageController: pageController,
                  quranPages: quranPages,
                  getAyahText: getAyahText,
                  selectedGlobalAyahIndex: currentGlobalAyahIndex,
                  onPageChanged: (pageIndex) {
                    final firstAyahIndex = quranPages[pageIndex].first;
                    updateCurrentPosition(firstAyahIndex);
                  },
                  onAyahTap: (globalAyahIndex) {
                    updateCurrentPosition(globalAyahIndex);
                  },
                  isDark: isDark,
                  fontSize: readerFontSize,
                  basmalaText: basmalaText,
                )
                    : QuranPngMushafView(
                  key: const ValueKey('pngMushaf'),
                  pageController: pageController,
                  selectedPageNumber: currentMushafPageNumber,
                  isDark: isDark,
                  controlsVisible: showMushafControls,
                  onToggleControls: toggleMushafControls,

                  // هنسيبه موجود عشان لو الكلاس لسه طالبه،
                  // بس مش هنستخدمه جوه quran_png_mushaf_view بعد التعديل.
                  topBar: readerTopBar,

                  currentSuraName: suraName,
                  currentJuzNumber: juzNumber,
                  onJumpToPage: jumpToMushafPage,
                  onPageChanged: (pageNumber) {
                    final pageFirstGlobalIndex =
                    getGlobalAyahIndexFromMushafPage(pageNumber);

                    final pagePosition =
                    QuranReaderHelpers.getPositionFromGlobalIndex(
                      pageFirstGlobalIndex,
                    );

                    setState(() {
                      currentMushafPageNumber = pageNumber;
                      currentGlobalAyahIndex = pageFirstGlobalIndex;
                    });

                    QuranReaderStorage.saveLastRead(
                      suraIndex: pagePosition.suraIndex,
                      ayahIndex: pagePosition.ayahIndex,
                      viewMode: QuranReaderViewMode.pngMushaf.name,
                      mushafPageNumber: pageNumber,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReaderTopBar extends StatelessWidget {
  final String suraName;
  final int ayahNumber;
  final int juzNumber;
  final int pageNumber;
  final QuranReaderViewMode selectedMode;
  final ValueChanged<QuranReaderViewMode> onModeSelected;
  final VoidCallback onFontSizeTap;
  final VoidCallback onBookmarkTap;

  const _ReaderTopBar({
    required this.suraName,
    required this.ayahNumber,
    required this.juzNumber,
    required this.pageNumber,
    required this.selectedMode,
    required this.onModeSelected,
    required this.onFontSizeTap,
    required this.onBookmarkTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor =
    isDark ? const Color(0xff171B26) : theme.colorScheme.secondary;

    final textColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Container(
        width: double.infinity,
        height: 40.h,
        padding: EdgeInsets.symmetric(horizontal: 5.w),
        decoration: BoxDecoration(
          color: backgroundColor.withOpacity(0.94),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            _SmallModeSelector(
              selectedMode: selectedMode,
              onModeSelected: onModeSelected,
            ),
            SizedBox(width: 3.w),
            _MiniIconButton(
              icon: Icons.text_fields_rounded,
              onTap: onFontSizeTap,
            ),
            SizedBox(width: 3.w),
            _MiniIconButton(
              icon: Icons.bookmark_add_rounded,
              onTap: onBookmarkTap,
            ),
            SizedBox(width: 5.w),
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
                      fontSize: 8.2.sp,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    'آية ${ayahNumber.toString().toArabicNumbers} | ج ${juzNumber.toString().toArabicNumbers} | ص ${pageNumber.toString().toArabicNumbers}',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'cairo',
                      fontSize: 5.7.sp,
                      height: 1.0,
                      color: textColor.withOpacity(0.62),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MiniIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primary,
      borderRadius: BorderRadius.circular(7.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(7.r),
        onTap: onTap,
        child: SizedBox(
          width: 22.w,
          height: 26.h,
          child: Icon(
            icon,
            size: 12.sp,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _SmallModeSelector extends StatelessWidget {
  final QuranReaderViewMode selectedMode;
  final ValueChanged<QuranReaderViewMode> onModeSelected;

  const _SmallModeSelector({
    required this.selectedMode,
    required this.onModeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedColor =
    isDark ? const Color(0xff171B26) : const Color(0xffDEE9EF);

    return Container(
      height: 27.h,
      padding: EdgeInsets.all(2.5.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          _SmallModeButton(
            title: 'متصل',
            isSelected: selectedMode == QuranReaderViewMode.continuous,
            selectedColor: selectedColor,
            onTap: () => onModeSelected(QuranReaderViewMode.continuous),
          ),
          SizedBox(width: 2.w),
          _SmallModeButton(
            title: 'نصي',
            isSelected: selectedMode == QuranReaderViewMode.mushafText,
            selectedColor: selectedColor,
            onTap: () => onModeSelected(QuranReaderViewMode.mushafText),
          ),
          SizedBox(width: 2.w),
          _SmallModeButton(
            title: 'مصحف',
            isSelected: selectedMode == QuranReaderViewMode.pngMushaf,
            selectedColor: selectedColor,
            onTap: () => onModeSelected(QuranReaderViewMode.pngMushaf),
          ),
        ],
      ),
    );
  }
}

class _SmallModeButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _SmallModeButton({
    required this.title,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = isSelected
        ? isDark
        ? Colors.white
        : Colors.black
        : Colors.white70;

    return Material(
      color: isSelected ? selectedColor : Colors.transparent,
      borderRadius: BorderRadius.circular(6.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(6.r),
        onTap: onTap,
        child: SizedBox(
          width: 42.w,
          height: 22.h,
          child: Center(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontFamily: 'cairo',
                fontSize: 8.5.sp,
                fontWeight: FontWeight.w800,
                height: 1.0,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContinuousQuranView extends StatelessWidget {
  final String Function(int globalAyahIndex) getAyahText;
  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;
  final bool isDark;
  final double fontSize;
  final String basmalaText;

  const _ContinuousQuranView({
    super.key,
    required this.getAyahText,
    required this.itemScrollController,
    required this.itemPositionsListener,
    required this.isDark,
    required this.fontSize,
    required this.basmalaText,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
    isDark ? const Color(0xff171B26) : const Color(0xffFDFBF0);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22.r),
          topRight: Radius.circular(22.r),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22.r),
          topRight: Radius.circular(22.r),
        ),
        child: ScrollablePositionedList.builder(
          physics: const ClampingScrollPhysics(),
          itemCount: QuranReaderHelpers.totalAyahs,
          itemScrollController: itemScrollController,
          itemPositionsListener: itemPositionsListener,
          itemBuilder: (context, globalIndex) {
            final position = QuranReaderHelpers.getPositionFromGlobalIndex(
              globalIndex,
            );

            return Column(
              children: [
                if (position.ayahIndex == 0)
                  _SurahDivider(
                    suraName: QuranReaderHelpers.getSuraName(
                      position.suraIndex,
                    ),
                    showBasmala: QuranReaderHelpers.shouldShowBasmala(
                      suraIndex: position.suraIndex,
                      ayahIndex: position.ayahIndex,
                    ),
                    isDark: isDark,
                    fontSize: fontSize,
                    basmalaText: basmalaText,
                  ),
                _AyahReadingTile(
                  ayahText: getAyahText(globalIndex),
                  isDark: isDark,
                  isEven: globalIndex.isEven,
                  fontSize: fontSize,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SurahDivider extends StatelessWidget {
  final String suraName;
  final bool showBasmala;
  final bool isDark;
  final double fontSize;
  final String basmalaText;

  const _SurahDivider({
    required this.suraName,
    required this.showBasmala,
    required this.isDark,
    required this.fontSize,
    required this.basmalaText,
  });

  @override
  Widget build(BuildContext context) {
    final dividerColor =
    isDark ? const Color(0xff005349) : const Color(0xff224368);

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(top: 10.h),
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: dividerColor,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Center(
            child: Text(
              'سورة $suraName',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'cairo',
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        if (showBasmala)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            child: Text(
              basmalaText,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              strutStyle: StrutStyle(
                fontSize: (fontSize - 1).sp,
                height: 2.25,
                forceStrutHeight: true,
              ),
              style: TextStyle(
                fontFamily: arabicFont,
                fontSize: (fontSize - 1).sp,
                height: 2.25,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
      ],
    );
  }
}

class _AyahReadingTile extends StatelessWidget {
  final String ayahText;
  final bool isDark;
  final bool isEven;
  final double fontSize;

  const _AyahReadingTile({
    required this.ayahText,
    required this.isDark,
    required this.isEven,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDark
        ? isEven
        ? const Color(0xff1E2433)
        : const Color(0xff171B26)
        : isEven
        ? const Color(0xffFDF7E6)
        : const Color(0xffFDFBF0);

    final textColor = isDark ? Colors.white.withOpacity(0.92) : Colors.black87;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: const Border(
          bottom: BorderSide(
            color: Color(0xffDDD6C2),
            width: 0.5,
          ),
        ),
      ),
      child: Text(
        ayahText,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        strutStyle: StrutStyle(
          fontSize: fontSize.sp,
          height: 1.7,
          forceStrutHeight: true,
        ),
        style: TextStyle(
          fontSize: fontSize.sp,
          height: 1.7,
          fontFamily: arabicFont,
          color: textColor,
        ),
      ),
    );
  }
}