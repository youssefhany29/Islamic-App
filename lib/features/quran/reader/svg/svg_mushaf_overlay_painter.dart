import 'package:flutter/material.dart';

import '../hiding/quran_hide_mode.dart';
import '../models/qpc_models.dart';
import '../models/quran_selection.dart';
import '../theme/quran_reader_theme.dart';
import 'svg_mushaf_geometry_models.dart';
import 'svg_mushaf_page_layout.dart';

const double _ayahNumberGapMin = 4;
const double _ayahNumberGapMax = 8;

class SvgMushafOverlayPainter extends CustomPainter {
  const SvgMushafOverlayPainter({
    required this.geometry,
    required this.imageSize,
    required this.readerTheme,
    required this.hideMode,
    required this.selection,
    required this.waqfHighlightEnabled,
  });

  final SvgPageGeometry geometry;
  final Size imageSize;
  final QuranReaderTheme readerTheme;
  final QuranHideMode hideMode;
  final QuranSelection? selection;
  final bool waqfHighlightEnabled;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect pageRect = calculateDisplayedPageRect(size, imageSize);
    if (pageRect.isEmpty) {
      return;
    }

    final QpcAyahKey? selectedAyah = selection?.ayahKey;

    if (selectedAyah != null) {
      final SvgAyahGeometry? ayah = geometry.ayahForKey(selectedAyah);
      if (ayah != null) {
        _paintAyahHighlight(canvas, pageRect, ayah);
      }
    }

    if (waqfHighlightEnabled) {
      _paintWaqfHighlights(canvas, pageRect);
    }

