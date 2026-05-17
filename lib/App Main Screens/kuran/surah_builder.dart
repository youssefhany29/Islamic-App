import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/App%20Main%20Screens/App%20Main%20Screens%20Components/custom_app_bar.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:share_plus/share_plus.dart';

import 'constant.dart';

class SurahBuilder extends StatefulWidget {
  final dynamic sura;
  final dynamic arabic;
  final dynamic suraName;
  final int ayah;

  const SurahBuilder({
    Key? key,
    this.sura,
    this.arabic,
    this.suraName,
    required this.ayah,
  }) : super(key: key);

  @override
  State<SurahBuilder> createState() => _SurahBuilderState();
}

class _SurahBuilderState extends State<SurahBuilder> {
  bool view = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      jumpToAyah();
    });
  }

  void jumpToAyah() {
    if (!fabIsClicked) return;

    itemScrollController.scrollTo(
      index: widget.ayah,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOutCubic,
    );

    fabIsClicked = false;
  }

  int getPreviousVersesCount() {
    int previousVerses = 0;

    if (widget.sura + 1 != 1) {
      for (int i = widget.sura - 1; i >= 0; i--) {
        previousVerses += noOfVerses[i];
      }
    }

    return previousVerses;
  }

  String getFullSuraText({
    required int lengthOfSura,
    required int previousVerses,
  }) {
    final buffer = StringBuffer();

    for (int i = 0; i < lengthOfSura; i++) {
      buffer.write(widget.arabic[i + previousVerses]['aya_text']);
      buffer.write(' ');
    }

    return buffer.toString();
  }

  bool shouldShowBasmala(int index) {
    return index == 0 && widget.sura != 0 && widget.sura != 8;
  }

  void saveCurrentBookmark(int ayahIndex) async {
    await saveBookMark(widget.sura + 1, ayahIndex);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ العلامة'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void shareAyah({
    required int index,
    required int previousVerses,
  }) {
    final ayahText = widget.arabic[index + previousVerses]['aya_text'];
    final surahName = widget.suraName;

    Share.share('$ayahText\n\nسورة $surahName');
  }

  @override
  Widget build(BuildContext context) {
    final int lengthOfSura = noOfVerses[widget.sura];
    final int previousVerses = getPreviousVersesCount();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final pageBackground = theme.colorScheme.background;
    final readingBackground =
    isDark ? const Color(0xff171B26) : const Color(0xffFDFBF0);
    final verseColor =
    isDark ? const Color(0xff1E2433) : const Color(0xffFDF7E6);
    final alternateVerseColor =
    isDark ? const Color(0xff171B26) : const Color(0xffFDFBF0);
    final textColor = isDark ? Colors.white.withOpacity(0.92) : Colors.black87;
    final secondaryTextColor =
    isDark ? Colors.white70 : Colors.black.withOpacity(0.55);

    return Scaffold(
      backgroundColor: pageBackground,
      body: ColoredBox(
        color: pageBackground,
        child: SafeArea(
          child: Column(
            children: [
              CustomAppBar(
                category: CustomAppBarCategory(
                  text: widget.suraName.toString(),
                ),
              ),

              SizedBox(height: 8.h),

              _ReadingModeBar(
                isMushafMode: !view,
                onToggleView: () {
                  setState(() {
                    view = !view;
                  });
                },
              ),

              SizedBox(height: 8.h),

              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: 12.w),
                  decoration: BoxDecoration(
                    color: readingBackground,
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
                    child: view
                        ? _AyahByAyahView(
                      lengthOfSura: lengthOfSura,
                      previousVerses: previousVerses,
                      verseColor: verseColor,
                      alternateVerseColor: alternateVerseColor,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                      shouldShowBasmala: shouldShowBasmala,
                      buildVerseText: (index) {
                        return widget.arabic[index + previousVerses]
                        ['aya_text'];
                      },
                      onBookmark: saveCurrentBookmark,
                      onShare: (index) {
                        shareAyah(
                          index: index,
                          previousVerses: previousVerses,
                        );
                      },
                    )
                        : _MushafView(
                      fullSura: getFullSuraText(
                        lengthOfSura: lengthOfSura,
                        previousVerses: previousVerses,
                      ),
                      shouldShowBasmala:
                      widget.sura + 1 != 1 && widget.sura + 1 != 9,
                      textColor: textColor,
                    ),
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

class _ReadingModeBar extends StatelessWidget {
  final bool isMushafMode;
  final VoidCallback onToggleView;

  const _ReadingModeBar({
    required this.isMushafMode,
    required this.onToggleView,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final buttonColor =
    isDark ? const Color(0xff171B26) : theme.colorScheme.secondary;
    final textColor = isDark ? Colors.white : Colors.black;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Container(
        height: 38.h,
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Text(
              'طريقة العرض',
              style: TextStyle(
                fontFamily: 'cairo',
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),

            const Spacer(),

            Material(
              color: buttonColor,
              borderRadius: BorderRadius.circular(12.r),
              child: InkWell(
                borderRadius: BorderRadius.circular(12.r),
                onTap: onToggleView,
                child: Container(
                  height: 28.h,
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  child: Row(
                    children: [
                      Icon(
                        isMushafMode
                            ? Icons.view_agenda_rounded
                            : Icons.chrome_reader_mode_rounded,
                        size: 14.sp,
                        color: textColor,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        isMushafMode ? 'آية آية' : 'مصحف',
                        style: TextStyle(
                          fontFamily: 'cairo',
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
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

class _AyahByAyahView extends StatelessWidget {
  final int lengthOfSura;
  final int previousVerses;
  final Color verseColor;
  final Color alternateVerseColor;
  final Color textColor;
  final Color secondaryTextColor;
  final bool Function(int index) shouldShowBasmala;
  final String Function(int index) buildVerseText;
  final void Function(int index) onBookmark;
  final void Function(int index) onShare;

  const _AyahByAyahView({
    required this.lengthOfSura,
    required this.previousVerses,
    required this.verseColor,
    required this.alternateVerseColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.shouldShowBasmala,
    required this.buildVerseText,
    required this.onBookmark,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return ScrollablePositionedList.builder(
      itemScrollController: itemScrollController,
      itemPositionsListener: itemPositionsListener,
      itemCount: lengthOfSura,
      itemBuilder: (BuildContext context, int index) {
        return Column(
          children: [
            if (shouldShowBasmala(index)) const RetunBasmala(),

            _AyahTile(
              index: index,
              ayahText: buildVerseText(index),
              backgroundColor:
              index.isEven ? verseColor : alternateVerseColor,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              onBookmark: () => onBookmark(index),
              onShare: () => onShare(index),
            ),
          ],
        );
      },
    );
  }
}

class _AyahTile extends StatelessWidget {
  final int index;
  final String ayahText;
  final Color backgroundColor;
  final Color textColor;
  final Color secondaryTextColor;
  final VoidCallback onBookmark;
  final VoidCallback onShare;

  const _AyahTile({
    required this.index,
    required this.ayahText,
    required this.backgroundColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.onBookmark,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: Theme.of(context).colorScheme.background,
      onSelected: (value) {
        if (value == 'bookmark') {
          onBookmark();
        }

        if (value == 'share') {
          onShare();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'bookmark',
          child: Row(
            children: [
              Icon(Icons.bookmark_add_outlined),
              SizedBox(width: 10),
              Text('حفظ علامة'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share_outlined),
              SizedBox(width: 10),
              Text('مشاركة'),
            ],
          ),
        ),
      ],
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
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

            SizedBox(height: 8.h),

            Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(
                  Icons.touch_app_outlined,
                  size: 12.sp,
                  color: secondaryTextColor,
                ),
                SizedBox(width: 4.w),
                Text(
                  'اضغط مطولًا أو اضغط للخيارات',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'cairo',
                    fontSize: 8.sp,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MushafView extends StatelessWidget {
  final String fullSura;
  final bool shouldShowBasmala;
  final Color textColor;

  const _MushafView({
    required this.fullSura,
    required this.shouldShowBasmala,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      children: [
        if (shouldShowBasmala) const RetunBasmala(),

        Text(
          fullSura,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          strutStyle: StrutStyle(
            fontSize: mushafFontSize.sp,
            height: 1.8,
            forceStrutHeight: true,
          ),
          style: TextStyle(
            fontSize: mushafFontSize.sp,
            height: 1.8,
            fontFamily: arabicFont,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

class RetunBasmala extends StatelessWidget {
  const RetunBasmala({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 10.w),
      child: Center(
        child: Text(
          'بسم الله الرحمن الرحيم',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'me_quran',
            fontSize: 23.sp,
            height: 1.5,
            color: textColor,
          ),
        ),
      ),
    );
  }
}