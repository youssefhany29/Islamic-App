part of 'prayer_tracking_details_page.dart';

extension _PrayerTrackingDetailsPhoneLayout on _PrayerTrackingDetailsPageState {
  Widget _buildPrayerTrackingDetailsPhoneScaffold(BuildContext context) {
    final int completedCount = _checked.where((value) => value).length;
    final int totalCount = _checked.length;
    final double todayRate = totalCount == 0 ? 0 : completedCount / totalCount;

    final int weeklyCompletedDays = _weeklyHistory
        .where((day) => day.completed)
        .length;

    final double weeklyRate = _weeklyHistory.isEmpty
        ? 0
        : weeklyCompletedDays / 7;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: const CustomAppBar(
        category: CustomAppBarCategory(text: 'تتبع صلاتي'),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: AppLayoutConstants.pageHorizontalPadding,
            vertical: 14.h,
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: [
                _MainTrackingCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const _SectionTitle(
                        title: 'ملخص اليوم',
                        icon: Icons.today_rounded,
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: _MiniStatCard(
                              title: 'صلوات اليوم',
                              value: '$completedCount / $totalCount',
                              icon: Icons.check_circle_outline_rounded,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: _MiniStatCard(
                              title: 'نسبة اليوم',
                              value: '${(todayRate * 100).round()}%',
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
                              title: 'الأيام المتتالية',
                              value: '${_streak}',
                              icon: Icons.local_fire_department_rounded,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: _MiniStatCard(
                              title: 'أفضل سلسلة',
                              value: '${_bestStreak}',
                              icon: Icons.workspace_premium_rounded,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Expanded(
                            child: _MiniStatCard(
                              title: 'حالة اليوم',
                              value: _completedToday ? 'مكتمل' : 'غير مكتمل',
                              icon: _completedToday
                                  ? Icons.verified_rounded
                                  : Icons.hourglass_bottom_rounded,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: _MiniStatCard(
                              title: 'الصلوات الباقية',
                              value: '${totalCount - completedCount}',
                              icon: Icons.timelapse_rounded,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14.h),
                _StreakStatusCard(
                  streak: _streak,
                  bestStreak: _bestStreak,
                  completedToday: _completedToday,
                  completedCount: completedCount,
                  totalCount: totalCount,
                ),
                SizedBox(height: 14.h),
                TodayReviewCard(
                  prayers: widget.prayers,
                  checked: _checked,
                  completedToday: _completedToday,
                ),
                SizedBox(height: 14.h),
                SmartPrayerAdviceCard(
                  prayers: widget.prayers,
                  checked: _checked,
                ),
                SizedBox(height: 14.h),
                _MainTrackingCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const _SectionTitle(
                        title: 'صلوات اليوم',
                        icon: Icons.mosque_rounded,
                      ),
                      SizedBox(height: 10.h),
                      for (int i = 0; i < widget.prayers.length; i++)
                        _PrayerStatusTile(
                          prayerName: widget.prayers[i],
                          completed: _checked[i],
                          enabled: _canEditPrayer(i),
                          statusText: _prayerStatusText(i),
                          statusColor: _prayerStatusColor(i),
                          onTap: () {
                            if (!_canEditPrayer(i)) return;
                            _onPrayerChanged(i, !_checked[i]);
                          },
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 14.h),
                _MainTrackingCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const _SectionTitle(
                        title: 'آخر ٧ أيام',
                        icon: Icons.calendar_month_rounded,
                      ),
                      SizedBox(height: 10.h),
                      _WeeklyHistoryDetails(weeklyHistory: _weeklyHistory),
                      SizedBox(height: 12.h),
                      _InfoLine(
                        title: 'أيام مكتملة هذا الأسبوع',
                        value: '$weeklyCompletedDays / 7',
                      ),
                      SizedBox(height: 6.h),
                      _InfoLine(
                        title: 'نسبة الالتزام الأسبوعية',
                        value: '${(weeklyRate * 100).round()}%',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14.h),
                const MonthlyCalendarCard(),
                SizedBox(height: 14.h),
                _MainTrackingCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const _SectionTitle(
                        title: 'إحصائيات الشهر',
                        icon: Icons.bar_chart_rounded,
                      ),
                      SizedBox(height: 10.h),
                      _InfoLine(
                        title: 'الأيام المكتملة',
                        value:
                            '${_monthlyStats.completedDays} / ${_monthlyStats.daysInMonth}',
                      ),
                      SizedBox(height: 6.h),
                      _InfoLine(
                        title: 'إجمالي الصلوات المسجلة',
                        value: '${_monthlyStats.totalLoggedPrayers}',
                      ),
                      SizedBox(height: 6.h),
                      _InfoLine(
                        title: 'أيام بها أي تقدم',
                        value: '${_monthlyStats.daysWithAnyProgress}',
                      ),
                      SizedBox(height: 6.h),
                      _InfoLine(
                        title: 'نسبة اكتمال الشهر',
                        value:
                            '${(_monthlyStats.completionRate * 100).round()}%',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14.h),
                PrayerPatternCard(prayers: widget.prayers),
                SizedBox(height: 14.h),
                _MainTrackingCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const _SectionTitle(
                        title: 'إنجازاتك',
                        icon: Icons.emoji_events_rounded,
                      ),
                      SizedBox(height: 10.h),
                      _AchievementTile(
                        title: 'أول خطوة',
                        subtitle: 'سجلت أول صلاة في التطبيق',
                        unlocked: _monthlyStats.totalLoggedPrayers >= 1,
                      ),
                      _AchievementTile(
                        title: 'أول يوم كامل',
                        subtitle: 'أكمل جميع صلوات يوم واحد',
                        unlocked: _monthlyStats.completedDays >= 1,
                      ),
                      _AchievementTile(
                        title: 'يومك مكتمل',
                        subtitle: 'أتممت صلوات اليوم',
                        unlocked: _completedToday,
                      ),
                      _AchievementTile(
                        title: 'بداية قوية',
                        subtitle: 'أكملت ٣ أيام هذا الشهر',
                        unlocked: _monthlyStats.completedDays >= 3,
                      ),
                      _AchievementTile(
                        title: 'أسبوع نور',
                        subtitle: 'أكملت ٧ أيام هذا الشهر',
                        unlocked: _monthlyStats.completedDays >= 7,
                      ),
                      _AchievementTile(
                        title: 'منتصف الطريق',
                        subtitle: 'أكملت ١٥ يومًا هذا الشهر',
                        unlocked: _monthlyStats.completedDays >= 15,
                      ),
                      _AchievementTile(
                        title: 'شهر مميز',
                        subtitle: 'أكملت ٢٠ يومًا هذا الشهر',
                        unlocked: _monthlyStats.completedDays >= 20,
                      ),
                      _AchievementTile(
                        title: 'قريب من الكمال',
                        subtitle: 'أكملت ٢٥ يومًا هذا الشهر',
                        unlocked: _monthlyStats.completedDays >= 25,
                      ),
                      _AchievementTile(
                        title: 'شهر كامل',
                        subtitle: 'أكملت ٣٠ يومًا هذا الشهر',
                        unlocked: _monthlyStats.completedDays >= 30,
                      ),
                      _AchievementTile(
                        title: 'ثبات جميل',
                        subtitle: '٣ أيام متتالية',
                        unlocked: _streak >= 3,
                      ),
                      _AchievementTile(
                        title: 'سلسلة مباركة',
                        subtitle: '٧ أيام متتالية',
                        unlocked: _streak >= 7,
                      ),
                      _AchievementTile(
                        title: 'مجاهد النفس',
                        subtitle: '١٤ يومًا متتاليًا',
                        unlocked: _streak >= 14,
                      ),
                      _AchievementTile(
                        title: 'ثبات عظيم',
                        subtitle: '٢١ يومًا متتاليًا',
                        unlocked: _streak >= 21,
                      ),
                      _AchievementTile(
                        title: 'محافظ قوي',
                        subtitle: '٣٠ يومًا متتاليًا',
                        unlocked: _streak >= 30,
                      ),
                      _AchievementTile(
                        title: 'همة عالية',
                        subtitle: '٤٠ يومًا متتاليًا',
                        unlocked: _streak >= 40,
                      ),
                      _AchievementTile(
                        title: 'عادة ثابتة',
                        subtitle: '٥٠ يومًا متتاليًا',
                        unlocked: _streak >= 50,
                      ),
                      _AchievementTile(
                        title: 'طريق النور',
                        subtitle: '١٠٠ يوم متتالي',
                        unlocked: _streak >= 100,
                      ),
                      _AchievementTile(
                        title: 'أفضل سلسلة ٣ أيام',
                        subtitle: 'وصلت سابقًا إلى ٣ أيام متتالية',
                        unlocked: _bestStreak >= 3,
                      ),
                      _AchievementTile(
                        title: 'أفضل سلسلة ٧ أيام',
                        subtitle: 'وصلت سابقًا إلى ٧ أيام متتالية',
                        unlocked: _bestStreak >= 7,
                      ),
                      _AchievementTile(
                        title: 'أفضل سلسلة ٣٠ يوم',
                        subtitle: 'وصلت سابقًا إلى ٣٠ يومًا متتاليًا',
                        unlocked: _bestStreak >= 30,
                      ),
                      _AchievementTile(
                        title: 'سجل ١٠ صلوات',
                        subtitle: 'سجلت ١٠ صلوات في التطبيق',
                        unlocked: _monthlyStats.totalLoggedPrayers >= 10,
                      ),
                      _AchievementTile(
                        title: 'سجل ٢٥ صلاة',
                        subtitle: 'سجلت ٢٥ صلاة في التطبيق',
                        unlocked: _monthlyStats.totalLoggedPrayers >= 25,
                      ),
                      _AchievementTile(
                        title: 'سجل ٥٠ صلاة',
                        subtitle: 'سجلت ٥٠ صلاة في التطبيق',
                        unlocked: _monthlyStats.totalLoggedPrayers >= 50,
                      ),
                      _AchievementTile(
                        title: 'سجل ٧٥ صلاة',
                        subtitle: 'سجلت ٧٥ صلاة في التطبيق',
                        unlocked: _monthlyStats.totalLoggedPrayers >= 75,
                      ),
                      _AchievementTile(
                        title: 'سجل ١٠٠ صلاة',
                        subtitle: 'سجلت ١٠٠ صلاة في التطبيق',
                        unlocked: _monthlyStats.totalLoggedPrayers >= 100,
                      ),
                      _AchievementTile(
                        title: 'سجل ١٥٠ صلاة',
                        subtitle: 'سجلت ١٥٠ صلاة في التطبيق',
                        unlocked: _monthlyStats.totalLoggedPrayers >= 150,
                      ),
                      _AchievementTile(
                        title: 'سجل ٣٠٠ صلاة',
                        subtitle: 'سجلت ٣٠٠ صلاة في التطبيق',
                        unlocked: _monthlyStats.totalLoggedPrayers >= 300,
                      ),
                      _AchievementTile(
                        title: 'أسبوع نشيط',
                        subtitle: 'سجلت تقدمًا في ٥ أيام هذا الشهر',
                        unlocked: _monthlyStats.daysWithAnyProgress >= 5,
                      ),
                      _AchievementTile(
                        title: 'حضور مستمر',
                        subtitle: 'سجلت تقدمًا في ١٠ أيام هذا الشهر',
                        unlocked: _monthlyStats.daysWithAnyProgress >= 10,
                      ),
                      _AchievementTile(
                        title: 'نشاط رائع',
                        subtitle: 'سجلت تقدمًا في ١٥ يومًا هذا الشهر',
                        unlocked: _monthlyStats.daysWithAnyProgress >= 15,
                      ),
                      _AchievementTile(
                        title: 'قلب متعلق بالصلاة',
                        subtitle: 'سجلت تقدمًا في ٢٠ يومًا هذا الشهر',
                        unlocked: _monthlyStats.daysWithAnyProgress >= 20,
                      ),
                      _AchievementTile(
                        title: 'لا يفوتك الخير',
                        subtitle: 'سجلت تقدمًا في ٢٥ يومًا هذا الشهر',
                        unlocked: _monthlyStats.daysWithAnyProgress >= 25,
                      ),
                      _AchievementTile(
                        title: 'متابع يومي',
                        subtitle: 'سجلت تقدمًا في ٣٠ يومًا هذا الشهر',
                        unlocked: _monthlyStats.daysWithAnyProgress >= 30,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
