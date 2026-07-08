import 'package:flutter/material.dart';

import 'package:islamic_app/features/prayer/data/services/prayer_tracking_service.dart';
import 'package:islamic_app/features/prayer/data/services/prayer_tracking_storage.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/features/prayer/presentation/widgets/tracking_widgets/prayer_quick_actions_section.dart';
import 'package:islamic_app/features/prayer/presentation/widgets/tracking_widgets/prayer_motivation_card.dart';
import 'package:islamic_app/features/prayer/presentation/widgets/tracking_widgets/prayer_weekly_summary_card.dart';
import 'package:provider/provider.dart';

import 'package:islamic_app/core/services/app_haptics.dart';
import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/azkar/data/datasources/zekr_local_data.dart';
import 'package:islamic_app/features/azkar/presentation/pages/zekr_reading_page.dart';
import 'package:islamic_app/features/home/presentation/widgets/main_app_widgets/qibla_direction_page.dart';
import 'package:islamic_app/features/prayer/data/notifications/prayer_notification_settings_provider.dart';
import 'package:islamic_app/features/settings/reminder_settings_page.dart';

import 'package:islamic_app/features/prayer/presentation/widgets/tracking_widgets/prayer_today_tracking_card.dart';
import 'package:islamic_app/features/prayer/presentation/widgets/tracking_widgets/prayer_tracking_stats_card.dart';
import 'package:islamic_app/features/prayer/presentation/widgets/tracking_widgets/prayer_today_tracking_models.dart';

class FollowingPray extends StatefulWidget {
  const FollowingPray({
    super.key,
    this.prayerWeek = const [],
    this.large = false,
  });

  final List<Map<String, String>> prayerWeek;
  final bool large;

  @override
  State<FollowingPray> createState() => _FollowingPrayState();
}

class _FollowingPrayState extends State<FollowingPray> {
  static const int _onTimeGraceMinutes = 60;
  static const int _lockBeforeNextPrayerMinutes = 30;

  final List<String> _prayers = const [
    'الفجر',
    'الظهر',
    'العصر',
    'المغرب',
    'العشاء',
  ];

  final List<String> _prayerKeys = const [
    'fajr',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
  ];

  List<bool> _checked = List<bool>.filled(5, false);
  int _streak = 0;
  int _bestStreak = 0;
  bool _completedToday = false;
  List<PrayerWeeklyDay> _weeklyHistory = const [];
  bool _isLoaded = false;


  @override
  void initState() {
    super.initState();
    _loadTrackingData();
  }

  Future<void> _loadTrackingData() async {
    final data = await PrayerTrackingStorage.loadTrackingData();

    if (!mounted) return;

    setState(() {
      _checked = data.checked;
      _streak = data.streak;
      _bestStreak = data.bestStreak;
      _completedToday = data.completedToday;
      _weeklyHistory = data.weeklyHistory;
      _isLoaded = true;
    });

    await const PrayerTrackingService().scheduleDailySummaryIfNeeded(
      checked: _checked,
    );
  }

  Future<void> _onPrayerChanged(int index, bool newValue) async {
    if (!_canEditPrayer(index)) {
      return;
    }

    final List<bool> optimisticChecked = List<bool>.from(_checked);
    optimisticChecked[index] = newValue;

    if (mounted) {
      setState(() {
        _checked = optimisticChecked;
      });
    }

    final result = await const PrayerTrackingService().changePrayerStatus(
      prayers: _prayers,
      currentChecked: _checked,
      prayerIndex: index,
      newValue: newValue,
      currentStreak: _streak,
      completedToday: _completedToday,
      prayerWeek: widget.prayerWeek,
    );

    if (!mounted) return;

    setState(() {
      _checked = result.checked;
      _streak = result.streak;
      _bestStreak = result.bestStreak;
      _completedToday = result.completedToday;
      _weeklyHistory = result.weeklyHistory;
    });
  }

  int _getTodayPrayerRowIndex() {
    final String todayKey = PrayerTrackingStorage.todayKey();

    for (int i = 0; i < widget.prayerWeek.length; i++) {
      if (widget.prayerWeek[i]['date'] == todayKey) {
        return i;
      }
    }

    final todayName = _todayArabicName();

    for (int i = 0; i < widget.prayerWeek.length; i++) {
      if (widget.prayerWeek[i]['day'] == todayName) {
        return i;
      }
    }

    return -1;
  }

