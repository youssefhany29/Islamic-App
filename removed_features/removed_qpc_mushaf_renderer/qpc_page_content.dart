import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../data/qpc_page_font_loader.dart';
import '../data/qpc_reader_perf.dart';
import '../hiding/quran_hide_mode.dart';
import '../models/qpc_models.dart';
import '../models/quran_selection.dart';
import '../theme/quran_reader_theme.dart';
import 'qpc_line_view.dart';
import 'qpc_render_probe.dart';

class QpcPageContent extends StatelessWidget {
  const QpcPageContent({
    super.key,
    required this.pageData,
    required this.readerTheme,
    required this.hideMode,
    required this.selection,
    required this.activeAudioWord,
    required this.onWordTap,
    this.fontScale = 1.0,
  });

  final QpcPageData pageData;
  final QuranReaderTheme readerTheme;
  final QuranHideMode hideMode;
  final QuranSelection? selection;
  final QpcWordKey? activeAudioWord;
  final ValueChanged<QpcLineTapResult> onWordTap;
  final double fontScale;

  @override
  Widget build(BuildContext context) {
    final String fontFamily = QpcPageFontLoader.familyForPage(
      pageData.pageNumber,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final Stopwatch? stopwatch = QpcReaderPerf.start();
        final bool isLargeScreen = MediaQuery.sizeOf(context).width >= 600;
        final double pageWidth = constraints.maxWidth;
        final double pageHeight = constraints.maxHeight;

        final _QpcPageMetrics metrics = _QpcPageMetrics.fromSize(
          width: pageWidth,
          height: pageHeight,
          isLargeScreen: isLargeScreen,
        );

        final Widget content = Container(
          color: readerTheme.pageBackground,
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              Positioned(
                top: metrics.headerTop,
                left: metrics.headerHorizontalInset,
                right: metrics.headerHorizontalInset,
                child: _QpcInlineMetaHeader(
                  readerTheme: readerTheme,
                  surahName: _currentSurahName,
                  juzNumber: _currentJuzNumber,
                  isLargeScreen: isLargeScreen,
                ),
              ),
              Positioned.fill(
                top: metrics.contentTopOffset,
                bottom: metrics.contentBottomOffset,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: metrics.horizontalPadding,
                  ),
                  child: Column(
                    children: List.generate(15, (index) {
                      final int lineNumber = index + 1;
                      final QpcMushafLine? line = pageData.lineByNumber(
                        lineNumber,
                      );

                      return SizedBox(
                        width: double.infinity,
                        height: metrics.lineHeight,
                        child: QpcLineView(
                          line: line,
                          fontFamily: fontFamily,
                          lineHeight: metrics.lineHeight,
                          readerTheme: readerTheme,
                          hideMode: hideMode,
                          selectedAyah: selection?.ayahKey,
                          selectedWord: null,
                          activeAudioWord: activeAudioWord,
                          finalWordByAyah: pageData.finalWordByAyah,
                          onWordTap: onWordTap,
                          fontScale: fontScale,
                        ),
                      );
                    }),
                  ),
                ),
              ),
              Positioned(
                left: pageData.pageNumber.isEven
                    ? metrics.pageNumberHorizontalInset
                    : null,
                right: pageData.pageNumber.isOdd
                    ? metrics.pageNumberHorizontalInset
                    : null,
                bottom: metrics.pageNumberBottom,
                child: _QpcInlinePageNumber(
                  pageNumber: pageData.pageNumber,
                  readerTheme: readerTheme,
                  isLargeScreen: isLargeScreen,
                ),
              ),
            ],
          ),
        );

        QpcReaderPerf.end(
          'page content build p${pageData.pageNumber}',
          stopwatch,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          QpcReaderPerf.mark('page content frame p${pageData.pageNumber}');
        });

        return QpcLayoutPaintProbe(
          label: 'page content p${pageData.pageNumber}',
          child: content,
        );
      },
    );
  }

  String get _currentSurahName {
    if (pageData.allWords.isEmpty) {
      return 'الفاتحة';
    }

    final int surah = pageData.allWords.first.surah;

    if (surah < 1 || surah > 114) {
      return 'الفاتحة';
    }

    return _surahNames[surah - 1];
  }

  int get _currentJuzNumber {
    int result = 1;

    for (int index = 0; index < _juzStartPages.length; index++) {
      if (pageData.pageNumber >= _juzStartPages[index]) {
        result = index + 1;
      } else {
        break;
      }
    }

    return result;
  }
}

