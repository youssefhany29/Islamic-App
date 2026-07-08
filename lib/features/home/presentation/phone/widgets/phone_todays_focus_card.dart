import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/services/app_haptics.dart';
import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/azkar/data/datasources/zekr_local_data.dart';
import 'package:islamic_app/features/azkar/data/services/zekr_data_service.dart';
import 'package:islamic_app/features/azkar/data/services/zekr_progress_service.dart';
import 'package:islamic_app/features/azkar/zekr_page.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_today_task_model.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_plan_storage.dart';
import 'package:islamic_app/features/memorization/my_lessons_home_page.dart';
import 'package:islamic_app/features/quran/wird/daily_wird_page.dart';
import 'package:islamic_app/features/quran/wird/quran_wird_progress_storage.dart';
import 'package:islamic_app/features/quran/wird/quran_wird_storage.dart';
import 'package:islamic_app/shared/widgets/common_components/app_layout_constants.dart';

import '../../../../memorization/data/services/memorization_session_result_storage.dart';

class PhoneTodaysFocusCard extends StatefulWidget {
  const PhoneTodaysFocusCard({
    super.key,
    required this.prayerWeek,
    required this.isLoadingPrayerTimes,
    this.onTasksChanged,
  });

  final List<Map<String, String>> prayerWeek;
  final bool isLoadingPrayerTimes;
  final Future<void> Function()? onTasksChanged;

  @override
  State<PhoneTodaysFocusCard> createState() => _PhoneTodaysFocusCardState();
}

