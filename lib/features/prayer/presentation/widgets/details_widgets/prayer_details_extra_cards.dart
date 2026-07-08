import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/features/prayer/data/services/prayer_tracking_storage.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class TodayReviewCard extends StatelessWidget {
  final List<String> prayers;
  final List<bool> checked;
  final bool completedToday;

  const TodayReviewCard({
    super.key,
    required this.prayers,
    required this.checked,
    required this.completedToday,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount = checked.where((value) => value).length;
    final missingCount = checked.length - completedCount;

    return _ExtraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const _ExtraTitle(
            title: 'مراجعة اليوم',
            icon: Icons.fact_check_rounded,
          ),
          SizedBox(height: 10.h),
          _ExtraInfoLine(
            title: 'الصلوات المسجلة',
            value: '$completedCount / ${checked.length}',
          ),
          SizedBox(height: 6.h),
          _ExtraInfoLine(
            title: 'الصلوات غير المسجلة',
            value: '$missingCount',
          ),
          SizedBox(height: 6.h),
          _ExtraInfoLine(
            title: 'حالة اليوم',
            value: completedToday ? 'مكتمل' : 'لم يكتمل بعد',
          ),
        ],
      ),
    );
  }
}

class SmartPrayerAdviceCard extends StatelessWidget {
  final List<String> prayers;
  final List<bool> checked;

  const SmartPrayerAdviceCard({
    super.key,
    required this.prayers,
    required this.checked,
  });

  String _buildAdvice() {
    final firstMissingIndex = checked.indexWhere((value) => !value);

    if (firstMissingIndex == -1) {
      return 'ما شاء الله، يومك مكتمل. حاول تثبيت هذا المستوى يوميًا.';
    }

    final missingPrayer = prayers[firstMissingIndex];

    if (missingPrayer == 'الفجر') {
      return 'حاول النوم مبكرًا وتجهيز المنبه قبل الفجر بوقت كافٍ.';
    }

    if (missingPrayer == 'الظهر' || missingPrayer == 'العصر') {
      return 'اجعل للصلاة وقتًا ثابتًا وسط اليوم حتى لا تضيع مع الانشغال.';
    }

    if (missingPrayer == 'المغرب') {
      return 'وقت المغرب قصير، فحاول أداؤها فور دخول الوقت.';
    }

    if (missingPrayer == 'العشاء') {
      return 'لا تؤخر العشاء كثيرًا حتى لا يغلبك النوم أو التعب.';
    }

    return 'ابدأ بالصلاة التالية، ولا تجعل ما فاتك يمنعك من الاستمرار.';
  }

  @override
  Widget build(BuildContext context) {
    return _ExtraCard(
      child: Row(
        children: [
          Expanded(
            child: Text(
              _buildAdvice(),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.82),
                height: 1.45
),
            ),
          ),
          SizedBox(width: 10.w),
          Icon(
            Icons.tips_and_updates_rounded,
            color: const Color(0xffffb300),
            size: 20.sp,
          ),
        ],
      ),
    );
  }
}

