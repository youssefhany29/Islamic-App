import 'package:flutter/material.dart';

class AppTextStyles {
  const AppTextStyles._();

  static bool _isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 600;
  }

  static TextStyle _style(
    BuildContext context, {
    required double mobileSize,
    required double tabletSize,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return TextStyle(
      fontFamily: 'cairo',
      fontSize: _isTablet(context) ? tabletSize : mobileSize,
      fontWeight: fontWeight,
    );
  }

  static TextStyle display(BuildContext context) {
    return _style(context, mobileSize: 20, tabletSize: 24);
  }

  static TextStyle headline(BuildContext context) {
    return _style(context, mobileSize: 18, tabletSize: 22);
  }

  static TextStyle body(BuildContext context) {
    return _style(context, mobileSize: 16, tabletSize: 20);
  }

  static TextStyle caption(BuildContext context) {
    return _style(context, mobileSize: 14, tabletSize: 18);
  }
}
