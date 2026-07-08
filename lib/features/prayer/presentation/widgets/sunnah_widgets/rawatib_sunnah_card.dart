import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';
import 'package:islamic_app/shared/widgets/common_components/app_layout_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class RawatibSunnahCard extends StatefulWidget {
  final List<Map<String, String>> prayerWeek;
  final bool large;

  const RawatibSunnahCard({
    super.key,
    this.prayerWeek = const [],
    this.large = false,
  });

  @override
  State<RawatibSunnahCard> createState() => _RawatibSunnahCardState();
}

class _RawatibSunnahCardState extends State<RawatibSunnahCard> {
  static const String _storageKey = 'rawatib_sunnah_today';
  static const String _dateKey = 'rawatib_sunnah_date';
  static const String _historyKey = 'rawatib_sunnah_history';
  static const int _afterPrayerGraceMinutes = 60;
  static const int _lockBeforeNextPrayerMinutes = 30;

  static const List<String> _prayerKeys = [
    'fajr',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
  ];

  final List<_RawatibItem> _items = const [
    _RawatibItem(
      id: 'fajr_before',
      title: 'قبل الفجر',
      count: '٢ ركعة',
      relatedPrayerIndex: 0,
      type: _RawatibTimeType.before,
      highlight: true,
    ),
    _RawatibItem(
      id: 'dhuhr_before',
      title: 'قبل الظهر',
      count: '٤ ركعات',
      relatedPrayerIndex: 1,
      type: _RawatibTimeType.before,
    ),
    _RawatibItem(
      id: 'dhuhr_after',
      title: 'بعد الظهر',
      count: '٢ ركعة',
      relatedPrayerIndex: 1,
      type: _RawatibTimeType.after,
    ),
    _RawatibItem(
      id: 'maghrib_after',
      title: 'بعد المغرب',
      count: '٢ ركعة',
      relatedPrayerIndex: 3,
      type: _RawatibTimeType.after,
    ),
    _RawatibItem(
      id: 'isha_after',
      title: 'بعد العشاء',
      count: '٢ ركعة',
      relatedPrayerIndex: 4,
      type: _RawatibTimeType.after,
    ),
  ];

