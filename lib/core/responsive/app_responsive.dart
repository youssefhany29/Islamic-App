import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppResponsive {
  const AppResponsive._();

  static bool isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 600;
  }

  static double font(BuildContext context, double size) {
    return size.sp;
  }

  static double icon(BuildContext context, double size) {
    return size.sp;
  }
}