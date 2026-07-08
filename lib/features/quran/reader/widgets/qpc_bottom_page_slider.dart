import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/quran_reader_theme.dart';

class QpcBottomPageSlider extends StatefulWidget {
  const QpcBottomPageSlider({
    super.key,
    required this.visible,
    required this.readerTheme,
    required this.selectedPageNumber,
    required this.onJumpToPage,
    this.onPreviewPage,
    this.onInteractionStart,
    this.onInteractionEnd,
    this.currentSuraName = '',
    this.currentAyahNumber = 1,
    this.currentJuzNumber = 1,
  });

  final bool visible;
  final QuranReaderTheme readerTheme;
  final int selectedPageNumber;
  final ValueChanged<int> onJumpToPage;
  final ValueChanged<int>? onPreviewPage;
  final VoidCallback? onInteractionStart;
  final VoidCallback? onInteractionEnd;
  final String currentSuraName;
  final int currentAyahNumber;
  final int currentJuzNumber;

  @override
  State<QpcBottomPageSlider> createState() => _QpcBottomPageSliderState();
}

class _QpcBottomPageSliderState extends State<QpcBottomPageSlider> {
  double? _dragValue;

  int get _shownPage {
    return (_dragValue?.round() ?? widget.selectedPageNumber).clamp(1, 604);
  }

  @override
  void didUpdateWidget(covariant QpcBottomPageSlider oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedPageNumber != widget.selectedPageNumber) {
      _dragValue = null;
    }
  }

  void _finishInteraction(int page) {
    setState(() {
      _dragValue = null;
    });

    widget.onJumpToPage(page);
    widget.onInteractionEnd?.call();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLargeScreen = MediaQuery.sizeOf(context).width >= 600;
    final int safePage = _shownPage;

    return IgnorePointer(
      ignoring: !widget.visible,
      child: AnimatedOpacity(
        opacity: widget.visible ? 1 : 0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            height: isLargeScreen ? 34 : 36.h,
            padding: EdgeInsets.symmetric(
              horizontal: isLargeScreen ? 12 : 10.w,
            ),
            decoration: BoxDecoration(
              color: widget.readerTheme.controlsBackgroundColor.withValues(
                alpha: 0.94,
              ),
              borderRadius: BorderRadius.circular(isLargeScreen ? 14 : 16.r),
              border: Border.all(
                color: widget.readerTheme.dividerColor.withValues(alpha: 0.62),
                width: 0.85,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: isLargeScreen ? 10 : 12,
                  offset: isLargeScreen ? const Offset(0, 3) : Offset(0, 4.h),
                ),
              ],
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                if (isLargeScreen) ...[
                  SizedBox(
                    width: 190,
                    child: Text(
                      _compactLocationText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: widget.readerTheme.controlsTextColor.withValues(
                          alpha: 0.82,
                        ),
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: isLargeScreen ? 1.8 : 2.6.h,
                      showValueIndicator: ShowValueIndicator.onDrag,
                      valueIndicatorTextStyle: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: isLargeScreen ? 8.5 : 9.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      thumbShape: RoundSliderThumbShape(
                        enabledThumbRadius: isLargeScreen ? 3.8 : 5.r,
                      ),
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      min: 1,
                      max: 604,
                      divisions: 603,
                      value: safePage.toDouble(),
                      label: _labelForPage(safePage),
                      onChangeStart: (_) {
                        widget.onInteractionStart?.call();
                      },
                      onChanged: (value) {
                        widget.onInteractionStart?.call();
                        final int previewPage = value.round().clamp(1, 604);
                        setState(() {
                          _dragValue = value;
                        });
                        widget.onPreviewPage?.call(previewPage);
                      },
                      onChangeEnd: (value) {
                        final int page = value.round().clamp(1, 604);
                        _finishInteraction(page);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _compactLocationText {
    final String surah = widget.currentSuraName.trim();
    final String ayahText = _arabicNumber(widget.currentAyahNumber);
    final String juzText = _arabicNumber(widget.currentJuzNumber);

    if (surah.isEmpty) {
      return 'آية $ayahText • الجزء $juzText';
    }

    return 'سورة $surah • آية $ayahText • الجزء $juzText';
  }

  String _labelForPage(int page) {
    final String surah = widget.currentSuraName.trim();
    final String pageText = _arabicNumber(page);
    final String ayahText = _arabicNumber(widget.currentAyahNumber);
    final String juzText = _arabicNumber(widget.currentJuzNumber);

    if (surah.isEmpty) {
      return 'صفحة $pageText | آية $ayahText | جزء $juzText';
    }

    return '$surah | آية $ayahText | صفحة $pageText | جزء $juzText';
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