  DateTime? _getPrayerTimeToday(int prayerIndex) {
    final int todayIndex = _getTodayPrayerRowIndex();
    if (todayIndex == -1) return null;

    return _parsePrayerTimeForDay(
      day: widget.prayerWeek[todayIndex],
      prayerKey: _prayerKeys[prayerIndex],
    );
  }

  DateTime? _getPrayerLockTime(int prayerIndex) {
    final int todayIndex = _getTodayPrayerRowIndex();
    if (todayIndex == -1) return null;

    final DateTime? prayerTime = _getPrayerTimeToday(prayerIndex);
    if (prayerTime == null) return null;

    final DateTime? nextPrayerTime = _getNextPrayerTime(
      todayIndex: todayIndex,
      prayerIndex: prayerIndex,
    );

    if (nextPrayerTime == null) {
      return prayerTime.add(
        const Duration(minutes: _onTimeGraceMinutes),
      );
    }

    final DateTime lockTime = nextPrayerTime.subtract(
      const Duration(minutes: _lockBeforeNextPrayerMinutes),
    );

    if (lockTime.isBefore(prayerTime)) {
      return prayerTime.add(
        const Duration(minutes: _onTimeGraceMinutes),
      );
    }

    return lockTime;
  }

  DateTime? _getNextPrayerTime({
    required int todayIndex,
    required int prayerIndex,
  }) {
    int nextDayIndex = todayIndex;
    int nextPrayerIndex = prayerIndex + 1;

    if (nextPrayerIndex >= _prayerKeys.length) {
      nextPrayerIndex = 0;
      nextDayIndex = todayIndex + 1;
    }

    if (nextDayIndex >= widget.prayerWeek.length) {
      return null;
    }

    return _parsePrayerTimeForDay(
      day: widget.prayerWeek[nextDayIndex],
      prayerKey: _prayerKeys[nextPrayerIndex],
      fallbackDayOffset: nextDayIndex - todayIndex,
    );
  }

  DateTime? _parsePrayerTimeForDay({
    required Map<String, String> day,
    required String prayerKey,
    int fallbackDayOffset = 0,
  }) {
    final String? time = day[prayerKey];

    if (time == null || !time.contains(':')) return null;

    final parts = time.split(':');

    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return null;

    final DateTime fallbackDay = DateTime.now().add(
      Duration(days: fallbackDayOffset),
    );

    final DateTime targetDay = _parseDateKey(day['date']) ?? fallbackDay;

    return DateTime(
      targetDay.year,
      targetDay.month,
      targetDay.day,
      hour,
      minute,
    );
  }

  DateTime? _parseDateKey(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final parts = value.split('-');

    if (parts.length != 3) return null;

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);

    if (year == null || month == null || day == null) return null;