  List<bool> _checked = List<bool>.filled(5, false);
  Map<String, List<bool>> _history = {};
  bool _isLoaded = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadRawatib();
  }

  String _todayKey() {
    final now = DateTime.now();

    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadRawatib() async {
    final prefs = await SharedPreferences.getInstance();

    final savedDate = prefs.getString(_dateKey);
    final today = _todayKey();
    final savedHistory = _decodeHistory(prefs.getString(_historyKey));

    if (savedDate != today) {
      final resetList = List<bool>.filled(_items.length, false);

      savedHistory[today] = resetList;

      await prefs.setString(_dateKey, today);
      await prefs.setStringList(
        _storageKey,
        resetList.map((value) => value.toString()).toList(),
      );
      await prefs.setString(_historyKey, _encodeHistory(savedHistory));

      if (!mounted) return;

      setState(() {
        _checked = resetList;
        _history = savedHistory;
        _isLoaded = true;
      });

      return;
    }

    final savedList = prefs.getStringList(_storageKey);
    List<bool> todayList = List<bool>.filled(_items.length, false);

    if (savedList != null && savedList.length == _items.length) {
      todayList = savedList.map((value) => value == 'true').toList();
    }

    savedHistory[today] = todayList;
    await prefs.setString(_historyKey, _encodeHistory(savedHistory));

    if (!mounted) return;

    setState(() {
      _checked = todayList;
      _history = savedHistory;
      _isLoaded = true;
    });
  }

  Future<void> _onChanged(int index, bool value) async {
    if (!_canEditSunnah(index)) {
      return;
    }

    setState(() {
      _checked[index] = value;
      _history[_todayKey()] = List<bool>.from(_checked);
    });

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_dateKey, _todayKey());
    await prefs.setStringList(
      _storageKey,
      _checked.map((value) => value.toString()).toList(),
    );
    await prefs.setString(_historyKey, _encodeHistory(_history));
  }

  Map<String, List<bool>> _decodeHistory(String? raw) {
    if (raw == null || raw.isEmpty) return {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return {};

      return decoded.map((key, value) {
        if (value is List) {
          final list = value
              .map((item) => item == true || item.toString() == 'true')
              .toList();

          return MapEntry(
            key,
            list.length == _items.length
                ? list
                : List<bool>.filled(_items.length, false),
          );
        }

        return MapEntry(key, List<bool>.filled(_items.length, false));
      });
    } catch (_) {
      return {};
    }
  }

  String _encodeHistory(Map<String, List<bool>> history) {
    final now = DateTime.now();
    final allowedDates = List<String>.generate(14, (index) {
      final date = now.subtract(Duration(days: index));
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }).toSet();

    final cleanedHistory = <String, List<bool>>{};

    for (final entry in history.entries) {
      if (allowedDates.contains(entry.key)) {
        cleanedHistory[entry.key] = entry.value;
      }
    }

    return jsonEncode(cleanedHistory);
  }

  int _getTodayPrayerRowIndex() {
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

  DateTime? _getNextPrayerTime(int prayerIndex) {
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

  bool _canEditSunnah(int index) {
    final item = _items[index];
    final DateTime? prayerTime = _getPrayerTimeToday(item.relatedPrayerIndex);

    if (prayerTime == null) return true;

    final DateTime now = DateTime.now();
    final DateTime endTime = _getSunnahLockTime(item.relatedPrayerIndex, prayerTime);

    return !now.isBefore(prayerTime) && !now.isAfter(endTime);
  }

  DateTime _getSunnahLockTime(int relatedPrayerIndex, DateTime prayerTime) {
    final DateTime? nextPrayerTime = _getNextPrayerTime(relatedPrayerIndex);

    if (nextPrayerTime == null) {
      return prayerTime.add(
        const Duration(minutes: _afterPrayerGraceMinutes),
      );
    }

    final DateTime lockTime = nextPrayerTime.subtract(
      const Duration(minutes: _lockBeforeNextPrayerMinutes),
    );

    if (lockTime.isBefore(prayerTime)) {
      return prayerTime.add(
        const Duration(minutes: _afterPrayerGraceMinutes),
      );
    }

    return lockTime;
  }

  String _sunnahStatusText(int index) {
    if (_checked[index]) {
      return 'تم تسجيلها';
    }

    final item = _items[index];
    final DateTime? prayerTime = _getPrayerTimeToday(item.relatedPrayerIndex);

    if (prayerTime == null) {
      return 'متاحة اليوم';
    }

    final now = DateTime.now();

    if (_canEditSunnah(index)) {
      return 'متاحة الآن';
    }

    if (now.isBefore(prayerTime)) {
      return 'تفتح عند دخول وقت الصلاة';
    }

    return 'انتهى وقتها';
  }

  Color _sunnahStatusColor(int index) {
    if (_checked[index] || _canEditSunnah(index)) {
      return const Color(0xff21C58E);
    }

    return Colors.white.withOpacity(0.48);
  }

  int get _todayCompletedCount => _checked.where((value) => value).length;

  int get _weeklyCompletedCount {
    int total = 0;

    for (final day in _lastSevenDateKeys()) {
      total += _history[day]?.where((value) => value).length ?? 0;
    }

    return total;
  }

  int get _weeklyPossibleCount => _items.length * 7;

  String get _bestRawatibMessage {
    if (_todayCompletedCount == _items.length) {
      return 'ممتاز جدًا، أتممت سنن اليوم كلها.';
    }

    if (_todayCompletedCount == 0) {
      return 'ابدأ بسنة واحدة اليوم، والقليل الدائم خير.';
    }

    return 'أحسنت، أكمل باقي سنن اليوم قدر استطاعتك.';
  }

  List<String> _lastSevenDateKeys() {
    final now = DateTime.now();

    return List<String>.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    });
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
    final double todayProgress = _todayCompletedCount / _items.length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: widget.large ? double.infinity : AppLayoutConstants.mainCardWidth,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.large ? 12 : 12.w,
            vertical: widget.large ? 10 : 12.h,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(
              AppLayoutConstants.mainCardRadius,
            ),
          ),
          child: !_isLoaded
              ? Padding(
            padding: EdgeInsets.symmetric(vertical: 18.h),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          )
              : Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _RawatibExpandableHeader(
                large: widget.large,
                isExpanded: _isExpanded,
                completedCount: _todayCompletedCount,
                totalCount: _items.length,
                onTap: () {
                  AppHaptics.tap(context);
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
              ),

              SizedBox(height: widget.large ? 7 : 8.h),

              Text(
                _isExpanded
                    ? 'اختَر السنن التي صليتها اليوم، وسيتم حفظ تقدمك تلقائيًا.'
                    : 'إحصائيات سنن اليوم وآخر ٧ أيام بدون إظهار الاختيارات.',
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.72),
                  height: 1.45
),
              ),

              SizedBox(height: widget.large ? 8 : 10.h),

              _RawatibStatsBox(
                large: widget.large,
                todayCompleted: _todayCompletedCount,
                todayTotal: _items.length,
                todayProgress: todayProgress,
                weeklyCompleted: _weeklyCompletedCount,
                weeklyTotal: _weeklyPossibleCount,
                message: _bestRawatibMessage,
              ),

              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(height: widget.large ? 8 : 10.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: widget.large ? 8 : 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xff171B26),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                color: const Color(0xff21C58E),
                                size: 15.sp,
                              ),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: Text(
                                  'اختيارات أنا صليت',
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.rtl,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
                                    color: Colors.white
),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: widget.large ? 7 : 8.h),
                          for (int i = 0; i < _items.length; i++)
                            _RawatibTrackingRow(
                              large: widget.large,
                              item: _items[i],
                              value: _checked[i],
                              enabled: _canEditSunnah(i),
                              statusText: _sunnahStatusText(i),
                              statusColor: _sunnahStatusColor(i),
                              onTap: () => _onChanged(i, !_checked[i]),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 220),
                sizeCurve: Curves.easeOutCubic,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RawatibExpandableHeader extends StatelessWidget {
  final bool large;
  final bool isExpanded;
  final int completedCount;
  final int totalCount;
  final VoidCallback onTap;

  const _RawatibExpandableHeader({
    required this.large,
    required this.isExpanded,
    required this.completedCount,
    required this.totalCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14.r),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Container(
              width: 30.w,
              height: 30.w,
              decoration: BoxDecoration(
                color: const Color(0xffffb300).withOpacity(0.14),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.volunteer_activism_rounded,
                color: const Color(0xffffb300),
                size: large ? 16 : 18.sp,
              ),
            ),

            SizedBox(width: 8.w),

            Expanded(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'سنن الرواتب',
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
                        color: Colors.white
),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'اليوم: $completedCount / $totalCount',
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w600,
                        color: const Color(0xff21C58E)
),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(width: 8.w),

            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 180),
              child: Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: large ? 18 : 20.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RawatibStatsBox extends StatelessWidget {
  final bool large;
  final int todayCompleted;
  final int todayTotal;
  final double todayProgress;
  final int weeklyCompleted;
  final int weeklyTotal;
  final String message;

  const _RawatibStatsBox({
    required this.large,
    required this.todayCompleted,
    required this.todayTotal,
    required this.todayProgress,
    required this.weeklyCompleted,
    required this.weeklyTotal,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 10.w,
        vertical: large ? 8 : 10.h,
      ),
      decoration: BoxDecoration(
        color: const Color(0xff171B26),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 0.8.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              _SmallStatPill(
                large: large,
                title: 'اليوم',
                value: '$todayCompleted / $todayTotal',
              ),
              SizedBox(width: 8.w),
              _SmallStatPill(
                large: large,
                title: 'آخر ٧ أيام',
                value: '$weeklyCompleted / $weeklyTotal',
              ),
            ],
          ),

          SizedBox(height: 9.h),

          ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: LinearProgressIndicator(
              minHeight: 7.h,
              value: todayProgress.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xff21C58E),
              ),
            ),
          ),

          SizedBox(height: 7.h),

          Text(
            message,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.78),
              height: 1.35
),
          ),
        ],
      ),
    );
  }
}

