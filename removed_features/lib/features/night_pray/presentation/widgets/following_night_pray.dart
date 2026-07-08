import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/shared/widgets/common_components/app_layout_constants.dart';
import 'package:islamic_app/features/prayer/data/services/prayer_time_service.dart';

import 'package:islamic_app/features/night_pray/presentation/pages/night_pray_tracking_details_page.dart';
import 'package:islamic_app/features/night_pray/data/services/night_pray_tracking_storage.dart';
import 'night_pray_action_row.dart';
import 'night_pray_best_time_card.dart';
import 'night_pray_details_button.dart';
import 'night_pray_dua_card.dart';
import 'night_pray_motivation_card.dart';
import 'night_pray_progress_card.dart';
import 'night_pray_streak_card.dart';
import 'night_pray_tracking_header.dart';
import 'night_pray_weekly_badge_card.dart';
import 'night_pray_weekly_history_row.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';

class FollowingNightPray extends StatefulWidget {
  const FollowingNightPray({super.key});

  @override
  State<FollowingNightPray> createState() => _FollowingNightPrayState();
}

class _FollowingNightPrayState extends State<FollowingNightPray> {
  static const List<String> _items = [
    'صليت ركعتين',
    'صليت الوتر',
    'قرأت قرآنًا',
    'دعوت الله',
    'استغفرت',
  ];

  static const List<String> _nightDuas = [
    'اللهم لك الحمد أنت نور السماوات والأرض ومن فيهن.',
    'اللهم أعني على ذكرك وشكرك وحسن عبادتك.',
    'رب اغفر لي وتب علي إنك أنت التواب الرحيم.',
    'اللهم اجعلني من أهل قيام الليل وثبّت قلبي على طاعتك.',
    'اللهم ارزقني قلبًا خاشعًا ولسانًا ذاكرًا ودعاءً مستجابًا.',
    'اللهم اجعل قيامي لك خالصًا، وقلبي بك مطمئنًا، ولساني بذكرك عامرًا.',
    'اللهم لا تحرمني لذة مناجاتك، ولا تجعلني من الغافلين عن ذكرك.',
  ];

  bool _loading = true;

  List<bool> _checked = List<bool>.filled(_items.length, false);

  int _streak = 0;
  int _bestStreak = 0;
  bool _completedToday = false;

  int _duaIndex = 0;
  bool _hasPrayerTimes = false;
  bool _isInsideNightWindow = false;
  String _nightWindowStatusText = 'يتم تحديد وقت قيام الليل...';

  String? _nightRangeText;
  String? _lastThirdStartText;

  List<NightPrayWeeklyDay> _weeklyHistory = [];

