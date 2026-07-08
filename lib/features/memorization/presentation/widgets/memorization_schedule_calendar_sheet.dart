part of 'memorization_schedule_calendar_card.dart';

class _MonthCalendarSheet extends StatefulWidget {
  const _MonthCalendarSheet({required this.data});

  final _ScheduleData data;

  @override
  State<_MonthCalendarSheet> createState() => _MonthCalendarSheetState();
}

class _MonthCalendarSheetState extends State<_MonthCalendarSheet> {
  late DateTime selectedDate;
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedDate = DateTime(now.year, now.month, now.day);
    pageController = PageController();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  DateTime _monthForPage(int page) {
    final now = DateTime.now();
    return DateTime(now.year, now.month + page, 1);
  }

  int get _monthsCount {
    if (widget.data.items.isEmpty) return 12;

    final now = DateTime.now();
    final firstMonth = DateTime(now.year, now.month, 1);
    DateTime lastMonth = firstMonth;

    for (final item in widget.data.items) {
      final itemMonth = DateTime(item.date.year, item.date.month, 1);
      if (itemMonth.isAfter(lastMonth)) lastMonth = itemMonth;
    }

    final diff =
        (lastMonth.year - firstMonth.year) * 12 +
        (lastMonth.month - firstMonth.month) +
        1;

    return diff.clamp(12, 48).toInt();
  }

  List<_ScheduleItem> _itemsForDate(DateTime date) {
    return widget.data.items.where((item) => _sameDay(item.date, date)).toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _openTask(_ScheduleItem item) async {
    AppHaptics.tap(context);

    if (!item.task.hasValidRange) return;

    // مؤقتًا: نسمح بفتح مهام التقويم القادمة أثناء تطوير النظام.
    // كارت مهام اليوم يظل هو المسؤول عن عرض المستحق اليوم فقط.

    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => item.task.type == 'selfTest'
            ? MemorizationTestSessionPage(task: item.task)
            : MemorizationTrainingSessionPage(task: item.task),
      ),
    );
  }

  String _monthTitle(DateTime month) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];

    return '${months[month.month - 1]} ${month.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedItems = _itemsForDate(selectedDate);

    return DraggableScrollableSheet(
      initialChildSize: 0.86,
      minChildSize: 0.62,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 22.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Center(
                  child: Container(
                    width: 42.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                _MonthSheetHeader(),
                SizedBox(height: 14.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(13.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary,
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.12),
                    ),
                  ),
                  child: SizedBox(
                    height: 230.h,
                    child: PageView.builder(
                      controller: pageController,
                      reverse: true,
                      itemCount: _monthsCount,
                      itemBuilder: (context, page) {
                        final month = _monthForPage(page);
                        return _MonthGrid(
                          month: month,
                          title: _monthTitle(month),
                          selectedDate: selectedDate,
                          itemsForDate: _itemsForDate,
                          onDayTap: (date) {
                            AppHaptics.tap(context);
                            setState(() => selectedDate = date);
                          },
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                _SelectedDateTasksCard(
                  date: selectedDate,
                  items: selectedItems,
                  plansCount: widget.data.plansCount,
                  onTaskTap: _openTask,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MonthSheetHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Container(
          width: 42.w,
          height: 42.w,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(15.r),
          ),
          child: Icon(
            Icons.calendar_month_rounded,
            color: theme.colorScheme.primary,
            size: 23.sp,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'تقويم الخطة الشهري',
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: AppTextStyles.caption(context).copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.surface,
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                'الألوان توضّح نوع المهمة مباشرة، واضغط على أي يوم لعرض التفاصيل.',
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.surface.withOpacity(0.58),
                  height: 1.4,
                ),
              ),
              SizedBox(height: 7.h),
              const _CalendarLegendRow(),
            ],
          ),
        ),
      ],
    );
  }
}

class _CalendarLegendRow extends StatelessWidget {
  const _CalendarLegendRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      textDirection: TextDirection.rtl,
      alignment: WrapAlignment.end,
      spacing: 8.w,
      runSpacing: 5.h,
      children: [
        _LegendItem(label: 'حفظ', color: theme.colorScheme.primary),
        const _LegendItem(label: 'مراجعة', color: Colors.orange),
        const _LegendItem(label: 'إنقاذ', color: Colors.red),
        const _LegendItem(label: 'اختبار', color: Colors.indigo),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.rtl,
      children: [
        Container(
          width: 6.w,
          height: 6.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 4.w),
        Text(
          label,
          textDirection: TextDirection.rtl,
          style: AppTextStyles.caption(context).copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.surface.withOpacity(0.62),
          ),
        ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.title,
    required this.selectedDate,
    required this.itemsForDate,
    required this.onDayTap,
  });

  final DateTime month;
  final String title;
  final DateTime selectedDate;
  final List<_ScheduleItem> Function(DateTime date) itemsForDate;
  final ValueChanged<DateTime> onDayTap;

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstDay = DateTime(month.year, month.month, 1);
    final daysCount = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday = firstDay.weekday;
    final leadingEmpty = firstWeekday - 1;
    final totalCells = leadingEmpty + daysCount;
    final rows = (totalCells / 7).ceil();

