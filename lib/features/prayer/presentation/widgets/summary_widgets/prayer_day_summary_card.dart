import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';
import 'package:islamic_app/shared/widgets/common_components/app_layout_constants.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';

class PrayerDaySummaryCard extends StatelessWidget {
  final List<Map<String, String>> prayerWeek;
  final bool usingCachedData;
  final String? cachedDate;
  final VoidCallback onRefresh;
  final bool large;

  const PrayerDaySummaryCard({
    super.key,
    required this.prayerWeek,
    required this.usingCachedData,
    required this.cachedDate,
    required this.onRefresh,
    this.large = false,
  });

  static const List<String> _arabicDays = [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  static const List<_PrayerInfo> _prayers = [
    _PrayerInfo(name: 'الفجر', key: 'fajr'),
    _PrayerInfo(name: 'الظهر', key: 'dhuhr'),
    _PrayerInfo(name: 'العصر', key: 'asr'),
    _PrayerInfo(name: 'المغرب', key: 'maghrib'),
    _PrayerInfo(name: 'العشاء', key: 'isha'),
  ];

  String _todayArabicName() {
    return _arabicDays[DateTime.now().weekday - 1];
  }

  String _todayKey() {
    final now = DateTime.now();
    return _dateKey(now);
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Map<String, String>? _getTodayRow() {
    final todayKey = _todayKey();

    for (final day in prayerWeek) {
      if (day['date'] == todayKey) {
        return day;
      }
    }

    final todayName = _todayArabicName();

    for (final day in prayerWeek) {
      if (day['day'] == todayName) {
        return day;
      }
    }

    return prayerWeek.isEmpty ? null : prayerWeek.first;
  }

  int _passedPrayersCount() {
    final todayRow = _getTodayRow();
    if (todayRow == null) return 0;

    final now = DateTime.now();
    int count = 0;

    for (final prayer in _prayers) {
      final prayerTime = _parsePrayerDateTime(
        day: todayRow,
        fallbackDayOffset: 0,
        timeText: todayRow[prayer.key],
      );

      if (prayerTime != null && now.isAfter(prayerTime)) {
        count++;
      }
    }

    return count;
  }

  _NextPrayerInfo? _getNextPrayerInfo() {
    if (prayerWeek.isEmpty) return null;

    final now = DateTime.now();

    for (int dayIndex = 0; dayIndex < prayerWeek.length; dayIndex++) {
      final day = prayerWeek[dayIndex];

      for (final prayer in _prayers) {
        final prayerDateTime = _parsePrayerDateTime(
          day: day,
          fallbackDayOffset: dayIndex,
          timeText: day[prayer.key],
        );

        if (prayerDateTime != null && prayerDateTime.isAfter(now)) {
          return _NextPrayerInfo(
            prayerName: prayer.name,
            prayerTimeText: day[prayer.key] ?? '--:--',
            prayerDateTime: prayerDateTime,
            dayName: day['day'] ?? _todayArabicName(),
            isToday: _dateKey(prayerDateTime) == _todayKey(),
          );
        }
      }
    }

    return null;
  }

  DateTime? _parsePrayerDateTime({
    required Map<String, String> day,
    required int fallbackDayOffset,
    required String? timeText,
  }) {
    if (timeText == null || !timeText.contains(':')) return null;

    final parts = timeText.split(':');

    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return null;

    final dateText = day['date'];
    final parsedDate = _parseDateKey(dateText);
    final fallbackDate = DateTime.now().add(Duration(days: fallbackDayOffset));
    final date = parsedDate ?? fallbackDate;

    return DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
  }

  DateTime? _parseDateKey(String? dateText) {
    if (dateText == null || !dateText.contains('-')) return null;

    final parts = dateText.split('-');

    if (parts.length != 3) return null;

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);

    if (year == null || month == null || day == null) return null;

    return DateTime(year, month, day);
  }

  String _remainingText(DateTime? nextPrayerTime) {
    if (nextPrayerTime == null) return 'غير متاح الآن';

    final difference = nextPrayerTime.difference(DateTime.now());

    if (difference.isNegative) return 'حان الوقت الآن';

    final hours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);

    if (hours <= 0) {
      return 'باقي $minutes دقيقة';
    }

    return 'باقي $hours س و $minutes د';
  }

