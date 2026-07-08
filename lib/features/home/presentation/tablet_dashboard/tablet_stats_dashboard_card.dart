import 'package:flutter/material.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_active_plan_model.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_today_task_model.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_plan_storage.dart';
import 'package:islamic_app/features/prayer/data/services/prayer_tracking_storage.dart';
import 'package:islamic_app/features/quran/stats/quran_reading_stats_storage.dart';

import 'tablet_dashboard_card_base.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class TabletStatsDashboardCard extends StatefulWidget {
  const TabletStatsDashboardCard({super.key});

  @override
  State<TabletStatsDashboardCard> createState() =>
      _TabletStatsDashboardCardState();
}

class _TabletStatsDashboardCardState extends State<TabletStatsDashboardCard> {
  late Future<_TabletStatsSnapshot> _snapshotFuture;

  @override
  void initState() {
    super.initState();
    _snapshotFuture = _loadSnapshot();
  }

  Future<_TabletStatsSnapshot> _loadSnapshot() async {
    final results = await Future.wait<dynamic>([
      MemorizationPlanStorage.getActivePlan(),
      MemorizationPlanStorage.getTodayTask(),
      PrayerTrackingStorage.loadTrackingData(),
      QuranReadingStatsStorage.getStats(),
    ]);

    return _TabletStatsSnapshot(
      activePlan: results[0] as MemorizationActivePlanModel?,
      todayTask: results[1] as MemorizationTodayTaskModel?,
      prayerData: results[2] as PrayerTrackingData,
      quranStats: results[3] as QuranReadingStats,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _TabletStatsDashboardCardBody(
      snapshotFuture: _snapshotFuture,
    );
  }
}

class _TabletStatsDashboardCardBody extends TabletDashboardCardBase {
  const _TabletStatsDashboardCardBody({
    required this.snapshotFuture,
  });

  final Future<_TabletStatsSnapshot> snapshotFuture;

  @override
  String get title => 'لوحة المتابعة';

  @override
  String get subtitle => 'إحصائيات سريعة للصلاة والقرآن وحلقة الحفظ.';

  @override
  Widget buildCardContent(BuildContext context) {
    return FutureBuilder<_TabletStatsSnapshot>(
      future: snapshotFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          );
        }

        return _StatsContent(
          snapshot: snapshot.data ?? const _TabletStatsSnapshot(),
        );
      },
    );
  }
}

class _StatsContent extends StatelessWidget {
  const _StatsContent({
    required this.snapshot,
  });

  final _TabletStatsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final bool isFoldLandscape = size.width >= 600 && size.shortestSide < 600;

    final MemorizationActivePlanModel? activePlan = snapshot.activePlan;
    final MemorizationTodayTaskModel? todayTask = snapshot.todayTask;
    final PrayerTrackingData? prayerData = snapshot.prayerData;
    final QuranReadingStats? quranStats = snapshot.quranStats;

    final bool hasPlan = activePlan != null;
    final bool hasTask = todayTask != null && todayTask.isAvailableToday;

    final int completedPrayers =
        prayerData?.checked.where((value) => value).length ?? 0;

    final int prayerStreak = prayerData?.streak ?? 0;
    final int bestPrayerStreak = prayerData?.bestStreak ?? 0;

    final int quranPages = quranStats?.totalReadPages ?? 0;
    final int quranStreak = quranStats?.currentStreakDays ?? 0;

    final List<_DashboardStatItem> stats = <_DashboardStatItem>[
      _DashboardStatItem(
        title: 'صلاة اليوم',
        value: '$completedPrayers / 5',
        subtitle: completedPrayers == 5
            ? 'تم إكمال صلوات اليوم'
            : 'تابع تسجيل صلوات اليوم',
      ),
      _DashboardStatItem(
        title: 'سلسلة الصلاة',
        value: '$prayerStreak يوم',
        subtitle: 'أفضل سلسلة: $bestPrayerStreak يوم',
      ),
      _DashboardStatItem(
        title: 'ورد القرآن',
        value: '$quranPages صفحة',
        subtitle: quranStreak > 0
            ? 'مداومة القرآن: $quranStreak يوم'
            : 'ابدأ قراءة اليوم',
      ),
      _DashboardStatItem(
        title: 'خطة الحفظ',
        value: hasPlan ? activePlan.planName : 'لا توجد خطة',
        subtitle: hasPlan ? activePlan.scopeTitle : 'ابدأ حلقة حفظ جديدة',
      ),
      _DashboardStatItem(
        title: 'مهمة اليوم',
        value: hasTask ? todayTask.title : 'لا توجد مهمة',
        subtitle: hasTask ? todayTask.scopeTitle : 'لا توجد مهمة متاحة اليوم',
      ),
      _DashboardStatItem(
        title: 'حالة المهمة',
        value: hasTask ? todayTask.statusTitle : 'غير متاحة',
        subtitle: hasTask ? todayTask.subtitle : 'افتح حلقة الحفظ للمتابعة',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool useThreeColumns = constraints.maxWidth >= 620;
        final int columns = useThreeColumns ? 3 : 2;

        final double gap = isFoldLandscape ? 12 : 14;

        final List<List<_DashboardStatItem>> rows = <List<_DashboardStatItem>>[];

        for (int i = 0; i < stats.length; i += columns) {
          rows.add(
            stats.sublist(
              i,
              (i + columns) > stats.length ? stats.length : i + columns,
            ),
          );
        }

        return Column(
          children: [
            for (int rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
              Expanded(
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    for (int itemIndex = 0;
                    itemIndex < rows[rowIndex].length;
                    itemIndex++) ...[
                      Expanded(
                        child: _StatTile(
                          item: rows[rowIndex][itemIndex],
                        ),
                      ),
                      if (itemIndex != rows[rowIndex].length - 1)
                        SizedBox(width: gap),
                    ],
                  ],
                ),
              ),
              if (rowIndex != rows.length - 1) SizedBox(height: gap),
            ],
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.item,
  });

