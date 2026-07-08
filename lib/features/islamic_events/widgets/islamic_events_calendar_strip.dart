import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import '../models/islamic_event_model.dart';
import 'islamic_events_section_title.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
bool _eventsCalendarLargeScreen(BuildContext context) {
  final Size size = MediaQuery.sizeOf(context);
  return size.shortestSide >= 600 || (size.width >= 700 && size.height >= 500);
}

class IslamicEventsCalendarStrip extends StatelessWidget {
  const IslamicEventsCalendarStrip({
    super.key,
    required this.events,
    required this.selectedDate,
    required this.onDateSelected,
  });

  final List<IslamicEventModel> events;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  int _eventsCount(DateTime date) {
    final normalizedDate = _normalizeDate(date);

    return events
        .where((event) => _normalizeDate(event.gregorianDate) == normalizedDate)
        .length;
  }

  bool _hasTodayEvent(DateTime date) {
    return events.any(
          (event) =>
      _normalizeDate(event.gregorianDate) == _normalizeDate(date) &&
          event.isToday,
    );
  }

  String _weekdayName(int weekday) {
    switch (weekday) {
      case DateTime.saturday:
        return 'سبت';
      case DateTime.sunday:
        return 'أحد';
      case DateTime.monday:
        return 'اثنين';
      case DateTime.tuesday:
        return 'ثلاثاء';
      case DateTime.wednesday:
        return 'أربعاء';
      case DateTime.thursday:
        return 'خميس';
      case DateTime.friday:
        return 'جمعة';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = _normalizeDate(DateTime.now());
    final dates = List.generate(
      14,
          (index) => today.add(Duration(days: index)),
    );
    final bool large = _eventsCalendarLargeScreen(context);
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final double padding = large ? 14 : 14.w;
    final double radius = large ? 22 : 20.r;
    final double gap = large ? 8 : 8.w;
    final double stripHeight = large ? 80 : 84.h;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(isDark ? 0.18 : 0.34),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const IslamicEventsSectionTitle(
              title: 'تقويم المناسبات',
              icon: Icons.calendar_view_week_rounded,
            ),
            SizedBox(height: large ? 10 : 9.h),
            SizedBox(
              height: stripHeight,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: dates.length,
                  separatorBuilder: (_, __) => SizedBox(width: gap),
                  itemBuilder: (context, index) {
                    final date = dates[index];
                    final normalized = _normalizeDate(date);
                    final bool isSelected = selectedDate == normalized;
                    final bool isToday = index == 0;
                    final int count = _eventsCount(date);
                    final bool hasTodayEvent = _hasTodayEvent(date);

                    return _CalendarDayPill(
                      date: date,
                      weekdayText: isToday ? 'اليوم' : _weekdayName(date.weekday),
                      eventsCount: count,
                      isSelected: isSelected,
                      isToday: isToday,
                      hasTodayEvent: hasTodayEvent,
                      onTap: () {
                        AppHaptics.tap(context);
                        onDateSelected(date);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarDayPill extends StatelessWidget {
  const _CalendarDayPill({
    required this.date,
    required this.weekdayText,
    required this.eventsCount,
    required this.isSelected,
    required this.isToday,
    required this.hasTodayEvent,
    required this.onTap,
  });

  final DateTime date;
  final String weekdayText;
  final int eventsCount;
  final bool isSelected;
  final bool isToday;
  final bool hasTodayEvent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool large = _eventsCalendarLargeScreen(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final double width = large ? 64 : 62.w;
    final double radius = large ? 18 : 18.r;
    final double weekdaySize = large ? 9 : 8.sp;
    final double daySize = large ? 22 : 23.sp;

    final Color backgroundColor =
    isSelected ? theme.colorScheme.primary : theme.colorScheme.secondary;
    final Color mainTextColor =
    isSelected ? Colors.white : theme.colorScheme.surface;
    final Color mutedTextColor = isSelected
        ? Colors.white.withOpacity(0.75)
        : theme.colorScheme.surface.withOpacity(0.58);

    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(
              horizontal: large ? 6 : 6.w,
              vertical: large ? 6 : 6.h,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : eventsCount > 0
                    ? theme.colorScheme.primary.withOpacity(isDark ? 0.55 : 0.38)
                    : theme.colorScheme.outline.withOpacity(isDark ? 0.18 : 0.35),
              ),
              boxShadow: [
                if (isSelected || hasTodayEvent)
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
              ],
            ),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Text(
                    weekdayText,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: weekdaySize,
                      fontFamily: 'cairo',
                      fontWeight: FontWeight.w800,
                      color: mutedTextColor,
                      height: 1.15,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    '${date.day}',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: daySize,
                      fontFamily: 'cairo',
                      fontWeight: FontWeight.w900,
                      color: mainTextColor,
                      height: 1.0,
                    ),
                  ),
                ),
                if (eventsCount > 0)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: large ? 5 : 5.w,
                        vertical: large ? 1 : 1.h,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.16)
                            : theme.colorScheme.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$eventsCount',
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.white : theme.colorScheme.primary,
                          height: 1.1
),
                      ),
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
