import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/theme/app_typography.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

class ZekrTasbeehPreviewCard extends StatefulWidget {
  const ZekrTasbeehPreviewCard({super.key});

  @override
  State<ZekrTasbeehPreviewCard> createState() => _ZekrTasbeehPreviewCardState();
}

class _ZekrTasbeehPreviewCardState extends State<ZekrTasbeehPreviewCard> {
  int counter = 0;

  bool _isLargeScreen(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    return size.shortestSide >= 600 ||
        (size.width >= 700 && size.height >= 500);
  }

  void _increment() {
    AppHaptics.tap(context);

    setState(() {
      counter++;
    });
  }

  void _reset() {
    AppHaptics.tap(context);

    setState(() {
      counter = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final bool isLargeScreen = _isLargeScreen(context);

    final double radius = isLargeScreen ? 22 : 18.r;
    final double padding = isLargeScreen ? 16 : 14.w;
    final double iconBox = isLargeScreen ? 44 : 40.w;
    final double iconSize = isLargeScreen ? 24 : 21.sp;
    final double counterSize = isLargeScreen ? 30 : 24.sp;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(isDark ? 0.18 : 0.42),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.08 : 0.025),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: iconBox,
                  height: iconBox,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(
                      isDark ? 0.20 : 0.10,
                    ),
                    borderRadius: BorderRadius.circular(
                      isLargeScreen ? 15 : 14.r,
                    ),
                  ),
                  child: Icon(
                    Icons.radio_button_checked_rounded,
                    color: theme.colorScheme.primary,
                    size: iconSize,
                  ),
                ),
                SizedBox(width: isLargeScreen ? 12 : 10.w),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          'تسبيح سريع',
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          locale: const Locale('ar'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.cardTitle(
                            context,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.surface,
                          ),
                        ),
                      ),
                      SizedBox(height: isLargeScreen ? 4 : 3.h),
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          'اضغط للتسبيح بسرعة من الصفحة.',
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          locale: const Locale('ar'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.cardSubtitle(
                            context,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.surface.withOpacity(0.64),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: isLargeScreen ? 12 : 10.w),
                Text(
                  '$counter',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontFamily: 'cairo',
                    fontSize: counterSize,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                    height: 1.0,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
            SizedBox(height: isLargeScreen ? 14 : 12.h),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _increment,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isLargeScreen ? 12 : 10.h,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          isLargeScreen ? 15 : 14.r,
                        ),
                      ),
                    ),
                    child: Text(
                      'سبحان الله',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      style: AppTypography.button(
                        context,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isLargeScreen ? 10 : 10.w),
                OutlinedButton(
                  onPressed: _reset,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(
                      color: theme.colorScheme.primary.withOpacity(0.45),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isLargeScreen ? 20 : 16.w,
                      vertical: isLargeScreen ? 12 : 10.h,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        isLargeScreen ? 15 : 14.r,
                      ),
                    ),
                  ),
                  child: Text(
                    'تصفير',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: AppTypography.button(
                      context,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