class _PhoneTodaysFocusCardState extends State<PhoneTodaysFocusCard> {
  bool _isLoading = true;
  List<_FocusItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void didUpdateWidget(covariant PhoneTodaysFocusCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.prayerWeek != widget.prayerWeek ||
        oldWidget.isLoadingPrayerTimes != widget.isLoadingPrayerTimes) {
      _loadItems();
    }
  }

  Future<void> _loadItems() async {
    final items = <_FocusItem>[
      await _buildWirdItem(),
      await _buildZekrItem(),
      await _buildMemorizationItem(),
    ];

    if (!mounted) return;

    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  Future<_FocusItem> _buildWirdItem() async {
    final activeWirds = await QuranWirdStorage.buildTodayWirds();

    if (activeWirds.isEmpty) {
      return _FocusItem(
        title: 'الورد اليومي',
        subtitle: 'لم تبدأ خطة ورد بعد',
        completed: false,
        onTap: () => _openPage(const DailyWirdPage()),
      );
    }

    final wird = activeWirds.first;
    final completedToday =
    await QuranWirdProgressStorage.wasCompletedToday(wird.planId);

    if (completedToday) {
      return _FocusItem(
        title: 'تم ورد اليوم',
        subtitle: 'أحسنت، أنهيت وردك اليومي',
        completed: true,
        onTap: () => _openPage(const DailyWirdPage()),
      );
    }

    final progress = await QuranWirdProgressStorage.getProgress(wird.planId);

    final bool completed = progress != null &&
        progress.suraIndex == wird.toSuraIndex &&
        progress.ayahIndex >= wird.toAyahIndex;

    return _FocusItem(
      title: completed ? 'تم ورد اليوم' : 'الورد اليومي',
      subtitle: completed ? 'أحسنت، أتممت وردك اليوم' : 'تابع ورد القرآن اليومي',
      completed: completed,
      onTap: () => _openPage(const DailyWirdPage()),
    );
  }

  Future<_FocusItem> _buildZekrItem() async {
    final dataService = ZekrDataService();
    const progressService = ZekrProgressService();

    final dailyCategoryIds = <String>[
      ZekrLocalData.morningId,
      ZekrLocalData.eveningId,
      ZekrLocalData.afterPrayerId,
      ZekrLocalData.sleepId,
    ];

    final completedKeys = await progressService.getCompletedItemsToday();

    int completedCategories = 0;

    for (final categoryId in dailyCategoryIds) {
      final items = await dataService.getItemsByCategory(categoryId);

      if (items.isEmpty) continue;

      final completedForCategory = completedKeys.where((key) {
        return key.startsWith('$categoryId::');
      }).length;

      if (completedForCategory >= items.length) {
        completedCategories++;
      }
    }

    final completed = completedCategories >= dailyCategoryIds.length;

    return _FocusItem(
      title: completed ? 'تمت أذكار اليوم' : 'أذكار اليوم',
      subtitle:
      '${_arabicNumber(completedCategories)} من ${_arabicNumber(dailyCategoryIds.length)} أقسام أساسية',
      completed: completed,
      onTap: () => _openPage(const ZekrPage()),
    );
  }

  Future<_FocusItem> _buildMemorizationItem() async {
    final task = await MemorizationPlanStorage.getTodayTask();

    if (task == null) {
      return _FocusItem(
        title: 'الحفظ',
        subtitle: 'لا توجد مهمة حفظ نشطة اليوم',
        completed: false,
        onTap: () => _openPage(const MyLessonsHomePage()),
      );
    }

    final completed = await _isMemorizationTaskCompletedToday(task);

    final title = completed
        ? 'تمت مهمة الحفظ'
        : task.type == 'selfTest' || task.isReadyForTest
        ? 'اختبار الحفظ'
        : task.type == 'dailyReview'
        ? 'مراجعة الحفظ'
        : 'مهمة الحفظ';

    final subtitle = completed
        ? 'أحسنت، أنهيت مهمة الحفظ اليوم'
        : task.scopeTitle.trim().isNotEmpty
        ? task.scopeTitle.trim()
        : task.subtitle.trim().isNotEmpty
        ? task.subtitle.trim()
        : 'افتح حلقة الحفظ للمتابعة';

    return _FocusItem(
      title: title,
      subtitle: subtitle,
      completed: completed,
      onTap: () => _openPage(const MyLessonsHomePage()),
    );
  }

  Future<bool> _isMemorizationTaskCompletedToday(MemorizationTodayTaskModel task) async {
    if (task.isCompleted ||
        task.status == MemorizationTodayTaskModel.statusCompleted) {
      return true;
    }

    final results = await MemorizationSessionResultStorage.getResults();
    final now = DateTime.now();

    for (final result in results) {
      if (!_sameDay(result.completedAt, now)) continue;
      if (result.completedStep != 'completed') continue;
      if (result.taskType == 'weakReview') continue;

      final exactTask = result.taskId == task.id;
      final sameRange = result.startGlobalAyahIndex == task.startGlobalAyahIndex &&
          result.endGlobalAyahIndex == task.endGlobalAyahIndex;
      final compatibleType = result.taskType == task.type ||
          (task.type == 'dailyNew' && result.taskType == 'dailyReview') ||
          (task.type == 'dailyReview' && result.taskType == 'dailyNew');

      if (exactTask || sameRange || compatibleType) return true;
    }

    return false;
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _openPage(Widget page) {
    AppHaptics.tap(context);

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    ).then((_) async {
      await _loadItems();
      await widget.onTasksChanged?.call();
    });
  }

  String _arabicNumber(Object value) {
    return value
        .toString()
        .replaceAll('0', '0')
        .replaceAll('1', '1')
        .replaceAll('2', '2')
        .replaceAll('3', '3')
        .replaceAll('4', '4')
        .replaceAll('5', '5')
        .replaceAll('6', '6')
        .replaceAll('7', '7')
        .replaceAll('8', '8')
        .replaceAll('9', '9');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: AppLayoutConstants.mainCardWidth,
      child: Container(
        padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 13.h),
        decoration: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withOpacity(0.22),
              blurRadius: 22.r,
              offset: Offset(0, 10.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _FocusHeader(),
            SizedBox(height: 12.h),
            Divider(
              color: Colors.white.withOpacity(0.12),
              height: 1.h,
              thickness: 0.7.h,
            ),
            SizedBox(height: 5.h),
            if (_isLoading)
              SizedBox(
                height: 116.h,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            else
              ...List.generate(_items.length, (index) {
                return _FocusRow(
                  item: _items[index],
                  isFirst: index == 0,
                  isLast: index == _items.length - 1,
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _FocusHeader extends StatelessWidget {
  const _FocusHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 38.w,
          height: 38.w,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.11),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.fact_check_rounded,
            color: Colors.white.withOpacity(0.88),
            size: 18.sp,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'مهام اليوم',
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 13.sp,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'كل خطوة تقربك من رضا الله',
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.62),
                  fontSize: 8.sp,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FocusRow extends StatelessWidget {
  const _FocusRow({
    required this.item,
    required this.isFirst,
    required this.isLast,
  });

  final _FocusItem item;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final row = Container(
      padding: EdgeInsets.symmetric(vertical: 6.2.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isLast ? Colors.transparent : Colors.white.withOpacity(0.09),
            width: 0.7.h,
          ),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _TimelineStatusCircle(
            completed: item.completed,
            isFirst: isFirst,
            isLast: isLast,
          ),
          SizedBox(width: 9.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 10.sp,
                    height: 1.08,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  item.subtitle,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    fontSize: 8.sp,
                    height: 1.1,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          const _ForcedBackArrow(),
        ],
      ),
    );

    if (item.onTap == null) return row;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: item.onTap,
        child: row,
      ),
    );
  }
}

class _TimelineStatusCircle extends StatelessWidget {
  const _TimelineStatusCircle({
    required this.completed,
    required this.isFirst,
    required this.isLast,
  });

  final bool completed;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final lineColor = Colors.white.withOpacity(0.20);

    return SizedBox(
      width: 22.w,
      height: 34.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 0,
            bottom: 0,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 1.w,
                    color: isFirst ? Colors.transparent : lineColor,
                  ),
                ),
                SizedBox(height: 19.w),
                Expanded(
                  child: Container(
                    width: 1.w,
                    color: isLast ? Colors.transparent : lineColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 20.w,
            height: 20.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: completed
                  ? Colors.white.withOpacity(0.17)
                  : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: completed
                    ? Colors.white.withOpacity(0.12)
                    : Colors.white.withOpacity(0.34),
                width: 1.w,
              ),
            ),
            child: completed
                ? Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 12.5.sp,
            )
                : null,
          ),
        ],
      ),
    );
  }
}

class _ForcedBackArrow extends StatelessWidget {
  const _ForcedBackArrow();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Icon(
        Icons.chevron_left_rounded,
        color: Colors.white.withOpacity(0.72),
        size: 16.sp,
      ),
    );
  }
}

class _FocusItem {
  const _FocusItem({
    required this.title,
    required this.subtitle,
    required this.completed,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final bool completed;
  final VoidCallback? onTap;
}