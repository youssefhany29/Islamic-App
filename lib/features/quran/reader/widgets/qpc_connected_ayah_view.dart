import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../main_quraan_components/constant.dart';
import '../hiding/quran_hide_mode.dart';
import '../hiding/quran_text_masker.dart';
import '../models/qpc_models.dart';
import '../models/quran_ayah_tap_result.dart';
import '../models/quran_selection.dart';
import '../quran_page_mapper.dart';
import '../quran_reader_helpers.dart';
import '../theme/quran_reader_theme.dart';

class QpcConnectedAyahView extends StatefulWidget {
  const QpcConnectedAyahView({
    super.key,
    required this.readerTheme,
    required this.hideMode,
    required this.selection,
    required this.activeAudioWord,
    required this.fontScale,
    required this.onAyahTap,
    required this.onToggleControls,
    required this.onPageChanged,
    required this.onAnchorChanged,
    required this.initialPageNumber,
    this.anchorAyahKey,
  });

  final QuranReaderTheme readerTheme;
  final QuranHideMode hideMode;
  final QuranSelection? selection;
  final QpcWordKey? activeAudioWord;
  final double fontScale;
  final ValueChanged<QpcLineTapResult> onAyahTap;
  final VoidCallback onToggleControls;
  final ValueChanged<int> onPageChanged;
  final void Function(QpcAyahKey ayahKey, int pageNumber) onAnchorChanged;
  final int initialPageNumber;
  final QpcAyahKey? anchorAyahKey;

  @override
  State<QpcConnectedAyahView> createState() => QpcConnectedAyahViewState();
}

