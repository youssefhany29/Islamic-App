import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../data/qpc_page_font_loader.dart';
import '../models/qpc_models.dart';

class QpcTextLayoutWarmUp {
  QpcTextLayoutWarmUp._();

  static final Set<_WarmPageKey> _warmedPages = <_WarmPageKey>{};

  static void warmPage({
    required QpcPageData pageData,
    required Size pageSize,
    required double fontScale,
  }) {
    if (pageSize.width <= 0 || pageSize.height <= 0) {
      return;
    }

    final bool isLargeScreen = pageSize.width >= 600;
    final double safeFontScale = fontScale.clamp(0.92, 1.08).toDouble();
    final _WarmPageKey key = _WarmPageKey(
      pageNumber: pageData.pageNumber,
      width: pageSize.width.round(),
      height: pageSize.height.round(),
      fontScaleX100: (safeFontScale * 100).round(),
    );

    if (!_warmedPages.add(key)) {
      return;
    }

    if (_warmedPages.length > 36) {
      _warmedPages.remove(_warmedPages.first);
    }

    final _WarmPageMetrics metrics = _WarmPageMetrics.fromSize(
      width: pageSize.width,
      height: pageSize.height,
      isLargeScreen: isLargeScreen,
    );

    final String fontFamily = QpcPageFontLoader.familyForPage(
      pageData.pageNumber,
    );
    final double textMaxWidth = (pageSize.width - metrics.horizontalPadding * 2)
        .clamp(1.0, pageSize.width)
        .toDouble();

    for (int lineNumber = 1; lineNumber <= 15; lineNumber++) {
      final QpcMushafLine? line = pageData.lineByNumber(lineNumber);
      if (line == null ||
          line.words.isEmpty ||
          line.isSurahNameLine ||
          line.isBasmallahLine) {
        continue;
      }

      final String text = line.words.map((word) => word.text).join(' ');
      if (text.trim().isEmpty) {
        continue;
      }

      final TextPainter painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: _fontSizeForLine(
              line: line,
              lineHeight: metrics.lineHeight,
              fontScale: safeFontScale,
              isLargeScreen: isLargeScreen,
            ),
            height: 1.0,
            fontWeight: FontWeight.normal,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        maxLines: 1,
      );

      painter.layout(maxWidth: textMaxWidth);
    }
  }

  static double _fontSizeForLine({
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
}

class _WarmPageMetrics {
  const _WarmPageMetrics({
    required this.horizontalPadding,
    required this.lineHeight,
  });

  final double horizontalPadding;
  final double lineHeight;

  static _WarmPageMetrics fromSize({
    required double width,
    required double height,
    required bool isLargeScreen,
  }) {
    final double horizontalPadding = _horizontalPaddingForWidth(
      width,
      isLargeScreen: isLargeScreen,
    );
    final double contentTopOffset = _topOffsetForHeight(
      height,
      isLargeScreen: isLargeScreen,
    );
    final double contentBottomOffset = _bottomOffsetForHeight(
      height,
      isLargeScreen: isLargeScreen,
    );
    final double availableHeight =
        height - contentTopOffset - contentBottomOffset;

    return _WarmPageMetrics(
      horizontalPadding: horizontalPadding,
      lineHeight: availableHeight / 15.0,
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

class _WarmPageKey {
  const _WarmPageKey({
    required this.pageNumber,
    required this.width,
    required this.height,
    required this.fontScaleX100,
  });

  final int pageNumber;
  final int width;
  final int height;
  final int fontScaleX100;

  @override
  bool operator ==(Object other) {
    return other is _WarmPageKey &&
        other.pageNumber == pageNumber &&
        other.width == width &&
        other.height == height &&
        other.fontScaleX100 == fontScaleX100;
  }

  @override
  int get hashCode => Object.hash(pageNumber, width, height, fontScaleX100);
}
