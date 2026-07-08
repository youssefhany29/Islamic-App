import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../quran/memorization/services/quran_memorization_progress_storage.dart';
import '../../../quran/reader/quran_page_mapper.dart';
import '../../../quran/reader/quran_reader_helpers.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_today_task_model.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class MemorizationTaskProgressCard extends StatelessWidget {
  const MemorizationTaskProgressCard({
    super.key,
    required this.task,
  });

  final MemorizationTodayTaskModel task;

  Future<_TaskProgressData> _loadProgress() async {
    await QuranPageMapper.load();

    final savedProgress =
    await QuranMemorizationProgressStorage.getProgress(task.id);

    final int safeStart = task.startGlobalAyahIndex.clamp(
      0,
      QuranReaderHelpers.totalAyahs - 1,
    );

    final int safeEnd = task.endGlobalAyahIndex.clamp(
      safeStart,
      QuranReaderHelpers.totalAyahs - 1,
    );

    final int totalAyahs = (safeEnd - safeStart + 1).clamp(0, 100000).toInt();

    final _TaskRangeData rangeData = _TaskRangeData.fromRange(
      startGlobalAyahIndex: safeStart,
      endGlobalAyahIndex: safeEnd,
      taskType: task.type,
    );

    if (savedProgress == null || !task.hasValidRange || totalAyahs <= 0) {
      return _TaskProgressData(
        hasStarted: false,
        currentGlobalAyahIndex: safeStart,
        completedAyahs: 0,
        remainingAyahs: totalAyahs,
        totalAyahs: totalAyahs,
        progressPercent: 0,
        currentAyahText: rangeData.startText,
        rangeData: rangeData,
      );
    }

    final int safeCurrentGlobalAyahIndex = savedProgress.globalAyahIndex.clamp(
      safeStart,
      safeEnd,
    ).toInt();

    final int completedAyahs =
    (safeCurrentGlobalAyahIndex - safeStart + 1)
        .clamp(0, totalAyahs)
        .toInt();

    final int remainingAyahs =
    (totalAyahs - completedAyahs).clamp(0, totalAyahs).toInt();

    final int progressPercent = totalAyahs <= 0
        ? 0
        : ((completedAyahs / totalAyahs) * 100).round().clamp(0, 100).toInt();

    final position = QuranReaderHelpers.getPositionFromGlobalIndex(
      safeCurrentGlobalAyahIndex,
    );

    final surahName = QuranReaderHelpers.getSuraName(position.suraIndex);

    return _TaskProgressData(
      hasStarted: true,
      currentGlobalAyahIndex: safeCurrentGlobalAyahIndex,
      completedAyahs: completedAyahs,
      remainingAyahs: remainingAyahs,
      totalAyahs: totalAyahs,
      progressPercent: progressPercent,
      currentAyahText: 'سورة $surahName • آية ${position.ayahIndex + 1}',
      rangeData: rangeData,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TaskProgressData>(
      future: _loadProgress(),
      builder: (context, snapshot) {
        final fallbackTotal = (task.endGlobalAyahIndex -
            task.startGlobalAyahIndex +
            1)
            .clamp(0, 100000)
            .toInt();

        final data = snapshot.data ??
            _TaskProgressData(
              hasStarted: false,
              currentGlobalAyahIndex: task.startGlobalAyahIndex,
              completedAyahs: 0,
              remainingAyahs: fallbackTotal,
              totalAyahs: fallbackTotal,
              progressPercent: 0,
              currentAyahText: 'جارٍ تحميل الموضع...',
              rangeData: const _TaskRangeData.empty(),
            );

        return _TaskProgressCardContent(data: data);
      },
    );
  }
}

class _TaskProgressCardContent extends StatelessWidget {
  const _TaskProgressCardContent({
    required this.data,
  });

