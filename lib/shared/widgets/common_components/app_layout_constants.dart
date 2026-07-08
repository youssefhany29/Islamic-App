import 'dart:math' as math;

import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppLayoutConstants {
  static bool get isLargeScreen => ScreenUtil().screenWidth >= 600;

  static double get pageHorizontalPadding {
    if (isLargeScreen) return 0;
    return 14.w;
  }

  static double get mainCardWidth {
    if (isLargeScreen) {
      return double.infinity;
    }

    return 272.w;
  }

  static double get halfCardWidth {
    if (!isLargeScreen) {
      return 132.w;
    }

    return math.max(0, (ScreenUtil().screenWidth - 16) / 2);
  }

  static double get mainCardRadius {
    if (isLargeScreen) return 18;
    return 16.r;
  }

  static double get mainCardPadding {
    if (isLargeScreen) return 16;
    return 10.w;
  }
}