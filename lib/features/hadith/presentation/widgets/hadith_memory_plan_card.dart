import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/theme/app_typography.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

class HadithMemoryPlanCard extends StatelessWidget {
  const HadithMemoryPlanCard({
    super.key,
    required this.enabled,
    required this.isChanging,
    required this.onChanged,
  });

  final bool enabled;
  final bool isChanging;
  final ValueChanged<bool> onChanged;

  bool _isLargeScreen(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    return size.shortestSide >= 600 ||
        (size.width >= 700 && size.height >= 500);
  }

  void _showPlanInfo(BuildContext context) {
    AppHaptics.tap(context);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isLargeScreen = _isLargeScreen(context);

    final double sheetMargin = isLargeScreen ? 18 : 12.w;
    final double sheetHorizontalPadding = isLargeScreen ? 18 : 14.w;
    final double sheetTopPadding = isLargeScreen ? 18 : 14.h;
    final double sheetBottomPadding = isLargeScreen ? 18 : 16.h;
    final double sheetRadius = isLargeScreen ? 28 : 24.r;

    final double headerIconBox = isLargeScreen ? 52 : 40.w;
    final double headerIconSize = isLargeScreen ? 28 : 22.sp;
    final double headerIconRadius = isLargeScreen ? 16 : 14.r;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.all(sheetMargin),
              padding: EdgeInsets.fromLTRB(
                sheetHorizontalPadding,
                sheetTopPadding,
                sheetHorizontalPadding,
                sheetBottomPadding,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                borderRadius: BorderRadius.circular(sheetRadius),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(
                    isDark ? 0.18 : 0.32,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    textDirection: TextDirection.rtl,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: headerIconBox,
                        height: headerIconBox,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(headerIconRadius),
                        ),
                        child: Icon(
                          Icons.psychology_alt_outlined,
                          color: theme.colorScheme.primary,
                          size: headerIconSize,
                        ),
                      ),
                      SizedBox(width: isLargeScreen ? 12 : 10.w),
                      Expanded(
                        child: Text(
                          'ما هي خطة حفظ الحديث؟',
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          locale: const Locale('ar'),
                          style: AppTypography.pageHeader(
                            context,
                            color: theme.colorScheme.surface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isLargeScreen ? 14 : 12.h),
                  _InfoPoint(
                    icon: Icons.menu_book_rounded,
                    text: 'تقرأ الحديث عادي بدون أي إجبار على الحفظ.',
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(height: isLargeScreen ? 9 : 8.h),
                  _InfoPoint(
                    icon: Icons.psychology_alt_outlined,
                    text:
                        'لو حبيت تحفظ، افتح "درّبني على حفظ الحديث" واستخدم القراءة أو التدريب أو الاختبار.',
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(height: isLargeScreen ? 9 : 8.h),
                  _InfoPoint(
                    icon: Icons.rate_review_rounded,
                    text:
                        'بعد التدريب قيّم نفسك: تمام، نص نص، أو محتاج مراجعة.',
                    color: const Color(0xff21C58E),
                  ),
                  SizedBox(height: isLargeScreen ? 9 : 8.h),
                  _InfoPoint(
                    icon: Icons.today_rounded,
                    text:
                        'التطبيق يحدد لك ميعاد المراجعة القادم ويظهرها في مراجعة اليوم في وقتها فقط.',
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(height: isLargeScreen ? 14 : 12.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isLargeScreen ? 12 : 11.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            isLargeScreen ? 16 : 15.r,
                          ),
                        ),
                      ),
                      child: Text(
                        'فهمت',
                        style: AppTypography.button(
                          context,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isLargeScreen = _isLargeScreen(context);

    final double cardHorizontalPadding = isLargeScreen ? 16 : 13.w;
    final double cardVerticalPadding = isLargeScreen ? 13 : 11.h;
    final double cardRadius = isLargeScreen ? 22 : 20.r;

    final double iconBox = isLargeScreen ? 42 : 39.w;
    final double iconSize = isLargeScreen ? 22 : 21.sp;

    final double infoBox = isLargeScreen ? 30 : 28.w;
    final double infoIconSize = isLargeScreen ? 16 : 17.sp;
    final double switchScale = isLargeScreen ? 0.78 : 0.74;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: cardHorizontalPadding,
          vertical: cardVerticalPadding,
        ),
        decoration: BoxDecoration(
          color: enabled
              ? theme.colorScheme.primary
              : theme.colorScheme.secondary,
          borderRadius: BorderRadius.circular(cardRadius),
          border: Border.all(
            color: enabled
                ? Colors.white.withOpacity(0.10)
                : theme.colorScheme.outline.withOpacity(isDark ? 0.18 : 0.42),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.08 : 0.035),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: iconBox,
              height: iconBox,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: enabled
                    ? Colors.white.withOpacity(0.14)
                    : theme.colorScheme.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(isLargeScreen ? 14 : 14.r),
              ),
              child: Icon(
                Icons.psychology_alt_outlined,
                color: enabled ? Colors.white : theme.colorScheme.primary,
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
                      enabled
                          ? 'خطة حفظ الحديث مفعّلة'
                          : 'تفعيل خطة حفظ الحديث',
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      locale: const Locale('ar'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.cardTitle(
                        context,
                        fontWeight: FontWeight.w700,
                        color: enabled
                            ? Colors.white
                            : theme.colorScheme.surface,
                      ),
                    ),
                  ),
                  SizedBox(height: isLargeScreen ? 4 : 3.h),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      enabled
                          ? 'التدريب والتحليل والمراجعة ظاهرين الآن.'
                          : 'اختيارية؛ فعّلها لو حابب تتابع حفظ الأحاديث.',
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      locale: const Locale('ar'),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.cardSubtitle(
                        context,
                        fontWeight: FontWeight.w400,
                        color: enabled
                            ? Colors.white.withOpacity(0.78)
                            : theme.colorScheme.surface.withOpacity(0.62),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: isLargeScreen ? 10 : 8.w),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: enabled
                      ? Colors.white.withOpacity(0.12)
                      : theme.colorScheme.primary.withOpacity(0.08),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _showPlanInfo(context),
                    child: SizedBox(
                      width: infoBox,
                      height: infoBox,
                      child: Icon(
                        Icons.info_outline_rounded,
                        color: enabled
                            ? Colors.white
                            : theme.colorScheme.primary,
                        size: infoIconSize,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: isLargeScreen ? 4 : 4.h),
                Transform.scale(
                  scale: switchScale,
                  child: Switch(
                    value: enabled,
                    onChanged: isChanging
                        ? null
                        : (value) {
                            AppHaptics.tap(context);
                            onChanged(value);
                          },
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xff21C58E),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.black.withOpacity(0.55),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

class _InfoPoint extends StatelessWidget {
  const _InfoPoint({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  bool _isLargeScreen(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    return size.shortestSide >= 600 ||
        (size.width >= 700 && size.height >= 500);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isLargeScreen = _isLargeScreen(context);

    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: isLargeScreen ? 24 : 20.w,
          height: isLargeScreen ? 24 : 20.w,
          child: Icon(icon, color: color, size: isLargeScreen ? 18 : 16.sp),
        ),
        SizedBox(width: isLargeScreen ? 8 : 8.w),
        Expanded(
          child: Text(
            text,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            locale: const Locale('ar'),
            softWrap: true,
            style: AppTypography.cardSubtitle(
              context,
              color: theme.colorScheme.surface.withOpacity(0.74),
            ),
          ),
        ),
      ],
    );
  }
}
