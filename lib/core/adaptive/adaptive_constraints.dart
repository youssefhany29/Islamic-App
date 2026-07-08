import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'adaptive_breakpoints.dart';

class AdaptiveConstraints {
  const AdaptiveConstraints._();

  static const double mediumContentMaxWidth = 760;
  static const double expandedContentMaxWidth = 1120;
  static const double dashboardColumnGap = 16;
  static const double mediumCardMaxWidth = 360;
  static const double expandedCardMaxWidth = 420;

  static bool isCompactWidth(double width) {
    return width < AdaptiveBreakpoints.compact;
  }

  static bool isMediumWidth(double width) {
    return width >= AdaptiveBreakpoints.compact &&
        width < AdaptiveBreakpoints.expanded;
  }

  static bool isExpandedWidth(double width) {
    return width >= AdaptiveBreakpoints.expanded;
  }

  static double centeredContentWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (isCompactWidth(width)) {
      return width;
    }

    if (isMediumWidth(width)) {
      return math.min(width, mediumContentMaxWidth);
    }

    return math.min(width, expandedContentMaxWidth);
  }

  static double cardWidthForWindow({
    required double windowWidth,
    required double scaledPhoneWidth,
  }) {
    if (isCompactWidth(windowWidth)) {
      return scaledPhoneWidth;
    }

    if (isMediumWidth(windowWidth)) {
      return math.min(scaledPhoneWidth, mediumCardMaxWidth);
    }

    return math.min(scaledPhoneWidth, expandedCardMaxWidth);
  }
}
