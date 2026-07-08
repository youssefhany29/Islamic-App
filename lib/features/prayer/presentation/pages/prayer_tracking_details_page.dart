import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';
import 'package:islamic_app/shared/widgets/app_main_components/custom_app_bar.dart';
import 'package:islamic_app/shared/widgets/common_components/app_layout_constants.dart';
import 'package:islamic_app/core/adaptive/adaptive_side_navigation.dart';
import 'package:islamic_app/core/adaptive/adaptive_large_screen_shell.dart';
import 'package:islamic_app/features/home/presentation/adaptive/home_large_screen_navigation.dart';
import 'package:islamic_app/features/settings/app_settings_drawer.dart';

import 'package:islamic_app/features/prayer/presentation/widgets/details_widgets/prayer_details_extra_cards.dart';
import 'package:islamic_app/features/prayer/data/services/prayer_tracking_storage.dart';
import 'package:islamic_app/features/prayer/data/services/prayer_tracking_service.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
part 'prayer_tracking_details_widgets.dart';
part 'prayer_tracking_details_layout.dart';
part 'prayer_tracking_details_phone_layout.dart';
part 'prayer_tracking_details_large_layout.dart';

class PrayerTrackingDetailsPage extends StatefulWidget {
  final List<String> prayers;
  final List<bool> checked;
  final int streak;
  final int bestStreak;
  final bool completedToday;
  final List<PrayerWeeklyDay> weeklyHistory;
  final PrayerMonthlyStats monthlyStats;
  final List<Map<String, String>> prayerWeek;

  const PrayerTrackingDetailsPage({
    super.key,
    required this.prayers,
    required this.checked,
    required this.streak,
    required this.bestStreak,
    required this.completedToday,
    required this.weeklyHistory,
    required this.monthlyStats,
    required this.prayerWeek,
  });

  @override
  State<PrayerTrackingDetailsPage> createState() =>
      _PrayerTrackingDetailsPageState();
}

class _PrayerTrackingDetailsPageState extends State<PrayerTrackingDetailsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late List<bool> _checked;
  late int _streak;
  late int _bestStreak;
  late bool _completedToday;
  late List<PrayerWeeklyDay> _weeklyHistory;
  late PrayerMonthlyStats _monthlyStats;

  static const int _onTimeGraceMinutes = 60;
  static const int _lockBeforeNextPrayerMinutes = 30;
  static const List<String> _prayerKeys = [
    'fajr',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
  ];

  @override
  void initState() {
    super.initState();

    _checked = List<bool>.from(widget.checked);
    _streak = widget.streak;
    _bestStreak = widget.bestStreak;
    _completedToday = widget.completedToday;
    _weeklyHistory = List<PrayerWeeklyDay>.from(widget.weeklyHistory);
    _monthlyStats = widget.monthlyStats;
  }

  Future<void> _onPrayerChanged(int index, bool newValue) async {
    final List<bool> optimisticChecked = List<bool>.from(_checked);
    optimisticChecked[index] = newValue;

    if (mounted) {
      setState(() {
        _checked = optimisticChecked;
      });
    }

    final result = await const PrayerTrackingService().changePrayerStatus(
      prayers: widget.prayers,
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
      _monthlyStats = result.monthlyStats;
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

    return _parsePrayerTimeForDayOffset(
      widget.prayerWeek[todayIndex][_prayerKeys[prayerIndex]],
      0,
    );
  }

  DateTime? _getNextPrayerTime({required int prayerIndex}) {
    final int todayIndex = _getTodayPrayerRowIndex();
    if (todayIndex == -1) return null;

    int nextDayIndex = todayIndex;
    int nextPrayerIndex = prayerIndex + 1;
    int dayOffset = 0;

    if (nextPrayerIndex >= _prayerKeys.length) {
      nextPrayerIndex = 0;
      nextDayIndex = todayIndex + 1;
      dayOffset = 1;
    }

    if (nextDayIndex >= widget.prayerWeek.length) {
      return null;
    }

    return _parsePrayerTimeForDayOffset(
      widget.prayerWeek[nextDayIndex][_prayerKeys[nextPrayerIndex]],
      dayOffset,
    );
  }

  DateTime? _getPrayerLockTime(int prayerIndex) {
    final DateTime? prayerTime = _getPrayerTimeToday(prayerIndex);
    if (prayerTime == null) return null;

    final DateTime? nextPrayerTime = _getNextPrayerTime(
      prayerIndex: prayerIndex,
    );

    if (nextPrayerTime == null) {
      return prayerTime.add(const Duration(minutes: _onTimeGraceMinutes));
    }

    final DateTime lockTime = nextPrayerTime.subtract(
      const Duration(minutes: _lockBeforeNextPrayerMinutes),
    );

    if (lockTime.isBefore(prayerTime)) {
      return prayerTime.add(const Duration(minutes: _onTimeGraceMinutes));
    }

    return lockTime;
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

    // قبل وقت الصلاة: ممنوع التسجيل
    if (now.isBefore(prayerTime)) {
      return false;
    }

    // بعد دخول الوقت وحتى بعد القفل: مسموح
    // بعد القفل تعتبر قضاء
    return true;
  }

  String _prayerStatusText(int prayerIndex) {
    if (_checked[prayerIndex]) {
      if (_isPrayerLocked(prayerIndex)) {
        return 'تم قضاؤها';
      }

      return 'تم تسجيلها';
    }

    final DateTime? prayerTime = _getPrayerTimeToday(prayerIndex);
    if (prayerTime == null) return 'اضغط للتسجيل';

    final DateTime now = DateTime.now();

    if (now.isBefore(prayerTime)) {
      return 'لم يدخل وقتها بعد';
    }

    final DateTime graceEnd = prayerTime.add(
      const Duration(minutes: _onTimeGraceMinutes),
    );

    if (_isPrayerLocked(prayerIndex)) {
      return 'صلاة فائتة';
    }

    if (!now.isAfter(graceEnd)) {
      return 'متاحة الآن';
    }

    return 'متاحة للتسجيل حتى وقت القفل';
  }

  Color _prayerStatusColor(int prayerIndex) {
    if (_checked[prayerIndex]) {
      return const Color(0xff21C58E);
    }

    if (_isPrayerLocked(prayerIndex)) {
      return Colors.redAccent;
    }

    final DateTime? prayerTime = _getPrayerTimeToday(prayerIndex);
    if (prayerTime != null && DateTime.now().isBefore(prayerTime)) {
      return Colors.white.withValues(alpha: 0.5);
    }

    return Colors.amber;
  }

  DateTime? _parsePrayerTimeForDayOffset(String? time, int dayOffset) {
    if (time == null || !time.contains(':')) return null;

    final parts = time.split(':');

    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return null;

    final now = DateTime.now();
    final targetDay = now.add(Duration(days: dayOffset));

    return DateTime(
      targetDay.year,
      targetDay.month,
      targetDay.day,
      hour,
      minute,
    );
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

  @override
  Widget build(BuildContext context) {
    return _buildPrayerTrackingDetailsScaffold(context);
  }
}
