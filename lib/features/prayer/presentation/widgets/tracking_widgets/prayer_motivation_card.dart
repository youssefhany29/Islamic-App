import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/shared/widgets/common_components/app_layout_constants.dart';

class PrayerMotivationCard extends StatelessWidget {
  const PrayerMotivationCard({
    super.key,
    this.large = false,
  });

  final bool large;

  static const String _lightAsset = 'assets/quraan/pray_light.png';
  static const String _darkAsset = 'assets/quraan/pray_night.png';

  static const List<_PrayerMotivationMessage> _messages = [
    _PrayerMotivationMessage(
      title: 'أقم الصلاة لذكري',
      subtitle: 'واجعل صلاتك نورًا ليومك وسكينة لقلبك.',
    ),
    _PrayerMotivationMessage(
      title: 'حافظ على موعدك مع الله',
      subtitle: 'كل صلاة تقرّب قلبك وتعيد ترتيب يومك.',
    ),
    _PrayerMotivationMessage(
      title: 'الصلاة راحة لا عبء',
      subtitle: 'قف بين يدي الله دقائق، وامضِ بقلب أخف.',
    ),
    _PrayerMotivationMessage(
      title: 'لا تؤخر نور يومك',
      subtitle: 'صلاتك في وقتها بداية هدوء وبركة.',
    ),
    _PrayerMotivationMessage(
      title: 'أقبل على صلاتك',
      subtitle: 'هي لحظة صدق تردّك إلى الطمأنينة.',
    ),
    _PrayerMotivationMessage(
      title: 'صلاتك أمان قلبك',
      subtitle: 'كل سجدة تزرع في يومك طمأنينة جديدة.',
    ),
    _PrayerMotivationMessage(
      title: 'ابدأ من الصلاة',
      subtitle: 'ومنها يأتي الهدوء والبركة وسعة الصدر.',
    ),
  ];

  _PrayerMotivationMessage _todayMessage() {
    final DateTime now = DateTime.now();
    final DateTime firstDay = DateTime(now.year);
    final int dayIndex = now.difference(firstDay).inDays;

    return _messages[dayIndex % _messages.length];
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final _PrayerMotivationMessage message = _todayMessage();

    final Color cardColor = isDark ? colors.secondary : Colors.white;
    final Color textColor = isDark ? Colors.white : colors.surface;
    final String asset = isDark ? _darkAsset : _lightAsset;

    final double cardHeight = large ? 96 : 72.h;
    final double cardRadius = large ? 24 : 20.r;
    final double quoteRight = large ? 22 : 15.w;
    final double quoteTop = large ? 20 : 13.h;
    final double textRight = large ? 78 : 48.w;
    final double textLeft = large ? 184 : 40.w;
    final double textTop = large ? 23 : 11.h;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: large ? double.infinity : AppLayoutConstants.mainCardWidth,
        height: cardHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(cardRadius),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(cardRadius),
              border: Border.all(
                color: textColor.withOpacity(isDark ? 0.08 : 0.055),
                width: large ? 0.8 : 0.8.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.16 : 0.045),
                  blurRadius: large ? 16 : 16.r,
                  offset: Offset(0, large ? 7 : 7.h),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: Image.asset(
                    asset,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.fill,
                    alignment: Alignment.centerRight,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) => DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [
                            colors.primary.withOpacity(isDark ? 0.09 : 0.035),
                            colors.primary.withOpacity(isDark ? 0.05 : 0.018),
                            colors.primary.withOpacity(isDark ? 0.12 : 0.055),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withOpacity(0.05)
                          : Colors.white.withOpacity(0.02),
                    ),
                  ),
                ),
                Positioned(
                  right: quoteRight,
                  top: quoteTop,
                  child: Icon(
                    Icons.format_quote_rounded,
                    color: colors.primary.withOpacity(isDark ? 0.72 : 0.82),
                    size: large ? 30 : 20.sp,
                  ),
                ),
                Positioned(
                  right: textRight,
                  left: textLeft,
                  top: textTop,
                  bottom: large ? 18 : 8.h,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        message.title,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body(context).copyWith(
                          color: textColor,
                          fontSize: large ? 20 : 12.sp,
                          fontWeight: FontWeight.w700,
                          height: 1.05,
                        ),
                      ),
                      SizedBox(height: large ? 8 : 4.h),
                      Text(
                        message.subtitle,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        maxLines: 2,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption(context).copyWith(
                          color: textColor.withOpacity(isDark ? 0.72 : 0.58),
                          fontSize: large ? 15 : 10.sp,
                          fontWeight: FontWeight.w600,
                          height: 1.22,
                        ),
                      ),
                    ],
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

class _PrayerMotivationMessage {
  const _PrayerMotivationMessage({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;
}
