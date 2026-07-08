import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hijri_calendar/hijri_calendar.dart';
import 'package:islamic_app/core/services/app_haptics.dart';
import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/home/presentation/phone/widgets/prayer_hero_background_resolver.dart';
import 'package:islamic_app/features/prayer/data/services/prayer_time_service.dart';
import 'package:islamic_app/features/settings/prayer_background_style_provider.dart';
import 'package:islamic_app/shared/widgets/common_components/app_layout_constants.dart';
import 'package:provider/provider.dart';

class PhonePrayerHeroCard extends StatefulWidget {
  const PhonePrayerHeroCard({
    super.key,
    required this.prayerWeek,
    required this.locationLabel,
    required this.isLoadingPrayerTimes,
    required this.onRefresh,
    this.lastUpdatedAt,
  });

  final List<Map<String, String>> prayerWeek;
  final String locationLabel;
  final bool isLoadingPrayerTimes;
  final DateTime? lastUpdatedAt;
  final VoidCallback onRefresh;

  @override
  State<PhonePrayerHeroCard> createState() => _PhonePrayerHeroCardState();
}

class _PhonePrayerHeroCardState extends State<PhonePrayerHeroCard> {
  Timer? _timer;
  _PrayerHeroNextInfo? _nextInfo;
  String? _countryIso;
  String _backgroundAsset = PrayerHeroBackgroundResolver.fallbackAsset;

  static const List<_PrayerHeroItem> _prayers = [
    _PrayerHeroItem(name: 'الفجر', assetKey: 'fajr', key: 'fajr'),
    _PrayerHeroItem(name: 'الظهر', assetKey: 'dhuhr', key: 'dhuhr'),
    _PrayerHeroItem(name: 'العصر', assetKey: 'asr', key: 'asr'),
    _PrayerHeroItem(name: 'المغرب', assetKey: 'maghrib', key: 'maghrib'),
    _PrayerHeroItem(name: 'العشاء', assetKey: 'isha', key: 'isha'),
  ];

