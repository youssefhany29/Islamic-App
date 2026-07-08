import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/islamic_event_model.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
bool _eventCardLargeScreen(BuildContext context) {
  final Size size = MediaQuery.sizeOf(context);
  return size.shortestSide >= 600 || (size.width >= 700 && size.height >= 500);
}

class IslamicEventCard extends StatelessWidget {
  const IslamicEventCard({
    super.key,
    required this.event,
    this.onTap,
  });

  final IslamicEventModel event;
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

  String _typeText(IslamicEventType type) {
    switch (type) {
      case IslamicEventType.fasting:
        return 'صيام';
      case IslamicEventType.greeting:
        return 'تهنئة';
      case IslamicEventType.specialDay:
        return 'مناسبة';
      case IslamicEventType.reminder:
        return 'تذكير';
    }
  }

  IconData _typeIcon(IslamicEventType type) {
    switch (type) {
      case IslamicEventType.fasting:
        return Icons.nightlight_round;
      case IslamicEventType.greeting:
        return Icons.celebration_rounded;
      case IslamicEventType.specialDay:
        return Icons.star_rounded;
      case IslamicEventType.reminder:
        return Icons.notifications_active_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool large = _eventCardLargeScreen(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final int days = _daysUntil(event.gregorianDate);

    final Color cardColor =
    event.isToday ? theme.colorScheme.primary : theme.colorScheme.secondary;

    final Color mainTextColor =
    event.isToday ? Colors.white : theme.colorScheme.surface;

    final Color mutedTextColor = event.isToday
        ? Colors.white.withOpacity(0.78)
        : theme.colorScheme.surface.withOpacity(0.65);

    final Color iconBackgroundColor = event.isToday
        ? Colors.white.withOpacity(0.15)
        : theme.colorScheme.primary.withOpacity(isDark ? 0.24 : 0.10);

    final Color iconColor =
    event.isToday ? Colors.white : theme.colorScheme.primary;

    final double radius = large ? 22 : 20.r;
    final double padding = large ? 14 : 14.w;
    final double iconBox = large ? 42 : 45.w;
    final double iconSize = large ? 21 : 22.sp;

    return Padding(
      padding: EdgeInsets.only(bottom: large ? 0 : 10.h),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          splashColor: theme.colorScheme.primary.withOpacity(0.10),
          highlightColor: theme.colorScheme.primary.withOpacity(0.06),
          child: Ink(
            width: double.infinity,
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: event.isToday
                    ? Colors.transparent
                    : theme.colorScheme.outline.withOpacity(
                  isDark ? 0.18 : 0.42,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.10 : 0.035),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                textDirection: TextDirection.rtl,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: iconBox,
                    height: iconBox,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: iconBackgroundColor,
                      borderRadius: BorderRadius.circular(large ? 14 : 15.r),
                    ),
                    child: Icon(
                      event.icon,
                      color: iconColor,
                      size: iconSize,
                    ),
                  ),
                  SizedBox(width: large ? 10 : 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          textDirection: TextDirection.rtl,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: SizedBox(
                                width: double.infinity,
                                child: Text(
                                  event.title,
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.rtl,
                                  locale: const Locale('ar'),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
                                    color: mainTextColor,
                                    height: 1.35
),
                                ),
                              ),
                            ),
                            SizedBox(width: large ? 8 : 8.w),
                            _Badge(
                              text: event.isToday ? 'اليوم' : _daysText(days),
                              color: event.isToday
                                  ? Colors.white.withOpacity(0.15)
                                  : theme.colorScheme.primary.withOpacity(
                                isDark ? 0.26 : 0.10,
                              ),
                              textColor: event.isToday
                                  ? Colors.white
                                  : theme.colorScheme.primary,
                              large: large,
                            ),
                          ],
                        ),
                        SizedBox(height: large ? 6 : 6.h),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            event.subtitle,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            locale: const Locale('ar'),
                            maxLines: large ? 3 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w500,
                              color: mutedTextColor,
                              height: 1.5
),
                          ),
                        ),
                        SizedBox(height: large ? 10 : 10.h),
                        Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _MiniInfo(
                                icon: Icons.calendar_month_rounded,
                                text: event.hijriDateText,
                                textColor: mutedTextColor,
                                iconColor: iconColor,
                                fontSize: large ? 9.2 : 8.2.sp,
                                fontWeight: FontWeight.w500,
                                large: large,
                              ),
                            ),
                            SizedBox(width: large ? 8 : 8.w),
                            Expanded(
                              flex: 2,
                              child: _MiniInfo(
                                icon: _typeIcon(event.type),
                                text: _typeText(event.type),
                                textColor: mutedTextColor,
                                iconColor: iconColor,
                                fontSize: large ? 9.6 : 8.8.sp,
                                fontWeight: FontWeight.w700,
                                large: large,
                              ),
                            ),
                            SizedBox(width: large ? 6 : 6.w),
                            _DetailsArrow(
                              color: iconColor,
                              isToday: event.isToday,
                              large: large,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.text,
    required this.color,
    required this.textColor,
    required this.large,
  });

  final String text;
  final Color color;
  final Color textColor;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 9 : 8.w,
        vertical: large ? 4 : 4.h,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        locale: const Locale('ar'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
          color: textColor,
          height: 1.2
),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({
    required this.icon,
    required this.text,
    required this.textColor,
    required this.iconColor,
    required this.fontSize,
    required this.fontWeight,
    required this.large,
  });

  final IconData icon;
  final String text;
  final Color textColor;
  final Color iconColor;
  final double fontSize;
  final FontWeight fontWeight;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(
          icon,
          color: iconColor,
          size: large ? 13 : 13.sp,
        ),
        SizedBox(width: large ? 4 : 4.w),
        Flexible(
          child: SizedBox(
            width: double.infinity,
            child: Text(
              text,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              locale: const Locale('ar'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize,
                fontFamily: 'cairo',
                fontWeight: fontWeight,
                color: textColor,
                height: 1.25,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailsArrow extends StatelessWidget {
  const _DetailsArrow({
    required this.color,
    required this.isToday,
    required this.large,
  });

  final Color color;
  final bool isToday;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: large ? 25 : 25.w,
      height: large ? 25 : 25.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isToday
            ? Colors.white.withOpacity(0.13)
            : color.withOpacity(
          Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.08,
        ),
        borderRadius: BorderRadius.circular(large ? 9 : 9.r),
      ),
      child: Icon(
        Icons.arrow_forward_ios_rounded,
        color: color,
        size: large ? 12 : 12.sp,
      ),
    );
  }
}