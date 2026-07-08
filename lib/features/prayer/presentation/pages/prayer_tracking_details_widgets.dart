part of 'prayer_tracking_details_page.dart';

class _PrayerDetailsLargeTitle extends StatelessWidget {
  const _PrayerDetailsLargeTitle();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isFoldLandscape =
        MediaQuery.sizeOf(context).width >= 600 &&
        MediaQuery.sizeOf(context).shortestSide < 600;

    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        'تتبع صلاتي',
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        style: AppTextStyles.display(context).copyWith(
          fontWeight: FontWeight.w900,
          color: theme.colorScheme.onBackground,
          height: 1.1,
        ),
      ),
    );
  }
}

class _MainTrackingCard extends StatelessWidget {
  final Widget child;

  const _MainTrackingCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final bool large = MediaQuery.sizeOf(context).width >= 600;

    return SizedBox(
      width: large ? double.infinity : AppLayoutConstants.mainCardWidth,
      child: Container(
        padding: EdgeInsets.all(large ? 12 : 12.w),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(
            large ? 18 : AppLayoutConstants.mainCardRadius,
          ),
        ),
        child: child,
      ),
    );
  }
}

class _StreakStatusCard extends StatelessWidget {
  final int streak;
  final int bestStreak;
  final bool completedToday;
  final int completedCount;
  final int totalCount;

  const _StreakStatusCard({
    required this.streak,
    required this.bestStreak,
    required this.completedToday,
    required this.completedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final int remaining = totalCount - completedCount;

    final String title;
    final String message;
    final IconData icon;
    final Color accentColor;

    if (completedToday) {
      title = 'السلسلة مستمرة';
      message = 'ما شاء الله، أتممت صلوات اليوم وحافظت على السلسلة.';
      icon = Icons.local_fire_department_rounded;
      accentColor = Colors.orange;
    } else if (completedCount > 0) {
      title = 'اقتربت من الحفاظ على السلسلة';
      message = 'باقي $remaining صلاة لإكمال اليوم والحفاظ على السلسلة.';
      icon = Icons.trending_up_rounded;
      accentColor = const Color(0xff21C58E);
    } else {
      title = 'ابدأ يومك بخطوة';
      message = streak > 0
          ? 'سلسلتك الحالية $streak يوم. سجّل صلوات اليوم حتى لا تنقطع.'
          : 'ابدأ بتسجيل صلاة واحدة، والاستمرار يبدأ بخطوة.';
      icon = Icons.flag_rounded;
      accentColor = Colors.amber;
    }

    return _MainTrackingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(icon, color: accentColor, size: 20.sp),
              SizedBox(width: 7.w),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.caption(
                    context,
                  ).copyWith(fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            message,
            textAlign: TextAlign.right,
            style: AppTextStyles.caption(context).copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.72),
              height: 1.4,
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
            decoration: BoxDecoration(
              color: const Color(0xff171B26),
              borderRadius: BorderRadius.circular(13.r),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Text(
                  'الحالية: $streak',
                  style: AppTextStyles.caption(
                    context,
                  ).copyWith(fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const Spacer(),
                Text(
                  'أفضل سلسلة: $bestStreak',
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xff21C58E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Icon(icon, color: Colors.white, size: 18.sp),
        SizedBox(width: 6.w),
        Text(
          title,
          style: AppTextStyles.caption(
            context,
          ).copyWith(fontWeight: FontWeight.w800, color: Colors.white),
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
      constraints: BoxConstraints(minHeight: large ? 56 : 60.h),
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
          Icon(icon, color: const Color(0xff21C58E), size: large ? 16 : 16.sp),
          SizedBox(height: large ? 5 : 5.h),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(
              context,
            ).copyWith(fontWeight: FontWeight.w800, color: Colors.white),
          ),
          SizedBox(height: large ? 2 : 2.h),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(
              context,
            ).copyWith(color: Colors.white.withOpacity(0.62)),
          ),
        ],
      ),
    );
  }
}

class _PrayerStatusTile extends StatelessWidget {
  final String prayerName;
  final bool completed;
  final bool enabled;
  final String statusText;
  final Color statusColor;
  final VoidCallback onTap;

  const _PrayerStatusTile({
    required this.prayerName,
    required this.completed,
    required this.enabled,
    required this.statusText,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.62,
      child: InkWell(
        borderRadius: BorderRadius.circular(13.r),
        onTap: enabled
            ? () {
                AppHaptics.tap(context);
                onTap();
              }
            : () {
                AppHaptics.tap(context);
              },
        child: Container(
          constraints: BoxConstraints(minHeight: 40.h),
          margin: EdgeInsets.only(bottom: 7.h),
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: const Color(0xff171B26),
            borderRadius: BorderRadius.circular(13.r),
            border: Border.all(
              color: completed ? const Color(0xff21C58E) : Colors.white24,
              width: 0.8.w,
            ),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                completed
                    ? Icons.check_circle_rounded
                    : enabled
                    ? Icons.radio_button_unchecked
                    : Icons.lock_rounded,
                color: completed
                    ? const Color(0xff21C58E)
                    : enabled
                    ? Colors.white70
                    : Colors.white38,
                size: 18.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                prayerName,
                style: AppTextStyles.caption(
                  context,
                ).copyWith(fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  statusText,
                  textAlign: TextAlign.left,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(
                    context,
                  ).copyWith(color: statusColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyHistoryDetails extends StatelessWidget {
  final List<PrayerWeeklyDay> weeklyHistory;

  const _WeeklyHistoryDetails({required this.weeklyHistory});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: weeklyHistory.map((day) {
        return Container(
          height: 32.h,
          margin: EdgeInsets.only(bottom: 6.h),
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          decoration: BoxDecoration(
            color: const Color(0xff171B26),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Text(
                day.isToday ? '${day.dayName} - اليوم' : day.dayName,
                style: AppTextStyles.caption(context).copyWith(
                  fontWeight: day.isToday ? FontWeight.w800 : FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                day.completed
                    ? 'مكتمل'
                    : day.checkedCount > 0
                    ? '${day.checkedCount} / 5'
                    : 'لا يوجد تقدم',
                style: AppTextStyles.caption(
                  context,
                ).copyWith(color: Colors.white.withOpacity(0.72)),
              ),
              SizedBox(width: 8.w),
              Icon(
                day.completed
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                color: day.completed ? const Color(0xff21C58E) : Colors.white60,
                size: 16.sp,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String title;
  final String value;

  const _InfoLine({required this.title, required this.value});

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
        textDirection: TextDirection.rtl,
        children: [
          Text(
            title,
            style: AppTextStyles.caption(
              context,
            ).copyWith(fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.caption(context).copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xff21C58E),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool unlocked;

  const _AchievementTile({
    required this.title,
    required this.subtitle,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xff171B26),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: unlocked
              ? const Color(0xff21C58E)
              : Colors.white.withOpacity(0.15),
          width: 0.8.w,
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(
            unlocked ? Icons.emoji_events_rounded : Icons.lock_outline_rounded,
            color: unlocked ? const Color(0xffffb300) : Colors.white54,
            size: 18.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: unlocked ? Colors.white : Colors.white54,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w500,
                    color: unlocked
                        ? Colors.white.withOpacity(0.65)
                        : Colors.white.withOpacity(0.35),
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
