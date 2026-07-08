import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'hijrii_date.dart';
import 'api_cal.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';

class HijriCalendarBottomSheet extends StatefulWidget {
  const HijriCalendarBottomSheet({
    super.key,
  });

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return const HijriCalendarBottomSheet();
      },
    );
  }

  @override
  State<HijriCalendarBottomSheet> createState() =>
      _HijriCalendarBottomSheetState();
}

class _HijriCalendarBottomSheetState extends State<HijriCalendarBottomSheet> {
  final IslamicCalendarApiService _apiService = IslamicCalendarApiService();

  late int _displayedYear;
  late int _displayedMonth;

  late int _selectedYear;
  late int _selectedMonth;
  late int _selectedDay;

  bool _isLoadingEvents = false;
  bool _apiFailed = false;

  final Map<String, String> _apiEventsByHijriDate = {};

  @override
  void initState() {
    super.initState();

    final todayHijri = HijriiDate.now();

    _displayedYear = todayHijri.hYear;
    _displayedMonth = todayHijri.hMonth;

    _selectedYear = todayHijri.hYear;
    _selectedMonth = todayHijri.hMonth;
    _selectedDay = todayHijri.hDay;

    _loadEventsForDisplayedMonth();
  }

  String _eventKey({
    required int year,
    required int month,
    required int day,
  }) {
    return '$year-$month-$day';
  }

  String? get _selectedEventName {
    return _eventNameForDay(_selectedDay);
  }

  Future<void> _loadEventsForDisplayedMonth() async {
    if (!mounted) return;

    setState(() {
      _isLoadingEvents = true;
      _apiFailed = false;
      _apiEventsByHijriDate.clear();
    });

    try {
      final monthLength = HijriiDate.monthLength(
        year: _displayedYear,
        month: _displayedMonth,
      );

      final firstGregorian = HijriiDate.toGregorian(
        year: _displayedYear,
        month: _displayedMonth,
        day: 1,
      );

      final lastGregorian = firstGregorian.add(
        Duration(days: monthLength - 1),
      );

      final monthsToFetch = <String, DateTime>{
        '${firstGregorian.year}-${firstGregorian.month}': DateTime(
          firstGregorian.year,
          firstGregorian.month,
          1,
        ),
        '${lastGregorian.year}-${lastGregorian.month}': DateTime(
          lastGregorian.year,
          lastGregorian.month,
          1,
        ),
      }.values.toList();

      final List<IslamicCalendarDay> allDays = [];

      for (final date in monthsToFetch) {
        final days = await _apiService.getGregorianMonthCalendar(
          month: date.month,
          year: date.year,
        );

        allDays.addAll(days);
      }

      final Map<String, String> loadedEvents = {};

      for (final day in allDays) {
        if (day.hijriYear != _displayedYear ||
            day.hijriMonth != _displayedMonth) {
          continue;
        }

        if (day.holidays.isEmpty) continue;

        final event = _prepareEventForCalendar(day.holidays.first);

        if (event == null || event.trim().isEmpty) continue;

        loadedEvents[_eventKey(
          year: day.hijriYear,
          month: day.hijriMonth,
          day: day.hijriDay,
        )] = event;
      }

      if (!mounted) return;

      setState(() {
        _apiEventsByHijriDate
          ..clear()
          ..addAll(loadedEvents);

        _isLoadingEvents = false;
        _apiFailed = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _apiEventsByHijriDate.clear();
        _isLoadingEvents = false;
        _apiFailed = true;
      });
    }
  }

