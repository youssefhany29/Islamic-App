import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../data/qpc_reader_perf.dart';
import '../hiding/quran_hide_mode.dart';
import '../models/qpc_models.dart';
import '../theme/quran_reader_theme.dart';
import 'qpc_basmallah_line.dart';
import 'qpc_render_probe.dart';
import 'qpc_surah_header_line.dart';

class QpcLineTapResult {
  const QpcLineTapResult({required this.ayahKey, required this.wordKey});

  final QpcAyahKey ayahKey;
  final QpcWordKey wordKey;
}

class QpcLineView extends StatelessWidget {
  const QpcLineView({
    super.key,
    required this.line,
    required this.fontFamily,
    required this.lineHeight,
    required this.readerTheme,
    required this.hideMode,
    required this.selectedAyah,
    required this.selectedWord,
    required this.activeAudioWord,
    required this.finalWordByAyah,
    required this.onWordTap,
    this.fontScale = 1.0,
  });

  final QpcMushafLine? line;
  final String fontFamily;
  final double lineHeight;
  final QuranReaderTheme readerTheme;
  final QuranHideMode hideMode;
  final QpcAyahKey? selectedAyah;
  final QpcWordKey? selectedWord;
  final QpcWordKey? activeAudioWord;
  final Map<QpcAyahKey, int> finalWordByAyah;
  final ValueChanged<QpcLineTapResult> onWordTap;
  final double fontScale;

  @override
  Widget build(BuildContext context) {
    final Stopwatch? stopwatch = QpcReaderPerf.start();
    final QpcMushafLine? currentLine = line;

    if (currentLine == null) {
      return const SizedBox.expand();
    }

    if (currentLine.isSurahNameLine) {
      return QpcSurahHeaderLine(
        surahNumber: currentLine.surahNumber,
        lineHeight: lineHeight,
        readerTheme: readerTheme,
      );
    }

    if (currentLine.isBasmallahLine && currentLine.words.isEmpty) {
      return QpcBasmallahLine(lineHeight: lineHeight, readerTheme: readerTheme);
    }

    if (currentLine.words.isEmpty) {
      return const SizedBox.expand();
    }

    final bool isLargeScreen = MediaQuery.sizeOf(context).width >= 600;
    final double safeFontScale = fontScale.clamp(0.92, 1.08).toDouble();

    final double fontSize = _fontSizeForLine(
      line: currentLine,
      lineHeight: lineHeight,
      fontScale: safeFontScale,
      isLargeScreen: isLargeScreen,
    );

    final TextStyle baseStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      height: 1.0,
      color: readerTheme.textColor,
      fontWeight: FontWeight.normal,
    );

