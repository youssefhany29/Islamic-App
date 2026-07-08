part of 'hadith_review_calendar_card.dart';

class _ReviewCalendarStrip extends StatelessWidget {
  const _ReviewCalendarStrip({
    required this.dates,
    required this.selectedDate,
    required this.states,
    required this.selectedItems,
    required this.upcomingCount,
    required this.weekdayName,
    required this.normalizeDate,
    required this.onDateSelected,
  });

  final List<DateTime> dates;
  final DateTime selectedDate;
  final List<HadithMemoryItemStateModel> states;
  final List<HadithMemoryItemStateModel> selectedItems;
  final int upcomingCount;
  final String Function(int weekday) weekdayName;
  final DateTime Function(DateTime date) normalizeDate;
  final ValueChanged<DateTime> onDateSelected;

  int _reviewsCount(DateTime date) {
    final normalizedDate = normalizeDate(date);

    return states.where((state) {
      return normalizeDate(state.nextReviewAt) == normalizedDate;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool large = _hadithCalendarLargeScreen(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final double padding = large ? 12 : 14.w;
    final double radius = large ? 22 : 18.r;
    final double headerGap = large ? 10 : 9.h;
    final double dayGap = large ? 8 : 8.w;
    final double stripHeight = large ? 76 : 82.h;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(isDark ? 0.18 : 0.32),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.10 : 0.025),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _CalendarStripHeader(upcomingCount: upcomingCount),
            SizedBox(height: headerGap),
            SizedBox(
              height: stripHeight,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  reverse: false,
                  physics: const BouncingScrollPhysics(),
                  itemCount: dates.length,
                  separatorBuilder: (_, __) => SizedBox(width: dayGap),
                  itemBuilder: (context, index) {
                    final date = dates[index];
                    final normalized = normalizeDate(date);
                    final count = _reviewsCount(date);

                    return _CalendarDayPill(
                      date: date,
                      weekdayText: index == 0
                          ? 'اليوم'
                          : weekdayName(date.weekday),
                      isToday: index == 0,
                      isSelected: selectedDate == normalized,
                      hasReview: count > 0,
                      reviewsCount: count,
                      onTap: () {
                        AppHaptics.tap(context);
                        onDateSelected(date);
                      },
                    );
                  },
                ),
              ),
            ),
            if (selectedItems.isNotEmpty) ...[
              SizedBox(height: large ? 8 : 8.h),
              SizedBox(
                width: double.infinity,
                child: Text(
                  'اضغط على اليوم لعرض تفاصيل المراجعات.',
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  locale: const Locale('ar'),
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.surface.withOpacity(0.54),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CalendarStripHeader extends StatelessWidget {
  const _CalendarStripHeader({required this.upcomingCount});

  final int upcomingCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool large = _hadithCalendarLargeScreen(context);

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: large ? 42 : 40.w),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(left: large ? 52 : 52.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      'تقويم المراجعة',
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      locale: const Locale('ar'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body(context).copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.surface,
                        height: 1.25,
                      ),
                    ),
                  ),
                  SizedBox(height: large ? 2 : 2.h),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      upcomingCount == 0
                          ? 'لا توجد مراجعات قادمة خلال 14 يوم.'
                          : 'عندك $upcomingCount مراجعات قادمة خلال 14 يوم.',
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      locale: const Locale('ar'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.surface.withOpacity(0.62),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: large ? 38 : 40.w,
              height: large ? 38 : 40.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(large ? 13 : 14.r),
              ),
              child: Icon(
                Icons.calendar_view_week_rounded,
                color: theme.colorScheme.primary,
                size: large ? 20 : 21.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarDayPill extends StatelessWidget {
  const _CalendarDayPill({
    required this.date,
    required this.weekdayText,
    required this.isToday,
    required this.isSelected,
    required this.hasReview,
    required this.reviewsCount,
    required this.onTap,
  });

  final DateTime date;
  final String weekdayText;
  final bool isToday;
  final bool isSelected;
  final bool hasReview;
  final int reviewsCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool large = _hadithCalendarLargeScreen(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final double width = large ? 62 : 62.w;
    final double radius = large ? 18 : 18.r;
    final double dayNumberSize = large ? 21 : 23.sp;
    final double weekdaySize = large ? 9 : 8.sp;

    final Color backgroundColor = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.secondary;

    final Color mainTextColor = isSelected
        ? Colors.white
        : theme.colorScheme.surface;

    final Color mutedTextColor = isSelected
        ? Colors.white.withOpacity(0.74)
        : theme.colorScheme.surface.withOpacity(0.60);

    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          splashColor: theme.colorScheme.primary.withOpacity(0.10),
          highlightColor: theme.colorScheme.primary.withOpacity(0.06),
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
                    : hasReview
                    ? theme.colorScheme.primary.withOpacity(
                        isDark ? 0.55 : 0.38,
                      )
                    : theme.colorScheme.outline.withOpacity(
                        isDark ? 0.18 : 0.35,
                      ),
              ),
              boxShadow: [
                if (isSelected || (isToday && hasReview))
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.18),
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
                      fontSize: dayNumberSize,
                      fontFamily: 'cairo',
                      fontWeight: FontWeight.w900,
                      color: mainTextColor,
                      height: 1.0,
                    ),
                  ),
                ),
                if (hasReview)
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
                        '$reviewsCount',
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: AppTextStyles.caption(context).copyWith(
                          fontWeight: FontWeight.w900,
                          color: isSelected
                              ? Colors.white
                              : theme.colorScheme.primary,
                          height: 1.1,
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

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.title,
    required this.subtitle,
    required this.hasReviews,
  });

  final String title;
  final String subtitle;
  final bool hasReviews;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool large = _hadithCalendarLargeScreen(context);

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: large ? 46 : 44.w),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(left: large ? 56 : 54.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      title,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      locale: const Locale('ar'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body(context).copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.surface,
                        height: 1.25,
                      ),
                    ),
                  ),
                  SizedBox(height: large ? 4 : 3.h),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      subtitle,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      locale: const Locale('ar'),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.surface.withOpacity(0.66),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: large ? 42 : 40.w,
              height: large ? 42 : 40.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(large ? 14 : 14.r),
              ),
              child: Icon(
                hasReviews
                    ? Icons.assignment_turned_in_outlined
                    : Icons.event_available_rounded,
                color: theme.colorScheme.primary,
                size: large ? 23 : 22.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewDaySummaryBanner extends StatelessWidget {
  const _ReviewDaySummaryBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool large = _hadithCalendarLargeScreen(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 10.w,
        vertical: large ? 10 : 9.h,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(large ? 16 : 15.r),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.10)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              'راجع الأحاديث التالية، وبعد الانتهاء قيّم حفظك من صفحة مراجعة اليوم.',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              locale: const Locale('ar'),
              style: AppTextStyles.caption(context).copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.surface.withOpacity(0.68),
                height: 1.45,
              ),
            ),
          ),
          SizedBox(width: large ? 8 : 7.w),
          Icon(
            Icons.info_outline_rounded,
            color: theme.colorScheme.primary,
            size: large ? 19 : 18.sp,
          ),
        ],
      ),
    );
  }
}

