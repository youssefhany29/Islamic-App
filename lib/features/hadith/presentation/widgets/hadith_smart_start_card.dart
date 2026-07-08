import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import 'package:islamic_app/features/hadith/data/datasources/hadith_local_data.dart';
import 'package:islamic_app/features/hadith/data/models/hadith_category_model.dart';
import 'package:islamic_app/features/hadith/presentation/pages/hadith_reading_page.dart';

class HadithSmartStartCard extends StatelessWidget {
  const HadithSmartStartCard({super.key});

  bool _isLargeScreen(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    return size.shortestSide >= 600 ||
        (size.width >= 700 && size.height >= 500);
  }

  bool _isMorningTime() {
    final DateTime now = DateTime.now();
    return now.hour >= 5 && now.hour < 15;
  }

  HadithCategoryModel _categoryById(String id) {
    return HadithLocalData.categories.firstWhere(
      (category) => category.id == id,
      orElse: () => HadithLocalData.categories.first,
    );
  }

  HadithCategoryModel _currentCategory() {
    // الأحاديث لا تحتوي على morning/evening IDs مثل الأذكار.
    // لذلك نستخدم أقسام موجودة فعلًا داخل HadithLocalData:
    // الصباح: حياة المسلم اليومية
    // المساء: الرحمة والتيسير
    return _isMorningTime()
        ? _categoryById(HadithLocalData.dailyLifeId)
        : _categoryById(HadithLocalData.mercyId);
  }

  void _openCurrentHadith(BuildContext context) {
    AppHaptics.tap(context);

    final HadithCategoryModel category = _currentCategory();

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return HadithReadingPage(category: category);
        },
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final bool isLargeScreen = _isLargeScreen(context);
    final bool isMorning = _isMorningTime();

    final String title = isMorning
        ? 'حديث يناسب بداية اليوم'
        : 'حديث يناسب ختام اليوم';

    final String subtitle = isMorning
        ? 'ابدأ يومك بحديث عملي يذكّرك بالنية والعمل.'
        : 'اختم يومك بحديث يفتح باب الرحمة والطمأنينة.';

    final double radius = isLargeScreen ? 22 : 18.r;
    final double padding = isLargeScreen ? 15 : 14.w;
    final double iconBox = isLargeScreen ? 44 : 42.w;
    final double iconSize = isLargeScreen ? 23 : 23.sp;
    final double arrowBox = isLargeScreen ? 30 : 28.w;
    final double arrowSize = isLargeScreen ? 15 : 15.sp;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: () => _openCurrentHadith(context),
          borderRadius: BorderRadius.circular(radius),
          splashColor: theme.colorScheme.primary.withOpacity(0.10),
          highlightColor: theme.colorScheme.primary.withOpacity(0.06),
          child: Ink(
            width: double.infinity,
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(
                  isDark ? 0.18 : 0.34,
                ),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.10 : 0.025),
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
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(
                      isLargeScreen ? 15 : 14.r,
                    ),
                  ),
                  child: Icon(
                    isMorning
                        ? Icons.wb_sunny_outlined
                        : Icons.nightlight_round,
                    color: theme.colorScheme.primary,
                    size: iconSize,
                  ),
                ),
                SizedBox(width: isLargeScreen ? 11 : 10.w),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          title,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          locale: const Locale('ar'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            height: 1.35,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      SizedBox(height: isLargeScreen ? 4 : 3.h),
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          subtitle,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          locale: const Locale('ar'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.surface.withOpacity(0.68),
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: isLargeScreen ? 9 : 8.w),
                Container(
                  width: arrowBox,
                  height: arrowBox,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(
                      isLargeScreen ? 10 : 9.r,
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: theme.colorScheme.primary,
                    size: arrowSize,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
