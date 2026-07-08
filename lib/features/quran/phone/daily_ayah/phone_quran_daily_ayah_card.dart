import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/quran/phone/daily_ayah/quran_daily_ayah_data.dart';
import 'package:islamic_app/shared/widgets/common_components/app_layout_constants.dart';

class PhoneQuranDailyAyahCard extends StatefulWidget {
  const PhoneQuranDailyAyahCard({super.key});

  @override
  State<PhoneQuranDailyAyahCard> createState() =>
      _PhoneQuranDailyAyahCardState();
}

class _PhoneQuranDailyAyahCardState extends State<PhoneQuranDailyAyahCard> {
  static const String _lightBackgroundAsset = 'assets/quraan/quran_ayah.png';
  static const String _darkBackgroundAsset =
      'assets/quraan/ayah_night_mood.png';

  late final Future<QuranDailyAyahInfo> _ayahFuture =
  QuranDailyAyahData.today();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String backgroundAsset =
    isDark ? _darkBackgroundAsset : _lightBackgroundAsset;

    final Color ayahTextColor = isDark ? Colors.white : colors.primary;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: AppLayoutConstants.mainCardWidth,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18.r),
          child: Container(
            constraints: BoxConstraints(minHeight: 62.h),
            decoration: BoxDecoration(
              color: isDark ? colors.secondary : Colors.white,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: colors.surface.withOpacity(isDark ? 0.08 : 0.055),
                width: 0.8.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.16 : 0.045),
                  blurRadius: 15.r,
                  offset: Offset(0, 7.h),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: ClipRect(
                    child: Transform.scale(
                      scaleX: 1.9,
                      scaleY: 1.35,
                      alignment: Alignment.center,
                      child: Image.asset(
                        backgroundAsset,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (_, __, ___) => DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerRight,
                              end: Alignment.centerLeft,
                              colors: [
                                colors.primary.withOpacity(
                                  isDark ? 0.20 : 0.10,
                                ),
                                colors.primary.withOpacity(
                                  isDark ? 0.07 : 0.035,
                                ),
                                colors.primary.withOpacity(
                                  isDark ? 0.20 : 0.10,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withOpacity(0.12)
                          : Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),
                FutureBuilder<QuranDailyAyahInfo>(
                  future: _ayahFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _DailyAyahContent(
                        ayahText: 'جاري تجهيز آية اليوم...',
                        reference: '',
                        textColor: ayahTextColor,
                        isLoading: true,
                      );
                    }

                    if (snapshot.hasError || snapshot.data == null) {
                      return _DailyAyahContent(
                        ayahText: 'تعذّر تحميل آية اليوم من ملف المصحف',
                        reference: '',
                        textColor: ayahTextColor,
                        isLoading: false,
                      );
                    }

                    final QuranDailyAyahInfo ayah = snapshot.data!;

                    return _DailyAyahContent(
                      ayahText: '﴿ ${ayah.text} ﴾',
                      reference: ayah.reference,
                      textColor: ayahTextColor,
                      isLoading: false,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyAyahContent extends StatelessWidget {
  const _DailyAyahContent({
    required this.ayahText,
    required this.reference,
    required this.textColor,
    required this.isLoading,
  });

  final String ayahText;
  final String reference;
  final Color textColor;
  final bool isLoading;

  bool get _isLongAyah {
    if (isLoading) return false;

    final String cleanText = ayahText
        .replaceAll(RegExp(r'[﴿﴾]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final int wordsCount = cleanText
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .length;

    return cleanText.length > 78 || wordsCount > 13;
  }

  @override
  Widget build(BuildContext context) {
    final bool isLongAyah = _isLongAyah;

    return Transform.translate(
      offset: Offset(0, isLongAyah ? -3.h : 0),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: isLongAyah ? 6.h : 8.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: double.infinity,
              child: Text(
                ayahText,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                maxLines: 2,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  color: textColor,
                  fontFamily: isLoading ? null : 'quran',
                  fontSize: isLoading ? 9.sp : (isLongAyah ? 9.2.sp : 10.2.sp),
                  fontWeight: FontWeight.w800,
                  height: isLongAyah ? 1.28 : 1.35,
                ),
              ),
            ),
            if (reference.trim().isNotEmpty) ...[
              SizedBox(height: isLongAyah ? 2.h : 3.h),
              Text(
                reference,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  color: textColor.withOpacity(0.72),
                  fontSize: 6.8.sp,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}