class _QpcPageMetrics {
  const _QpcPageMetrics({
    required this.horizontalPadding,
    required this.headerTop,
    required this.headerHorizontalInset,
    required this.contentTopOffset,
    required this.contentBottomOffset,
    required this.pageNumberHorizontalInset,
    required this.pageNumberBottom,
    required this.lineHeight,
  });

  final double horizontalPadding;
  final double headerTop;
  final double headerHorizontalInset;
  final double contentTopOffset;
  final double contentBottomOffset;
  final double pageNumberHorizontalInset;
  final double pageNumberBottom;
  final double lineHeight;

  static _QpcPageMetrics fromSize({
    required double width,
    required double height,
    required bool isLargeScreen,
  }) {
    final double horizontalPadding = _horizontalPaddingForWidth(
      width,
      isLargeScreen: isLargeScreen,
    );

    final double headerTop = isLargeScreen ? 8 : 0;
    final double headerHorizontalInset = isLargeScreen ? 34 : 28.w;
    final double contentTopOffset = _topOffsetForHeight(
      height,
      isLargeScreen: isLargeScreen,
    );
    final double contentBottomOffset = _bottomOffsetForHeight(
      height,
      isLargeScreen: isLargeScreen,
    );
    final double pageNumberHorizontalInset = isLargeScreen ? 26 : 22.w;
    final double pageNumberBottom = isLargeScreen ? 7 : 4.h;

    final double availableHeight =
        height - contentTopOffset - contentBottomOffset;

    final double lineHeight = availableHeight / 15.0;

    return _QpcPageMetrics(
      horizontalPadding: horizontalPadding,
      headerTop: headerTop,
      headerHorizontalInset: headerHorizontalInset,
      contentTopOffset: contentTopOffset,
      contentBottomOffset: contentBottomOffset,
      pageNumberHorizontalInset: pageNumberHorizontalInset,
      pageNumberBottom: pageNumberBottom,
      lineHeight: lineHeight,
    );
  }

  static double _horizontalPaddingForWidth(
    double width, {
    required bool isLargeScreen,
  }) {
    if (isLargeScreen) {
      if (width <= 620) return 16;
      if (width <= 760) return 22;
      return 30;
    }

    if (width <= 330) {
      return 10.w;
    }

    if (width <= 390) {
      return 12.w;
    }

    if (width <= 460) {
      return 14.w;
    }

    return 18.w;
  }

  static double _topOffsetForHeight(
    double height, {
    required bool isLargeScreen,
  }) {
    if (isLargeScreen) {
      return height <= 720 ? 34 : 38;
    }

    if (height <= 650) {
      return 30.h;
    }

    if (height <= 760) {
      return 34.h;
    }

    return 38.h;
  }

  static double _bottomOffsetForHeight(
    double height, {
    required bool isLargeScreen,
  }) {
    if (isLargeScreen) {
      return height <= 720 ? 26 : 30;
    }

    if (height <= 650) {
      return 24.h;
    }

    if (height <= 760) {
      return 28.h;
    }

    return 32.h;
  }
}

class _QpcInlineMetaHeader extends StatelessWidget {
  const _QpcInlineMetaHeader({
    required this.readerTheme,
    required this.surahName,
    required this.juzNumber,
    required this.isLargeScreen,
  });

