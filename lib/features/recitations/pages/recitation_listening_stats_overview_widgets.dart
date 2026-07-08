part of 'recitation_listening_stats_page.dart';

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

  const _Header({required this.title, required this.onBack, this.trailing});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onBackground;

    return Padding(
      padding: EdgeInsets.only(top: 12.h),
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 38.w, minHeight: 38.h),
            onPressed: onBack,
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18.sp,
              color: textColor,
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.headline(
                context,
              ).copyWith(fontWeight: FontWeight.w900, color: textColor),
            ),
          ),
          trailing ?? SizedBox(width: 38.w),
        ],
      ),
    );
  }
}

class _DailyGoalProgressCard extends StatelessWidget {
  final RecitationListeningStatsData stats;

  const _DailyGoalProgressCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final todayText = RecitationListeningStatsStorage.formatListeningTime(
      stats.todaySeconds,
    );
    final goalText = RecitationListeningStatsStorage.formatListeningTime(
      stats.dailyGoalSeconds,
    );
    final percentage = (stats.todayProgress * 100).round();

    return _MainTrackingCard(
      child: _InnerDarkCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                CircleAvatar(
                  radius: 19.r,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.track_changes_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 21.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    stats.completedTodayGoal
                        ? 'ما شاء الله، أتممت ورد الاستماع اليومي'
                        : 'ورد الاستماع اليومي',
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(context).copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: Text(
                    '$todayText من $goalText',
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.82),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  '$percentage%',
                  textDirection: TextDirection.ltr,
                  style: AppTextStyles.caption(
                    context,
                  ).copyWith(fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ],
            ),
            SizedBox(height: 9.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: LinearProgressIndicator(
                value: stats.todayProgress,
                minHeight: 7.h,
                backgroundColor: Colors.white.withOpacity(0.24),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xff21C58E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalEditHintCard extends StatelessWidget {
  final VoidCallback onTap;

  const _GoalEditHintCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xff171B26),
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () {
          AppHaptics.tap(context);
          onTap();
        },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 0.8.w,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'يمكنك تعديل هدف الاستماع اليومي في أي وقت',
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.82),
                    height: 1.35,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Icon(
                Icons.edit_rounded,
                color: const Color(0xff21C58E),
                size: 18.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyBadgeCard extends StatelessWidget {
  final RecitationListeningStatsData stats;

  const _WeeklyBadgeCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final completedDays = stats.weeklyHistory
        .where((day) => day.completedGoal)
        .length;

    final String message = completedDays >= 7
        ? 'أسبوع كامل مكتمل، ما شاء الله ✨'
        : completedDays >= 4
        ? 'أسبوعك جيد، اقتربت من أسبوع كامل'
        : 'اجعل هذا الأسبوع بداية جديدة مع القرآن';

    return _InnerDarkCard(
      borderColor: completedDays >= 7
          ? const Color(0xff21C58E)
          : Colors.white.withOpacity(0.12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.82),
                height: 1.35,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Icon(
            Icons.workspace_premium_rounded,
            color: completedDays >= 7
                ? const Color(0xffffb300)
                : Colors.white70,
            size: 18.sp,
          ),
        ],
      ),
    );
  }
}

class _TodaySummaryCard extends StatelessWidget {
  final RecitationListeningStatsData stats;

  const _TodaySummaryCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final todayText = RecitationListeningStatsStorage.formatListeningTime(
      stats.todaySeconds,
    );
    final totalText = RecitationListeningStatsStorage.formatListeningTime(
      stats.totalSeconds,
    );
    final percentage = (stats.todayProgress * 100).round();

    return _MainTrackingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const _SectionTitle(title: 'ملخص اليوم', icon: Icons.today_rounded),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _MiniStatCard(
                  title: 'استماع اليوم',
                  value: todayText,
                  icon: Icons.headphones_rounded,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _MiniStatCard(
                  title: 'نسبة الهدف',
                  value: '$percentage%',
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
                  title: 'إجمالي الاستماع',
                  value: totalText,
                  icon: Icons.all_inclusive_rounded,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _MiniStatCard(
                  title: 'حالة اليوم',
                  value: stats.completedTodayGoal ? 'مكتمل' : 'غير مكتمل',
                  icon: stats.completedTodayGoal
                      ? Icons.verified_rounded
                      : Icons.hourglass_bottom_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakStatusCard extends StatelessWidget {
  final RecitationListeningStatsData stats;

  const _StreakStatusCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final weeklyCompletedDays = stats.weeklyHistory
        .where((day) => day.completedGoal)
        .length;

    return _MainTrackingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const _SectionTitle(
            title: 'الثبات والمتابعة',
            icon: Icons.local_fire_department_rounded,
          ),
          SizedBox(height: 10.h),
          _StreakSlimCard(streak: stats.streak, bestStreak: stats.bestStreak),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: _MiniStatCard(
                  title: 'أهداف مكتملة',
                  value: '${stats.completedGoalDays}',
                  icon: Icons.flag_rounded,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _MiniStatCard(
                  title: 'أسبوعك الحالي',
                  value: '$weeklyCompletedDays / 7',
                  icon: Icons.calendar_month_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakSlimCard extends StatelessWidget {
  final int streak;
  final int bestStreak;

  const _StreakSlimCard({required this.streak, required this.bestStreak});

  @override
  Widget build(BuildContext context) {
    return _InnerDarkCard(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
      child: SizedBox(
        height: 40.h,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 205.w,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'أيام متتالية: $streak',
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'أفضل سلسلة: $bestStreak',
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Icon(
                Icons.local_fire_department_rounded,
                color: Colors.orange,
                size: 22.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
