import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdaptiveOrientationPolicy {
  const AdaptiveOrientationPolicy._();

  static _OrientationMode? _lastMode;

  /// المطلوب:
  /// - الموبايل: Portrait ثابت.
  /// - الفولد: Portrait ثابت.
  /// - التابلت الحقيقي: حر حسب وضع المستخدم الحالي.
  ///
  /// ملاحظة:
  /// بنستخدم shortestSide >= 600 كعلامة عامة للتابلت.
  /// أما الفولد/الشاشات المتوسطة اللي shortestSide أقل من 600
  /// فبنخليها Portrait ثابتة زي الموبايل.
  static void applyForContext(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);

    final bool isTablet = size.shortestSide >= 600;

    final _OrientationMode nextMode =
    isTablet ? _OrientationMode.free : _OrientationMode.portraitOnly;

    if (_lastMode == nextMode) return;

    _lastMode = nextMode;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (nextMode == _OrientationMode.free) {
        SystemChrome.setPreferredOrientations([]);
        return;
      }

      SystemChrome.setPreferredOrientations(
        const [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ],
      );
    });
  }

  static Future<void> reset() {
    _lastMode = null;
    return SystemChrome.setPreferredOrientations([]);
  }
}

enum _OrientationMode {
  free,
  portraitOnly,
}