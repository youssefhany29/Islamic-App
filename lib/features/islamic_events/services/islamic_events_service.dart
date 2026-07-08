import 'package:flutter/material.dart';
import 'package:hijri_calendar/hijri_calendar.dart';

import '../models/islamic_event_model.dart';
import 'islamic_calendar_api_service.dart';

class IslamicEventsResult {
  final List<IslamicEventModel> events;
  final bool isFromApi;
  final String? message;

  const IslamicEventsResult({
    required this.events,
    required this.isFromApi,
    this.message,
  });
}

class IslamicEventsService {
  final IslamicCalendarApiService _apiService = IslamicCalendarApiService();

  Future<IslamicEventsResult> getUpcomingEventsSmart() async {
    try {
      final events = await _getUpcomingEventsFromApi();

      return IslamicEventsResult(
        events: events,
        isFromApi: true,
        message: null,
      );
    } catch (_) {
      final events = _getUpcomingEventsOffline();

      return IslamicEventsResult(
        events: events,
        isFromApi: false,
        message:
        'يتم عرض المناسبات بالحسابات التقريبية بدون إنترنت. للدقة قم بتفعيل الإنترنت واضغط تحديث.',
      );
    }
  }

  Future<List<IslamicEventModel>> _getUpcomingEventsFromApi() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final currentMonthDays = await _apiService.getGregorianMonthCalendar(
      month: now.month,
      year: now.year,
    );

    final nextMonthDate = DateTime(now.year, now.month + 1, 1);

    final nextMonthDays = await _apiService.getGregorianMonthCalendar(
      month: nextMonthDate.month,
      year: nextMonthDate.year,
    );

    final allDays = [
      ...currentMonthDays,
      ...nextMonthDays,
    ];

    final List<IslamicEventModel> events = [];

    for (final day in allDays) {
      final normalizedDate = DateTime(
        day.gregorianDate.year,
        day.gregorianDate.month,
        day.gregorianDate.day,
      );

      if (normalizedDate.isBefore(today)) continue;

      events.addAll(
        _eventsForDate(
          date: normalizedDate,
          hijriDay: day.hijriDay,
          hijriMonth: day.hijriMonth,
          hijriDateText: day.hijriDateText,
          isToday: normalizedDate == today,
        ),
      );
    }