    const weekDays = [
      'إثنين',
      'ثللاثاء',
      'أرباء',
      'خميس',
      'جمعه',
      'سبت',
      'أحد',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          textDirection: TextDirection.rtl,
          children: [
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
            Icon(
              Icons.swipe_rounded,
              color: theme.colorScheme.primary.withOpacity(0.78),
              size: 18.sp,
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          textDirection: TextDirection.rtl,
          children: weekDays.map((day) {
            return Expanded(
              child: Center(
                child: Text(
                  day,
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.surface.withOpacity(0.50),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 8.h),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rows * 7,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6.h,
              crossAxisSpacing: 6.w,
            ),
            itemBuilder: (context, index) {
              final dayNumber = index - leadingEmpty + 1;

              if (dayNumber < 1 || dayNumber > daysCount) {
                return const SizedBox.shrink();
              }

              final date = DateTime(month.year, month.month, dayNumber);
              final items = itemsForDate(date);
              final isSelected = _sameDay(date, selectedDate);
              final now = DateTime.now();
              final isToday = _sameDay(
                date,
                DateTime(now.year, now.month, now.day),
              );

              return _MonthDayCell(
                date: date,
                count: items.length,
                isSelected: isSelected,
                isToday: isToday,
                hasNew: items.any((item) => item.task.type == 'dailyNew'),
                hasReview: items.any((item) => item.task.type == 'dailyReview'),
                hasTest: items.any((item) => item.task.type == 'selfTest'),
                hasRescue: items.any((item) => item.isRescue),
                onTap: () => onDayTap(date),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MonthDayCell extends StatelessWidget {
  const _MonthDayCell({
    required this.date,
    required this.count,
    required this.isSelected,
    required this.isToday,
    required this.hasNew,
    required this.hasReview,
    required this.hasTest,
    required this.hasRescue,
    required this.onTap,
  });

  final DateTime date;
  final int count;
  final bool isSelected;
  final bool isToday;
  final bool hasNew;
  final bool hasReview;
  final bool hasTest;
  final bool hasRescue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlighted = isSelected || isToday;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: highlighted
                ? theme.colorScheme.primary.withOpacity(
                    isSelected ? 0.16 : 0.09,
                  )
                : theme.colorScheme.background.withOpacity(0.34),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary.withOpacity(0.48)
                  : theme.colorScheme.outline.withOpacity(0.08),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${date.day}',
                style: AppTextStyles.caption(context).copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.surface,
                  height: 1,
                ),
              ),
              SizedBox(height: 5.h),
              _TaskDotsRow(
                hasNew: hasNew,
                hasReview: hasReview,
                hasTest: hasTest,
                hasRescue: hasRescue,
                count: count,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskDotsRow extends StatelessWidget {
  const _TaskDotsRow({
    required this.hasNew,
    required this.hasReview,
    required this.hasTest,
    required this.hasRescue,
    required this.count,
  });

  final bool hasNew;
  final bool hasReview;
  final bool hasTest;
  final bool hasRescue;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeDots = [
      hasNew,
      hasReview,
      hasTest,
      hasRescue,
    ].where((value) => value).length;

    if (count == 0 || activeDots == 0) {
      return Container(
        width: 4.w,
        height: 4.w,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.10),
          shape: BoxShape.circle,
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasNew) _Dot(color: theme.colorScheme.primary),
        if (hasReview) _Dot(color: Colors.orange),
        if (hasRescue) _Dot(color: Colors.red),
        if (hasTest) _Dot(color: Colors.indigo),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4.5.w,
      height: 4.5.w,
      margin: EdgeInsets.symmetric(horizontal: 1.w),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _SelectedDateTasksCard extends StatelessWidget {
  const _SelectedDateTasksCard({
    required this.date,
    required this.items,
    required this.plansCount,
    required this.onTaskTap,
  });

  final DateTime date;
  final List<_ScheduleItem> items;
  final int plansCount;
  final ValueChanged<_ScheduleItem> onTaskTap;

  String _titleForDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(date.year, date.month, date.day);
    final diff = selected.difference(today).inDays;

    if (diff == 0) return 'مهام اليوم';
    if (diff == 1) return 'مهام الغد';
    return 'مهام يوم ${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.12)),
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
                size: 19.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  _titleForDate(date),
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
          SizedBox(height: 10.h),
          if (items.isEmpty)
            _EmptyDayLine(
              plansCount: plansCount,
              dayOffset: DateTime(date.year, date.month, date.day)
                  .difference(
                    DateTime(
                      DateTime.now().year,
                      DateTime.now().month,
                      DateTime.now().day,
                    ),
                  )
                  .inDays,
            )
          else
            ...items.map(
              (item) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: _DayTaskTile(item: item, onTap: () => onTaskTap(item)),
              ),
            ),
        ],
      ),
    );
  }
}