class _EmptyReviewDayMessage extends StatelessWidget {
  const _EmptyReviewDayMessage({required this.isToday});

  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool large = _hadithCalendarLargeScreen(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(large ? 14 : 12.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(large ? 17 : 16.r),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.10)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              isToday
                  ? 'تمام، لا يوجد عليك أي مراجعة اليوم. لو تدربت على حديث جديد، هيظهر ميعاد مراجعته هنا.'
                  : 'لا توجد مراجعات في هذا اليوم. اختر يومًا آخر من التقويم لمعرفة المراجعات القادمة.',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              locale: const Locale('ar'),
              style: AppTextStyles.caption(context).copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.surface.withOpacity(0.72),
                height: 1.6,
              ),
            ),
          ),
          SizedBox(width: large ? 9 : 8.w),
          Icon(
            Icons.check_circle_outline_rounded,
            color: const Color(0xff21C58E),
            size: large ? 22 : 21.sp,
          ),
        ],
      ),
    );
  }
}

class _ReviewPreviewTile extends StatelessWidget {
  const _ReviewPreviewTile({required this.item, required this.index});

  final HadithMemoryItemStateModel item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool large = _hadithCalendarLargeScreen(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(large ? 12 : 10.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(large ? 16 : 14.r),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.10)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: large ? 66 : 64.h),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(left: large ? 50 : 46.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        item.itemTitle,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        locale: const Locale('ar'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption(context).copyWith(
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.surface,
                          height: 1.35,
                        ),
                      ),
                    ),
                    SizedBox(height: large ? 4 : 3.h),
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        item.categoryTitle,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        locale: const Locale('ar'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                          height: 1.35,
                        ),
                      ),
                    ),
                    SizedBox(height: large ? 5 : 4.h),
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        _ReviewMetaChip(
                          text: item.level.label,
                          icon: Icons.psychology_alt_outlined,
                        ),
                        SizedBox(width: large ? 7 : 6.w),
                        _ReviewMetaChip(
                          text:
                              'قوة ${item.memoryStrength.toStringAsFixed(0)}%',
                          icon: Icons.speed_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: large ? 38 : 34.w,
                height: large ? 38 : 34.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(large ? 13 : 12.r),
                ),
                child: Text(
                  '$index',
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewMetaChip extends StatelessWidget {
  const _ReviewMetaChip({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool large = _hadithCalendarLargeScreen(context);

    return Flexible(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: large ? 8 : 7.w,
          vertical: large ? 4 : 3.h,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.rtl,
          children: [
            Icon(
              icon,
              color: theme.colorScheme.primary,
              size: large ? 13 : 12.sp,
            ),
            SizedBox(width: large ? 4 : 3.w),
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
