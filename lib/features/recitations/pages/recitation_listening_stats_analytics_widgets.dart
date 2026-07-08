part of 'recitation_listening_stats_page.dart';

class _MonthlyStatsCard extends StatelessWidget {
  final RecitationListeningStatsData stats;

  const _MonthlyStatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final monthText = RecitationListeningStatsStorage.formatListeningTime(
      stats.monthlySeconds,
    );

    return _MainTrackingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const _SectionTitle(
            title: 'إحصائيات الشهر',
            icon: Icons.date_range_rounded,
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _MiniStatCard(
                  title: 'استماع الشهر',
                  value: monthText,
                  icon: Icons.timer_rounded,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _MiniStatCard(
                  title: 'أهداف الشهر',
                  value: '${stats.monthCompletedGoalDays}',
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: _MiniStatCard(
                  title: 'سور مختلفة',
                  value: '${stats.uniqueSurahCount}',
                  icon: Icons.menu_book_rounded,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _MiniStatCard(
                  title: 'قراء مختلفون',
                  value: '${stats.uniqueReciterCount}',
                  icon: Icons.record_voice_over_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final RecitationListeningStatsData stats;

  const _AnalyticsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final topSurah = stats.topSurah;
    final topReciter = stats.topReciter;

    return _MainTrackingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const _SectionTitle(
            title: 'تحليل الاستماع',
            icon: Icons.analytics_rounded,
          ),
          SizedBox(height: 10.h),
          _AnalysisRow(
            icon: Icons.schedule_rounded,
            title: 'أكثر وقت تستمع فيه',
            value: stats.topListeningTime.title,
            subtitle: stats.topListeningTime.seconds <= 0
                ? stats.topListeningTime.subtitle
                : RecitationListeningStatsStorage.formatListeningTime(
                    stats.topListeningTime.seconds,
                  ),
          ),
          SizedBox(height: 8.h),
          _AnalysisRow(
            icon: Icons.menu_book_rounded,
            title: 'أكثر سورة تستمع لها',
            value: topSurah?.name ?? 'لم يتحدد بعد',
            subtitle: topSurah == null
                ? 'استمع أكثر ليظهر التحليل'
                : RecitationListeningStatsStorage.formatListeningTime(
                    topSurah.seconds,
                  ),
          ),
          SizedBox(height: 8.h),
          _AnalysisRow(
            icon: Icons.record_voice_over_rounded,
            title: 'أكثر قارئ تستمع له',
            value: topReciter?.name ?? 'لم يتحدد بعد',
            subtitle: topReciter == null
                ? 'استمع أكثر ليظهر التحليل'
                : RecitationListeningStatsStorage.formatListeningTime(
                    topReciter.seconds,
                  ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyHistoryCard extends StatelessWidget {
  final RecitationListeningStatsData stats;

  const _WeeklyHistoryCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.weeklyHistory.isEmpty) return const SizedBox.shrink();

    return _InnerDarkCard(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'آخر ٧ أيام',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.caption(
                context,
              ).copyWith(fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: stats.weeklyHistory.map((day) {
              return Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 23.w,
                      height: 23.w,
                      decoration: BoxDecoration(
                        color: day.completedGoal
                            ? const Color(0xff21C58E)
                            : day.listened
                            ? Colors.white.withOpacity(0.32)
                            : Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(7.r),
                        border: Border.all(
                          color: day.isToday
                              ? Colors.white
                              : Colors.white.withOpacity(0.18),
                          width: day.isToday ? 1.2.w : 0.6.w,
                        ),
                      ),
                      child: day.completedGoal
                          ? Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 15.sp,
                            )
                          : day.listened
                          ? Icon(
                              Icons.headphones_rounded,
                              color: Colors.white,
                              size: 13.sp,
                            )
                          : null,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      day.dayName,
                      textDirection: TextDirection.rtl,
                      style: AppTextStyles.caption(context).copyWith(
                        fontWeight: day.isToday
                            ? FontWeight.w800
                            : FontWeight.w500,
                        color: Colors.white.withOpacity(0.82),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      day.seconds <= 0
                          ? '-'
                          : RecitationListeningStatsStorage.formatShortTime(
                              day.seconds,
                            ),
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(
                        context,
                      ).copyWith(color: Colors.white.withOpacity(0.52)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