    events.sort((a, b) => a.gregorianDate.compareTo(b.gregorianDate));
    return events;
  }

  List<IslamicEventModel> _getUpcomingEventsOffline({
    int daysCount = 60,
  }) {
    HijriCalendarConfig.language = 'ar';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final List<IslamicEventModel> events = [];

    for (int i = 0; i < daysCount; i++) {
      final date = today.add(Duration(days: i));
      final hijri = HijriCalendarConfig.fromGregorian(date);

      events.addAll(
        _eventsForDate(
          date: date,
          hijriDay: hijri.hDay,
          hijriMonth: hijri.hMonth,
          hijriDateText: hijri.toFormat('dd MMMM yyyy'),
          isToday: i == 0,
        ),
      );
    }

    events.sort((a, b) => a.gregorianDate.compareTo(b.gregorianDate));
    return events;
  }

  List<IslamicEventModel> _eventsForDate({
    required DateTime date,
    required int hijriDay,
    required int hijriMonth,
    required String hijriDateText,
    required bool isToday,
  }) {
    final List<IslamicEventModel> events = [];

    if (date.weekday == DateTime.monday ||
        date.weekday == DateTime.thursday) {
      events.add(
        IslamicEventModel(
          title: date.weekday == DateTime.monday
              ? 'صيام الاثنين'
              : 'صيام الخميس',
          subtitle: 'يوم مستحب للصيام، لا تنس نية الصيام والعمل الصالح.',
          hijriDateText: hijriDateText,
          gregorianDate: date,
          icon: Icons.calendar_today_rounded,
          type: IslamicEventType.fasting,
          isToday: isToday,
        ),
      );
    }

    if (hijriDay == 13 || hijriDay == 14 || hijriDay == 15) {
      events.add(
        IslamicEventModel(
          title: 'الأيام البيض',
          subtitle: 'اليوم $hijriDay من الشهر الهجري، من الأيام المستحب صيامها.',
          hijriDateText: hijriDateText,
          gregorianDate: date,
          icon: Icons.brightness_2_rounded,
          type: IslamicEventType.fasting,
          isToday: isToday,
        ),
      );
    }

    if (hijriMonth == 8 && hijriDay == 15) {
      events.add(
        IslamicEventModel(
          title: 'اقترب رمضان',
          subtitle: 'استعد لرمضان بالنية، القرآن، الدعاء وتنظيم وقتك.',
          hijriDateText: hijriDateText,
          gregorianDate: date,
          icon: Icons.nightlight_round,
          type: IslamicEventType.reminder,
          isToday: isToday,
        ),
      );
    }

    if (hijriMonth == 8 && hijriDay == 25) {
      events.add(
        IslamicEventModel(
          title: 'أيام قليلة على رمضان',
          subtitle: 'اللهم بلغنا رمضان وبارك لنا فيه.',
          hijriDateText: hijriDateText,
          gregorianDate: date,
          icon: Icons.auto_awesome_rounded,
          type: IslamicEventType.greeting,
          isToday: isToday,
        ),
      );
    }

    if (hijriMonth == 9 && hijriDay == 1) {
      events.add(
        IslamicEventModel(
          title: 'رمضان مبارك',
          subtitle: 'هلّ شهر رمضان، كل عام وأنتم بخير.',
          hijriDateText: hijriDateText,
          gregorianDate: date,
          icon: Icons.mosque_rounded,
          type: IslamicEventType.greeting,
          isToday: isToday,
        ),
      );
    }

    if (hijriMonth == 9 && hijriDay >= 21 && hijriDay <= 29) {
      events.add(
        IslamicEventModel(
          title: 'العشر الأواخر من رمضان',
          subtitle: 'أكثر من الدعاء والقيام وقراءة القرآن في هذه الليالي المباركة.',
          hijriDateText: hijriDateText,
          gregorianDate: date,
          icon: Icons.star_rounded,
          type: IslamicEventType.specialDay,
          isToday: isToday,
        ),
      );
    }

    if (hijriMonth == 9 && hijriDay == 29) {
      events.add(
        IslamicEventModel(
          title: 'اقترب عيد الفطر',
          subtitle: 'تقبل الله منا ومنكم صالح الأعمال.',
          hijriDateText: hijriDateText,
          gregorianDate: date,
          icon: Icons.celebration_rounded,
          type: IslamicEventType.greeting,
          isToday: isToday,
        ),
      );
    }

    if (hijriMonth == 10 && hijriDay == 1) {
      events.add(
        IslamicEventModel(
          title: 'عيد فطر مبارك',
          subtitle: 'كل عام وأنتم بخير، تقبل الله طاعتكم.',
          hijriDateText: hijriDateText,
          gregorianDate: date,
          icon: Icons.celebration_rounded,
          type: IslamicEventType.greeting,
          isToday: isToday,
        ),
      );
    }

    if (hijriMonth == 12 && hijriDay >= 1 && hijriDay <= 8) {
      events.add(
        IslamicEventModel(
          title: 'العشر الأوائل من ذي الحجة',
          subtitle: 'أيام عظيمة، أكثر فيها من الذكر والصيام والعمل الصالح.',
          hijriDateText: hijriDateText,
          gregorianDate: date,
          icon: Icons.volunteer_activism_rounded,
          type: IslamicEventType.fasting,
          isToday: isToday,
        ),
      );
    }

    if (hijriMonth == 12 && hijriDay == 8) {
      events.add(
        IslamicEventModel(
          title: 'غدًا يوم عرفة',
          subtitle: 'لا تنس نية الصيام والاستعداد للدعاء والذكر.',
          hijriDateText: hijriDateText,
          gregorianDate: date,
          icon: Icons.notifications_active_rounded,
          type: IslamicEventType.reminder,
          isToday: isToday,
        ),
      );
    }

    if (hijriMonth == 12 && hijriDay == 9) {
      events.add(
        IslamicEventModel(
          title: 'يوم عرفة',
          subtitle: 'يوم عظيم، أكثر فيه من الدعاء والذكر والصيام لغير الحاج.',
          hijriDateText: hijriDateText,
          gregorianDate: date,
          icon: Icons.wb_sunny_rounded,
          type: IslamicEventType.specialDay,
          isToday: isToday,
        ),
      );
    }

    if (hijriMonth == 12 && hijriDay == 10) {
      events.add(
        IslamicEventModel(
          title: 'عيد أضحى مبارك',
          subtitle: 'كل عام وأنتم بخير، تقبل الله منا ومنكم.',
          hijriDateText: hijriDateText,
          gregorianDate: date,
          icon: Icons.celebration_rounded,
          type: IslamicEventType.greeting,
          isToday: isToday,
        ),
      );
    }

    if (hijriMonth == 1 && hijriDay == 9) {
      events.add(
        IslamicEventModel(
          title: 'تاسوعاء',
          subtitle: 'غدًا عاشوراء، من الأيام المستحب صيامها.',
          hijriDateText: hijriDateText,
          gregorianDate: date,
          icon: Icons.notifications_active_rounded,
          type: IslamicEventType.reminder,
          isToday: isToday,
        ),
      );
    }

    if (hijriMonth == 1 && hijriDay == 10) {
      events.add(
        IslamicEventModel(
          title: 'عاشوراء',
          subtitle: 'يوم مستحب صيامه، أكثر فيه من العمل الصالح.',
          hijriDateText: hijriDateText,
          gregorianDate: date,
          icon: Icons.favorite_rounded,
          type: IslamicEventType.fasting,
          isToday: isToday,
        ),
      );
    }

    return events;
  }
}