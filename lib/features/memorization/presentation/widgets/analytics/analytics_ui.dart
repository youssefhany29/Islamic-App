import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AnalyticsColors {
  const AnalyticsColors._();

  static const Color navy = Color(0xFF173B61);
  static const Color blue = Color(0xFF2D73CC);
  static const Color green = Color(0xFF35A88F);
  static const Color red = Color(0xFFE06A6A);
  static const Color orange = Color(0xFFE9A23B);
  static const Color purple = Color(0xFF6C63D8);

  static const Color softBlue = Color(0xFFEAF3FF);
  static const Color softGreen = Color(0xFFE9F8F2);
  static const Color softRed = Color(0xFFFDEBEC);
  static const Color softOrange = Color(0xFFFFF3DF);
  static const Color softPurple = Color(0xFFF0EEFF);

  // Light mode يرجع لنفس ألوان أول تصميم.
  static const Color cardInner = Color(0xFFFAFCFE);
  static const Color cardBorder = Color(0xFFE8EEF4);
  static const Color emptyChipLight = Color(0xFFF2F6F9);
}

class AnalyticsThemeColors {
  const AnalyticsThemeColors._();

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color pageBackground(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return isDark(context) ? colors.background : colors.primary;
  }

  static Color appBarText(BuildContext context) {
    return Colors.white;
  }

  static Color outerCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (isDark(context)) {
      // دارك مود من الثيم، مش أبيض ثابت.
      return colors.secondary;
    }

    // لايت مود زي أول نسخة.
    return Colors.white;
  }

  static Color innerCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (isDark(context)) {
      // درجة بسيطة من لون النص فوق الخلفية الداكنة، علشان الكارت يبان من غير ما يوجع العين.
      return colors.surface.withOpacity(0.055);
    }

    // لايت مود زي أول نسخة.
    return AnalyticsColors.cardInner;
  }

  static Color miniCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (isDark(context)) {
      return colors.surface.withOpacity(0.065);
    }

    return Colors.white;
  }

  static Color textPrimary(BuildContext context) {
    if (isDark(context)) return Theme.of(context).colorScheme.surface;

    // لا نعتمد على theme.surface هنا في اللايت علشان أي Theme override ما يخليش النص أبيض.
    return AnalyticsColors.navy;
  }

  static Color textSecondary(BuildContext context, [double opacity = 0.60]) {
    return textPrimary(context).withOpacity(opacity);
  }

  static Color border(BuildContext context, [double? opacity]) {
    final colors = Theme.of(context).colorScheme;

    if (isDark(context)) {
      return colors.outline.withOpacity(opacity ?? 0.14);
    }

    return AnalyticsColors.cardBorder.withOpacity(opacity ?? 0.78);
  }

  static Color softTone(BuildContext context, Color lightColor, Color accentColor) {
    if (isDark(context)) return accentColor.withOpacity(0.14);
    return lightColor;
  }

  static Color emptyChip(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (isDark(context)) return colors.surface.withOpacity(0.07);
    return AnalyticsColors.emptyChipLight;
  }
}

class AnalyticsDecorations {
  const AnalyticsDecorations._();

  static BoxDecoration outerCard(BuildContext context, {double? radius}) {
    return BoxDecoration(
      color: AnalyticsThemeColors.outerCard(context),
      borderRadius: BorderRadius.circular(radius ?? 18.r),
      border: Border.all(
        color: AnalyticsThemeColors.isDark(context)
            ? AnalyticsThemeColors.border(context, 0.16)
            : Colors.white.withOpacity(0.82),
        width: 0.8.w,
      ),
    );
  }

  static BoxDecoration innerCard(BuildContext context, {double? radius}) {
    return BoxDecoration(
      color: AnalyticsThemeColors.innerCard(context),
      borderRadius: BorderRadius.circular(radius ?? 18.r),
      border: Border.all(
        color: AnalyticsThemeColors.border(
          context,
          AnalyticsThemeColors.isDark(context) ? 0.14 : 0.78,
        ),
        width: 0.8.w,
      ),
    );
  }

  static BoxDecoration miniCard(BuildContext context, {double? radius}) {
    return BoxDecoration(
      color: AnalyticsThemeColors.miniCard(context),
      borderRadius: BorderRadius.circular(radius ?? 15.r),
      border: Border.all(
        color: AnalyticsThemeColors.border(
          context,
          AnalyticsThemeColors.isDark(context) ? 0.12 : 0.78,
        ),
        width: 0.8.w,
      ),
    );
  }
}
