import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import 'package:islamic_app/features/hadith/data/models/hadith_memory_item_state_model.dart';
import 'package:islamic_app/features/hadith/data/services/hadith_memory_progress_service.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
part 'hadith_review_calendar_widgets.dart';

bool _hadithCalendarLargeScreen(BuildContext context) {
  final Size size = MediaQuery.sizeOf(context);
  return size.shortestSide >= 600 || (size.width >= 700 && size.height >= 500);
}

class HadithReviewCalendarCard extends StatefulWidget {
  const HadithReviewCalendarCard({
    super.key,
    required this.refreshTick,
    required this.onOpenTodayReview,
  });

  final int refreshTick;
  final VoidCallback onOpenTodayReview;

  @override
  State<HadithReviewCalendarCard> createState() =>
      _HadithReviewCalendarCardState();
}

class _HadithReviewCalendarCardState extends State<HadithReviewCalendarCard> {
  final HadithMemoryProgressService _service =
      const HadithMemoryProgressService();

  late Future<List<HadithMemoryItemStateModel>> _statesFuture;
  DateTime _selectedDate = _todayOnly(DateTime.now());

  static DateTime _todayOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  @override
  void initState() {
    super.initState();
    _reloadStates();
  }

  @override
  void didUpdateWidget(covariant HadithReviewCalendarCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.refreshTick != widget.refreshTick) {
      _reloadStates();
    }
  }

  void _reloadStates() {
    _statesFuture = _service.getItemStates();
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  List<HadithMemoryItemStateModel> _itemsForDate(
    List<HadithMemoryItemStateModel> states,
    DateTime date,
  ) {
    final normalizedDate = _normalizeDate(date);

    return states.where((state) {
      return _normalizeDate(state.nextReviewAt) == normalizedDate;
    }).toList()..sort((a, b) => a.memoryStrength.compareTo(b.memoryStrength));
  }

  bool _isToday(DateTime date) {
    return _normalizeDate(date) == _normalizeDate(DateTime.now());
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

  void _showDayReviewsSheet({
    required BuildContext context,
    required DateTime date,
    required List<HadithMemoryItemStateModel> items,
  }) {
    AppHaptics.tap(context);

    final theme = Theme.of(context);
    final bool isToday = _isToday(date);
    final bool isLargeScreen = _hadithCalendarLargeScreen(context);

    final String sheetTitle = isToday
        ? 'مراجعات اليوم'
        : 'مراجعات يوم ${date.day}/${date.month}/${date.year}';

    final String sheetSubtitle = items.isEmpty
        ? 'لا يوجد عليك أي حديث للمراجعة في هذا اليوم.'
        : 'عليك ${items.length} ${items.length == 1 ? 'حديث' : 'أحاديث'} للمراجعة. ابدأ بالأضعف لتثبيت الحفظ.';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                left: isLargeScreen ? 18 : 12.w,
                right: isLargeScreen ? 18 : 12.w,
                bottom: isLargeScreen ? 18 : 12.h,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.78,
                ),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    isLargeScreen ? 18 : 14.w,
                    isLargeScreen ? 18 : 14.h,
                    isLargeScreen ? 18 : 14.w,
                    isLargeScreen ? 18 : 14.h,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary,
                    borderRadius: BorderRadius.circular(
                      isLargeScreen ? 28 : 24.r,
                    ),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          theme.brightness == Brightness.dark ? 0.22 : 0.10,
                        ),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _SheetHeader(
                        title: sheetTitle,
                        subtitle: sheetSubtitle,
                        hasReviews: items.isNotEmpty,
                      ),
                      SizedBox(height: isLargeScreen ? 14 : 12.h),
                      if (items.isEmpty)
                        _EmptyReviewDayMessage(isToday: isToday)
                      else ...[
                        _ReviewDaySummaryBanner(count: items.length),
                        SizedBox(height: isLargeScreen ? 12 : 10.h),
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                SizedBox(height: isLargeScreen ? 10 : 8.h),
                            itemBuilder: (context, index) {
                              return _ReviewPreviewTile(
                                item: items[index],
                                index: index + 1,
                              );
                            },
                          ),
                        ),
                      ],
                      if (isToday && items.isNotEmpty) ...[
                        SizedBox(height: isLargeScreen ? 14 : 12.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              widget.onOpenTodayReview();
                            },
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: isLargeScreen ? 13 : 11.h,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  isLargeScreen ? 16 : 15.r,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              textDirection: TextDirection.rtl,
                              children: [
                                Icon(
                                  Icons.play_arrow_rounded,
                                  size: isLargeScreen ? 20 : 18.sp,
                                ),
                                SizedBox(width: isLargeScreen ? 7 : 6.w),
                                Text(
                                  'ابدأ مراجعة اليوم',
                                  textAlign: TextAlign.center,
                                  textDirection: TextDirection.rtl,
                                  style: AppTextStyles.caption(
                                    context,
                                  ).copyWith(fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = _normalizeDate(DateTime.now());
    final dates = List.generate(
      14,
      (index) => today.add(Duration(days: index)),
    );

    return FutureBuilder<List<HadithMemoryItemStateModel>>(
      future: _statesFuture,
      builder: (context, snapshot) {
        final states = snapshot.data ?? [];

        final selectedItems = _itemsForDate(states, _selectedDate);
        final upcomingCount = states.where((state) {
          final reviewDate = _normalizeDate(state.nextReviewAt);
          return !reviewDate.isBefore(today) &&
              reviewDate.isBefore(today.add(const Duration(days: 14)));
        }).length;

        return _ReviewCalendarStrip(
          dates: dates,
          selectedDate: _selectedDate,
          states: states,
          selectedItems: selectedItems,
          upcomingCount: upcomingCount,
          weekdayName: _weekdayName,
          normalizeDate: _normalizeDate,
          onDateSelected: (date) {
            final normalized = _normalizeDate(date);

            setState(() {
              _selectedDate = normalized;
            });

            final dayItems = _itemsForDate(states, normalized);
            _showDayReviewsSheet(
              context: context,
              date: normalized,
              items: dayItems,
            );
          },
        );
      },
    );
  }
}
