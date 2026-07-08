import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_active_plan_model.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_session_result_model.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_today_task_model.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_plan_journey_engine.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_plan_storage.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_session_result_storage.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/memorization_help_button.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/current_plan/current_plan_hero_data.dart';
import 'package:islamic_app/features/quran/reader/quran_reader_helpers.dart';

class MasteryHeroCard extends StatelessWidget {
  const MasteryHeroCard({super.key});

  // مكان تعديل ارتفاع الهيرو كله.
  // الصورة بقت جوه الكارت نفسه، فلو عايز تكبر أو تصغر الهيرو غير الرقمين دول.
  static double _heroCardHeight(BuildContext context) {
    final double screenHeight = MediaQuery.sizeOf(context).height;
    return screenHeight >= 820 ? 260.h : 300.h;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<_MasteryHeroData>(
      future: _MasteryHeroData.load(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? const _MasteryHeroData.loading();

        return SizedBox(
          width: double.infinity,
          height: _heroCardHeight(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30.r),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/quraan/memorization_hero.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.centerLeft,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFF061A33),
                                theme.colorScheme.primary,
                                const Color(0xFF061A33),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // جريدينت ناحية الكلام فقط، علشان النص يبقى واضح
                      // والصورة تفضل باينة ناحية الشمال.
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.black.withOpacity(0.00),
                                theme.colorScheme.primary.withOpacity(0.08),
                                theme.colorScheme.primary.withOpacity(0.44),
                                const Color(0xFF061A33).withOpacity(0.88),
                              ],
                              stops: const [0.0, 0.38, 0.70, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // جريدينت بسيط فوق وتحت من غير شادو خارجي.
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.10),
                                Colors.black.withOpacity(0.00),
                                const Color(0xFF061A33).withOpacity(0.18),
                                const Color(0xFF061A33).withOpacity(0.42),
                              ],
                              stops: const [0.0, 0.42, 0.78, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // زر علامة الاستفهام موجود جوه الهيرو بدل AppBar.
                      Positioned(
                        top: 14.h,
                        left: 14.w,
                        child: const MemorizationHelpButton(heroStyle: true),
                      ),

                      Positioned(
                        top: 22.h,
                        right: 18.w,
                        left: 68.w,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'رحلة الإتقان',
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.headline(context).copyWith(
                                color: Colors.white,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w900,
                                height: 1.05,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            SizedBox(
                              width: 210.w,
                              child: Text(
                                data.subtitle,
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.right,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption(context).copyWith(
                                  color: Colors.white.withOpacity(0.78),
                                  fontSize: 8.8.sp,
                                  fontWeight: FontWeight.w600,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Positioned(
                        right: 18.w,
                        bottom: 17.h,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 101.w,
                              height: 101.w,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 94.w,
                                    height: 94.w,
                                    child: CircularProgressIndicator(
                                      value: data.masteryProgress,
                                      strokeWidth: 5.w,
                                      backgroundColor: Colors.white.withOpacity(
                                        0.24,
                                      ),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                      strokeCap: StrokeCap.round,
                                    ),
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${data.masteryPercent}%',
                                        textDirection: TextDirection.ltr,
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.headline(context)
                                            .copyWith(
                                              color: Colors.white,
                                              fontSize: 22.sp,
                                              fontWeight: FontWeight.w900,
                                              height: 1.1,
                                            ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        'الإتقان العام',
                                        textDirection: TextDirection.rtl,
                                        textAlign: TextAlign.center,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.caption(context)
                                            .copyWith(
                                              color: Colors.white.withOpacity(
                                                0.76,
                                              ),
                                              fontSize: 7.4.sp,
                                              fontWeight: FontWeight.w600,
                                              height: 1,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 10.h),
                            SizedBox(
                              width: 190.w,
                              child: Text(
                                data.dayText,
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.right,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption(context).copyWith(
                                  color: Colors.white.withOpacity(0.72),
                                  fontSize: 9.4.sp,
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            SizedBox(height: 5.h),
                            SizedBox(
                              width: 210.w,
                              child: Text(
                                data.surahText,
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.right,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.headline(context).copyWith(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w800,
                                  height: 1.16,
                                ),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            SizedBox(
                              width: 190.w,
                              child: Text(
                                data.ayahRangeText,
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.right,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption(context).copyWith(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 9.2.sp,
                                  fontWeight: FontWeight.w600,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _PartialHeroBorderPainter(
                      color: Colors.white.withOpacity(0.42),
                      radius: 30.r,
                      strokeWidth: 1.05.w,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MasteryHeroData {
  const _MasteryHeroData({
    required this.masteryPercent,
    required this.dayText,
    required this.surahText,
    required this.ayahRangeText,
    required this.subtitle,
  });

  const _MasteryHeroData.loading()
    : masteryPercent = 0,
      dayText = 'جاري تجهيز الخطة',
      surahText = 'حلقة الحفظ',
      ayahRangeText = 'انتظر لحظة...',
      subtitle = 'نجهز بيانات رحلة الحفظ من خطتك الحالية.';

  final int masteryPercent;
  final String dayText;
  final String surahText;
  final String ayahRangeText;
  final String subtitle;

  double get masteryProgress {
    return (masteryPercent / 100).clamp(0.0, 1.0).toDouble();
  }

  static Future<_MasteryHeroData> load() async {
    final activePlan = await MemorizationPlanStorage.getActivePlan();

    if (activePlan == null || !activePlan.hasValidScopeRange) {
      return const _MasteryHeroData(
        masteryPercent: 0,
        dayText: 'لم تبدأ الخطة بعد',
        surahText: 'رحلة الإتقان',
        ayahRangeText: 'أنشئ خطة الحفظ من الزر المخصص لاحقًا',
        subtitle:
            'ابدأ خطة مناسبة لك، وسنرتب الحفظ والمراجعة والاختبار تلقائيًا.',
      );
    }

    final activeTask = await MemorizationPlanStorage.getTodayTask();
    final results = await MemorizationSessionResultStorage.getResults();
    final timelineData = await CurrentPlanHeroData.load();

    if (timelineData?.plan.id == activePlan.id && timelineData!.isCompleted) {
      return _MasteryHeroData(
        masteryPercent: 100,
        dayText: 'تم إتمام خطة الحفظ',
        surahText: timelineData.rangeLabel,
        ayahRangeText: '100%',
        subtitle:
            'بارك الله فيك، أتممت الخطة بنجاح. يمكنك عرض الشهادة أو بدء خطة جديدة.',
      );
    }

    final displayTask = await _resolveDisplayTask(
      plan: activePlan,
      activeTask: activeTask,
    );

    final range = _rangeTextFor(
      startGlobalAyahIndex:
          displayTask?.startGlobalAyahIndex ??
          activePlan.scopeStartGlobalAyahIndex,
      endGlobalAyahIndex:
          displayTask?.endGlobalAyahIndex ?? activePlan.scopeEndGlobalAyahIndex,
    );

    final totalPlanDays = timelineData?.plan.id == activePlan.id
        ? timelineData!.timelineSummary?.effectiveCalendarDays ??
              timelineData.plan.effectiveCalendarDays
        : _totalPlanDays(activePlan);
    final currentDay = _currentPlanDay(activePlan, totalPlanDays);
    final masteryPercent = _overallMasteryPercent(
      plan: activePlan,
      results: results,
    );

    return _MasteryHeroData(
      masteryPercent: masteryPercent,
      dayText: timelineData?.plan.id == activePlan.id
          ? timelineData!.currentPlanDayLabel
          : totalPlanDays > 1
          ? 'اليوم $currentDay من $totalPlanDays'
          : 'اليوم $currentDay من الخطة',
      surahText: range.surahText,
      ayahRangeText:
          '${(displayTask?.ayahsCount ?? activePlan.totalAyahs).clamp(0, 99999)} آية',
      subtitle:
          '${_subtitleFor(task: displayTask, plan: activePlan)} '
          'مدة الحفظ: ${activePlan.targetLearningDays} يوم • '
          'مدة الخطة الفعلية: $totalPlanDays يوم',
    );
  }

  static Future<MemorizationTodayTaskModel?> _resolveDisplayTask({
    required MemorizationActivePlanModel plan,
    required MemorizationTodayTaskModel? activeTask,
  }) async {
    final today = _dateOnly(DateTime.now());
    final candidates = <MemorizationTodayTaskModel>[];

    final lookAheadDays = (_totalPlanDays(plan) + 45).clamp(30, 2200).toInt();
    final journeyTasks = await const MemorizationPlanJourneyEngine()
        .buildJourneyTasks(
          plan: plan,
          activeTask: activeTask,
          daysAhead: lookAheadDays,
        );

    final todayJourneyTasks =
        journeyTasks.where((item) {
          if (!_sameDay(_dateOnly(item.date), today)) return false;
          if (!item.task.hasValidRange) return false;

          final taskDay = _dateOnly(item.task.effectiveScheduledDate);
          if (item.task.type == 'selfTest') {
            return _sameDay(taskDay, today) && !item.task.isFutureTask;
          }

          return !item.task.isFutureTask;
        }).toList()..sort((a, b) {
          final priority = a.priority.compareTo(b.priority);
          if (priority != 0) return priority;
          return a.date.compareTo(b.date);
        });

    for (final item in todayJourneyTasks) {
      candidates.add(item.task);
    }

    if (candidates.isEmpty &&
        activeTask != null &&
        activeTask.hasValidRange &&
        !activeTask.isFutureTask &&
        _sameDay(_dateOnly(activeTask.effectiveScheduledDate), today)) {
      candidates.add(activeTask);
    }

    if (candidates.isEmpty) return null;

    final dailyNew = _firstTaskOfType(candidates, 'dailyNew');
    if (dailyNew != null) return dailyNew;

    final dailyReview = _firstTaskOfType(candidates, 'dailyReview');
    if (dailyReview != null) return dailyReview;

    return candidates.first;
  }

  static MemorizationTodayTaskModel? _firstTaskOfType(
    List<MemorizationTodayTaskModel> tasks,
    String type,
  ) {
    for (final task in tasks) {
      if (task.type == type) return task;
    }

    return null;
  }

  static int _overallMasteryPercent({
    required MemorizationActivePlanModel plan,
    required List<MemorizationSessionResultModel> results,
  }) {
    final planResults = results.where((result) {
      if (result.completedAt.isBefore(plan.createdAt)) return false;

      final overlapsMainRange =
          result.endGlobalAyahIndex >= plan.scopeStartGlobalAyahIndex &&
          result.startGlobalAyahIndex <= plan.scopeEndGlobalAyahIndex;

      final overlapsReviewRange =
          plan.hasValidReviewRange &&
          result.endGlobalAyahIndex >= plan.reviewStartGlobalAyahIndex &&
          result.startGlobalAyahIndex <= plan.reviewEndGlobalAyahIndex;

      return overlapsMainRange || overlapsReviewRange;
    }).toList();

    if (planResults.isEmpty) return 0;

    final score = planResults.fold<int>(0, (sum, result) {
      return sum + _ratingScore(result.rating);
    });

    return (score / planResults.length).round().clamp(0, 100).toInt();
  }

  static int _ratingScore(String rating) {
    switch (rating) {
      case 'easy':
        return 100;
      case 'good':
        return 75;
      case 'hard':
        return 40;
      case 'forgot':
        return 15;
      default:
        return 70;
    }
  }

  static String _subtitleFor({
    required MemorizationTodayTaskModel? task,
    required MemorizationActivePlanModel plan,
  }) {
    if (task == null) {
      return 'استمر بثقة، وسنجهز المهمة التالية حسب تقدمك الحقيقي.';
    }

    if (task.type == 'selfTest') {
      return 'اختبار اليوم جاهز لتثبيت ما حفظته داخل الخطة.';
    }

    if (task.type == 'dailyReview') {
      return 'راجع بهدوء، التثبيت اليوم أهم من السرعة.';
    }

    return 'استمر بثقة، كل خطوة تقرّبك من رضا الله';
  }

  static int _totalPlanDays(MemorizationActivePlanModel plan) {
    return math.max(1, plan.effectiveCalendarDays);
  }

  static int _currentPlanDay(
    MemorizationActivePlanModel plan,
    int totalPlanDays,
  ) {
    final start = _dateOnly(plan.createdAt);
    final today = _dateOnly(DateTime.now());
    final day = today.difference(start).inDays + 1;
    return day.clamp(1, math.max(1, totalPlanDays)).toInt();
  }

  static _ResolvedRangeText _rangeTextFor({
    required int startGlobalAyahIndex,
    required int endGlobalAyahIndex,
  }) {
    final maxAyahIndex = QuranReaderHelpers.totalAyahs - 1;
    final startIndex = startGlobalAyahIndex.clamp(0, maxAyahIndex).toInt();
    final endIndex = endGlobalAyahIndex.clamp(startIndex, maxAyahIndex).toInt();

    final start = QuranReaderHelpers.getPositionFromGlobalIndex(startIndex);
    final end = QuranReaderHelpers.getPositionFromGlobalIndex(endIndex);

    final startSurahName = QuranReaderHelpers.getSuraName(start.suraIndex);
    final endSurahName = QuranReaderHelpers.getSuraName(end.suraIndex);
    final startAyah = start.ayahIndex + 1;
    final endAyah = end.ayahIndex + 1;

    if (start.suraIndex == end.suraIndex) {
      final range = startAyah == endAyah
          ? 'آية $startAyah'
          : 'من آية $startAyah إلى $endAyah';

      return _ResolvedRangeText(
        surahText: 'سورة $startSurahName',
        ayahRangeText: range,
      );
    }

    return _ResolvedRangeText(
      surahText: 'من $startSurahName إلى $endSurahName',
      ayahRangeText: 'من آية $startAyah إلى آية $endAyah',
    );
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _ResolvedRangeText {
  const _ResolvedRangeText({
    required this.surahText,
    required this.ayahRangeText,
  });

  final String surahText;
  final String ayahRangeText;
}

class _PartialHeroBorderPainter extends CustomPainter {
  const _PartialHeroBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  final Color color;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final double r = radius;
    final double w = size.width;
    final double h = size.height;

    final Path path = Path()
      // الجزء الظاهر من أعلى اليمين.
      ..moveTo(w * 0.50, 0)
      ..lineTo(w - r, 0)
      ..quadraticBezierTo(w, 0, w, r)
      // اليمين كامل ظاهر.
      ..lineTo(w, h - r)
      ..quadraticBezierTo(w, h, w - r, h)
      // ربع البوردر من تحت ناحية اليمين فقط.
      ..lineTo(w * 0.73, h);

    canvas.drawPath(path, paint);

    final Path softTop = Path()
      ..moveTo(w * 0.58, 0)
      ..lineTo(w * 0.82, 0);

    canvas.drawPath(softTop, paint..color = color.withOpacity(0.24));
  }

  @override
  bool shouldRepaint(covariant _PartialHeroBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