    if (hideMode != QuranHideMode.visible) {
      _paintHiddenWords(canvas, pageRect);
    }
  }

  void _paintAyahHighlight(Canvas canvas, Rect pageRect, SvgAyahGeometry ayah) {
    final Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..color = readerTheme.ayahHighlightColor;

    for (final SvgBoxGeometry segment in ayah.segments) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          _boxRect(segment, pageRect).inflate(2),
          const Radius.circular(3),
        ),
        paint,
      );
    }
  }

  void _paintWaqfHighlights(Canvas canvas, Rect pageRect) {
    final Paint fill = Paint()
      ..style = PaintingStyle.fill
      ..color = readerTheme.selectedWordTextColor.withValues(
        alpha: readerTheme.isDarkLike ? 0.22 : 0.13,
      );
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = readerTheme.selectedWordTextColor.withValues(
        alpha: readerTheme.isDarkLike ? 0.48 : 0.34,
      );

    for (final SvgAyahGeometry ayah in geometry.ayahs) {
      for (final SvgBoxGeometry word in ayah.textWords) {
        if (!word.isWaqfMark) {
          continue;
        }

        final Rect wordRect = _boxRect(word, pageRect);
        if (wordRect.isEmpty) {
          continue;
        }

        final double padding = (wordRect.height * 0.18)
            .clamp(1.2, 4.0)
            .toDouble();
        final Rect highlightRect = _inflateInsidePage(
          wordRect,
          pageRect,
          dx: padding,
          dy: padding * 0.6,
        );
        final Radius radius = Radius.circular(
          (highlightRect.height * 0.45).clamp(4.0, 10.0).toDouble(),
        );
        final RRect shape = RRect.fromRectAndRadius(highlightRect, radius);

        canvas.drawRRect(shape, fill);
        canvas.drawRRect(shape, stroke);
      }
    }
  }

  void _paintHiddenWords(Canvas canvas, Rect pageRect) {
    final Paint mask = Paint()
      ..style = PaintingStyle.fill
      ..color = readerTheme.pageBackground;

    final Paint dot = Paint()
      ..style = PaintingStyle.fill
      ..color = readerTheme.textColor.withValues(
        alpha: readerTheme.isDarkLike ? 0.42 : 0.34,
      );

    for (final SvgAyahGeometry ayah in geometry.ayahs) {
      final Path ayahNumberClipPath = _ayahNumberClipPath(ayah, pageRect);
      final Map<int, List<Rect>> ayahRectsByLine = <int, List<Rect>>{};

      for (final SvgBoxGeometry word in ayah.textWords) {
        final Rect wordRect = _boxRect(word, pageRect);
        if (wordRect.isEmpty) {
          continue;
        }

        ayahRectsByLine.putIfAbsent(word.line, () => <Rect>[]).add(wordRect);
      }

      for (final List<Rect> lineRects in ayahRectsByLine.values) {
        final Rect lineSpan = _lineSpanRect(lineRects);
        if (lineSpan.isEmpty) {
          continue;
        }

        final double verticalPadding = (lineSpan.height * 0.08)
            .clamp(0.6, 2.0)
            .toDouble();
        final double horizontalPadding = (lineSpan.height * 0.06)
            .clamp(0.5, 1.8)
            .toDouble();
        final Rect maskRect = _inflateInsidePage(
          lineSpan,
          pageRect,
          dx: horizontalPadding,
          dy: verticalPadding,
        );
        final Radius radius = Radius.circular(
          (maskRect.height * 0.12).clamp(1.2, 3.0).toDouble(),
        );
        final Path maskPath = Path()
          ..addRRect(RRect.fromRectAndRadius(maskRect, radius));
        final Path visibleMaskPath = Path.combine(
          PathOperation.difference,
          maskPath,
          ayahNumberClipPath,
        );

        canvas.drawPath(visibleMaskPath, mask);
        _paintLineDots(canvas, visibleMaskPath, maskRect, dot);
      }
    }
  }

  Rect _lineSpanRect(List<Rect> lineRects) {
    Rect span = lineRects.first;
    for (final Rect rect in lineRects.skip(1)) {
      span = span.expandToInclude(rect);
    }
    return span;
  }

  void _paintLineDots(Canvas canvas, Path clipPath, Rect maskRect, Paint dot) {
    const double radius = 0.75;
    const double spacing = 6.0;
    final double inset = (maskRect.height * 0.18).clamp(2.0, 5.0).toDouble();
    final double startX = maskRect.left + inset;
    final double endX = maskRect.right - inset;

    if (endX <= startX) {
      return;
    }

    canvas.save();
    canvas.clipPath(clipPath);
    for (double x = startX; x <= endX; x += spacing) {
      canvas.drawCircle(Offset(x, maskRect.center.dy), radius, dot);
    }
    canvas.restore();
  }

  Path _ayahNumberClipPath(SvgAyahGeometry ayah, Rect pageRect) {
    final Path path = Path();
    for (final SvgBoxGeometry box in ayah.ayahNumberBoxes) {
      final Rect boxRect = _boxRect(box, pageRect);
      final double gap = (boxRect.height * 0.22)
          .clamp(_ayahNumberGapMin, _ayahNumberGapMax)
          .toDouble();
      path.addRRect(
        RRect.fromRectAndRadius(
          _inflateInsidePage(boxRect, pageRect, dx: gap, dy: gap * 0.72),
          Radius.circular((boxRect.height * 0.25).clamp(4.0, 8.0).toDouble()),
        ),
      );
    }
    return path;
  }

  Rect _boxRect(SvgBoxGeometry box, Rect pageRect) {
    return box.toRect(pageRect.size).shift(pageRect.topLeft);
  }

  Rect _inflateInsidePage(
    Rect rect,
    Rect pageRect, {
    required double dx,
    required double dy,
  }) {
    return Rect.fromLTRB(
      (rect.left - dx).clamp(pageRect.left, pageRect.right).toDouble(),
      (rect.top - dy).clamp(pageRect.top, pageRect.bottom).toDouble(),
      (rect.right + dx).clamp(pageRect.left, pageRect.right).toDouble(),
      (rect.bottom + dy).clamp(pageRect.top, pageRect.bottom).toDouble(),
    );
  }

  @override
  bool shouldRepaint(covariant SvgMushafOverlayPainter oldDelegate) {
    return oldDelegate.geometry != geometry ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.readerTheme != readerTheme ||
        oldDelegate.hideMode != hideMode ||
        oldDelegate.selection != selection ||
        oldDelegate.waqfHighlightEnabled != waqfHighlightEnabled;
  }
}
