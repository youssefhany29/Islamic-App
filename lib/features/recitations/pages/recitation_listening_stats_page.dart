import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';
import '../services/recitation_custom_goals_storage.dart';
import '../widgets/recitation_custom_goals_card.dart';
import 'recitation_custom_goal_editor_page.dart';
import '../models/recitation_achievement_model.dart';
import '../services/recitation_listening_stats_storage.dart';
import 'recitation_listening_goal_page.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
part 'recitation_listening_stats_widgets.dart';
part 'recitation_listening_stats_overview_widgets.dart';
part 'recitation_listening_stats_analytics_widgets.dart';
part 'recitation_listening_stats_bottom_widgets.dart';

class RecitationListeningStatsPage extends StatefulWidget {
  const RecitationListeningStatsPage({super.key});

  @override
  State<RecitationListeningStatsPage> createState() =>
      _RecitationListeningStatsPageState();
}

class _RecitationListeningStatsPageState
    extends State<RecitationListeningStatsPage> {
  RecitationListeningStatsData? stats;
  bool isLoading = true;
  List<RecitationCustomGoalProgress> customGoals = [];
  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final loadedStats = await RecitationListeningStatsStorage.loadStats();
    final loadedCustomGoals =
        await RecitationCustomGoalsStorage.loadGoalsProgress();

    if (!mounted) return;

    setState(() {
      stats = loadedStats;
      customGoals = loadedCustomGoals;
      isLoading = false;
    });
  }

  Future<void> _openCustomGoalEditor() async {
    AppHaptics.tap(context);

    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RecitationCustomGoalEditorPage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );

    if (result == true) {
      await _loadStats();
    }
  }

  Future<void> _deleteCustomGoal(String id) async {
    await RecitationCustomGoalsStorage.deleteGoal(id);
    await _loadStats();
  }

  Future<void> _openGoalPage() async {
    AppHaptics.tap(context);

    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RecitationListeningGoalPage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );

    if (result == true) {
      await _loadStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onBackground;
    final primary = Theme.of(context).colorScheme.primary;
    final loadedStats = stats;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: Column(
            children: [
              _Header(
                title: 'إحصائيات الاستماع',
                onBack: () {
                  AppHaptics.tap(context);
                  Navigator.pop(context);
                },
                trailing: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 38.w, minHeight: 38.h),
                  onPressed: _openGoalPage,
                  icon: Icon(
                    Icons.track_changes_rounded,
                    size: 21.sp,
                    color: primary,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator(color: primary))
                    : loadedStats == null
                    ? Center(
                        child: Text(
                          'لا توجد إحصائيات بعد',
                          textDirection: TextDirection.rtl,
                          style: AppTextStyles.caption(
                            context,
                          ).copyWith(color: textColor.withOpacity(0.65)),
                        ),
                      )
                    : RefreshIndicator(
                        color: primary,
                        onRefresh: _loadStats,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          children: [
                            _DailyGoalProgressCard(stats: loadedStats),
                            SizedBox(height: 10.h),
                            _GoalEditHintCard(onTap: _openGoalPage),
                            SizedBox(height: 10.h),
                            _WeeklyBadgeCard(stats: loadedStats),
                            SizedBox(height: 10.h),
                            _TodaySummaryCard(stats: loadedStats),
                            SizedBox(height: 10.h),
                            _StreakStatusCard(stats: loadedStats),
                            SizedBox(height: 10.h),
                            _MonthlyStatsCard(stats: loadedStats),
                            SizedBox(height: 10.h),
                            _AnalyticsCard(stats: loadedStats),
                            SizedBox(height: 10.h),
                            _WeeklyHistoryCard(stats: loadedStats),
                            SizedBox(height: 10.h),
                            RecitationCustomGoalsCard(
                              goals: customGoals,
                              onAddGoal: _openCustomGoalEditor,
                              onDeleteGoal: _deleteCustomGoal,
                            ),
                            SizedBox(height: 10.h),
                            _AchievementsCard(
                              achievements: loadedStats.achievements,
                            ),
                            SizedBox(height: 10.h),
                            _MotivationCard(),
                            SizedBox(height: 18.h),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