  String? _prepareEventForCalendar(String value) {
    final clean = value
        .replaceAll(' - ', ' ')
        .replaceAll('Holiday', '')
        .replaceAll('holiday', '')
        .replaceAll('Observed', '')
        .replaceAll('observed', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (clean.isEmpty) return null;

    if (RegExp(r'[A-Za-z]').hasMatch(clean)) return null;

    return clean;
  }

  String? _eventNameForDay(int day) {
    final apiEvent = _apiEventsByHijriDate[_eventKey(
      year: _displayedYear,
      month: _displayedMonth,
      day: day,
    )];

    if (apiEvent != null && apiEvent.trim().isNotEmpty) {
      return apiEvent;
    }

    return HijriiDate.islamicEventName(
      hijriDay: day,
      hijriMonth: _displayedMonth,
    );
  }

  void _goToPreviousMonth() {
    setState(() {
      if (_displayedMonth == 1) {
        _displayedMonth = 12;
        _displayedYear--;
      } else {
        _displayedMonth--;
      }

      _selectedYear = _displayedYear;
      _selectedMonth = _displayedMonth;
      _selectedDay = 1;
    });

    _loadEventsForDisplayedMonth();
  }

  void _goToNextMonth() {
    setState(() {
      if (_displayedMonth == 12) {
        _displayedMonth = 1;
        _displayedYear++;
      } else {
        _displayedMonth++;
      }

      _selectedYear = _displayedYear;
      _selectedMonth = _displayedMonth;
      _selectedDay = 1;
    });

    _loadEventsForDisplayedMonth();
  }

  void _selectDay(int day) {
    setState(() {
      _selectedYear = _displayedYear;
      _selectedMonth = _displayedMonth;
      _selectedDay = day;
    });
  }

  @override
  Widget build(BuildContext context) {
    final monthLength = HijriiDate.monthLength(
      year: _displayedYear,
      month: _displayedMonth,
    );

    final firstWeekday = HijriiDate.firstWeekdayOfMonth(
      year: _displayedYear,
      month: _displayedMonth,
    );

    final emptyCellsBeforeFirstDay = firstWeekday == 6
        ? 0
        : firstWeekday == 7
        ? 1
        : firstWeekday + 1;

    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final isTablet = screenWidth >= 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.fromLTRB(
            isTablet ? 10 : 4,
            0,
            isTablet ? 10 : 4,
            6,
          ),
          padding: EdgeInsets.fromLTRB(
            isTablet ? 14 : 8,
            12,
            isTablet ? 14 : 8,
            14,
          ),
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.78,
            maxWidth: double.infinity,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTopHandle(),
                  const SizedBox(height: 12),
                  _buildTitle(context),
                  const SizedBox(height: 10),
                  _buildHeader(context),
                  if (_apiFailed) ...[
                    const SizedBox(height: 8),
                    _buildFallbackNotice(context),
                  ],
                  const SizedBox(height: 10),
                  _buildWeekDays(context),
                  const SizedBox(height: 6),
                  _buildDaysGrid(
                    monthLength: monthLength,
                    emptyCellsBeforeFirstDay: emptyCellsBeforeFirstDay,
                  ),
                  const SizedBox(height: 10),
                  _buildSelectedDayInfo(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopHandle() {
    return Container(
      width: 46,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.35),
        borderRadius: BorderRadius.circular(100),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            'التقويم الهجري',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body(context).copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (_isLoadingEvents) ...[
          const SizedBox(width: 8),
          const SizedBox(
            width: 13,
            height: 13,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ],
    );
  }

  Widget _buildFallbackNotice(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffF59E0B).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'تعذر تحميل مناسبات من الانترنت، يتم عرض المناسبات المحلية.',
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.caption(context).copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xffB45309),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final gregorianText = HijriiDate.gregorianMonthYearForHijriMonth(
      hijriYear: _displayedYear,
      hijriMonth: _displayedMonth,
    );

    return Row(
      children: [
        IconButton(
          onPressed: _goToPreviousMonth,
          icon: Transform.rotate(
            angle: math.pi,
            child: const Icon(Icons.chevron_right_rounded),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                HijriiDate.monthName(_displayedMonth),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'cairo',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$_displayedYear هـ',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'يوافق $gregorianText',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _goToNextMonth,
          icon: Transform.rotate(
            angle: math.pi,
            child: const Icon(Icons.chevron_left_rounded),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekDays(BuildContext context) {
    const days = [
      'السبت',
      'الأحد',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
    ];

    return Row(
      children: days.map((day) {
        return Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                day,
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.visible,
                style: AppTextStyles.caption(context).copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDaysGrid({
    required int monthLength,
    required int emptyCellsBeforeFirstDay,
  }) {
    final totalCells = emptyCellsBeforeFirstDay + monthLength;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isSmall = width < 360;
        final isTablet = width >= 600;

        final spacing = isTablet
            ? 5.0
            : isSmall
            ? 2.5
            : 3.5;

        final cellWidth = (width - (spacing * 6)) / 7;

        final cellHeight = isTablet
            ? 62.0
            : isSmall
            ? 44.0
            : cellWidth.clamp(48.0, 56.0);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalCells,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            mainAxisExtent: cellHeight,
          ),
          itemBuilder: (context, index) {
            if (index < emptyCellsBeforeFirstDay) {
              return const SizedBox.shrink();
            }

            final day = index - emptyCellsBeforeFirstDay + 1;

            final isSelected = _selectedYear == _displayedYear &&
                _selectedMonth == _displayedMonth &&
                _selectedDay == day;

            final eventName = _eventNameForDay(day);

            return _HijriDayCell(
              day: day,
              hasEvent: eventName != null && eventName.trim().isNotEmpty,
              isSelected: isSelected,
              isSmall: isSmall,
              isTablet: isTablet,
              onTap: () => _selectDay(day),
            );
          },
        );
      },
    );
  }

  Widget _buildSelectedDayInfo(BuildContext context) {
    final hijriText = HijriiDate.formatHijriDate(
      year: _selectedYear,
      month: _selectedMonth,
      day: _selectedDay,
    );

    final event = _selectedEventName;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xff1F8A5B).withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xff1F8A5B).withOpacity(0.18),
        ),
      ),
      child: Column(
        children: [
          Text(
            hijriText,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'cairo',
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Color(0xff1F8A5B),
            ),
          ),
          if (event != null && event.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              event,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'cairo',
                fontSize: 14,
                height: 1.2,
                fontWeight: FontWeight.w900,
                color: Color(0xff1F8A5B),
              ),
            ),
          ] else ...[
            const SizedBox(height: 4),
            Text(
              'لا توجد مناسبة مسجلة لهذا اليوم',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HijriDayCell extends StatelessWidget {
  final int day;
  final bool hasEvent;
  final bool isSelected;
  final bool isSmall;
  final bool isTablet;
  final VoidCallback onTap;

  const _HijriDayCell({
    required this.day,
    required this.hasEvent,
    required this.isSelected,
    required this.isSmall,
    required this.isTablet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const selectedColor = Color(0xff1F8A5B);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor
              : hasEvent
              ? selectedColor.withOpacity(0.10)
              : Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? selectedColor
                : hasEvent
                ? selectedColor.withOpacity(0.35)
                : Colors.grey.withOpacity(0.12),
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                '$day',
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: isTablet
                      ? 18
                      : isSmall
                      ? 13.5
                      : 15,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.white : null,
                ),
              ),
            ),
            if (hasEvent)
              Positioned(
                top: 2,
                left: 2,
                child: Container(
                  width: isTablet ? 7 : 6,
                  height: isTablet ? 7 : 6,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : selectedColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}