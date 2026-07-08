import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/shared/widgets/app_main_components/custom_app_bar.dart';
import 'package:islamic_app/shared/widgets/common_components/app_layout_constants.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import 'package:islamic_app/features/night_pray/data/services/night_pray_tracking_storage.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';

class NightPrayTrackingDetailsPage extends StatefulWidget {
  final List<String> items;
  final List<bool> checked;
  final int streak;
  final int bestStreak;
  final bool completedToday;
  final List<NightPrayWeeklyDay> weeklyHistory;
  final NightPrayMonthlyStats monthlyStats;
  final bool canEditTonight;
  final String? editLockedMessage;

  const NightPrayTrackingDetailsPage({
    super.key,
    required this.items,
    required this.checked,
    required this.streak,
    required this.bestStreak,
    required this.completedToday,
    required this.weeklyHistory,
    required this.monthlyStats,
    this.canEditTonight = true,
    this.editLockedMessage,
  });

  @override
  State<NightPrayTrackingDetailsPage> createState() =>
      _NightPrayTrackingDetailsPageState();
}

class _NightPrayTrackingDetailsPageState
    extends State<NightPrayTrackingDetailsPage> {
  late List<bool> _checked;
  late int _streak;
  late int _bestStreak;
  late bool _completedToday;
  late List<NightPrayWeeklyDay> _weeklyHistory;
  late NightPrayMonthlyStats _monthlyStats;
  List<NightPrayMonthlyDay> _monthHistory = [];

  @override
  void initState() {
    super.initState();

    _checked = List<bool>.from(widget.checked);
    _streak = widget.streak;
    _bestStreak = widget.bestStreak;
    _completedToday = widget.completedToday;
    _weeklyHistory = List<NightPrayWeeklyDay>.from(widget.weeklyHistory);
    _monthlyStats = widget.monthlyStats;
    _loadMonthHistory();
  }

  Future<void> _loadMonthHistory() async {
    final monthHistory =
        await NightPrayTrackingStorage.getCurrentMonthHistory();

    if (!mounted) return;

    setState(() {
      _monthHistory = monthHistory;
    });
  }

  Future<void> _onItemChanged(int index, bool newValue) async {
    if (!widget.canEditTonight) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.editLockedMessage ??
                'اختيارات قيام الليل تفتح من بعد العشاء إلى قبل الفجر.',
            textDirection: TextDirection.rtl,
          ),
        ),
      );
      return;
    }

    final wasCompletedToday = _completedToday;

    setState(() {
      _checked[index] = newValue;
    });

    final allCompleted = _checked.every((value) => value);

    if (allCompleted && !wasCompletedToday) {
      _completedToday = true;
      _streak++;
    }

    if (!allCompleted && wasCompletedToday) {
      _completedToday = false;
      if (_streak > 0) {
        _streak--;
      }
    }

    await NightPrayTrackingStorage.saveTrackingData(
      checked: _checked,
      streak: _streak,
      completedToday: _completedToday,
    );

    final data = await NightPrayTrackingStorage.loadTrackingData();
    final monthHistory =
        await NightPrayTrackingStorage.getCurrentMonthHistory();

    if (!mounted) return;

    setState(() {
      _weeklyHistory = data.weeklyHistory;
      _monthlyStats = data.monthlyStats;
      _bestStreak = data.bestStreak;
      _monthHistory = monthHistory;
    });
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _checked.where((value) => value).length;
    final totalCount = _checked.length;
    final todayRate = totalCount == 0 ? 0.0 : completedCount / totalCount;
    final weeklyCompletedNights =
        _weeklyHistory.where((day) => day.completed).length;
    final weeklyRate = _weeklyHistory.isEmpty ? 0.0 : weeklyCompletedNights / 7;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: const CustomAppBar(
        category: CustomAppBarCategory(
          text: 'تفاصيل قيام الليل',
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: AppLayoutConstants.pageHorizontalPadding,
            vertical: 14.h,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width >= 600
                    ? 760
                    : AppLayoutConstants.mainCardWidth,
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  children: [
                    _MainNightCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const _SectionTitle(
                            title: 'ملخص الليلة',
                            icon: Icons.nights_stay_rounded,
                          ),
                          SizedBox(height: 12.h),
                          Row(
                            children: [
                              Expanded(
                                child: _MiniStatCard(
                                  title: 'خطوات الليلة',
                                  value: '$completedCount / $totalCount',
                                  icon: Icons.check_circle_outline_rounded,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: _MiniStatCard(
                                  title: 'نسبة الليلة',
                                  value: '${(todayRate * 100).round()}%',
                                  icon: Icons.percent_rounded,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              Expanded(
                                child: _MiniStatCard(
                                  title: 'السلسلة الحالية',
                                  value: '$_streak',
                                  icon: Icons.local_fire_department_rounded,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: _MiniStatCard(
                                  title: 'أفضل سلسلة',
                                  value: '$_bestStreak',
                                  icon: Icons.workspace_premium_rounded,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              Expanded(
                                child: _MiniStatCard(
                                  title: 'حالة الليلة',
                                  value:
                                      _completedToday ? 'مكتملة' : 'غير مكتملة',
                                  icon: _completedToday
                                      ? Icons.verified_rounded
                                      : Icons.hourglass_bottom_rounded,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: _MiniStatCard(
                                  title: 'المتبقي',
                                  value: '${totalCount - completedCount}',
                                  icon: Icons.timelapse_rounded,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 14.h),
                    _MainNightCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const _SectionTitle(
                            title: 'مراجعة أعمال الليلة',
                            icon: Icons.fact_check_rounded,
                          ),
                          SizedBox(height: 12.h),
                          if (!widget.canEditTonight) ...[
                            _LockedNotice(
                              message: widget.editLockedMessage ??
                                  'اختيارات قيام الليل تفتح من بعد العشاء إلى قبل الفجر.',
                            ),
                            SizedBox(height: 10.h),
                          ],
                          for (int i = 0; i < widget.items.length; i++)
                            _DetailsCheckRow(
                              text: widget.items[i],
                              value: _checked[i],
                              enabled: widget.canEditTonight,
                              onChanged: (value) => _onItemChanged(i, value),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 14.h),
                    _MainNightCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const _SectionTitle(
                            title: 'إحصائيات الأسبوع والشهر',
                            icon: Icons.insights_rounded,
                          ),
                          SizedBox(height: 12.h),
                          Row(
                            children: [
                              Expanded(
                                child: _MiniStatCard(
                                  title: 'ليالي هذا الأسبوع',
                                  value: '$weeklyCompletedNights / 7',
                                  icon: Icons.calendar_view_week_rounded,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: _MiniStatCard(
                                  title: 'نسبة الأسبوع',
                                  value: '${(weeklyRate * 100).round()}%',
                                  icon: Icons.show_chart_rounded,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              Expanded(
                                child: _MiniStatCard(
                                  title: 'ليالي الشهر',
                                  value: '${_monthlyStats.completedNights}',
                                  icon: Icons.calendar_month_rounded,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: _MiniStatCard(
                                  title: 'أيام بها تقدم',
                                  value:
                                      '${_monthlyStats.nightsWithAnyProgress}',
                                  icon: Icons.done_all_rounded,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 14.h),
                    _MainNightCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const _SectionTitle(
                            title: 'تقويم الشهر',
                            icon: Icons.grid_view_rounded,
                          ),
                          SizedBox(height: 12.h),
                          _MonthGrid(days: _monthHistory),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MainNightCard extends StatelessWidget {
  final Widget child;

  const _MainNightCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final bool large = MediaQuery.sizeOf(context).width >= 600;

    return Container(
      width: large ? double.infinity : AppLayoutConstants.mainCardWidth,
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 12.w,
        vertical: large ? 12 : 12.h,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: AppTextStyles.caption(context)
              .copyWith(fontWeight: FontWeight.w800, color: Colors.white),
        ),
        const Spacer(),
        Icon(
          icon,
          color: Colors.white,
          size: 18.sp,
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bool large = MediaQuery.sizeOf(context).width >= 600;

    return Container(
      constraints: BoxConstraints(
        minHeight: large ? 56 : 60.h,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: large ? 10 : 8.w,
        vertical: large ? 8 : 7.h,
      ),
      decoration: BoxDecoration(
        color: const Color(0xff171B26),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Icon(
            icon,
            color: const Color(0xff21C58E),
            size: large ? 16 : 16.sp,
          ),
          SizedBox(height: large ? 5 : 5.h),
          Text(
            value,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(context)
                .copyWith(fontWeight: FontWeight.w800, color: Colors.white),
          ),
          SizedBox(height: large ? 2 : 2.h),
          Text(
            title,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(context).copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.68)),
          ),
        ],
      ),
    );
  }
}

class _DetailsCheckRow extends StatelessWidget {
  final String text;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  const _DetailsCheckRow({
    required this.text,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: enabled
            ? () {
                AppHaptics.tap(context);
                onChanged(!value);
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 38.h,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: value
                ? Colors.white.withOpacity(0.16)
                : enabled
                    ? const Color(0xff171B26)
                    : Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: value
                  ? const Color(0xff21C58E)
                  : enabled
                      ? Colors.white24
                      : Colors.white.withOpacity(0.10),
              width: 1.w,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: AppTextStyles.caption(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: enabled
                          ? Colors.white
                          : Colors.white.withOpacity(0.42)),
                ),
              ),
              SizedBox(width: 10.w),
              Icon(
                value
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: value
                    ? const Color(0xff21C58E)
                    : enabled
                        ? Colors.white70
                        : Colors.white.withOpacity(0.32),
                size: 20.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockedNotice extends StatelessWidget {
  final String message;

  const _LockedNotice({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 10.w,
        vertical: 9.h,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffffb300).withOpacity(0.12),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: const Color(0xffffb300).withOpacity(0.35),
          width: 0.8.w,
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(
            Icons.lock_clock_rounded,
            color: const Color(0xffffb300),
            size: 17.sp,
          ),
          SizedBox(width: 7.w),
          Expanded(
            child: Text(
              message,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.78)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final List<NightPrayMonthlyDay> days;

  const _MonthGrid({required this.days});

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 7.w,
      runSpacing: 7.h,
      children: days.map((day) {
        final color = day.isFuture
            ? Colors.white.withOpacity(0.06)
            : day.completed
                ? const Color(0xff21C58E)
                : day.checkedCount > 0
                    ? Colors.orange.withOpacity(0.9)
                    : Colors.white.withOpacity(0.16);

        return Container(
          width: 31.w,
          height: 31.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(9.r),
            border: Border.all(
              color:
                  day.isToday ? Colors.white : Colors.white.withOpacity(0.14),
              width: day.isToday ? 1.2.w : 0.6.w,
            ),
          ),
          child: Text(
            '${day.dayNumber}',
            textDirection: TextDirection.ltr,
            style: AppTextStyles.caption(context).copyWith(
                fontWeight: FontWeight.w800,
                color: day.isFuture ? Colors.white38 : Colors.white),
          ),
        );
      }).toList(),
    );
  }
}
