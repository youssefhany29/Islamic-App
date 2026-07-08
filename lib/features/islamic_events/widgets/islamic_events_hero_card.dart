import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import '../models/islamic_event_model.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';

bool _eventsHeroLargeScreen(BuildContext context) {
  final Size size = MediaQuery.sizeOf(context);
  return size.shortestSide >= 600 || (size.width >= 700 && size.height >= 500);
}

class IslamicEventsHeroCard extends StatelessWidget {
  const IslamicEventsHeroCard({
    super.key,
    required this.event,
    required this.onRefresh,
    this.onTap,
  });

  final IslamicEventModel? event;
  final Future<void> Function() onRefresh;
  final VoidCallback? onTap;

  int _daysUntil(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.difference(today).inDays;
  }

  String _daysText(int days) {
    if (days == 0) return 'اليوم';
    if (days == 1) return 'غدًا';
    if (days == 2) return 'بعد يومين';
    return 'بعد $days أيام';
  }

  String _actionText(int days) {
    if (days == 0) return 'مناسبة اليوم';
    if (days == 1) return 'استعد لها من الآن';
    return 'اضغط لمعرفة التفاصيل';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool large = _eventsHeroLargeScreen(context);
    final nextEvent = event;
    final days = nextEvent == null ? 0 : _daysUntil(nextEvent.gregorianDate);

    final double radius = large ? 24 : 24.r;
    final double padding = large ? 18 : 18.w;
    final double iconBox = large ? 46 : 46.w;
    final double iconSize = large ? 23 : 24.sp;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        splashColor: Colors.white.withOpacity(0.08),
        highlightColor: Colors.white.withOpacity(0.05),
        child: Ink(
          width: double.infinity,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: iconBox,
                      height: iconBox,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(large ? 16 : 16.r),
                      ),
                      child: Icon(
                        nextEvent?.icon ?? Icons.event_rounded,
                        color: Colors.white,
                        size: iconSize,
                      ),
                    ),
                    SizedBox(width: large ? 10 : 10.w),
                    Expanded(
                      child: Text(
                        nextEvent?.title ?? 'لا توجد مناسبات قريبة',
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        locale: const Locale('ar'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.headline(context).copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.35,
                        ),
                      ),
                    ),
                    if (nextEvent != null) ...[
                      SizedBox(width: large ? 8 : 8.w),
                      _CountdownBadge(text: _daysText(days), large: large),
                    ],
                  ],
                ),
                SizedBox(height: large ? 12 : 12.h),
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    nextEvent?.subtitle ??
                        'اسحب الصفحة للأسفل أو اضغط تحديث لجلب المناسبات.',
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    locale: const Locale('ar'),
                    maxLines: large ? 3 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(context).copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.86),
                      height: 1.5,
                    ),
                  ),
                ),
                SizedBox(height: large ? 14 : 14.h),
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Expanded(
                      child: _HeroSmallInfo(
                        icon: Icons.access_time_rounded,
                        title: 'الموعد',
                        text: nextEvent == null ? 'غير متاح' : _daysText(days),
                        large: large,
                      ),
                    ),
                    SizedBox(width: large ? 8 : 8.w),
                    Expanded(
                      child: _HeroSmallInfo(
                        icon: Icons.calendar_month_rounded,
                        title: 'هجري',
                        text: nextEvent?.hijriDateText ?? 'غير متاح',
                        large: large,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: large ? 14 : 14.h),
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Expanded(
                      child: Text(
                        nextEvent == null ? 'اضغط تحديث' : _actionText(days),
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        locale: const Locale('ar'),
                        style: AppTextStyles.caption(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withOpacity(0.82),
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.white.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(large ? 14 : 14.r),
                      child: InkWell(
                        onTap: () {
                          AppHaptics.tap(context);
                          onRefresh();
                        },
                        borderRadius: BorderRadius.circular(large ? 14 : 14.r),
                        child: SizedBox(
                          width: large ? 36 : 34.w,
                          height: large ? 36 : 34.w,
                          child: Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                            size: large ? 19 : 18.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountdownBadge extends StatelessWidget {
  const _CountdownBadge({required this.text, required this.large});

  final String text;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 10 : 9.w,
        vertical: large ? 6 : 5.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(large ? 100 : 100.r),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption(
          context,
        ).copyWith(fontWeight: FontWeight.w900, color: Colors.white),
      ),
    );
  }
}

class _HeroSmallInfo extends StatelessWidget {
  const _HeroSmallInfo({
    required this.icon,
    required this.title,
    required this.text,
    required this.large,
  });

  final IconData icon;
  final String title;
  final String text;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 10 : 9.w,
        vertical: large ? 9 : 8.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(large ? 15 : 15.r),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, color: Colors.white, size: large ? 15 : 15.sp),
          SizedBox(width: large ? 5 : 5.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    title,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(context).copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.70),
                    ),
                  ),
                ),
                SizedBox(height: large ? 2 : 2.h),
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    text,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(context).copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
