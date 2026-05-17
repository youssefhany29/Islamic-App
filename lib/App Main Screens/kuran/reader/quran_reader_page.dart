import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/App%20Main%20Screens/App%20Main%20Screens%20Components/custom_app_bar.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../constant.dart';
import '../to_arabic_no_converter.dart';
import 'quran_reader_helpers.dart';
import 'quran_reader_storage.dart';

enum QuranReaderViewMode {
  continuous,
  pages,
}

class QuranReaderPage extends StatefulWidget {
  final dynamic arabic;
  final int initialSuraIndex;
  final int initialAyahIndex;

  const QuranReaderPage({
    super.key,
    required this.arabic,
    required this.initialSuraIndex,
    required this.initialAyahIndex,
  });

  @override
  State<QuranReaderPage> createState() => _QuranReaderPageState();
}

class _QuranReaderPageState extends State<QuranReaderPage> {
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
  ItemPositionsListener.create();

  late final PageController pageController;

  Timer? saveDebounce;

  QuranReaderViewMode viewMode = QuranReaderViewMode.continuous;

  late int currentGlobalAyahIndex;

  static const int ayahsPerPage = 10;

  int get totalAyahs => QuranReaderHelpers.totalAyahs;

  int get totalPages => (totalAyahs / ayahsPerPage).ceil();

  QuranAyahPosition get currentPosition {
    return QuranReaderHelpers.getPositionFromGlobalIndex(currentGlobalAyahIndex);
  }