  @override
  void initState() {
    super.initState();
    _loadCountryIso();
    _updateHeroState();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateHeroState(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheBackground(_backgroundAsset);
  }

  @override
  void didUpdateWidget(covariant PhonePrayerHeroCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.prayerWeek != widget.prayerWeek) {
      _loadCountryIso();
      _updateHeroState();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadCountryIso() async {
    final String? countryIso = await const PrayerTimeService()
        .getCachedPrayerCountryIso();

    if (!mounted || countryIso == _countryIso) return;

    setState(() {
      _countryIso = countryIso;
    });

    _updateHeroState();
  }

  void _updateHeroState() {
    final DateTime now = DateTime.now();
    final _PrayerHeroNextInfo? info = _calculateNextPrayer(now: now);
    final PrayerBackgroundStyle backgroundStyle =
        Provider.of<PrayerBackgroundStyleProvider>(
          context,
          listen: false,
        ).style;
    final String backgroundAsset = PrayerHeroBackgroundResolver.resolve(
      prayerWeek: widget.prayerWeek,
      countryIso: _countryIso,
      now: now,
      backgroundStyle: backgroundStyle,
    );

    if (!mounted) return;

    final bool backgroundChanged = _backgroundAsset != backgroundAsset;
    final bool shouldUpdate = _nextInfo != info || backgroundChanged;

    if (!shouldUpdate) return;

    setState(() {
      _nextInfo = info;
      _backgroundAsset = backgroundAsset;
    });

    if (backgroundChanged) {
      _precacheBackground(backgroundAsset);
    }
  }

  void _precacheBackground(String asset) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      precacheImage(AssetImage(asset), context);
    });
  }

  _PrayerHeroNextInfo? _calculateNextPrayer({required DateTime now}) {
    if (widget.prayerWeek.isEmpty) return null;

    final List<_PrayerHeroParsedItem> parsedPrayers = [];

    for (int dayOffset = 0; dayOffset < widget.prayerWeek.length; dayOffset++) {
      final Map<String, String> day = widget.prayerWeek[dayOffset];
      final DateTime baseDate =
          _parseDate(day['date']) ??
          DateTime(now.year, now.month, now.day + dayOffset);

      for (final prayer in _prayers) {
        final DateTime? prayerTime = _parseTime(day[prayer.key], baseDate);
        if (prayerTime == null) continue;

        parsedPrayers.add(
          _PrayerHeroParsedItem(
            name: prayer.name,
            assetKey: prayer.assetKey,
            time: prayerTime,
          ),
        );
      }
    }

    parsedPrayers.sort((a, b) => a.time.compareTo(b.time));

    for (final prayer in parsedPrayers) {
      if (prayer.time.isAfter(now) || prayer.time.isAtSameMomentAs(now)) {
        final Duration remaining = prayer.time.difference(now);

        return _PrayerHeroNextInfo(
          name: prayer.name,
          assetKey: prayer.assetKey,
          prayerTime: prayer.time,
          remainingText: _formatRemaining(remaining),
          hijriText: _formatHijriDate(prayer.time),
        );
      }
    }

    return null;
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    try {
      final DateTime parsed = DateTime.parse(value.trim());
      return DateTime(parsed.year, parsed.month, parsed.day);
    } catch (_) {
      return null;
    }
  }

  DateTime? _parseTime(String? time, DateTime baseDate) {
    if (time == null || !time.contains(':')) return null;

    final List<String> parts = time.split(':');
    if (parts.length < 2) return null;

    final int? hour = int.tryParse(parts[0]);
    final int? minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return null;

    return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
  }

  String _formatDisplayTime(DateTime dateTime) {
    int hour = dateTime.hour;
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    final String period = hour >= 12 ? 'م' : 'ص';

    hour = hour % 12;
    if (hour == 0) hour = 12;

    return '${_arabicDigits(hour)}:$minute $period';
  }

  String _formatRemaining(Duration duration) {
    final Duration safeDuration = duration.isNegative
        ? Duration.zero
        : duration;
    final int hours = safeDuration.inHours;
    final int minutes = safeDuration.inMinutes.remainder(60);

    if (hours <= 0) {
      return '${_arabicDigits(minutes)} د';
    }

    return '${_arabicDigits(hours)} س و ${_arabicDigits(minutes)} د';
  }

  String _formatHijriDate(DateTime date) {
    try {
      HijriCalendarConfig.language = 'ar';
      final HijriCalendarConfig hijri = HijriCalendarConfig.fromGregorian(date);
      final String weekday = _weekdayName(date.weekday);

      return '$weekday ${_arabicDigits(hijri.hDay)} ${_hijriMonthName(hijri.hMonth)} ${_arabicDigits(hijri.hYear)} هـ';
    } catch (_) {
      final String weekday = _weekdayName(date.weekday);
      return '$weekday ${_arabicDigits(date.day)}-${_arabicDigits(date.month)}-${_arabicDigits(date.year)}';
    }
  }

  String _weekdayName(int weekday) {
    const List<String> names = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];

    return names[(weekday - 1).clamp(0, 6).toInt()];
  }

  String _hijriMonthName(int month) {
    const List<String> months = [
      'محرم',
      'صفر',
      'ربيع الأول',
      'ربيع الآخر',
      'جمادى الأولى',
      'جمادى الآخرة',
      'رجب',
      'شعبان',
      'رمضان',
      'شوال',
      'ذو القعدة',
      'ذو الحجة',
    ];

    final int index = (month - 1).clamp(0, 11).toInt();
    return months[index];
  }

  String _updatedText() {
    final DateTime? updatedAt = widget.lastUpdatedAt;

    if (updatedAt == null) {
      return 'تحديث الآن';
    }

    return 'تحديث ${_formatDisplayTime(updatedAt)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final _PrayerHeroNextInfo? info = _nextInfo;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: AppLayoutConstants.mainCardWidth,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22.r),
          child: Container(
            height: 170.h,
            decoration: BoxDecoration(
              color: colors.primary,
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withOpacity(isDark ? 0.16 : 0.20),
                  blurRadius: 18.r,
                  offset: Offset(0, 9.h),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 850),
                    switchInCurve: Curves.easeInOutCubic,
                    switchOutCurve: Curves.easeInOutCubic,
                    layoutBuilder: (currentChild, previousChildren) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      );
                    },
                    transitionBuilder: (child, animation) {
                      final Animation<double> fade = CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOutCubic,
                      );
                      final Animation<double> scale = Tween<double>(
                        begin: 1.03,
                        end: 1,
                      ).animate(fade);
                      final Animation<Offset> slide = Tween<Offset>(
                        begin: const Offset(0.018, 0),
                        end: Offset.zero,
                      ).animate(fade);

                      return FadeTransition(
                        opacity: fade,
                        child: SlideTransition(
                          position: slide,
                          child: ScaleTransition(scale: scale, child: child),
                        ),
                      );
                    },
                    child: Image.asset(
                      _backgroundAsset,
                      key: ValueKey<String>(_backgroundAsset),
                      fit: BoxFit.cover,
                      alignment: Alignment.centerLeft,
                      errorBuilder: (_, __, ___) => Image.asset(
                        PrayerHeroBackgroundResolver.fallbackAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [
                                colors.primary,
                                colors.primary.withOpacity(0.90),
                                const Color(0xFF061827),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withOpacity(0.00),
                          colors.primary.withOpacity(0.22),
                          colors.primary.withOpacity(0.86),
                        ],
                        stops: const [0.0, 0.56, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.03),
                          Colors.black.withOpacity(0.10),
                          Colors.black.withOpacity(0.30),
                        ],
                      ),
                    ),
                  ),
                ),
                if (widget.isLoadingPrayerTimes)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                else if (info == null)
                  Center(
                    child: Text(
                      'تعذر تحميل مواقيت الصلاة',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption(context).copyWith(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  _PrayerHeroContent(
                    info: info,
                    locationLabel: widget.locationLabel,
                    updatedText: _updatedText(),
                    onRefresh: widget.onRefresh,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrayerHeroContent extends StatelessWidget {
  const _PrayerHeroContent({
    required this.info,
    required this.locationLabel,
    required this.updatedText,
    required this.onRefresh,
  });

  final _PrayerHeroNextInfo info;
  final String locationLabel;
  final String updatedText;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final String cleanLocation = locationLabel.trim().isEmpty
        ? 'موقعك'
        : locationLabel.trim();

    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              _HeaderBadge(
                icon: Icons.notifications_active_outlined,
                label: 'الصلاة القادمة',
              ),
            ],
          ),

          SizedBox(height: 6.h),

          Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  info.name,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headline(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 34.sp,
                    height: 0.92,
                  ),
                ),
                SizedBox(height: 10.h),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  textDirection: TextDirection.rtl,
                  children: [
                    Text(
                      'باقي ',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.caption(context).copyWith(
                        color: Colors.white.withOpacity(0.90),
                        fontWeight: FontWeight.w900,
                        fontSize: 12.sp,
                        height: 1,
                      ),
                    ),
                    Text(
                      info.remainingText,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                        color: const Color(0xFF36D08E),
                        fontWeight: FontWeight.w900,
                        fontSize: 12.sp,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 12.h),

          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 126.w,
              height: 0.7.h,
              color: Colors.white.withOpacity(0.14),
            ),
          ),

          const Spacer(),

          Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: SizedBox(
                    width: 170.w,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _BottomInfoLine(
                          icon: Icons.calendar_month_rounded,
                          text: info.hijriText,
                        ),
                        SizedBox(height: 8.h),
                        _BottomInfoLine(
                          icon: Icons.location_on_rounded,
                          text: cleanLocation,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(width: 10.w),

              _UpdateChip(text: updatedText, onTap: onRefresh),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.86), size: 12.5.sp),
        SizedBox(width: 5.w),
        Text(
          label,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: AppTextStyles.caption(context).copyWith(
            color: Colors.white.withOpacity(0.84),
            fontSize: 9.sp,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _BottomInfoLine extends StatelessWidget {
  const _BottomInfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170.w,
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 14.w,
            child: Icon(
              icon,
              color: Colors.white.withOpacity(0.84),
              size: 12.sp,
            ),
          ),
          SizedBox(width: 5.w),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
                color: Colors.white.withOpacity(0.82),
                fontSize: 8.sp,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdateChip extends StatelessWidget {
  const _UpdateChip({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999.r),
        onTap: () {
          AppHaptics.tap(context);
          onTap();
        },
        child: Container(
          height: 24.h,
          padding: EdgeInsets.symmetric(horizontal: 9.w),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.18),
            borderRadius: BorderRadius.circular(999.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 0.8.w,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                Icons.refresh_rounded,
                color: Colors.white.withOpacity(0.84),
                size: 11.sp,
              ),
              SizedBox(width: 4.w),
              Text(
                text,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  color: Colors.white.withOpacity(0.84),
                  fontSize: 7.5.sp,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrayerHeroItem {
  const _PrayerHeroItem({
    required this.name,
    required this.assetKey,
    required this.key,
  });

  final String name;
  final String assetKey;
  final String key;
}

class _PrayerHeroParsedItem {
  const _PrayerHeroParsedItem({
    required this.name,
    required this.assetKey,
    required this.time,
  });

  final String name;
  final String assetKey;
  final DateTime time;
}

class _PrayerHeroNextInfo {
  const _PrayerHeroNextInfo({
    required this.name,
    required this.assetKey,
    required this.prayerTime,
    required this.remainingText,
    required this.hijriText,
  });

  final String name;
  final String assetKey;
  final DateTime prayerTime;
  final String remainingText;
  final String hijriText;

  @override
  bool operator ==(Object other) {
    return other is _PrayerHeroNextInfo &&
        other.name == name &&
        other.assetKey == assetKey &&
        other.prayerTime == prayerTime &&
        other.remainingText == remainingText &&
        other.hijriText == hijriText;
  }

  @override
  int get hashCode =>
      Object.hash(name, assetKey, prayerTime, remainingText, hijriText);
}

String _arabicDigits(Object value) {
  return value
      .toString()
      .replaceAll('0', '0')
      .replaceAll('1', '1')
      .replaceAll('2', '2')
      .replaceAll('3', '3')
      .replaceAll('4', '4')
      .replaceAll('5', '5')
      .replaceAll('6', '6')
      .replaceAll('7', '7')
      .replaceAll('8', '8')
      .replaceAll('9', '9');
}
