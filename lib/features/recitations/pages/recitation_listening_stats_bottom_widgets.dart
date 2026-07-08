part of 'recitation_listening_stats_page.dart';

class _AchievementsCard extends StatelessWidget {
  final List<RecitationAchievement> achievements;

  const _AchievementsCard({required this.achievements});

  @override
  Widget build(BuildContext context) {
    final earnedCount = achievements.where((item) => item.earned).length;

    return _MainTrackingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _SectionTitle(
            title: 'جوائز الاستماع  $earnedCount / ${achievements.length}',
            icon: Icons.emoji_events_rounded,
          ),
          SizedBox(height: 10.h),
          ...achievements.map(
            (achievement) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: _AchievementTile(achievement: achievement),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final RecitationAchievement achievement;

  const _AchievementTile({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return _InnerDarkCard(
      padding: EdgeInsets.all(10.w),
      borderColor: achievement.earned
          ? const Color(0xffffb300).withOpacity(0.75)
          : Colors.white.withOpacity(0.10),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          CircleAvatar(
            radius: 18.r,
            backgroundColor: achievement.earned
                ? const Color(0xffffb300)
                : Colors.white.withOpacity(0.12),
            child: Icon(
              achievement.earned ? Icons.check_rounded : achievement.icon,
              color: Colors.white,
              size: 18.sp,
            ),
          ),
          SizedBox(width: 9.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  achievement.title,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(
                    context,
                  ).copyWith(fontWeight: FontWeight.w900, color: Colors.white),
                ),
                SizedBox(height: 3.h),
                Text(
                  achievement.description,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.62),
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 7.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: LinearProgressIndicator(
                    value: achievement.progress,
                    minHeight: 4.h,
                    backgroundColor: Colors.white.withOpacity(0.18),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      achievement.earned
                          ? const Color(0xffffb300)
                          : const Color(0xff21C58E),
                    ),
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

class _MainTrackingCard extends StatelessWidget {
  final Widget child;

  const _MainTrackingCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: child,
    );
  }
}

class _InnerDarkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;

  const _InnerDarkCard({required this.child, this.padding, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          padding ?? EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xff171B26),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: borderColor ?? Colors.white.withOpacity(0.12),
          width: 0.8.w,
        ),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return _InnerDarkCard(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, color: const Color(0xff21C58E), size: 18.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(
                context,
              ).copyWith(fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
        ],
      ),
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

  String _shortTitle(String title) {
    switch (title) {
      case 'استماع اليوم':
        return 'اليوم';
      case 'إجمالي الاستماع':
        return 'الإجمالي';
      case 'نسبة الهدف':
        return 'الهدف';
      case 'حالة اليوم':
        return 'الحالة';
      case 'أهداف مكتملة':
        return 'الأهداف';
      case 'أسبوعك الحالي':
        return 'الأسبوع';
      case 'استماع الشهر':
        return 'الشهر';
      case 'أهداف الشهر':
        return 'أهداف الشهر';
      case 'سور مختلفة':
        return 'السور';
      case 'قراء مختلفون':
        return 'القراء';
      default:
        return title;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _InnerDarkCard(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 9.h),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          CircleAvatar(
            radius: 15.r,
            backgroundColor: Colors.white.withOpacity(0.12),
            child: Icon(icon, color: const Color(0xff21C58E), size: 16.sp),
          ),
          SizedBox(width: 7.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _shortTitle(title),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.62),
                  ),
                ),
                SizedBox(height: 3.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    value,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    style: AppTextStyles.caption(context).copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
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

class _AnalysisRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  const _AnalysisRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return _InnerDarkCard(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          CircleAvatar(
            radius: 17.r,
            backgroundColor: Colors.white.withOpacity(0.12),
            child: Icon(icon, color: const Color(0xff21C58E), size: 18.sp),
          ),
          SizedBox(width: 9.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.62),
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  value,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(
                    context,
                  ).copyWith(fontWeight: FontWeight.w900, color: Colors.white),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.52),
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

class _SmallActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const _SmallActionButton({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.12),
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: () {
          AppHaptics.tap(context);
          onTap();
        },
        borderRadius: BorderRadius.circular(14.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 14.sp),
              SizedBox(width: 4.w),
              Text(
                text,
                style: AppTextStyles.caption(
                  context,
                ).copyWith(fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MotivationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _InnerDarkCard(
      child: Row(
        children: [
          Expanded(
            child: Text(
              'استماع قصير يوميًا أفضل من انقطاع طويل. اجعل لك وردًا ثابتًا ولو دقائق قليلة.',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.80),
                height: 1.35,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Icon(
            Icons.favorite_rounded,
            color: const Color(0xff21C58E),
            size: 18.sp,
          ),
        ],
      ),
    );
  }
}