  @override
  Widget build(BuildContext context) {
    final passedCount = _passedPrayersCount();
    final nextPrayer = _getNextPrayerInfo();

    final sourceText = usingCachedData
        ? cachedDate == null
            ? 'يتم عرض آخر مواقيت محفوظة'
            : 'آخر تحديث محفوظ: $cachedDate'
        : 'تم تحديث المواقيت حسب موقعك';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: large ? double.infinity : AppLayoutConstants.mainCardWidth,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: large ? 12 : 12.w,
            vertical: large ? 12 : 12.h,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(
              large ? 18 : AppLayoutConstants.mainCardRadius,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الصلاة القادمة',
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption(context).copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: large ? 2 : 2.h),
                        Text(
                          nextPrayer == null
                              ? 'حدّث المواقيت لمعرفة الصلاة القادمة'
                              : nextPrayer.isToday
                                  ? 'اليوم · ${_todayArabicName()}'
                                  : '${nextPrayer.dayName} · غدًا تقريبًا',
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption(context).copyWith(
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.62),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: large ? 34 : 34.w,
                    height: large ? 34 : 34.w,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minWidth: large ? 34 : 34.w,
                        minHeight: large ? 34 : 34.w,
                      ),
                      onPressed: () {
                        AppHaptics.tap(context);
                        onRefresh();
                      },
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: large ? 18 : 19.sp,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: large ? 10 : 12.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: large ? 12 : 12.w,
                  vertical: large ? 10 : 12.h,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xff171B26),
                  borderRadius: BorderRadius.circular(large ? 15 : 16.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.06),
                    width: large ? 0.7 : 0.7.w,
                  ),
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Container(
                      width: large ? 38 : 42.w,
                      height: large ? 38 : 42.w,
                      decoration: BoxDecoration(
                        color: const Color(0xff21C58E).withOpacity(0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mosque_rounded,
                        color: const Color(0xff21C58E),
                        size: large ? 20 : 22.sp,
                      ),
                    ),
                    SizedBox(width: large ? 10 : 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nextPrayer?.prayerName ?? 'غير متاحة',
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.display(context).copyWith(
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: large ? 3 : 3.h),
                          Text(
                            _remainingText(nextPrayer?.prayerDateTime),
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption(context).copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xff21C58E)),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: large ? 8 : 8.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'الوقت',
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: AppTextStyles.caption(context).copyWith(
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.55)),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          nextPrayer?.prayerTimeText ?? '--:--',
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: AppTextStyles.caption(context).copyWith(
                              fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: large ? 8 : 9.h),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: _MiniInfoPill(
                      large: large,
                      title: 'دخل وقتها',
                      value: '$passedCount / 5',
                      icon: Icons.done_all_rounded,
                    ),
                  ),
                  SizedBox(width: large ? 8 : 8.w),
                  Expanded(
                    child: _MiniInfoPill(
                      large: large,
                      title: 'اليوم',
                      value: _todayArabicName(),
                      icon: Icons.today_rounded,
                    ),
                  ),
                ],
              ),
              SizedBox(height: large ? 8 : 8.h),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Icon(
                    usingCachedData
                        ? Icons.info_outline_rounded
                        : Icons.location_on_rounded,
                    color: usingCachedData
                        ? Colors.amber
                        : const Color(0xff21C58E),
                    size: large ? 14 : 15.sp,
                  ),
                  SizedBox(width: large ? 6 : 6.w),
                  Expanded(
                    child: Text(
                      sourceText,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                          fontWeight: FontWeight.w500,
                          color: usingCachedData
                              ? Colors.amber
                              : Colors.white.withOpacity(0.62)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniInfoPill extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool large;

  const _MiniInfoPill({
    required this.large,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 8 : 9.w,
        vertical: large ? 6 : 7.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(large ? 11 : 12.r),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(
            icon,
            color: const Color(0xff21C58E),
            size: large ? 13 : 14.sp,
          ),
          SizedBox(width: large ? 5 : 5.w),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.58)),
            ),
          ),
          SizedBox(width: large ? 4 : 4.w),
          Text(
            value,
            textAlign: TextAlign.left,
            textDirection: TextDirection.rtl,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(context)
                .copyWith(fontWeight: FontWeight.w900, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _NextPrayerInfo {
  final String prayerName;
  final String prayerTimeText;
  final DateTime prayerDateTime;
  final String dayName;
  final bool isToday;

  const _NextPrayerInfo({
    required this.prayerName,
    required this.prayerTimeText,
    required this.prayerDateTime,
    required this.dayName,
    required this.isToday,
  });
}

class _PrayerInfo {
  final String name;
  final String key;

  const _PrayerInfo({
    required this.name,
    required this.key,
  });
}
