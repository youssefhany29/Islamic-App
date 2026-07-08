import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/prayer/data/services/prayer_time_service.dart';
import 'package:islamic_app/features/settings/prayer_background_style_provider.dart';
import 'package:islamic_app/shared/widgets/common_components/app_layout_constants.dart';
import 'package:provider/provider.dart';

import 'prayer_hero_background_resolver.dart';

class PhoneHomeHeroSection extends StatefulWidget {
  const PhoneHomeHeroSection({
    super.key,
    required this.userName,
    required this.greetingMessage,
    required this.prayerWeek,
    required this.isLoadingPrayerTimes,
    required this.locationLabel,
  });

  final String userName;
  final String greetingMessage;
  final List<Map<String, String>> prayerWeek;
  final bool isLoadingPrayerTimes;
  final String locationLabel;

  @override
  State<PhoneHomeHeroSection> createState() => _PhoneHomeHeroSectionState();
}

class _PhoneHomeHeroSectionState extends State<PhoneHomeHeroSection> {
  Timer? _timer;
  _PhoneNextPrayerInfo? _nextPrayerInfo;
  String? _countryIso;
  String _heroBackgroundAsset = PrayerHeroBackgroundResolver.fallbackAsset;

  @override
  void initState() {
    super.initState();
    _loadCountryIso();
    _updateNextPrayer();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateNextPrayer(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheHeroBackground(_heroBackgroundAsset);
  }

  @override
  void didUpdateWidget(covariant PhoneHomeHeroSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.prayerWeek != widget.prayerWeek) {
      _loadCountryIso();
      _updateNextPrayer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateNextPrayer() {
    final now = DateTime.now();
    final info = _calculateNextPrayer(widget.prayerWeek, now: now);
    final backgroundStyle = Provider.of<PrayerBackgroundStyleProvider>(
      context,
      listen: false,
    ).style;
    final backgroundAsset = PrayerHeroBackgroundResolver.resolve(
      prayerWeek: widget.prayerWeek,
      countryIso: _countryIso,
      now: now,
      backgroundStyle: backgroundStyle,
    );

    if (!mounted) return;
    final bool backgroundChanged = _heroBackgroundAsset != backgroundAsset;

    if (_nextPrayerInfo == info && !backgroundChanged) return;

    setState(() {
      _nextPrayerInfo = info;
      _heroBackgroundAsset = backgroundAsset;
    });

    if (backgroundChanged) {
      _precacheHeroBackground(backgroundAsset);
    }
  }

  Future<void> _loadCountryIso() async {
    final String? countryIso = await const PrayerTimeService()
        .getCachedPrayerCountryIso();
    if (!mounted || countryIso == _countryIso) return;

    setState(() {
      _countryIso = countryIso;
    });
    _updateNextPrayer();
  }

  void _precacheHeroBackground(String asset) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      precacheImage(AssetImage(asset), context);
    });
  }

  _PhoneNextPrayerInfo? _calculateNextPrayer(
    List<Map<String, String>> prayerWeek, {
    DateTime? now,
  }) {
    if (prayerWeek.isEmpty) return null;

    final DateTime currentTime = now ?? DateTime.now();
    final List<_PhonePrayerItem> prayerItems = [];

    for (int dayOffset = 0; dayOffset < prayerWeek.length; dayOffset++) {
      final Map<String, String> day = prayerWeek[dayOffset];

      final DateTime baseDate =
          _parseDate(day['date']) ??
          DateTime(
            currentTime.year,
            currentTime.month,
            currentTime.day + dayOffset,
          );

      prayerItems.addAll([
        _PhonePrayerItem(
          name: 'الفجر',
          assetKey: 'fajr',
          time: _parseTime(day['fajr'], baseDate),
        ),
        _PhonePrayerItem(
          name: 'الشروق',
          assetKey: 'sunrise',
          time: _parseTime(day['sunrise'], baseDate),
        ),
        _PhonePrayerItem(
          name: 'الظهر',
          assetKey: 'dhuhr',
          time: _parseTime(day['dhuhr'], baseDate),
        ),
        _PhonePrayerItem(
          name: 'العصر',
          assetKey: 'asr',
          time: _parseTime(day['asr'], baseDate),
        ),
        _PhonePrayerItem(
          name: 'المغرب',
          assetKey: 'maghrib',
          time: _parseTime(day['maghrib'], baseDate),
        ),
        _PhonePrayerItem(
          name: 'العشاء',
          assetKey: 'isha',
          time: _parseTime(day['isha'], baseDate),
        ),
      ]);
    }

    final validPrayerItems = prayerItems
        .where((item) => item.time != null)
        .map(
          (item) => _PhonePrayerItem(
            name: item.name,
            assetKey: item.assetKey,
            time: item.time!,
          ),
        )
        .toList();

    validPrayerItems.sort((a, b) => a.time!.compareTo(b.time!));

    for (int index = 0; index < validPrayerItems.length; index++) {
      final item = validPrayerItems[index];
      final prayerTime = item.time!;

      if (prayerTime.isAfter(currentTime) ||
          prayerTime.isAtSameMomentAs(currentTime)) {
        final remaining = prayerTime.difference(currentTime);
        final nextItem = index + 1 < validPrayerItems.length
            ? validPrayerItems[index + 1]
            : null;

        return _PhoneNextPrayerInfo(
          name: item.name,
          assetKey: item.assetKey,
          timeText: _formatTime(prayerTime),
          remainingText: _formatDuration(remaining),
          followingPrayerName: nextItem?.name ?? '—',
          followingPrayerTime: nextItem?.time == null
              ? '—'
              : _formatTime(nextItem!.time!),
        );
      }
    }

    return null;
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    try {
      final parsed = DateTime.parse(value.trim());
      return DateTime(parsed.year, parsed.month, parsed.day);
    } catch (_) {
      return null;
    }
  }

  DateTime? _parseTime(String? time, DateTime baseDate) {
    if (time == null || !time.contains(':')) return null;

    final parts = time.split(':');
    if (parts.length < 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return null;

    return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
  }

  String _formatTime(DateTime dateTime) {
    int hour = dateTime.hour;
    final String minute = dateTime.minute.toString().padLeft(2, '0');

    hour = hour % 12;

    if (hour == 0) {
      hour = 12;
    }

    return '$hour:$minute';
  }

  String _formatDuration(Duration duration) {
    final safeDuration = duration.isNegative ? Duration.zero : duration;

    final hours = safeDuration.inHours.toString().padLeft(2, '0');
    final minutes = (safeDuration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (safeDuration.inSeconds % 60).toString().padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final info = _nextPrayerInfo;
    final String backgroundAsset = _heroBackgroundAsset;

    return SizedBox(
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
                      children: <Widget>[
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                  transitionBuilder: (child, animation) {
                    final fade = CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOutCubic,
                    );
                    final scale = Tween<double>(
                      begin: 1.03,
                      end: 1,
                    ).animate(fade);
                    final slide = Tween<Offset>(
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
                    backgroundAsset,
                    key: ValueKey<String>(backgroundAsset),
                    fit: BoxFit.cover,
                    alignment: Alignment.centerLeft,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
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
                        colors.primary.withOpacity(0.20),
                        colors.primary.withOpacity(0.82),
                      ],
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
                        Colors.black.withOpacity(0.04),
                        Colors.black.withOpacity(0.10),
                        Colors.black.withOpacity(0.28),
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
                    style: AppTextStyles.caption(context).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                _HeroPrayerContent(
                  info: info,
                  locationLabel: widget.locationLabel,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroPrayerContent extends StatelessWidget {
  const _HeroPrayerContent({required this.info, required this.locationLabel});

  final _PhoneNextPrayerInfo info;
  final String locationLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 13.h, 14.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              _SmallHeaderBadge(
                icon: Icons.notifications_active_outlined,
                label: 'الصلاة القادمة',
              ),
              const Spacer(),
              _LocationChip(locationLabel: locationLabel),
            ],
          ),
          SizedBox(height: 1.h),
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  info.name,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.headline(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 28.sp,
                    height: 1,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  info.timeText,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.headline(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 24.sp,
                    height: 1,
                  ),
                ),
                SizedBox(height: 6.h),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  textDirection: TextDirection.rtl,
                  children: [
                    Text(
                      'متبقي ${info.remainingText}',
                      textDirection: TextDirection.rtl,
                      style: AppTextStyles.caption(context).copyWith(
                        color: Colors.white.withOpacity(0.86),
                        fontWeight: FontWeight.w600,
                        fontSize: 10.sp,
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Icon(
                      Icons.hourglass_bottom_rounded,
                      size: 12.sp,
                      color: Colors.white.withOpacity(0.80),
                    ),
                  ],
                ),
                SizedBox(height: 5.h),
              ],
            ),
          ),
          const Spacer(),
          Container(
            height: 25.h,
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.13),
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1,
              ),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white.withOpacity(0.82),
                  size: 14.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'الصلاة التالية',
                  style: AppTextStyles.caption(context).copyWith(
                    color: Colors.white.withOpacity(0.64),
                    fontWeight: FontWeight.w600,
                    fontSize: 8.7.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  info.followingPrayerName,
                  style: AppTextStyles.body(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 9.sp,
                  ),
                ),
                const Spacer(),
                Text(
                  info.followingPrayerTime,
                  textDirection: TextDirection.ltr,
                  style: AppTextStyles.body(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11.sp,
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

class _SmallHeaderBadge extends StatelessWidget {
  const _SmallHeaderBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.84), size: 13.sp),
        SizedBox(width: 5.w),
        Text(
          label,
          style: AppTextStyles.caption(context).copyWith(
            color: Colors.white.withOpacity(0.84),
            fontWeight: FontWeight.w600,
            fontSize: 10.5.sp,
          ),
        ),
      ],
    );
  }
}