class _SmallStatPill extends StatelessWidget {
  final bool large;
  final String title;
  final String value;

  const _SmallStatPill({
    required this.large,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 8.w,
          vertical: 7.h,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              title,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.62)
),
            ),
            SizedBox(height: 2.h),
            Text(
              value,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
                color: Colors.white
),
            ),
          ],
        ),
      ),
    );
  }
}

class _RawatibTrackingRow extends StatelessWidget {
  final bool large;
  final _RawatibItem item;
  final bool value;
  final bool enabled;
  final String statusText;
  final Color statusColor;
  final VoidCallback onTap;

  const _RawatibTrackingRow({
    required this.large,
    required this.item,
    required this.value,
    required this.enabled,
    required this.statusText,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 7.h),
      child: Opacity(
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: BoxConstraints(
              minHeight: item.highlight ? 48.h : 43.h,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 10.w,
              vertical: 6.h,
            ),
            decoration: BoxDecoration(
              color: value
                  ? Colors.white.withOpacity(0.14)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(13.r),
              border: Border.all(
                color: value ? const Color(0xff21C58E) : Colors.white24,
                width: 0.8.w,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item.title,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
                          color: Colors.white
),
                      ),

                      SizedBox(height: 2.h),

                      Text(
                        item.highlight
                            ? 'ركعتا الفجرِ خيرٌ من الدُّنيا وما فيها'
                            : statusText,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w500,
                          color: item.highlight
                              ? const Color(0xffffb300)
                              : statusColor
),
                      ),

                      if (item.highlight) ...[
                        SizedBox(height: 1.h),
                        Text(
                          statusText,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w500,
                            color: statusColor
),
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(width: 8.w),

                Text(
                  item.count,
                  textDirection: TextDirection.rtl,
                  style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.72)
),
                ),

                SizedBox(width: 10.w),

                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 22.w,
                  height: 22.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: value ? const Color(0xff21C58E) : Colors.transparent,
                    border: Border.all(
                      color: enabled ? Colors.white : Colors.white38,
                      width: 1.3.w,
                    ),
                  ),
                  child: value
                      ? Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 15.sp,
                  )
                      : enabled
                      ? null
                      : Icon(
                    Icons.lock_rounded,
                    color: Colors.white38,
                    size: 13.sp,
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

enum _RawatibTimeType {
  before,
  after,
}

class _RawatibItem {
  final String id;
  final String title;
  final String count;
  final int relatedPrayerIndex;
  final _RawatibTimeType type;
  final bool highlight;

  const _RawatibItem({
    required this.id,
    required this.title,
    required this.count,
    required this.relatedPrayerIndex,
    required this.type,
    this.highlight = false,
  });
}
