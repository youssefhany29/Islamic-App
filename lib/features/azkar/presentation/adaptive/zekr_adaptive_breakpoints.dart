import 'package:flutter/material.dart';

class ZekrAdaptiveBreakpoints {
  const ZekrAdaptiveBreakpoints._();

  static bool isPhone(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    return size.width < 600;
  }

  static bool isFold(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    return size.width >= 600 && size.shortestSide < 600;
  }

  static bool isTablet(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    return size.shortestSide >= 600;
  }

  static bool isLargeScreen(BuildContext context) {
    return isFold(context) || isTablet(context);
  }

  static bool isLandscape(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    return size.width > size.height;
  }

  static double pageHorizontalPadding(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);

    if (isFold(context)) {
      return isLandscape(context) ? 18 : 20;
    }

    if (isTablet(context)) {
      return isLandscape(context) ? 26 : 30;
    }

    return 14;
  }

  static double sectionGap(BuildContext context) {
    if (isFold(context)) return 14;
    if (isTablet(context)) return 18;
    return 12;
  }

  static double cardRadius(BuildContext context) {
    if (isFold(context)) return 22;
    if (isTablet(context)) return 26;
    return 18;
  }
}