  NightPrayMonthlyStats _monthlyStats = const NightPrayMonthlyStats(
    completedNights: 0,
    totalLoggedItems: 0,
    nightsWithAnyProgress: 0,
    daysInMonth: 30,
    completionRate: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadTrackingData(),
      _loadNightBestTime(),
    ]);
  }

  Future<void> _loadTrackingData() async {
    final data = await NightPrayTrackingStorage.loadTrackingData();

    if (!mounted) return;

    setState(() {
      _checked = data.checked;
      _streak = data.streak;
      _bestStreak = data.bestStreak;
      _completedToday = data.completedToday;
      _weeklyHistory = data.weeklyHistory;
      _monthlyStats = data.monthlyStats;
      _loading = false;
    });
  }

  Future<void> _loadNightBestTime() async {
    try {
      final prayerWeek = await PrayerTimeService().getCachedPrayerWeek();

      if (prayerWeek.isEmpty) {
        _setNightTimeUnavailable();
        return;
      }

      final now = DateTime.now();
      final today = _findPrayerDayByDate(prayerWeek, now) ?? prayerWeek.first;
      final tomorrow = _findPrayerDayByDate(
            prayerWeek,
            now.add(const Duration(days: 1)),
          ) ??
          (prayerWeek.length > 1 ? prayerWeek[1] : null);

      final DateTime? todayFajr = _buildPrayerDateTime(
        day: today,
        prayerKey: 'fajr',
        fallbackDate: now,
      );

      final DateTime? todayIsha = _buildPrayerDateTime(
        day: today,
        prayerKey: 'isha',
        fallbackDate: now,
      );

      final DateTime? tomorrowFajr = tomorrow == null
          ? null
          : _buildPrayerDateTime(
              day: tomorrow,
              prayerKey: 'fajr',
              fallbackDate: now.add(const Duration(days: 1)),
            );

      final bool beforeTodayFajr = todayFajr != null && now.isBefore(todayFajr);

      final bool afterTodayIshaBeforeTomorrowFajr = todayIsha != null &&
          tomorrowFajr != null &&
          !now.isBefore(todayIsha) &&
          now.isBefore(tomorrowFajr);

      final bool isInsideWindow =
          beforeTodayFajr || afterTodayIshaBeforeTomorrowFajr;

      String? rangeText;
      String? lastThirdText;
      String statusText;

      if (afterTodayIshaBeforeTomorrowFajr &&
          todayIsha != null &&
          tomorrowFajr != null) {
        rangeText = '${_formatTime(todayIsha)} - ${_formatTime(tomorrowFajr)}';

        final nightDuration = tomorrowFajr.difference(todayIsha);
        final lastThirdStart = tomorrowFajr.subtract(
          Duration(minutes: nightDuration.inMinutes ~/ 3),
        );

        lastThirdText = _formatTime(lastThirdStart);
        statusText = 'اختيارات قيام الليل مفتوحة الآن حتى الفجر.';
      } else if (beforeTodayFajr && todayFajr != null) {
        rangeText = 'مفتوح الآن حتى ${_formatTime(todayFajr)}';
        statusText = 'اختيارات قيام الليل مفتوحة الآن حتى الفجر.';
      } else if (todayIsha != null) {
        rangeText = 'يفتح بعد العشاء ${_formatTime(todayIsha)}';
        statusText = 'اختيارات قيام الليل تفتح من بعد العشاء إلى قبل الفجر.';
      } else {
        rangeText = null;
        statusText = 'افتح صفحة الصلاة مرة واحدة لتحديث مواقيت العشاء والفجر.';
      }

      if (!mounted) return;

      setState(() {
        _hasPrayerTimes =
            todayFajr != null || todayIsha != null || tomorrowFajr != null;
        _isInsideNightWindow = isInsideWindow;
        _nightRangeText = rangeText;
        _lastThirdStartText = lastThirdText;
        _nightWindowStatusText = statusText;
      });
    } catch (_) {
      _setNightTimeUnavailable();
    }
  }

  void _setNightTimeUnavailable() {
    if (!mounted) return;

    setState(() {
      _hasPrayerTimes = false;
      _isInsideNightWindow = false;
      _nightRangeText = null;
      _lastThirdStartText = null;
      _nightWindowStatusText =
          'افتح صفحة الصلاة مرة واحدة لتحديث مواقيت العشاء والفجر.';
    });
  }

  Map<String, String>? _findPrayerDayByDate(
    List<Map<String, String>> prayerWeek,
    DateTime date,
  ) {
    final key = _dateKey(date);

    for (final day in prayerWeek) {
      if (day['date'] == key) {
        return day;
      }
    }

    return null;
  }

  DateTime? _buildPrayerDateTime({
    required Map<String, String> day,
    required String prayerKey,
    required DateTime fallbackDate,
  }) {
    final time = day[prayerKey];

    if (time == null || !time.contains(':')) return null;

    final parts = time.split(':');
    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return null;

    final rowDate = _parseDateKey(day['date']) ?? fallbackDate;

    return DateTime(
      rowDate.year,
      rowDate.month,
      rowDate.day,
      hour,
      minute,
    );
  }

  DateTime? _parseDateKey(String? dateKey) {
    if (dateKey == null || dateKey.trim().isEmpty) return null;

    final parts = dateKey.split('-');
    if (parts.length != 3) return null;

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);

    if (year == null || month == null || day == null) return null;

    return DateTime(year, month, day);
  }

  String _dateKey(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  Future<void> _onItemChanged(int index, bool newValue) async {
    if (!_isInsideNightWindow) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _nightWindowStatusText,
            textDirection: TextDirection.rtl,
          ),
        ),
      );
      return;
    }

    final wasCompletedToday = _completedToday;

    setState(() {
      _checked[index] = newValue;
    });

    final allCompleted = _checked.every((value) => value);

    if (allCompleted && !wasCompletedToday) {
      _completedToday = true;
      _streak++;
    }

    if (!allCompleted && wasCompletedToday) {
      _completedToday = false;
      if (_streak > 0) {
        _streak--;
      }
    }

    await NightPrayTrackingStorage.saveTrackingData(
      checked: _checked,
      streak: _streak,
      completedToday: _completedToday,
    );

    final weeklyHistory = await NightPrayTrackingStorage.getWeeklyHistory();
    final monthlyStats = await NightPrayTrackingStorage.getMonthlyStats();
    final freshData = await NightPrayTrackingStorage.loadTrackingData();

    if (!mounted) return;

    setState(() {
      _weeklyHistory = weeklyHistory;
      _monthlyStats = monthlyStats;
      _bestStreak = freshData.bestStreak;
    });
  }

  Future<void> _resetTracking() async {
    await NightPrayTrackingStorage.resetTrackingData();

    if (!mounted) return;

    setState(() {
      _checked = List<bool>.filled(_items.length, false);
      _streak = 0;
      _bestStreak = 0;
      _completedToday = false;
      _weeklyHistory = [];
      _monthlyStats = const NightPrayMonthlyStats(
        completedNights: 0,
        totalLoggedItems: 0,
        nightsWithAnyProgress: 0,
        daysInMonth: 30,
        completionRate: 0,
      );
    });

    await _loadTrackingData();
  }

  Future<void> _openTrackingDetailsPage() async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return NightPrayTrackingDetailsPage(
            items: _items,
            checked: _checked,
            streak: _streak,
            bestStreak: _bestStreak,
            completedToday: _completedToday,
            weeklyHistory: _weeklyHistory,
            monthlyStats: _monthlyStats,
            canEditTonight: _isInsideNightWindow,
            editLockedMessage: _nightWindowStatusText,
          );
        },
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );

    if (!mounted) return;
    await _loadTrackingData();
  }

  void _changeDua() {
    setState(() {
      _duaIndex = (_duaIndex + 1) % _nightDuas.length;
    });
  }

  String _motivationMessage({
    required int completedCount,
    required int totalCount,
  }) {
    final remaining = totalCount - completedCount;

    if (_completedToday) {
      return 'ما شاء الله، أتممت قيام الليلة. ربنا يتقبل منك 🤍';
    }

    if (completedCount == 0) {
      return 'ابدأ بركعتين فقط، المهم أن تبدأ ولو بالقليل.';
    }

    if (remaining == 1) {
      return 'باقي خطوة واحدة وتكمل قيام الليلة بإذن الله.';
    }

    return 'أحسنت، باقي $remaining خطوات لإكمال قيام الليلة.';
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _checked.where((value) => value).length;
    final totalCount = _checked.length;
    final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: MediaQuery.sizeOf(context).width >= 600
            ? double.infinity
            : AppLayoutConstants.mainCardWidth,
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: MediaQuery.sizeOf(context).width >= 600 ? 12 : 12.h,
            horizontal: MediaQuery.sizeOf(context).width >= 600 ? 12 : 12.w,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: _loading
              ? Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    NightPrayTrackingHeader(onReset: _resetTracking),
                    SizedBox(height: 10.h),
                    NightPrayBestTimeCard(
                      nightRangeText: _nightRangeText,
                      lastThirdStartText: _lastThirdStartText,
                      hasPrayerTimes: _hasPrayerTimes,
                    ),
                    SizedBox(height: 10.h),
                    NightPrayProgressCard(
                      completedToday: _completedToday,
                      completedCount: completedCount,
                      totalCount: totalCount,
                      progress: progress,
                    ),
                    SizedBox(height: 10.h),
                    NightPrayStreakCard(
                      streak: _streak,
                      bestStreak: _bestStreak,
                      completedToday: _completedToday,
                    ),
                    SizedBox(height: 10.h),
                    NightPrayMotivationCard(
                      message: _motivationMessage(
                        completedCount: completedCount,
                        totalCount: totalCount,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    _NightPrayActionsSection(
                      enabled: _isInsideNightWindow,
                      statusText: _nightWindowStatusText,
                      completedCount: completedCount,
                      totalCount: totalCount,
                      child: Column(
                        children: [
                          for (int i = 0; i < _items.length; i++)
                            NightPrayActionRow(
                              text: _items[i],
                              value: _checked[i],
                              enabled: _isInsideNightWindow,
                              onChanged: (value) => _onItemChanged(i, value),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 2.h),
                    NightPrayWeeklyHistoryRow(
                      weeklyHistory: _weeklyHistory,
                    ),
                    SizedBox(height: 10.h),
                    NightPrayWeeklyBadgeCard(
                      weeklyHistory: _weeklyHistory,
                    ),
                    SizedBox(height: 10.h),
                    NightPrayDuaCard(
                      dua: _nightDuas[_duaIndex],
                      onChangeDua: _changeDua,
                    ),
                    SizedBox(height: 10.h),
                    NightPrayDetailsButton(
                      onTap: _openTrackingDetailsPage,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _NightPrayActionsSection extends StatelessWidget {
  final bool enabled;
  final String statusText;
  final int completedCount;
  final int totalCount;
  final Widget child;

  const _NightPrayActionsSection({
    required this.enabled,
    required this.statusText,
    required this.completedCount,
    required this.totalCount,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor =
        enabled ? const Color(0xff21C58E) : const Color(0xffffb300);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 11.h,
      ),
      decoration: BoxDecoration(
        color: const Color(0xff171B26),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: statusColor.withOpacity(0.45),
          width: 0.8.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                enabled ? Icons.nights_stay_rounded : Icons.lock_clock_rounded,
                color: statusColor,
                size: 18.sp,
              ),
              SizedBox(width: 7.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'اختيارات قيام الليلة',
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                          fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      statusText,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.70)),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '$completedCount / $totalCount',
                  textDirection: TextDirection.ltr,
                  style: AppTextStyles.caption(context).copyWith(
                      fontWeight: FontWeight.w800, color: statusColor),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          child,
        ],
      ),
    );
  }
}
