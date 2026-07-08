import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/services/app_haptics.dart';
import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_today_task_model.dart';
import 'package:islamic_app/features/memorization/data/services/quran_memorization_range_resolver.dart';
import 'package:islamic_app/features/memorization/presentation/pages/memorization_training_session_page.dart';
import 'package:islamic_app/features/memorization/test/pages/memorization_test_session_page.dart';
import 'package:islamic_app/features/quran/reader/quran_reader_helpers.dart';

class CurrentPlanNextSessionCard extends StatelessWidget {
  const CurrentPlanNextSessionCard({
    super.key,
    required this.task,
    required this.onSessionFinished,
  });

  final MemorizationTodayTaskModel? task;
  final VoidCallback onSessionFinished;

  @override
  Widget build(BuildContext context) {
    final nextTask = task;
    if (nextTask == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? colors.surface : const Color(0xFF18385F);
    final cardColor = isDark ? colors.secondary : Colors.white;
    final innerCardColor = isDark
        ? colors.surface.withOpacity(0.055)
        : const Color(0xFFFAFCFE);
    final borderColor = isDark
        ? colors.outline.withOpacity(0.12)
        : const Color(0xFFE7EDF5);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 13.h, 14.w, 14.h),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: borderColor, width: 0.8.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _sectionTitle(nextTask),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            maxLines: 3,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body(context).copyWith(
              color: textColor,
              fontSize: 12.2.sp,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(13.w, 13.h, 13.w, 13.h),
            decoration: BoxDecoration(
              color: innerCardColor,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: borderColor, width: 0.8.w),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Container(
                      width: 42.w,
                      height: 42.w,
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.09),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: colors.primary,
                        size: 19.sp,
                      ),
                    ),
                    SizedBox(width: 11.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _surahLine(nextTask),
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            maxLines: 3,
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption(context).copyWith(
                              color: textColor,
                              fontSize: 11.2.sp,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          SizedBox(height: 5.h),
                          Text(
                            _ayahRangeLine(nextTask),
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            maxLines: 3,
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption(context).copyWith(
                              color: textColor,
                              fontSize: 11.2.sp,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                            ),
                          ),
                          SizedBox(height: 5.h),
                          Text(
                            '${nextTask.ayahsCount} آية',
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption(context).copyWith(
                              color: textColor.withOpacity(0.48),
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                _StartSessionButton(
                  task: nextTask,
                  onSessionFinished: onSessionFinished,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _sectionTitle(MemorizationTodayTaskModel task) {
    if (task.type == 'dailyReview') return 'جلسة المراجعة القادمة';
    if (task.type == 'weakReview') return 'جلسة تثبيت قادمة';
    if (task.type == 'selfTest') return 'الاختبار القادم';
    return 'حفظ اليوم';
  }

  String _surahLine(MemorizationTodayTaskModel task) {
    final range = _TaskRangeText.fromTask(task);
    return range.surahLine;
  }

  String _ayahRangeLine(MemorizationTodayTaskModel task) {
    if (task.type == 'dailyNew' && task.hasValidRange) {
      const resolver = QuranMemorizationRangeResolver();
      final startPage = resolver.pageForGlobalAyah(task.startGlobalAyahIndex);
      final endPage = resolver.pageForGlobalAyah(task.endGlobalAyahIndex);
      return startPage == endPage
          ? 'الصفحة: $startPage'
          : 'الصفحات: $startPage - $endPage';
    }
    final range = _TaskRangeText.fromTask(task);
    return range.ayahLine;
  }
}

class _StartSessionButton extends StatelessWidget {
  const _StartSessionButton({
    required this.task,
    required this.onSessionFinished,
  });

  final MemorizationTodayTaskModel task;
  final VoidCallback onSessionFinished;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool isCompleted =
        task.isCompleted ||
        task.status == MemorizationTodayTaskModel.statusCompleted;

    return Material(
      color: isCompleted ? colors.primary.withOpacity(0.38) : colors.primary,
      borderRadius: BorderRadius.circular(28.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(28.r),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: isCompleted
            ? null
            : () async {
                AppHaptics.tap(context);

                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => task.type == 'selfTest'
                        ? MemorizationTestSessionPage(task: task)
                        : MemorizationTrainingSessionPage(task: task),
                  ),
                );

                if (result == true) {
                  onSessionFinished();
                }
              },
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 46.h),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              SizedBox(width: 18.w),
              Expanded(
                child: Text(
                  isCompleted ? 'تم إنهاء جلسة اليوم' : _buttonText(task),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    color: Colors.white,
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_left_rounded,
                color: Colors.white.withOpacity(isCompleted ? 0.55 : 0.92),
                size: 20.sp,
              ),
              SizedBox(width: 14.w),
            ],
          ),
        ),
      ),
    );
  }

  String _buttonText(MemorizationTodayTaskModel task) {
    if (task.type == 'dailyReview') return 'ابدأ جلسة المراجعة القادمة';
    if (task.type == 'weakReview') return 'ابدأ جلسة التثبيت القادمة';
    if (task.type == 'selfTest') return 'ابدأ الاختبار القادم';
    return 'أكمل حفظ اليوم من حيث توقفت';
  }
}

class _TaskRangeText {
  const _TaskRangeText({required this.surahLine, required this.ayahLine});

  final String surahLine;
  final String ayahLine;

  factory _TaskRangeText.fromTask(MemorizationTodayTaskModel task) {
    if (!task.hasValidRange) {
      final fallback = task.scopeTitle.trim();
      return _TaskRangeText(
        surahLine: fallback.isEmpty ? 'نطاق الجلسة' : fallback,
        ayahLine: '${task.ayahsCount} آية',
      );
    }

    final maxAyahIndex = QuranReaderHelpers.totalAyahs - 1;
    final startIndex = task.startGlobalAyahIndex.clamp(0, maxAyahIndex).toInt();
    final endIndex = task.endGlobalAyahIndex
        .clamp(startIndex, maxAyahIndex)
        .toInt();

    final start = QuranReaderHelpers.getPositionFromGlobalIndex(startIndex);
    final end = QuranReaderHelpers.getPositionFromGlobalIndex(endIndex);

    final startSurahName = QuranReaderHelpers.getSuraName(start.suraIndex);
    final endSurahName = QuranReaderHelpers.getSuraName(end.suraIndex);
    final startAyah = start.ayahIndex + 1;
    final endAyah = end.ayahIndex + 1;

    if (start.suraIndex == end.suraIndex) {
      return _TaskRangeText(
        surahLine: 'سورة $startSurahName',
        ayahLine: startAyah == endAyah
            ? 'آية $startAyah'
            : 'الآيات $startAyah - $endAyah',
      );
    }

    return _TaskRangeText(
      surahLine: 'من $startSurahName إلى $endSurahName',
      ayahLine: 'من آية $startAyah إلى آية $endAyah',
    );
  }
}