class _LocationChip extends StatelessWidget {
  const _LocationChip({required this.locationLabel});

  final String locationLabel;

  @override
  Widget build(BuildContext context) {
    final cleanLocation = locationLabel.trim().isEmpty
        ? 'موقعك'
        : locationLabel;

    return Container(
      height: 25.h,
      constraints: BoxConstraints(maxWidth: 105.w),
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          Icon(
            Icons.location_on_outlined,
            color: Colors.white.withOpacity(0.88),
            size: 12.sp,
          ),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(
              cleanLocation,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 9.2.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhonePrayerItem {
  const _PhonePrayerItem({
    required this.name,
    required this.assetKey,
    required this.time,
  });

  final String name;
  final String assetKey;
  final DateTime? time;
}

class _PhoneNextPrayerInfo {
  const _PhoneNextPrayerInfo({
    required this.name,
    required this.assetKey,
    required this.timeText,
    required this.remainingText,
    required this.followingPrayerName,
    required this.followingPrayerTime,
  });

  final String name;
  final String assetKey;
  final String timeText;
  final String remainingText;
  final String followingPrayerName;
  final String followingPrayerTime;

  @override
  bool operator ==(Object other) {
    return other is _PhoneNextPrayerInfo &&
        other.name == name &&
        other.assetKey == assetKey &&
        other.timeText == timeText &&
        other.remainingText == remainingText &&
        other.followingPrayerName == followingPrayerName &&
        other.followingPrayerTime == followingPrayerTime;
  }

  @override
  int get hashCode => Object.hash(
    name,
    assetKey,
    timeText,
    remainingText,
    followingPrayerName,
    followingPrayerTime,
  );
}
