import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constant.dart';
import 'quran_reader_helpers.dart';

class QuranTextMushafView extends StatelessWidget {
  final PageController pageController;
  final List<List<int>> quranPages;
  final String Function(int globalAyahIndex) getAyahText;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onAyahTap;
  final int selectedGlobalAyahIndex;
  final bool isDark;
  final double fontSize;
  final String basmalaText;

  const QuranTextMushafView({
    super.key,
    required this.pageController,
    required this.quranPages,
    required this.getAyahText,
    required this.onPageChanged,
    required this.onAyahTap,
    required this.selectedGlobalAyahIndex,
    required this.isDark,
    required this.fontSize,
    required this.basmalaText,
  });

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      reverse: true,
      controller: pageController,
      onPageChanged: onPageChanged,
      itemCount: quranPages.length,
      itemBuilder: (context, pageIndex) {
        final ayahIndexes = quranPages[pageIndex];

        final firstPosition = QuranReaderHelpers.getPositionFromGlobalIndex(
          ayahIndexes.first,
        );

        return _TextMushafPage(
          ayahIndexes: ayahIndexes,
          firstPosition: firstPosition,
          getAyahText: getAyahText,
          onAyahTap: onAyahTap,
          selectedGlobalAyahIndex: selectedGlobalAyahIndex,
          isDark: isDark,
          fontSize: fontSize,
          basmalaText: basmalaText,
        );
      },
    );
  }
}

class _TextMushafPage extends StatelessWidget {
  final List<int> ayahIndexes;
  final QuranAyahPosition firstPosition;
  final String Function(int globalAyahIndex) getAyahText;
  final ValueChanged<int> onAyahTap;
  final int selectedGlobalAyahIndex;
  final bool isDark;
  final double fontSize;
  final String basmalaText;

  const _TextMushafPage({
    required this.ayahIndexes,
    required this.firstPosition,
    required this.getAyahText,
    required this.onAyahTap,
    required this.selectedGlobalAyahIndex,
    required this.isDark,
    required this.fontSize,
    required this.basmalaText,
  });

  @override
  Widget build(BuildContext context) {
    final pageBackground = isDark ? const Color(0xff171B26) : Colors.white;

    final startsNewSura = firstPosition.ayahIndex == 0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: pageBackground,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xffEEE7D2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            if (startsNewSura)
              _MushafSurahStart(
                suraName: QuranReaderHelpers.getSuraName(
                  firstPosition.suraIndex,
                ),
                showBasmala: QuranReaderHelpers.shouldShowBasmala(
                  suraIndex: firstPosition.suraIndex,
                  ayahIndex: firstPosition.ayahIndex,
                ),
                isDark: isDark,
                fontSize: fontSize,
                basmalaText: basmalaText,
              ),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    runAlignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6.w,
                    runSpacing: 10.h,
                    children: [
                      for (final globalIndex in ayahIndexes)
                        _ClickableMushafAyah(
                          ayahText: getAyahText(globalIndex),
                          isSelected: selectedGlobalAyahIndex == globalIndex,
                          isDark: isDark,
                          onTap: () => onAyahTap(globalIndex),
                          fontSize: fontSize,
                        ),
                    ],
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

class _MushafSurahStart extends StatelessWidget {
  final String suraName;
  final bool showBasmala;
  final bool isDark;
  final double fontSize;
  final String basmalaText;

  const _MushafSurahStart({
    required this.suraName,
    required this.showBasmala,
    required this.isDark,
    required this.fontSize,
    required this.basmalaText,
  });

  @override
  Widget build(BuildContext context) {
    final headerColor =
    isDark ? const Color(0xff005349) : const Color(0xff224368);

    final textColor = isDark ? Colors.white : Colors.black87;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 7.h),
          decoration: BoxDecoration(
            color: headerColor,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Center(
            child: Text(
              'سورة $suraName',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'cairo',
                fontSize: 12.sp,
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
                color: textColor,
              ),
            ),
          )
        else
          SizedBox(height: 8.h),
      ],
    );
  }
}

class _ClickableMushafAyah extends StatelessWidget {
  final String ayahText;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;
  final double fontSize;

  const _ClickableMushafAyah({
    required this.ayahText,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black87;

    final selectedColor = isDark
        ? const Color(0xff005349).withOpacity(0.55)
        : const Color(0xffE6F4EA);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          ayahText,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          strutStyle: StrutStyle(
            fontSize: fontSize.sp,
            height: 1.85,
            forceStrutHeight: true,
          ),
          style: TextStyle(
            fontFamily: arabicFont,
            fontSize: fontSize.sp,
            height: 1.85,
            color: textColor,
          ),
        ),
      ),
    );
  }
}