  final _TaskProgressData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(13.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
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
                  Icons.bookmark_added_rounded,
                  color: theme.colorScheme.primary,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Expanded(
                          child: Text(
                            'موضعك داخل المهمة',
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
                              color: theme.colorScheme.surface,
                              height: 1.25
),
                          ),
                        ),
                        SizedBox(width: 7.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(30.r),
                          ),
                          child: Text(
                            data.rangeData.taskTypeText,
                            textDirection: TextDirection.rtl,
                            style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
                              color: theme.colorScheme.primary,
                              height: 1
),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      data.hasStarted
                          ? 'وقفت عند: ${data.currentAyahText}'
                          : 'البداية: ${data.currentAyahText}',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w600,
                        color: theme.colorScheme.surface.withOpacity(0.58),
                        height: 1.4
),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 11.h),
          _TaskRangeSummary(rangeData: data.rangeData),
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(99.r),
            child: LinearProgressIndicator(
              value: data.progressPercent / 100,
              minHeight: 7.h,
              backgroundColor: theme.colorScheme.background.withOpacity(0.55),
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _MiniProgressBox(
                  value: '${data.completedAyahs}',
                  label: 'أنجزت',
                  icon: Icons.check_circle_rounded,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _MiniProgressBox(
                  value: '${data.remainingAyahs}',
                  label: 'متبقي',
                  icon: Icons.timelapse_rounded,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _MiniProgressBox(
                  value: '${data.progressPercent}%',
                  label: 'التقدم',
                  icon: Icons.trending_up_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskRangeSummary extends StatelessWidget {
  const _TaskRangeSummary({
    required this.rangeData,
  });

  final _TaskRangeData rangeData;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.065),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            rangeData.rangeText,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
              color: theme.colorScheme.surface.withOpacity(0.70),
              height: 1.4
),
          ),
          SizedBox(height: 9.h),
          Row(
            children: [
              Expanded(
                child: _MiniProgressBox(
                  value: '${rangeData.totalAyahs}',
                  label: 'آية عليك',
                  icon: Icons.format_list_numbered_rtl_rounded,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _MiniProgressBox(
                  value: '${rangeData.pagesCount}',
                  label: 'صفحة تقريبًا',
                  icon: Icons.auto_stories_rounded,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _MiniProgressBox(
                  value: '${rangeData.surahsCount}',
                  label: 'سورة',
                  icon: Icons.book_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniProgressBox extends StatelessWidget {
  const _MiniProgressBox({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.background.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.10),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 17.sp,
          ),
          SizedBox(height: 5.h),
          Text(
            value,
            textDirection: TextDirection.rtl,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
              color: theme.colorScheme.surface,
              height: 1
),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w700,
              color: theme.colorScheme.surface.withOpacity(0.55),
              height: 1
),
          ),
        ],
      ),
    );
  }
}

class _TaskProgressData {
  final bool hasStarted;
  final int currentGlobalAyahIndex;
  final int completedAyahs;
  final int remainingAyahs;
  final int totalAyahs;
  final int progressPercent;
  final String currentAyahText;
  final _TaskRangeData rangeData;

  const _TaskProgressData({
    required this.hasStarted,
    required this.currentGlobalAyahIndex,
    required this.completedAyahs,
    required this.remainingAyahs,
    required this.totalAyahs,
    required this.progressPercent,
    required this.currentAyahText,
    required this.rangeData,
  });
}

class _TaskRangeData {
  final String rangeText;
  final String startText;
  final int totalAyahs;
  final int pagesCount;
  final int surahsCount;
  final String taskTypeText;

  const _TaskRangeData({
    required this.rangeText,
    required this.startText,
    required this.totalAyahs,
    required this.pagesCount,
    required this.surahsCount,
    required this.taskTypeText,
  });

  const _TaskRangeData.empty()
      : rangeText = 'جارٍ تحميل نطاق المهمة...',
        startText = 'جارٍ تحميل الموضع...',
        totalAyahs = 0,
        pagesCount = 0,
        surahsCount = 0,
        taskTypeText = 'مهمة';

  factory _TaskRangeData.fromRange({
    required int startGlobalAyahIndex,
    required int endGlobalAyahIndex,
    required String taskType,
  }) {
    final int safeStart = startGlobalAyahIndex.clamp(
      0,
      QuranReaderHelpers.totalAyahs - 1,
    );

    final int safeEnd = endGlobalAyahIndex.clamp(
      safeStart,
      QuranReaderHelpers.totalAyahs - 1,
    );

    final startPosition = QuranReaderHelpers.getPositionFromGlobalIndex(
      safeStart,
    );

    final endPosition = QuranReaderHelpers.getPositionFromGlobalIndex(
      safeEnd,
    );

    final startSurahName = QuranReaderHelpers.getSuraName(
      startPosition.suraIndex,
    );

    final endSurahName = QuranReaderHelpers.getSuraName(
      endPosition.suraIndex,
    );

    final int totalAyahs = (safeEnd - safeStart + 1).clamp(0, 100000).toInt();

    final int startPage = QuranPageMapper.getPageNumberForGlobalAyah(
      safeStart,
    );

    final int endPage = QuranPageMapper.getPageNumberForGlobalAyah(
      safeEnd,
    );

    final int pagesCount = math.max(1, endPage - startPage + 1);

    final int surahsCount = math.max(
      1,
      endPosition.suraIndex - startPosition.suraIndex + 1,
    );

    final String rangeText;
    if (startPosition.suraIndex == endPosition.suraIndex) {
      if (startPosition.ayahIndex == endPosition.ayahIndex) {
        rangeText = 'مهمتك: سورة $startSurahName • آية ${startPosition.ayahIndex + 1}';
      } else {
        rangeText =
        'مهمتك: سورة $startSurahName • من آية ${startPosition.ayahIndex + 1} إلى ${endPosition.ayahIndex + 1}';
      }
    } else {
      rangeText =
      'مهمتك: من سورة $startSurahName آية ${startPosition.ayahIndex + 1} إلى سورة $endSurahName آية ${endPosition.ayahIndex + 1}';
    }

    final String startText =
        'سورة $startSurahName • آية ${startPosition.ayahIndex + 1}';

    return _TaskRangeData(
      rangeText: rangeText,
      startText: startText,
      totalAyahs: totalAyahs,
      pagesCount: pagesCount,
      surahsCount: surahsCount,
      taskTypeText: _taskTypeText(taskType),
    );
  }

  static String _taskTypeText(String type) {
    switch (type) {
      case 'dailyNew':
        return 'حفظ';
      case 'dailyReview':
        return 'مراجعة';
      case 'weakReview':
        return 'ضعيف';
      case 'selfTest':
        return 'اختبار';
      default:
        return 'مهمة';
    }
  }
}