class QpcConnectedAyahViewState extends State<QpcConnectedAyahView> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  late Future<List<_ConnectedEntry>> _entriesFuture;

  List<_ConnectedEntry> _entries = <_ConnectedEntry>[];
  final Map<QpcAyahKey, int> _ayahIndexByKey = <QpcAyahKey, int>{};

  QpcAyahKey? _lastReportedAnchor;
  bool _didInitialJump = false;
  Timer? _anchorDebounceTimer;

  @override
  void initState() {
    super.initState();
    _entriesFuture = _loadEntries();
    _itemPositionsListener.itemPositions.addListener(
      _handleVisibleItemsChanged,
    );
  }

  @override
  void didUpdateWidget(covariant QpcConnectedAyahView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final QpcAyahKey? nextAnchor = widget.anchorAyahKey;
    if (oldWidget.anchorAyahKey != nextAnchor &&
        nextAnchor != null &&
        _entries.isNotEmpty &&
        nextAnchor != _lastReportedAnchor) {
      _jumpToAyah(nextAnchor, animated: false);
    }
  }

  @override
  void dispose() {
    _anchorDebounceTimer?.cancel();
    _itemPositionsListener.itemPositions.removeListener(
      _handleVisibleItemsChanged,
    );
    super.dispose();
  }

  Future<List<_ConnectedEntry>> _loadEntries() async {
    await QuranPageMapper.load();

    final List<dynamic> quranData = await readJson();
    final dynamic arabicSource = quranData.isNotEmpty ? quranData.first : null;

    final List<_ConnectedEntry> entries = <_ConnectedEntry>[];
    final Map<QpcAyahKey, int> ayahIndexByKey = <QpcAyahKey, int>{};

    for (int suraIndex = 0; suraIndex < noOfVerses.length; suraIndex++) {
      final int surahNumber = suraIndex + 1;

      entries.add(
        _ConnectedEntry.surahHeader(
          surahNumber: surahNumber,
          pageNumber: _pageForPosition(suraIndex: suraIndex, ayahIndex: 0),
        ),
      );

      for (int ayahIndex = 0; ayahIndex < noOfVerses[suraIndex]; ayahIndex++) {
        final QpcAyahKey ayahKey = QpcAyahKey(
          surah: surahNumber,
          ayah: ayahIndex + 1,
        );

        final String ayahText = _QuranTextReader.readAyahText(
          source: arabicSource,
          suraIndex: suraIndex,
          ayahIndex: ayahIndex,
        );

        final int pageNumber = _pageForPosition(
          suraIndex: suraIndex,
          ayahIndex: ayahIndex,
        );

        ayahIndexByKey[ayahKey] = entries.length;

        entries.add(
          _ConnectedEntry.ayah(
            ayahKey: ayahKey,
            pageNumber: pageNumber,
            text: ayahText,
          ),
        );
      }
    }

    _entries = entries;
    _ayahIndexByKey
      ..clear()
      ..addAll(ayahIndexByKey);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didInitialJump) return;
      _didInitialJump = true;
      _jumpToInitialPosition();
    });

    return entries;
  }

  int _pageForPosition({required int suraIndex, required int ayahIndex}) {
    final int globalAyahIndex = QuranReaderHelpers.getGlobalAyahIndex(
      suraIndex: suraIndex,
      ayahIndex: ayahIndex,
    );

    return QuranPageMapper.getPageNumberForGlobalAyah(globalAyahIndex);
  }

  void _jumpToInitialPosition() {
    final QpcAyahKey? anchor = widget.anchorAyahKey;

    if (anchor != null) {
      _jumpToAyah(anchor, animated: false);
      return;
    }

    final int initialPage = widget.initialPageNumber.clamp(1, 604);
    final int pageStartGlobal = QuranPageMapper.getGlobalAyahIndexForPage(
      initialPage,
    );

    final QuranAyahPosition position =
        QuranReaderHelpers.getPositionFromGlobalIndex(pageStartGlobal);

    _jumpToAyah(
      QpcAyahKey(surah: position.suraIndex + 1, ayah: position.ayahIndex + 1),
      animated: false,
    );
  }

  void _jumpToAyah(QpcAyahKey ayahKey, {required bool animated}) {
    if (!_itemScrollController.isAttached || _entries.isEmpty) return;

    final int index = _indexForAyah(ayahKey);
    if (index < 0) return;

    if (animated) {
      unawaited(
        _itemScrollController.scrollTo(
          index: index,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: 0.02,
        ),
      );
    } else {
      _itemScrollController.jumpTo(index: index, alignment: 0.02);
    }
  }

  int _indexForAyah(QpcAyahKey ayahKey) {
    return _ayahIndexByKey[ayahKey] ?? -1;
  }

  void _handleVisibleItemsChanged() {
    _anchorDebounceTimer?.cancel();
    _anchorDebounceTimer = Timer(
      const Duration(milliseconds: 85),
      _updateVisibleAnchor,
    );
  }

  void _updateVisibleAnchor() {
    if (!mounted || _entries.isEmpty) return;

    final List<ItemPosition> visiblePositions = _itemPositionsListener
        .itemPositions
        .value
        .where(
          (position) =>
              position.itemTrailingEdge > 0 && position.itemLeadingEdge < 1,
        )
        .toList();

    if (visiblePositions.isEmpty) return;

    const double anchorLine = 0.22;

    visiblePositions.sort((a, b) {
      final double aDistance = _distanceFromAnchorLine(a, anchorLine);
      final double bDistance = _distanceFromAnchorLine(b, anchorLine);
      return aDistance.compareTo(bDistance);
    });

    for (final ItemPosition position in visiblePositions) {
      final int index = position.index;
      if (index < 0 || index >= _entries.length) continue;

      final _ConnectedEntry entry = _entries[index];
      final QpcAyahKey? ayahKey = entry.ayahKey;
      if (ayahKey == null) continue;

      if (_lastReportedAnchor == ayahKey) return;

      _lastReportedAnchor = ayahKey;
      widget.onPageChanged(entry.pageNumber);
      widget.onAnchorChanged(ayahKey, entry.pageNumber);
      return;
    }
  }

  double _distanceFromAnchorLine(ItemPosition position, double anchorLine) {
    if (position.itemLeadingEdge <= anchorLine &&
        position.itemTrailingEdge >= anchorLine) {
      return 0;
    }

    final double leadingDistance = (position.itemLeadingEdge - anchorLine)
        .abs();
    final double trailingDistance = (position.itemTrailingEdge - anchorLine)
        .abs();

    return leadingDistance < trailingDistance
        ? leadingDistance
        : trailingDistance;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onToggleControls,
      child: Container(
        color: widget.readerTheme.pageBackground,
        child: FutureBuilder<List<_ConnectedEntry>>(
          future: _entriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return _ConnectedLoadingView(readerTheme: widget.readerTheme);
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return _ConnectedErrorView(readerTheme: widget.readerTheme);
            }

            final List<_ConnectedEntry> entries = snapshot.data!;

            return ScrollablePositionedList.builder(
              itemScrollController: _itemScrollController,
              itemPositionsListener: _itemPositionsListener,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                top: MediaQuery.sizeOf(context).width >= 600 ? 42 : 58.h,
                bottom: MediaQuery.sizeOf(context).width >= 600 ? 118 : 158.h,
              ),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final _ConnectedEntry entry = entries[index];

                if (entry.isSurahHeader) {
                  return _SurahHeaderTile(
                    surahNumber: entry.surahNumber!,
                    readerTheme: widget.readerTheme,
                  );
                }

                final QpcAyahKey ayahKey = entry.ayahKey!;

                return _AyahTile(
                  ayahKey: ayahKey,
                  ayahText: entry.text,
                  readerTheme: widget.readerTheme,
                  hideMode: widget.hideMode,
                  isEven: ayahKey.ayah.isEven,
                  isSelected: widget.selection?.ayahKey == ayahKey,
                  activeAudioWord: widget.activeAudioWord,
                  fontScale: widget.fontScale,
                  onTap: () {
                    widget.onAyahTap(
                      QpcLineTapResult(
                        ayahKey: ayahKey,
                        wordKey: QpcWordKey(
                          surah: ayahKey.surah,
                          ayah: ayahKey.ayah,
                          word: 1,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ConnectedLoadingView extends StatelessWidget {
  const _ConnectedLoadingView({required this.readerTheme});

  final QuranReaderTheme readerTheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: readerTheme.secondaryTextColor,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'جاري تجهيز فهرس القراءة...',
              style: TextStyle(
                fontFamily: 'cairo',
                fontSize: 12.sp,
                color: readerTheme.secondaryTextColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectedErrorView extends StatelessWidget {
  const _ConnectedErrorView({required this.readerTheme});

  final QuranReaderTheme readerTheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'تعذر تجهيز القراءة النصية',
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: 'cairo',
          fontSize: 13.sp,
          fontWeight: FontWeight.w800,
          color: readerTheme.secondaryTextColor,
        ),
      ),
    );
  }
}

class _ConnectedEntry {
  const _ConnectedEntry._({
    this.surahNumber,
    this.ayahKey,
    this.text = '',
    required this.pageNumber,
    required this.isSurahHeader,
  });

  factory _ConnectedEntry.surahHeader({
    required int surahNumber,
    required int pageNumber,
  }) {
    return _ConnectedEntry._(
      surahNumber: surahNumber,
      pageNumber: pageNumber,
      isSurahHeader: true,
    );
  }

  factory _ConnectedEntry.ayah({
    required QpcAyahKey ayahKey,
    required int pageNumber,
    required String text,
  }) {
    return _ConnectedEntry._(
      ayahKey: ayahKey,
      pageNumber: pageNumber,
      text: text,
      isSurahHeader: false,
    );
  }

  final int? surahNumber;
  final QpcAyahKey? ayahKey;
  final String text;
  final int pageNumber;
  final bool isSurahHeader;
}

class _SurahHeaderTile extends StatelessWidget {
  const _SurahHeaderTile({
    required this.surahNumber,
    required this.readerTheme,
  });

  final int surahNumber;
  final QuranReaderTheme readerTheme;

  @override
  Widget build(BuildContext context) {
    final String name = QuranReaderHelpers.getSuraName(
      (surahNumber - 1).clamp(0, 113).toInt(),
    );

    return RepaintBoundary(
      child: Container(
        margin: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 4.h),
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 20.w),
        decoration: BoxDecoration(
          color: readerTheme.controlsBackgroundColor.withOpacity(
            readerTheme.isDarkLike ? 0.30 : 0.10,
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: readerTheme.dividerColor),
        ),
        child: Text(
          'سورة $name',
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: 'cairo',
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: readerTheme.selectedWordTextColor,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _AyahTile extends StatelessWidget {
  const _AyahTile({
    required this.ayahKey,
    required this.ayahText,
    required this.readerTheme,
    required this.hideMode,
    required this.isEven,
    required this.isSelected,
    required this.activeAudioWord,
    required this.fontScale,
    required this.onTap,
  });

  final QpcAyahKey ayahKey;
  final String ayahText;
  final QuranReaderTheme readerTheme;
  final QuranHideMode hideMode;
  final bool isEven;
  final bool isSelected;
  final QpcWordKey? activeAudioWord;
  final double fontScale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isLargeScreen = MediaQuery.sizeOf(context).width >= 600;
    final double contentMaxWidth = isLargeScreen ? 720 : double.infinity;

    final Color bgEven = readerTheme.pageBackground;
    final Color bgOdd = Color.alphaBlend(
      readerTheme.controlsBackgroundColor.withOpacity(
        readerTheme.isDarkLike ? 0.07 : 0.04,
      ),
      readerTheme.pageBackground,
    );

    Color bgColor = isEven ? bgEven : bgOdd;
    if (isSelected) {
      bgColor = Color.alphaBlend(readerTheme.ayahHighlightColor, bgColor);
    }

    final double fontSize = isLargeScreen
        ? (18.0 * fontScale.clamp(0.92, 1.12)).clamp(16.0, 24.0).toDouble()
        : (20.0 * fontScale.clamp(0.92, 1.18)).clamp(17.0, 31.0).toDouble();

    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPress: onTap,
        child: Container(
          color: bgColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: isLargeScreen
                    ? const EdgeInsets.fromLTRB(18, 8, 18, 8)
                    : EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: RichText(
                        textAlign: isLargeScreen
                            ? TextAlign.justify
                            : TextAlign.right,
                        textDirection: TextDirection.rtl,
                        text: TextSpan(
                          style: TextStyle(
                            fontFamily: 'quran',
                            fontSize: isLargeScreen ? fontSize : fontSize.sp,
                            height: isLargeScreen ? 1.72 : 1.95,
                            color: readerTheme.textColor,
                          ),
                          children: _buildWordSpans(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Divider(
                height: 1,
                thickness: 0.55,
                color: readerTheme.ayahSeparatorColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<InlineSpan> _buildWordSpans() {
    final List<String> words = QuranTextMasker.splitAyahWords(
      ayahText,
      ayahNumber: ayahKey.ayah,
    );

    if (words.isEmpty) {
      return <InlineSpan>[
        TextSpan(
          text: 'تعذر تحميل نص الآية',
          style: TextStyle(
            fontFamily: 'cairo',
            color: readerTheme.secondaryTextColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ];
    }

    final List<InlineSpan> spans = <InlineSpan>[];

    for (int index = 0; index < words.length; index++) {
      final int wordNumber = index + 1;
      final String wordText = words[index];
      final bool isLastWord = index == words.length - 1;

      final bool isActive =
          activeAudioWord != null &&
          activeAudioWord!.surah == ayahKey.surah &&
          activeAudioWord!.ayah == ayahKey.ayah &&
          activeAudioWord!.word == wordNumber;

      final bool hidden = _shouldHideWord(wordIndex: index);
      final String displayWordText = hidden
          ? QuranTextMasker.maskWordShape(wordText)
          : wordText;

      TextStyle wordStyle = TextStyle(
        color: isActive
            ? readerTheme.selectedWordTextColor
            : readerTheme.textColor,
        backgroundColor: isActive ? readerTheme.wordHighlightColor : null,
      );

      if (hidden) {
        wordStyle = wordStyle.copyWith(
          color: readerTheme.secondaryTextColor.withOpacity(0.58),
          backgroundColor: isSelected ? readerTheme.ayahHighlightColor : null,
        );
      }

      spans.add(
        TextSpan(
          text: isLastWord ? displayWordText : '$displayWordText ',
          style: wordStyle,
        ),
      );
    }

    spans.add(
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: EdgeInsetsDirectional.only(start: 8.w, end: 2.w),
          child: Semantics(
            label: 'آية ${ayahKey.ayah}',
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 1.5.h),
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  readerTheme.selectedWordTextColor.withOpacity(
                    readerTheme.isDarkLike ? 0.18 : 0.10,
                  ),
                  readerTheme.pageBackground,
                ),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: readerTheme.selectedWordTextColor.withOpacity(0.32),
                ),
              ),
              child: Text(
                '۝ ${ayahKey.ayah}',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: 12.sp,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                  color: readerTheme.selectedWordTextColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return spans;
  }

  bool _shouldHideWord({required int wordIndex}) {
    return QuranTextMasker.shouldHideWord(
      hideMode: hideMode,
      wordIndexInAyah: wordIndex,
    );
  }
}

class _QuranTextReader {
  const _QuranTextReader._();

  static String readAyahText({
    required dynamic source,
    required int suraIndex,
    required int ayahIndex,
  }) {
    final dynamic value = _readAyahValue(
      source: source,
      suraIndex: suraIndex,
      ayahIndex: ayahIndex,
    );

    return _cleanText(value?.toString() ?? '');
  }

  static dynamic _readAyahValue({
    required dynamic source,
    required int suraIndex,
    required int ayahIndex,
  }) {
    if (source == null) return null;

    if (source is List) {
      final int globalIndex = QuranReaderHelpers.getGlobalAyahIndex(
        suraIndex: suraIndex,
        ayahIndex: ayahIndex,
      );

      if (source.length > 114 &&
          globalIndex >= 0 &&
          globalIndex < source.length) {
        final dynamic flatText = _extractText(source[globalIndex]);
        if (flatText != null) return flatText;
      }

      if (suraIndex >= 0 && suraIndex < source.length) {
        final dynamic surahSource = source[suraIndex];
        final dynamic fromSurah = _readFromSurahSource(
          surahSource: surahSource,
          ayahIndex: ayahIndex,
        );
        if (fromSurah != null) return fromSurah;
      }

      if (globalIndex >= 0 && globalIndex < source.length) {
        return _extractText(source[globalIndex]);
      }
    }

    if (source is Map) {
      final dynamic surahSource =
          source['${suraIndex + 1}'] ??
          source[suraIndex + 1] ??
          source[suraIndex];

      final dynamic fromSurah = _readFromSurahSource(
        surahSource: surahSource,
        ayahIndex: ayahIndex,
      );

      if (fromSurah != null) return fromSurah;
    }

    return null;
  }

  static dynamic _readFromSurahSource({
    required dynamic surahSource,
    required int ayahIndex,
  }) {
    if (surahSource == null) return null;

    if (surahSource is List) {
      if (ayahIndex >= 0 && ayahIndex < surahSource.length) {
        return _extractText(surahSource[ayahIndex]);
      }
      return null;
    }

    if (surahSource is Map) {
      final dynamic ayahs =
          surahSource['ayahs'] ??
          surahSource['ayas'] ??
          surahSource['verses'] ??
          surahSource['data'];

      if (ayahs != null) {
        return _readFromSurahSource(surahSource: ayahs, ayahIndex: ayahIndex);
      }

      final dynamic directValue =
          surahSource['${ayahIndex + 1}'] ??
          surahSource[ayahIndex + 1] ??
          surahSource[ayahIndex];

      return _extractText(directValue);
    }

    return _extractText(surahSource);
  }

  static dynamic _extractText(dynamic value) {
    if (value == null) return null;

    if (value is String) return value;

    if (value is Map) {
      return value['aya_text'] ??
          value['ayah_text'] ??
          value['arabic_text'] ??
          value['uthmani'] ??
          value['simple'] ??
          value['clean'] ??
          value['text'] ??
          value['verse'] ??
          value['ayah'] ??
          value['aya'];
    }

    return value;
  }

  static String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[۝۞﴿﴾]+'), '')
        .replaceAll('ـ', '')
        .trim();
  }
}
