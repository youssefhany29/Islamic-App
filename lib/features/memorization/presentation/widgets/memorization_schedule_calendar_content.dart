part of 'memorization_schedule_calendar_card.dart';

class _ScheduleCalendarContent extends StatelessWidget {
  const _ScheduleCalendarContent({
    required this.data,
    required this.selectedDayOffset,
    required this.onDayTap,
    required this.onTaskTap,
    required this.onOpenMonthCalendar,
  });

  final _ScheduleData data;
  final int selectedDayOffset;
  final ValueChanged<int> onDayTap;
  final ValueChanged<_ScheduleItem> onTaskTap;
  final VoidCallback onOpenMonthCalendar;

  List<_ScheduleDay> get _days {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return List.generate(7, (index) {
      final date = today.add(Duration(days: index));
      final items = data.items
          .where((item) => _sameDay(item.date, date))
          .toList();
      return _ScheduleDay(offset: index, date: date, items: items);
    });
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _arabicDayName(DateTime date) {
    const days = [
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    return days[date.weekday - 1];
  }

  String _dayLabel(DateTime date, int offset) {
    if (offset == 0) return 'اليوم';
    if (offset == 1) return 'غدًا';
    return _arabicDayName(date);
  }

  String _selectedDayTitle(_ScheduleDay day) {
    if (day.offset == 0) return 'مهام اليوم';
    if (day.offset == 1) return 'مهام الغد';
    return 'مهام ${_arabicDayName(day.date)}';
  }

  int get todayTasksCount {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return data.items.where((item) => _sameDay(item.date, today)).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = _days;
    final selectedDay = days.firstWhere(
      (day) => day.offset == selectedDayOffset,
      orElse: () => days.first,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14.r),
                  onTap: onOpenMonthCalendar,
                  child: Container(
                    width: 38.w,
                    height: 38.w,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Icon(
                      Icons.calendar_month_rounded,
                      color: theme.colorScheme.primary,
                      size: 21.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'تقويم الحفظ والمراجعة',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.caption(context).copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.surface,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      data.plansCount == 0
                          ? 'لا توجد خطة محفوظة الآن.'
                          : todayTasksCount == 0
                          ? 'اختار يومًا من التقويم لعرض مهامه هنا.'
                          : 'اليوم لديك $todayTasksCount مهمة: حفظ، مراجعة، أو اختبار حسب نوع خطتك.',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.surface.withOpacity(0.58),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 76.h,
            child: ListView.separated(
              reverse: true,
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (_, __) => SizedBox(width: 8.w),
              itemBuilder: (context, index) {
                final day = days[index];
                return _DayChip(
                  label: _dayLabel(day.date, day.offset),
                  dayNumber: day.date.day,
                  count: day.items.length,
                  isToday: day.offset == 0,
                  isSelected: day.offset == selectedDay.offset,
                  onTap: () => onDayTap(day.offset),
                );
              },
            ),
          ),
          SizedBox(height: 12.h),
          _InlineDayTasksPanel(
            title: _selectedDayTitle(selectedDay),
            day: selectedDay,
            plansCount: data.plansCount,
            onTaskTap: onTaskTap,
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.dayNumber,
    required this.count,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int dayNumber;
  final int count;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlighted = isSelected || isToday;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          width: 64.w,
          padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: highlighted
                ? theme.colorScheme.primary.withOpacity(
                    isSelected ? 0.16 : 0.10,
                  )
                : theme.colorScheme.background.withOpacity(0.35),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary.withOpacity(0.52)
                  : isToday
                  ? theme.colorScheme.primary.withOpacity(0.30)
                  : theme.colorScheme.outline.withOpacity(0.12),
              width: isSelected ? 1.2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.surface.withOpacity(0.72),
                  height: 1,
                ),
              ),
              SizedBox(height: 5.h),
              Text(
                '$dayNumber',
                style: AppTextStyles.caption(context).copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.surface,
                  height: 1,
                ),
              ),
              SizedBox(height: 5.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: count == 0
                      ? theme.colorScheme.surface.withOpacity(0.05)
                      : theme.colorScheme.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(30.r),
                ),
                child: Text(
                  count == 0 ? 'فارغ' : '$count مهمة',
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: count == 0
                        ? theme.colorScheme.surface.withOpacity(0.42)
                        : theme.colorScheme.primary,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineDayTasksPanel extends StatelessWidget {
  const _InlineDayTasksPanel({
    required this.title,
    required this.day,
    required this.plansCount,
    required this.onTaskTap,
  });

  final String title;
  final _ScheduleDay day;
  final int plansCount;
  final ValueChanged<_ScheduleItem> onTaskTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = day.items;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: Container(
        key: ValueKey('day_tasks_${day.offset}_${items.length}'),
        width: double.infinity,
        padding: EdgeInsets.all(11.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.background.withOpacity(0.36),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.10),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(
                  Icons.event_note_rounded,
                  color: theme.colorScheme.primary,
                  size: 18.sp,
                ),
                SizedBox(width: 7.w),
                Expanded(
                  child: Text(
                    title,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: AppTextStyles.caption(context).copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.surface,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 9.h),
            if (items.isEmpty)
              _EmptyDayLine(plansCount: plansCount, dayOffset: day.offset)
            else
              ...items.map(
                (item) => Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: _DayTaskTile(item: item, onTap: () => onTaskTap(item)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DayTaskTile extends StatelessWidget {
  const _DayTaskTile({required this.item, required this.onTap});

  final _ScheduleItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: item.isRescue
                  ? theme.colorScheme.primary.withOpacity(0.18)
                  : theme.colorScheme.outline.withOpacity(0.10),
            ),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(13.r),
                ),
                child: Icon(
                  item.icon,
                  color: theme.colorScheme.primary,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 9.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption(context).copyWith(
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.surface,
                              height: 1.25,
                            ),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          item.timeLabel,
                          textDirection: TextDirection.rtl,
                          style: AppTextStyles.caption(context).copyWith(
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      item.subtitle,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.surface.withOpacity(0.56),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(30.r),
                ),
                child: Text(
                  item.badge,
                  textDirection: TextDirection.rtl,
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDayLine extends StatelessWidget {
  const _EmptyDayLine({required this.plansCount, required this.dayOffset});

  final int plansCount;
  final int dayOffset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = plansCount == 0
        ? 'أنشئ خطة أولًا حتى تظهر مهام الحفظ والمراجعة.'
        : dayOffset == 0
        ? 'لا توجد مهام إضافية اليوم.'
        : 'هذا اليوم فارغ من مهام المراجعة حتى الآن.';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withOpacity(0.70),
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Text(
        text,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        style: AppTextStyles.caption(context).copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.surface.withOpacity(0.58),
          height: 1.4,
        ),
      ),
    );
  }
}
