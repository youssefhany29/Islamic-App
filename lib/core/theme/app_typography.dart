import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum AppTextScaleClass {
  phone,
  fold,
  tablet,
}

class AppTypography {
  const AppTypography._();

  static AppTextScaleClass scaleClass(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);

    if (size.shortestSide >= 600) {
      return AppTextScaleClass.tablet;
    }

    if (size.width >= 700 && size.height >= 500) {
      return AppTextScaleClass.fold;
    }

    return AppTextScaleClass.phone;
  }

  static bool isLarge(BuildContext context) {
    return scaleClass(context) != AppTextScaleClass.phone;
  }

  static double _size(
    BuildContext context, {
    required double phone,
    required double fold,
    required double tablet,
  }) {
    switch (scaleClass(context)) {
      case AppTextScaleClass.phone:
        return phone.sp;
      case AppTextScaleClass.fold:
        return fold;
      case AppTextScaleClass.tablet:
        return tablet;
    }
  }

  static TextStyle pageHeader(
    BuildContext context, {
    Color? color,
    FontWeight fontWeight = FontWeight.w800,
  }) {
    return TextStyle(
      fontFamily: 'cairo',
      fontSize: _size(context, phone: 15.5, fold: 17, tablet: 18),
      fontWeight: fontWeight,
      color: color,
      height: 1.3,
      letterSpacing: 0,
    );
  }

  static TextStyle heroTitle(
    BuildContext context, {
    Color? color,
    FontWeight fontWeight = FontWeight.w900,
  }) {
    return TextStyle(
      fontFamily: 'cairo',
      fontSize: _size(context, phone: 18, fold: 21, tablet: 22),
      fontWeight: fontWeight,
      color: color,
      height: 1.15,
      letterSpacing: 0,
    );
  }

  static TextStyle heroSubtitle(
    BuildContext context, {
    Color? color,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return TextStyle(
      fontFamily: 'cairo',
      fontSize: _size(context, phone: 9.2, fold: 11, tablet: 11.5),
      fontWeight: fontWeight,
      color: color,
      height: 1.35,
      letterSpacing: 0,
    );
  }

  static TextStyle cardTitle(
    BuildContext context, {
    Color? color,
    FontWeight fontWeight = FontWeight.w800,
  }) {
    return TextStyle(
      fontFamily: 'cairo',
      fontSize: _size(context, phone: 12.4, fold: 14.2, tablet: 15),
      fontWeight: fontWeight,
      color: color,
      height: 1.3,
      letterSpacing: 0,
    );
  }

  static TextStyle cardSubtitle(
    BuildContext context, {
    Color? color,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return TextStyle(
      fontFamily: 'cairo',
      fontSize: _size(context, phone: 9.4, fold: 10.6, tablet: 11.2),
      fontWeight: fontWeight,
      color: color,
      height: 1.45,
      letterSpacing: 0,
    );
  }

  static TextStyle metadata(
    BuildContext context, {
    Color? color,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    return TextStyle(
      fontFamily: 'cairo',
      fontSize: _size(context, phone: 9, fold: 9.8, tablet: 10.4),
      fontWeight: fontWeight,
      color: color,
      height: 1.35,
      letterSpacing: 0,
    );
  }

  static TextStyle button(
    BuildContext context, {
    Color? color,
    FontWeight fontWeight = FontWeight.w800,
  }) {
    return TextStyle(
      fontFamily: 'cairo',
      fontSize: _size(context, phone: 11, fold: 12, tablet: 12.5),
      fontWeight: fontWeight,
      color: color,
      height: 1.25,
      letterSpacing: 0,
    );
  }

  static TextStyle searchField(
    BuildContext context, {
    Color? color,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return TextStyle(
      fontFamily: 'cairo',
      fontSize: _size(context, phone: 11.5, fold: 12.4, tablet: 13),
      fontWeight: fontWeight,
      color: color,
      height: 1.4,
      letterSpacing: 0,
    );
  }

  static TextStyle detailContent(
    BuildContext context, {
    Color? color,
    FontWeight fontWeight = FontWeight.w600,
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'cairo',
      fontSize: _size(context, phone: 14, fold: 15.2, tablet: 16),
      fontWeight: fontWeight,
      color: color,
      height: height ?? 1.75,
      letterSpacing: 0,
      wordSpacing: 0,
    );
  }
}