  final _DashboardStatItem item;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final bool isFoldLandscape = size.width >= 600 && size.shortestSide < 600;

    final double padding = isFoldLandscape ? 12 : 14;
    final double titleSize = isFoldLandscape ? 13 : 13.5;
    final double valueSize = isFoldLandscape ? 20 : 19;
    final double subtitleSize = isFoldLandscape ? 11.2 : 11.5;

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: isFoldLandscape ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xff171B26),
        borderRadius: BorderRadius.circular(isFoldLandscape ? 16 : 18),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    item.title,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'cairo',
                      fontSize: titleSize,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.68),
                      height: 1.05,
                    ),
                  ),
                ),
                SizedBox(height: isFoldLandscape ? 5 : 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    item.value,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'cairo',
                      fontSize: valueSize,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.05,
                    ),
                  ),
                ),
                SizedBox(height: isFoldLandscape ? 5 : 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    item.subtitle,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'cairo',
                      fontSize: subtitleSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.60),
                      height: 1.15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TabletTodaySmartStrip extends StatefulWidget {
  const TabletTodaySmartStrip({super.key});

  @override
  State<TabletTodaySmartStrip> createState() => _TabletTodaySmartStripState();
}

class _TabletTodaySmartStripState extends State<TabletTodaySmartStrip> {
  late Future<_TabletStatsSnapshot> _snapshotFuture;

  @override
  void initState() {
    super.initState();
    _snapshotFuture = _loadSnapshot();
  }

  Future<_TabletStatsSnapshot> _loadSnapshot() async {
    final results = await Future.wait<dynamic>([
      MemorizationPlanStorage.getActivePlan(),
      MemorizationPlanStorage.getTodayTask(),
      PrayerTrackingStorage.loadTrackingData(),
      QuranReadingStatsStorage.getStats(),
    ]);

    return _TabletStatsSnapshot(
      activePlan: results[0] as MemorizationActivePlanModel?,
      todayTask: results[1] as MemorizationTodayTaskModel?,
      prayerData: results[2] as PrayerTrackingData,
      quranStats: results[3] as QuranReadingStats,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TabletStatsSnapshot>(
      future: _snapshotFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }

        return _TodayTaskStrip(
          snapshot: snapshot.data ?? const _TabletStatsSnapshot(),
        );
      },
    );
  }
}

class _TodayTaskStrip extends StatelessWidget {
  const _TodayTaskStrip({
    required this.snapshot,
  });

  final _TabletStatsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final bool isFoldLandscape = size.width >= 600 && size.shortestSide < 600;

    final MemorizationTodayTaskModel? task = snapshot.todayTask;
    final MemorizationActivePlanModel? plan = snapshot.activePlan;

    final int completedPrayers =
        snapshot.prayerData?.checked.where((value) => value).length ?? 0;

    final int quranPages = snapshot.quranStats?.totalReadPages ?? 0;

    final bool hasTask = task != null && task.isAvailableToday;

    final String title = _buildSmartTitle(
      completedPrayers: completedPrayers,
      quranPages: quranPages,
      hasTask: hasTask,
    );

    final String subtitle = hasTask
        ? '${task.title} • ${task.scopeTitle} • ${task.statusTitle}'
        : plan != null
        ? 'الصلاة: $completedPrayers من 5 • القرآن: $quranPages صفحة • افتح خطة الحفظ للمتابعة'
        : 'الصلاة: $completedPrayers من 5 • القرآن: $quranPages صفحة • ابدأ خطة حفظ جديدة';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isFoldLandscape ? 16 : 18,
          vertical: isFoldLandscape ? 13 : 15,
        ),
        decoration: BoxDecoration(
          color: const Color(0xff171B26),
          borderRadius: BorderRadius.circular(isFoldLandscape ? 18 : 20),
          border: Border.all(
            color: const Color(0xff224367).withOpacity(0.42),
            width: 1,
          ),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    title,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headline(context).copyWith(
fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1
),
                  ),
                ),
                const SizedBox(height: 5),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    subtitle,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.74),
                      height: 1.2
),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildSmartTitle({
    required int completedPrayers,
    required int quranPages,
    required bool hasTask,
  }) {
    if (completedPrayers < 5) {
      return 'كمّل صلوات اليوم';
    }

    if (quranPages == 0) {
      return 'صلاتك ممتازة، افتح ورد القرآن';
    }

    if (hasTask) {
      return 'أكمل مهمة الحفظ اليوم';
    }

    return 'متابعة يومك ممتازة';
  }
}

class _DashboardStatItem {
  const _DashboardStatItem({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;
}

class _TabletStatsSnapshot {
  const _TabletStatsSnapshot({
    this.activePlan,
    this.todayTask,
    this.prayerData,
    this.quranStats,
  });

  final MemorizationActivePlanModel? activePlan;
  final MemorizationTodayTaskModel? todayTask;
  final PrayerTrackingData? prayerData;
  final QuranReadingStats? quranStats;
}