    final Widget content = Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: RichText(
            textAlign: TextAlign.center,
            maxLines: 1,
            softWrap: false,
            textDirection: TextDirection.rtl,
            text: TextSpan(
              style: baseStyle,
              children: _buildWordSpans(
                line: currentLine,
                baseStyle: baseStyle,
              ),
            ),
          ),
        ),
      ),
    );

    QpcReaderPerf.end(
      'line rich build p${currentLine.pageNumber} l${currentLine.lineNumber}',
      stopwatch,
    );

    return QpcLayoutPaintProbe(
      label: 'line rich p${currentLine.pageNumber} l${currentLine.lineNumber}',
      child: content,
    );
  }

  List<InlineSpan> _buildWordSpans({
    required QpcMushafLine line,
    required TextStyle baseStyle,
  }) {
    final List<InlineSpan> spans = <InlineSpan>[];
    final Map<QpcAyahKey, int> wordIndexByAyah = <QpcAyahKey, int>{};

    for (int i = 0; i < line.words.length; i++) {
      final QpcWord word = line.words[i];
      final bool isLastWordInLine = i == line.words.length - 1;
      final QpcAyahKey ayahKey = word.ayahKey;
      final QpcWordKey wordKey = word.wordKey;

      final int wordIndexInAyah = wordIndexByAyah[ayahKey] ?? 0;
      wordIndexByAyah[ayahKey] = wordIndexInAyah + 1;

      final bool ayahSelected = _sameAyah(selectedAyah, ayahKey);
      final bool wordSelected = _sameWord(selectedWord, wordKey);
      final bool audioWordActive = _sameWord(activeAudioWord, wordKey);
      final bool ayahEndGlyph = finalWordByAyah[ayahKey] == word.word;

      final bool hidden = _shouldHideWord(
        wordIndexInAyah: wordIndexInAyah,
        ayahEndGlyph: ayahEndGlyph,
      );

      final TextStyle style = _styleForWord(
        baseStyle: baseStyle,
        hidden: hidden,
        ayahSelected: ayahSelected,
        wordSelected: wordSelected,
        audioWordActive: audioWordActive,
      );

      spans.add(
        TextSpan(
          text: isLastWordInLine ? word.text : '${word.text} ',
          style: style,
          recognizer:
              LongPressGestureRecognizer(
                  duration: const Duration(milliseconds: 420),
                )
                ..onLongPress = () {
                  onWordTap(
                    QpcLineTapResult(ayahKey: ayahKey, wordKey: wordKey),
                  );
                },
        ),
      );
    }

    return spans;
  }

  double _fontSizeForLine({
    required QpcMushafLine line,
    required double lineHeight,
    required double fontScale,
    required bool isLargeScreen,
  }) {
    final int wordCount = line.words.length;
    final bool centered = line.isCentered;

    if (isLargeScreen) {
      if (centered) {
        return (lineHeight * 0.62 * fontScale).clamp(14.0, 22.0).toDouble();
      }

      if (wordCount <= 6) {
        return (lineHeight * 0.66 * fontScale).clamp(14.5, 24.0).toDouble();
      }

      if (wordCount <= 9) {
        return (lineHeight * 0.72 * fontScale).clamp(15.0, 26.0).toDouble();
      }

      return (lineHeight * 0.78 * fontScale).clamp(16.0, 29.0).toDouble();
    }

    /// مهم:
    /// آخر صفحات المصحف فيها سور قصيرة، وسطورها أحيانًا centered وقليلة الكلمات.
    /// لو استخدمنا نفس معامل الصفحات الطويلة، آخر آية في كل سورة بتظهر ضخمة.
    if (centered && wordCount <= 6) {
      return (lineHeight * 0.68 * fontScale).clamp(15.0, 25.0).toDouble();
    }

    if (centered && wordCount <= 9) {
      return (lineHeight * 0.72 * fontScale).clamp(15.5, 27.0).toDouble();
    }

    if (wordCount <= 6) {
      return (lineHeight * 0.74 * fontScale).clamp(16.0, 28.0).toDouble();
    }

    if (wordCount <= 9) {
      return (lineHeight * 0.80 * fontScale).clamp(16.0, 30.0).toDouble();
    }

    return (lineHeight * 0.86 * fontScale).clamp(17.0, 33.0).toDouble();
  }

  bool _shouldHideWord({
    required int wordIndexInAyah,
    required bool ayahEndGlyph,
  }) {
    if (ayahEndGlyph) {
      return false;
    }

    if (hideMode == QuranHideMode.visible) {
      return false;
    }

    if (hideMode == QuranHideMode.full) {
      return true;
    }

    if (hideMode == QuranHideMode.partial) {
      return wordIndexInAyah % 3 != 0;
    }

    return false;
  }

  TextStyle _styleForWord({
    required TextStyle baseStyle,
    required bool hidden,
    required bool ayahSelected,
    required bool wordSelected,
    required bool audioWordActive,
  }) {
    TextStyle style = baseStyle;

    if (ayahSelected) {
      style = style.copyWith(backgroundColor: readerTheme.ayahHighlightColor);
    }

    if (wordSelected || audioWordActive) {
      style = style.copyWith(
        color: readerTheme.selectedWordTextColor,
        backgroundColor: readerTheme.wordHighlightColor,
      );
    }

    if (hidden) {
      style = style.copyWith(
        color: Colors.transparent,
        backgroundColor: ayahSelected
            ? readerTheme.ayahHighlightColor
            : Colors.transparent,
        decoration: TextDecoration.underline,
        decorationColor: readerTheme.selectedWordTextColor.withOpacity(0.60),
        decorationStyle: TextDecorationStyle.solid,
        decorationThickness: 1.25,
      );
    }

    return style;
  }

  bool _sameAyah(QpcAyahKey? first, QpcAyahKey second) {
    return first != null &&
        first.surah == second.surah &&
        first.ayah == second.ayah;
  }

  bool _sameWord(QpcWordKey? first, QpcWordKey second) {
    return first != null &&
        first.surah == second.surah &&
        first.ayah == second.ayah &&
        first.word == second.word;
  }
}