  @override
  void initState() {
    super.initState();

    currentGlobalAyahIndex = QuranReaderHelpers.getGlobalAyahIndex(
      suraIndex: widget.initialSuraIndex,
      ayahIndex: widget.initialAyahIndex,
    );

    pageController = PageController(
      initialPage: currentGlobalAyahIndex ~/ ayahsPerPage,
    );

    itemPositionsListener.itemPositions.addListener(handleVisibleAyahChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      itemScrollController.jumpTo(
        index: currentGlobalAyahIndex,
      );
    });
  }

  @override
  void dispose() {
    saveDebounce?.cancel();
    pageController.dispose();
    itemPositionsListener.itemPositions.removeListener(handleVisibleAyahChanged);
    super.dispose();
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
        });
      }

      final position = QuranReaderHelpers.getPositionFromGlobalIndex(
        globalAyahIndex,
      );

      QuranReaderStorage.saveLastRead(
        suraIndex: position.suraIndex,
        ayahIndex: position.ayahIndex,
        viewMode: viewMode.name,
      );
    });
  }

  void changeViewMode(QuranReaderViewMode mode) {
    if (mode == viewMode) return;

    setState(() {
      viewMode = mode;
    });

    QuranReaderStorage.saveLastRead(
      suraIndex: currentPosition.suraIndex,
      ayahIndex: currentPosition.ayahIndex,
      viewMode: mode.name,
    );

    if (mode == QuranReaderViewMode.continuous) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!itemScrollController.isAttached) return;

        itemScrollController.jumpTo(
          index: currentGlobalAyahIndex,
        );
      });
    }

    if (mode == QuranReaderViewMode.pages) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!pageController.hasClients) return;

        pageController.jumpToPage(
          currentGlobalAyahIndex ~/ ayahsPerPage,
        );
      });
    }
  }

  String getAyahText(int globalAyahIndex) {
    return widget.arabic[globalAyahIndex]['aya_text'].toString();
  }

  List<int> getPageAyahIndexes(int pageIndex) {
    final start = pageIndex * ayahsPerPage;
    final end = (start + ayahsPerPage).clamp(0, totalAyahs);

    return List.generate(
      end - start,
          (index) => start + index,
    );
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
    final pageNumber = QuranReaderHelpers.getApproxPageNumber(
      currentGlobalAyahIndex,
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

              SizedBox(height: 8.h),

              _ReaderInfoBar(
                suraName: suraName,
                ayahNumber: position.ayahIndex + 1,
                juzNumber: juzNumber,
                pageNumber: pageNumber,
              ),

              SizedBox(height: 8.h),

              _ReaderModeSelector(
                selectedMode: viewMode,
                onModeSelected: changeViewMode,
              ),

              SizedBox(height: 8.h),

              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: viewMode == QuranReaderViewMode.continuous
                      ? _ContinuousQuranView(
                    key: const ValueKey('continuous'),
                    arabic: widget.arabic,
                    getAyahText: getAyahText,
                    itemScrollController: itemScrollController,
                    itemPositionsListener: itemPositionsListener,
                    isDark: isDark,
                  )
                      : _PageQuranView(
                    key: const ValueKey('pages'),
                    pageController: pageController,
                    totalPages: totalPages,
                    getPageAyahIndexes: getPageAyahIndexes,
                    getAyahText: getAyahText,
                    onPageChanged: (pageIndex) {
                      final firstAyahIndex = pageIndex * ayahsPerPage;
                      updateCurrentPosition(firstAyahIndex);
                    },
                    isDark: isDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReaderInfoBar extends StatelessWidget {
  final String suraName;
  final int ayahNumber;
  final int juzNumber;
  final int pageNumber;

  const _ReaderInfoBar({
    required this.suraName,
    required this.ayahNumber,
    required this.juzNumber,
    required this.pageNumber,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor =
    isDark ? const Color(0xff171B26) : theme.colorScheme.secondary;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Container(
        height: 36.h,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: Text(
                'سورة $suraName',
                textDirection: TextDirection.rtl,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              'آية ${ayahNumber.toString().toArabicNumbers}',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'cairo',
                fontSize: 8.5.sp,
                color: textColor.withOpacity(0.65),
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              'جزء ${juzNumber.toString().toArabicNumbers}',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'cairo',
                fontSize: 8.5.sp,
                color: textColor.withOpacity(0.65),
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              'ص ${pageNumber.toString().toArabicNumbers}',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'cairo',
                fontSize: 8.5.sp,
                color: textColor.withOpacity(0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReaderModeSelector extends StatelessWidget {
  final QuranReaderViewMode selectedMode;
  final ValueChanged<QuranReaderViewMode> onModeSelected;

  const _ReaderModeSelector({
    required this.selectedMode,
    required this.onModeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Container(
        height: 38.h,
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: _ModeButton(
                title: 'متصل',
                isSelected: selectedMode == QuranReaderViewMode.continuous,
                onTap: () => onModeSelected(QuranReaderViewMode.continuous),
              ),
            ),
            SizedBox(width: 6.w),
            Expanded(
              child: _ModeButton(
                title: 'صفحات',
                isSelected: selectedMode == QuranReaderViewMode.pages,
                onTap: () => onModeSelected(QuranReaderViewMode.pages),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedColor =
    isDark ? const Color(0xff171B26) : const Color(0xffDEE9EF);

    final textColor = isSelected
        ? isDark
        ? Colors.white
        : Colors.black
        : Colors.white70;

    return Material(
      color: isSelected ? selectedColor : Colors.transparent,
      borderRadius: BorderRadius.circular(11.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(11.r),
        onTap: onTap,
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _ContinuousQuranView extends StatelessWidget {
  final dynamic arabic;
  final String Function(int globalAyahIndex) getAyahText;
  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;
  final bool isDark;

  const _ContinuousQuranView({
    super.key,
    required this.arabic,
    required this.getAyahText,
    required this.itemScrollController,
    required this.itemPositionsListener,
    required this.isDark,
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
                  ),
                _AyahReadingTile(
                  ayahText: getAyahText(globalIndex),
                  isDark: isDark,
                  isEven: globalIndex.isEven,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PageQuranView extends StatelessWidget {
  final PageController pageController;
  final int totalPages;
  final List<int> Function(int pageIndex) getPageAyahIndexes;
  final String Function(int globalAyahIndex) getAyahText;
  final ValueChanged<int> onPageChanged;
  final bool isDark;

  const _PageQuranView({
    super.key,
    required this.pageController,
    required this.totalPages,
    required this.getPageAyahIndexes,
    required this.getAyahText,
    required this.onPageChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      reverse: true,
      controller: pageController,
      onPageChanged: onPageChanged,
      itemCount: totalPages,
      itemBuilder: (context, pageIndex) {
        final ayahIndexes = getPageAyahIndexes(pageIndex);
        final firstPosition = QuranReaderHelpers.getPositionFromGlobalIndex(
          ayahIndexes.first,
        );

        return _MushafLikePage(
          pageIndex: pageIndex,
          ayahIndexes: ayahIndexes,
          firstPosition: firstPosition,
          getAyahText: getAyahText,
          isDark: isDark,
        );
      },
    );
  }
}

class _MushafLikePage extends StatelessWidget {
  final int pageIndex;
  final List<int> ayahIndexes;
  final QuranAyahPosition firstPosition;
  final String Function(int globalAyahIndex) getAyahText;
  final bool isDark;

  const _MushafLikePage({
    required this.pageIndex,
    required this.ayahIndexes,
    required this.firstPosition,
    required this.getAyahText,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDark ? const Color(0xff171B26) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    final juzNumber = QuranReaderHelpers.getJuzNumber(
      suraIndex: firstPosition.suraIndex,
      ayahIndex: firstPosition.ayahIndex,
    );

    final approxPage = QuranReaderHelpers.getApproxPageNumber(
      firstPosition.globalAyahIndex,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Column(
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: Text(
                    'الجزء ${juzNumber.toString().toArabicNumbers} - صفحة ${approxPage.toString().toArabicNumbers}',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'cairo',
                      fontSize: 10.sp,
                      color: textColor.withOpacity(0.65),
                    ),
                  ),
                ),
                Text(
                  QuranReaderHelpers.getSuraName(firstPosition.suraIndex),
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'cairo',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: textColor.withOpacity(0.75),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Text(
                  ayahIndexes.map(getAyahText).join(' '),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.justify,
                  strutStyle: StrutStyle(
                    fontSize: 24.sp,
                    height: 1.8,
                    forceStrutHeight: true,
                  ),
                  style: TextStyle(
                    fontFamily: arabicFont,
                    fontSize: 24.sp,
                    height: 1.8,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurahDivider extends StatelessWidget {
  final String suraName;
  final bool showBasmala;
  final bool isDark;

  const _SurahDivider({
    required this.suraName,
    required this.showBasmala,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final dividerColor = isDark ? const Color(0xff005349) : const Color(0xff224368);
    final textColor = Colors.white;

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
                color: textColor,
              ),
            ),
          ),
        ),
        if (showBasmala)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Text(
              'بسم الله الرحمن الرحيم',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'me_quran',
                fontSize: 22.sp,
                height: 1.5,
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

  const _AyahReadingTile({
    required this.ayahText,
    required this.isDark,
    required this.isEven,
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
          fontSize: arabicFontSize.sp,
          height: 1.65,
          forceStrutHeight: true,
        ),
        style: TextStyle(
          fontSize: arabicFontSize.sp,
          height: 1.65,
          fontFamily: arabicFont,
          color: textColor,
        ),
      ),
    );
  }
}