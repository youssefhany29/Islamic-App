import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/features/memorization/data/models/memorization_session_result_model.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_session_result_storage.dart';
import 'mastery_base_card.dart';
import 'mastery_stat_box.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class MasteryProgressCard extends StatefulWidget {
  const MasteryProgressCard({super.key});

  @override
  State<MasteryProgressCard> createState() => _MasteryProgressCardState();
}

class _MasteryProgressCardState extends State<MasteryProgressCard> {
  Future<_MasteryProgressData>? progressFuture;
  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();

    _refreshProgress();

    // تحديث خفيف أثناء وجود الكارت على الصفحة.
    // الهدف: بعد الرجوع من جلسة الإتقان أو الاختبار، الأرقام تتحدث بدون الخروج من الصفحة.
    refreshTimer = Timer.periodic(
      const Duration(seconds: 2),
          (_) => _refreshProgress(),
    );
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  void _refreshProgress() {
    if (!mounted) return;

    setState(() {
      progressFuture = _loadProgress();
    });
  }

  Future<_MasteryProgressData> _loadProgress() async {
    final allResults = await MemorizationSessionResultStorage.getResults();

    if (allResults.isEmpty) {
      return const _MasteryProgressData.empty();
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(const Duration(days: 6));

    final weeklyResults = allResults.where((result) {
      final date = DateTime(
        result.completedAt.year,
        result.completedAt.month,
        result.completedAt.day,
      );

      return !date.isBefore(weekStart) && !date.isAfter(today);
    }).toList();

    if (weeklyResults.isEmpty) {
      final lastResult = allResults.first;

      return _MasteryProgressData(
        completedSessions: 0,
        completedAyahs: 0,
        weakCount: 0,
        rescueSessionsCount: 0,
        testSessionsCount: 0,
        masteryPercent: 0,
        totalMinutes: 0,
        lastRating: lastResult.rating,
        lastSessionDate: lastResult.completedAt,
        activeDaysCount: 0,
        bestDayText: 'لا توجد جلسات هذا الأسبوع',
        summaryText: 'آخر جلسة كانت ${_ratingText(lastResult.rating)}.',
      );
    }

    final completedSessions = weeklyResults.length;

    final learningResults = weeklyResults.where((result) {
      return result.taskType != 'selfTest';
    }).toList();

    final completedAyahs = learningResults.fold<int>(
      0,
          (sum, result) => sum + math.max(0, result.ayahsCount),
    );

    final weakCount = weeklyResults.where((result) {
      return result.needsRescueReview ||
          result.rating == 'hard' ||
          result.rating == 'forgot';
    }).length;

    final rescueSessionsCount = weeklyResults.where((result) {
      return result.taskType == 'weakReview';
    }).length;

    final testSessionsCount = weeklyResults.where((result) {
      return result.taskType == 'selfTest';
    }).length;

    final easyCount = weeklyResults.where((result) => result.rating == 'easy').length;
    final goodCount = weeklyResults.where((result) => result.rating == 'good').length;
    final hardCount = weeklyResults.where((result) => result.rating == 'hard').length;
    final forgotCount = weeklyResults.where((result) => result.rating == 'forgot').length;

    final masteryScore = completedSessions <= 0
        ? 0
        : (((easyCount * 100) +
        (goodCount * 75) +
        (hardCount * 40) +
        (forgotCount * 15)) /
        completedSessions)
        .round()
        .clamp(0, 100);

    final totalMinutes = weeklyResults.fold<int>(
      0,
          (sum, result) => sum + math.max(0, result.actualMinutes),
    );

    final activeDays = <String, int>{};

    for (final result in weeklyResults) {
      final date = DateTime(
        result.completedAt.year,
        result.completedAt.month,
        result.completedAt.day,
      );

      final key = '${date.year}-${date.month}-${date.day}';
      activeDays[key] = (activeDays[key] ?? 0) + math.max(0, result.ayahsCount);
    }

    final activeDaysCount = activeDays.length;
    final bestDayAyahs = activeDays.values.isEmpty
        ? 0
        : activeDays.values.reduce(math.max);

    final lastResult = weeklyResults.first;

    final summaryText = _buildSummaryText(
      sessions: completedSessions,
      weakCount: weakCount,
      rescueSessionsCount: rescueSessionsCount,
      testSessionsCount: testSessionsCount,
      masteryPercent: masteryScore,
    );

    return _MasteryProgressData(
      completedSessions: completedSessions,
      completedAyahs: completedAyahs,
      weakCount: weakCount,
      rescueSessionsCount: rescueSessionsCount,
      testSessionsCount: testSessionsCount,
      masteryPercent: masteryScore,
      totalMinutes: totalMinutes,
      lastRating: lastResult.rating,
      lastSessionDate: lastResult.completedAt,
      activeDaysCount: activeDaysCount,
      bestDayText: bestDayAyahs <= 0
          ? 'لا يوجد يوم بارز بعد'
          : 'أفضل يوم: $bestDayAyahs آية',
      summaryText: summaryText,
    );
  }

  static String _ratingText(String rating) {
    switch (rating) {
      case 'easy':
        return 'سهلة';
      case 'good':
        return 'جيدة';
      case 'hard':
        return 'صعبة';
      case 'forgot':
        return 'منسية';
      default:
        return 'محفوظة';
    }
  }

  String _buildSummaryText({
    required int sessions,
    required int weakCount,
    required int rescueSessionsCount,
    required int testSessionsCount,
    required int masteryPercent,
  }) {
    if (sessions <= 0) {
      return 'ابدأ جلسة هذا الأسبوع حتى يظهر الملخص.';
    }

    if (testSessionsCount > 0 && weakCount == 0 && masteryPercent >= 75) {
      return 'أسبوع قوي: حفظ مستقر واختبارات تثبيت بدون مواضع ضعيفة.';
    }

    if (testSessionsCount > 0 && weakCount > 0) {
      return 'عملت $testSessionsCount اختبار هذا الأسبوع، وفيه $weakCount موضع يحتاج تثبيتًا.';
    }

    if (weakCount == 0 && masteryPercent >= 75) {
      return 'أسبوع ممتاز، أغلب الجلسات مستقرة ولا توجد مواضع ضعيفة.';
    }

    if (rescueSessionsCount > 0 && weakCount <= rescueSessionsCount) {
      return 'فيه تحسن واضح؛ جلسات الإنقاذ بدأت تقلل المواضع الضعيفة.';
    }

    if (weakCount > 0) {
      return 'فيه $weakCount موضع يحتاج تثبيتًا. لا تقلق، الإنقاذ هيرجعه قريبًا.';
    }

    return 'استمر بنفس الهدوء، التقدم الأسبوعي بدأ يظهر بوضوح.';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_MasteryProgressData>(
      future: progressFuture,
      builder: (context, snapshot) {
        final data = snapshot.data ?? const _MasteryProgressData.empty();

        return MasteryBaseCard(
          icon: Icons.insights_rounded,
          title: 'ملخص آخر ٧ أيام',
          subtitle: data.completedSessions == 0
              ? 'ابدأ أول جلسة هذا الأسبوع حتى تظهر الإحصائيات الحقيقية.'
              : data.summaryText,
          badgeText: data.completedSessions == 0
              ? 'ابدأ'
              : '${data.completedSessions} جلسة',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: MasteryStatBox(
                      value: '${data.masteryPercent}%',
                      label: 'الإتقان',
                      icon: Icons.verified_rounded,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: MasteryStatBox(
                      value: '${data.completedAyahs}',
                      label: 'آيات',
                      icon: Icons.menu_book_rounded,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: MasteryStatBox(
                      value: '${data.weakCount}',
                      label: 'ضعيف',
                      icon: Icons.warning_amber_rounded,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    child: MasteryStatBox(
                      value: '${data.activeDaysCount}',
                      label: 'أيام',
                      icon: Icons.local_fire_department_rounded,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: MasteryStatBox(
                      value: '${data.testSessionsCount}',
                      label: 'اختبارات',
                      icon: Icons.fact_check_rounded,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: MasteryStatBox(
                      value: '${data.rescueSessionsCount}',
                      label: 'إنقاذ',
                      icon: Icons.healing_rounded,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    child: MasteryStatBox(
                      value: _shortMinutes(data.totalMinutes),
                      label: 'وقت',
                      icon: Icons.timer_rounded,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    flex: 2,
                    child: _ProgressMiniLine(
                      icon: Icons.auto_graph_rounded,
                      text: data.completedSessions == 0
                          ? 'ابدأ جلسة حتى يظهر أفضل يوم.'
                          : data.bestDayText,
                    ),
                  ),
                ],
              ),
              if (data.completedSessions > 0) ...[
                SizedBox(height: 10.h),
                _ProgressDetailsLine(data: data),
              ],
            ],
          ),
        );
      },
    );
  }

  String _shortMinutes(int minutes) {
    if (minutes <= 0) return '0د';
    if (minutes < 60) return '${minutes}د';

    final hours = minutes ~/ 60;
    final remaining = minutes % 60;

    if (remaining == 0) return '${hours}س';

    return '${hours}س';
  }
}

class _ProgressMiniLine extends StatelessWidget {
  const _ProgressMiniLine({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 62.h,
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.background.withOpacity(0.34),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.10),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 18.sp,
          ),
          SizedBox(width: 7.w),
          Expanded(
            child: Text(
              text,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w700,
                color: theme.colorScheme.surface.withOpacity(0.62),
                height: 1.3
),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressDetailsLine extends StatelessWidget {
  const _ProgressDetailsLine({
    required this.data,
  });

  final _MasteryProgressData data;

  String get _lastRatingText {
    switch (data.lastRating) {
      case 'easy':
        return 'آخر تقييم: سهل';
      case 'good':
        return 'آخر تقييم: جيد';
      case 'hard':
        return 'آخر تقييم: صعب';
      case 'forgot':
        return 'آخر تقييم: نسيت';
      default:
        return 'آخر تقييم محفوظ';
    }
  }

  String get _minutesText {
    if (data.totalMinutes <= 0) return 'وقت غير محسوب';
    if (data.totalMinutes < 60) return '${data.totalMinutes} دقيقة تدريب';

    final hours = data.totalMinutes ~/ 60;
    final minutes = data.totalMinutes % 60;

    if (minutes == 0) return '$hours ساعة تدريب';

    return '$hours ساعة و $minutes دقيقة تدريب';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.10),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(
            Icons.fact_check_rounded,
            color: theme.colorScheme.primary,
            size: 18.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              '$_lastRatingText • $_minutesText • ${data.testSessionsCount} اختبار هذا الأسبوع',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w700,
                color: theme.colorScheme.surface.withOpacity(0.64),
                height: 1.38
),
            ),
          ),
        ],
      ),
    );
  }
}

class _MasteryProgressData {
  final int completedSessions;
  final int completedAyahs;
  final int weakCount;
  final int rescueSessionsCount;
  final int testSessionsCount;
  final int masteryPercent;
  final int totalMinutes;
  final String lastRating;
  final DateTime? lastSessionDate;
  final int activeDaysCount;
  final String bestDayText;
  final String summaryText;

  const _MasteryProgressData({
    required this.completedSessions,
    required this.completedAyahs,
    required this.weakCount,
    required this.rescueSessionsCount,
    required this.testSessionsCount,
    required this.masteryPercent,
    required this.totalMinutes,
    required this.lastRating,
    required this.lastSessionDate,
    required this.activeDaysCount,
    required this.bestDayText,
    required this.summaryText,
  });

  const _MasteryProgressData.empty()
      : completedSessions = 0,
        completedAyahs = 0,
        weakCount = 0,
        rescueSessionsCount = 0,
        testSessionsCount = 0,
        masteryPercent = 0,
        totalMinutes = 0,
        lastRating = '',
        lastSessionDate = null,
        activeDaysCount = 0,
        bestDayText = 'لا يوجد يوم بارز بعد',
        summaryText = 'ابدأ جلسة هذا الأسبوع حتى يظهر الملخص.';
}