  final QuranReaderTheme readerTheme;
  final String surahName;
  final int juzNumber;
  final bool isLargeScreen;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          height: isLargeScreen ? 18 : 22.h,
          child: Row(
            children: [
              Text(
                'الجزء ${_arabicNumber(juzNumber)}',
                textAlign: TextAlign.right,
                style: _style,
              ),
              const Spacer(),
              Text(surahName, textAlign: TextAlign.left, style: _style),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle get _style {
    return TextStyle(
      fontFamily: 'cairo',
      fontSize: isLargeScreen ? 8.5 : 9.5.sp,
      height: 1.0,
      fontWeight: FontWeight.w900,
      color: readerTheme.secondaryTextColor.withOpacity(0.72),
    );
  }
}

class _QpcInlinePageNumber extends StatelessWidget {
  const _QpcInlinePageNumber({
    required this.pageNumber,
    required this.readerTheme,
    required this.isLargeScreen,
  });

  final int pageNumber;
  final QuranReaderTheme readerTheme;
  final bool isLargeScreen;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: isLargeScreen ? 32 : 36.w,
        height: isLargeScreen ? 17 : 20.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: readerTheme.pageBadgeBackground.withOpacity(0.86),
          borderRadius: BorderRadius.circular(isLargeScreen ? 30 : 30.r),
          border: Border.all(
            color: readerTheme.pageBadgeBorder.withOpacity(0.64),
            width: 0.8,
          ),
        ),
        child: Text(
          _arabicNumber(pageNumber),
          style: TextStyle(
            fontFamily: 'cairo',
            fontSize: isLargeScreen ? 8.5 : 8.5.sp,
            fontWeight: FontWeight.w900,
            color: readerTheme.pageBadgeText,
            height: 1,
          ),
        ),
      ),
    );
  }
}

String _arabicNumber(int value) {
  const List<String> digits = <String>[
    '٠',
    '١',
    '٢',
    '٣',
    '٤',
    '٥',
    '٦',
    '٧',
    '٨',
    '٩',
  ];

  return value.toString().split('').map((char) {
    final int? digit = int.tryParse(char);
    return digit == null ? char : digits[digit];
  }).join();
}

const List<int> _juzStartPages = <int>[
  1,
  22,
  42,
  62,
  82,
  102,
  121,
  142,
  162,
  182,
  201,
  222,
  242,
  262,
  282,
  302,
  322,
  342,
  362,
  382,
  402,
  422,
  442,
  462,
  482,
  502,
  522,
  542,
  562,
  582,
];

const List<String> _surahNames = <String>[
  'الفاتحة',
  'البقرة',
  'آل عمران',
  'النساء',
  'المائدة',
  'الأنعام',
  'الأعراف',
  'الأنفال',
  'التوبة',
  'يونس',
  'هود',
  'يوسف',
  'الرعد',
  'إبراهيم',
  'الحجر',
  'النحل',
  'الإسراء',
  'الكهف',
  'مريم',
  'طه',
  'الأنبياء',
  'الحج',
  'المؤمنون',
  'النور',
  'الفرقان',
  'الشعراء',
  'النمل',
  'القصص',
  'العنكبوت',
  'الروم',
  'لقمان',
  'السجدة',
  'الأحزاب',
  'سبأ',
  'فاطر',
  'يس',
  'الصافات',
  'ص',
  'الزمر',
  'غافر',
  'فصلت',
  'الشورى',
  'الزخرف',
  'الدخان',
  'الجاثية',
  'الأحقاف',
  'محمد',
  'الفتح',
  'الحجرات',
  'ق',
  'الذاريات',
  'الطور',
  'النجم',
  'القمر',
  'الرحمن',
  'الواقعة',
  'الحديد',
  'المجادلة',
  'الحشر',
  'الممتحنة',
  'الصف',
  'الجمعة',
  'المنافقون',
  'التغابن',
  'الطلاق',
  'التحريم',
  'الملك',
  'القلم',
  'الحاقة',
  'المعارج',
  'نوح',
  'الجن',
  'المزمل',
  'المدثر',
  'القيامة',
  'الإنسان',
  'المرسلات',
  'النبأ',
  'النازعات',
  'عبس',
  'التكوير',
  'الانفطار',
  'المطففين',
  'الانشقاق',
  'البروج',
  'الطارق',
  'الأعلى',
  'الغاشية',
  'الفجر',
  'البلد',
  'الشمس',
  'الليل',
  'الضحى',
  'الشرح',
  'التين',
  'العلق',
  'القدر',
  'البينة',
  'الزلزلة',
  'العاديات',
  'القارعة',
  'التكاثر',
  'العصر',
  'الهمزة',
  'الفيل',
  'قريش',
  'الماعون',
  'الكوثر',
  'الكافرون',
  'النصر',
  'المسد',
  'الإخلاص',
  'الفلق',
  'الناس',
];
