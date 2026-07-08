import 'package:flutter/material.dart';

class PrayerAdaptive {
  const PrayerAdaptive._();

  static const double largeBreakpoint = 600;

  static bool isLarge(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= largeBreakpoint;
  }

  static bool isFoldLandscape(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width >= largeBreakpoint && size.shortestSide < largeBreakpoint;
  }

  static double pagePadding(BuildContext context) {
    return isFoldLandscape(context) ? 14 : 22;
  }

  static double sectionGap(BuildContext context) {
    return isFoldLandscape(context) ? 12 : 16;
  }

  static double cardRadius(BuildContext context) {
    return isFoldLandscape(context) ? 18 : 20;
  }

  static double titleSize(BuildContext context) {
    return isFoldLandscape(context) ? 16 : 19;
  }

  static double cardTitleSize(BuildContext context) {
    return isFoldLandscape(context) ? 11 : 12.5;
  }

  static double subtitleSize(BuildContext context) {
    return isFoldLandscape(context) ? 8 : 9;
  }

  static double smallTextSize(BuildContext context) {
    return isFoldLandscape(context) ? 7.5 : 8.5;
  }

  static double iconSize(BuildContext context) {
    return isFoldLandscape(context) ? 15 : 17;
  }

  static double buttonHeight(BuildContext context) {
    return isFoldLandscape(context) ? 30 : 34;
  }
}