    return DateTime(year, month, day);
  }

  String _todayArabicName() {
    const days = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];

    return days[DateTime.now().weekday - 1];
  }

  bool _isPrayerLocked(int prayerIndex) {
    final DateTime? lockTime = _getPrayerLockTime(prayerIndex);
    if (lockTime == null) return false;

    return DateTime.now().isAfter(lockTime);
  }

  bool _canEditPrayer(int prayerIndex) {
    final DateTime? prayerTime = _getPrayerTimeToday(prayerIndex);

    if (prayerTime == null) return true;

    final DateTime now = DateTime.now();

    if (now.isBefore(prayerTime)) {
      return false;
    }

    return true;
  }

  PrayerTodayRowState _rowState(int prayerIndex) {
    if (_checked[prayerIndex]) {
      return PrayerTodayRowState.completed;
    }

    final DateTime? prayerTime = _getPrayerTimeToday(prayerIndex);

    if (prayerTime == null) {
      return PrayerTodayRowState.future;
    }

    final DateTime now = DateTime.now();

    if (now.isBefore(prayerTime)) {
      return PrayerTodayRowState.future;
    }

    if (_isPrayerLocked(prayerIndex)) {
      return PrayerTodayRowState.missed;
    }

    return PrayerTodayRowState.current;
  }

  String _rowStatusText(int prayerIndex) {
    switch (_rowState(prayerIndex)) {
      case PrayerTodayRowState.completed:
        return 'تمت الصلاة';
      case PrayerTodayRowState.current:
        return 'حان الآن';
      case PrayerTodayRowState.missed:
        return 'فات وقتها';
      case PrayerTodayRowState.future:
        return 'لم يحن بعد';
    }
  }

  String _prayerTimeText(int prayerIndex) {
    final int todayIndex = _getTodayPrayerRowIndex();

    if (todayIndex == -1 || todayIndex >= widget.prayerWeek.length) {
      return '--:--';
    }

    return widget.prayerWeek[todayIndex][_prayerKeys[prayerIndex]] ?? '--:--';
  }

  List<PrayerTodayRowData> _buildRows() {
    return List<PrayerTodayRowData>.generate(_prayers.length, (index) {
      final PrayerTodayRowState state = _rowState(index);

      return PrayerTodayRowData(
        prayerName: _prayers[index],
        timeText: _prayerTimeText(index),
        statusText: _rowStatusText(index),
        state: state,
        enabled: _canEditPrayer(index),
        onTap: () => _onPrayerChanged(index, !_checked[index]),
      );
    });
  }

  Future<void> _pushPage(Widget page) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  Future<void> _openPage(Widget page) async {
    AppHaptics.tap(context);
    await _pushPage(page);
  }

  Future<void> _openQiblaPage() async {
    await _openPage(const QiblaDirectionPage());
  }

  Future<void> _openAfterPrayerAzkar() async {
    final category = ZekrLocalData.getCategoryById(
      ZekrLocalData.afterPrayerId,
    );

    await _openPage(
      ZekrReadingPage(category: category),
    );
  }

  Future<void> _openReminderSettings() async {
    AppHaptics.tap(context);

    final provider = context.read<PrayerNotificationSettingsProvider>();

    if (!provider.isLoaded) {
      await provider.loadSettings();
    }

    if (!mounted) return;

    if (!provider.enabled) {
      final bool shouldEnable = await _askToEnablePrayerReminders();

      if (!mounted || !shouldEnable) return;

      await provider.setEnabled(true);

      if (!mounted) return;

      if (!provider.enabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'لم يتم تفعيل تذكيرات الصلاة. راجع صلاحيات الإشعارات أو حدّث مواقيت الصلاة.',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }
    }

    await _pushPage(const ReminderSettingsPage());
  }

  Future<bool> _askToEnablePrayerReminders() async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final colors = theme.colorScheme;
        final bool isDark = theme.brightness == Brightness.dark;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: isDark ? colors.secondary : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22.r),
            ),
            title: Text(
              'التذكيرات غير مفعلة',
              textAlign: TextAlign.right,
              style: AppTextStyles.body(dialogContext).copyWith(
                color: colors.surface,
                fontSize: widget.large ? 18 : 14.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
            content: Text(
              'تحب نفعّل تذكيرات الصلاة الآن وبعدها نفتح صفحة الإعدادات؟',
              textAlign: TextAlign.right,
              style: AppTextStyles.caption(dialogContext).copyWith(
                color: colors.surface.withOpacity(0.70),
                fontSize: widget.large ? 14 : 10.sp,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
            actionsAlignment: MainAxisAlignment.start,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(
                  'إلغاء',
                  style: AppTextStyles.caption(dialogContext).copyWith(
                    color: colors.surface.withOpacity(0.55),
                    fontSize: widget.large ? 13 : 9.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(
                  'تفعيل وفتح',
                  style: AppTextStyles.caption(dialogContext).copyWith(
                    color: colors.primary,
                    fontSize: widget.large ? 13 : 9.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final int completedPrayers = _checked.where((value) => value).length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        PrayerTodayTrackingCard(
          large: widget.large,
          isLoading: !_isLoaded,
          rows: _buildRows(),
        ),
        SizedBox(height: widget.large ? 12 : 10.h),
        PrayerTrackingStatsCard(
          large: widget.large,
          isLoading: !_isLoaded,
          completedPrayers: completedPrayers,
          totalPrayers: _checked.length,
          currentStreak: _streak,
          bestStreak: _bestStreak,
        ),
        SizedBox(height: widget.large ? 12 : 10.h),
        PrayerQuickActionsSection(
          large: widget.large,
          onAfterPrayerAzkarTap: _openAfterPrayerAzkar,
          onQiblaTap: _openQiblaPage,
          onRemindersTap: _openReminderSettings,
        ),
        SizedBox(height: widget.large ? 12 : 10.h),
        PrayerWeeklySummaryCard(
          large: widget.large,
          isLoading: !_isLoaded,
          weeklyHistory: _weeklyHistory,
        ),
        SizedBox(height: widget.large ? 12 : 10.h),
        PrayerMotivationCard(
          large: widget.large,
        ),
      ],
    );
  }
}