class MonthlyCalendarCard extends StatelessWidget {
  const MonthlyCalendarCard({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PrayerMonthlyDay>>(
      future: PrayerTrackingStorage.getCurrentMonthHistory(),
      builder: (context, snapshot) {
        final days = snapshot.data ?? [];

        return _ExtraCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const _ExtraTitle(
                title: 'تقويم الشهر',
                icon: Icons.calendar_month_rounded,
              ),
              SizedBox(height: 10.h),
              if (snapshot.connectionState == ConnectionState.waiting)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 5.w,
                  runSpacing: 6.h,
                  alignment: WrapAlignment.end,
                  children: days.map((day) {
                    return _MonthDayBox(day: day);
                  }).toList(),
                ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  _LegendItem(
                    title: 'مكتمل',
                    color: const Color(0xff21C58E),
                  ),
                  SizedBox(width: 10.w),
                  _LegendItem(
                    title: 'جزئي',
                    color: Colors.amber,
                  ),
                  const Spacer(),
                  _LegendItem(
                    title: 'بدون تقدم',
                    color: Colors.white24,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class PrayerPatternCard extends StatelessWidget {
  final List<String> prayers;

  const PrayerPatternCard({
    super.key,
    required this.prayers,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PrayerMonthlyDay>>(
      future: PrayerTrackingStorage.getCurrentMonthHistory(),
      builder: (context, snapshot) {
        final days = (snapshot.data ?? [])
            .where((day) => !day.isFuture && day.checkedPrayers.length == prayers.length)
            .toList();

        final completedCounts = List<int>.filled(prayers.length, 0);
        final missedCounts = List<int>.filled(prayers.length, 0);

        for (final day in days) {
          for (int i = 0; i < prayers.length; i++) {
            if (day.checkedPrayers[i]) {
              completedCounts[i]++;
            } else {
              missedCounts[i]++;
            }
          }
        }

        int bestIndex = 0;
        int weakIndex = 0;

        for (int i = 0; i < prayers.length; i++) {
          if (completedCounts[i] > completedCounts[bestIndex]) {
            bestIndex = i;
          }

          if (missedCounts[i] > missedCounts[weakIndex]) {
            weakIndex = i;
          }
        }

        final hasData = days.any((day) => day.checkedCount > 0);

        return _ExtraCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const _ExtraTitle(
                title: 'تحليل صلاتك',
                icon: Icons.insights_rounded,
              ),
              SizedBox(height: 10.h),
              if (snapshot.connectionState == ConnectionState.waiting)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                )
              else if (!hasData)
                Text(
                  'ابدأ بتسجيل صلواتك لعرض تحليل أدق خلال الشهر.',
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.75),
                    height: 1.4
),
                )
              else ...[
                  _ExtraInfoLine(
                    title: 'أكثر صلاة ملتزم بها',
                    value: prayers[bestIndex],
                  ),
                  SizedBox(height: 6.h),
                  _ExtraInfoLine(
                    title: 'أكثر صلاة تحتاج انتباه',
                    value: prayers[weakIndex],
                  ),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _ExtraCard extends StatelessWidget {
  final Widget child;

  const _ExtraCard({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: child,
    );
  }
}

class _ExtraTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _ExtraTitle({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Text(
          title,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
            color: Colors.white
),
        ),
        const Spacer(),
        Icon(
          icon,
          color: const Color(0xff21C58E),
          size: 18.sp,
        ),
      ],
    );
  }
}

class _ExtraInfoLine extends StatelessWidget {
  final String title;
  final String value;

  const _ExtraInfoLine({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        color: const Color(0xff171B26),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Text(
            title,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w600,
              color: Colors.white
),
          ),
          const Spacer(),
          Text(
            value,
            textAlign: TextAlign.left,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
              color: const Color(0xff21C58E)
),
          ),
        ],
      ),
    );
  }
}

class _MonthDayBox extends StatelessWidget {
  final PrayerMonthlyDay day;

  const _MonthDayBox({
    required this.day,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;

    if (day.isFuture) {
      color = Colors.white.withOpacity(0.06);
    } else if (day.completed) {
      color = const Color(0xff21C58E);
    } else if (day.checkedCount > 0) {
      color = Colors.amber;
    } else {
      color = Colors.white.withOpacity(0.16);
    }

    return Container(
      width: 24.w,
      height: 24.w,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(7.r),
        border: Border.all(
          color: day.isToday ? Colors.white : Colors.white.withOpacity(0.12),
          width: day.isToday ? 1.2.w : 0.6.w,
        ),
      ),
      child: Center(
        child: Text(
          '${day.dayNumber}',
          style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
            color: day.isFuture ? Colors.white30 : Colors.white
),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String title;
  final Color color;

  const _LegendItem({
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          textDirection: TextDirection.rtl,
          style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.72)
),
        ),
        SizedBox(width: 4.w),
        Container(
          width: 10.w,
          height: 10.w,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}