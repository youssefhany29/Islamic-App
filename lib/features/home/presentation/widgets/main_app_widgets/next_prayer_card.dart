import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/shared/widgets/common_components/app_layout_constants.dart';

import 'qibla_direction_page.dart';

class NextPrayerCard extends StatefulWidget {
  final List<Map<String, String>> prayerWeek;

  const NextPrayerCard({
    super.key,
    required this.prayerWeek,
  });

  @override
  State<NextPrayerCard> createState() => _NextPrayerCardState();
}

class _NextPrayerCardState extends State<NextPrayerCard> {
  Timer? _timer;
  _NextPrayerInfo? _nextPrayerInfo;

  @override
  void initState() {
    super.initState();
    _updateNextPrayer();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        _updateNextPrayer();
      },
    );
  }

  @override
  void didUpdateWidget(covariant NextPrayerCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.prayerWeek != widget.prayerWeek) {
      _updateNextPrayer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateNextPrayer() {
    final _NextPrayerInfo? nextPrayerInfo =
    _calculateNextPrayer(widget.prayerWeek);

    if (!mounted) return;

    if (_nextPrayerInfo == nextPrayerInfo) {
      return;
    }

    setState(() {
      _nextPrayerInfo = nextPrayerInfo;
    });
  }

  void _openQiblaPage() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const QiblaDirectionPage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  _NextPrayerInfo? _calculateNextPrayer(
      List<Map<String, String>> prayerWeek,
      ) {
    if (prayerWeek.isEmpty) return null;

    final DateTime now = DateTime.now();
    final List<_PrayerItem> prayerItems = [];

    for (int dayOffset = 0; dayOffset < prayerWeek.length; dayOffset++) {
      final Map<String, String> day = prayerWeek[dayOffset];

      final DateTime baseDate = _parseDate(day['date']) ??
          DateTime(
            now.year,
            now.month,
            now.day + dayOffset,
          );

      prayerItems.addAll([
        _PrayerItem(name: 'الفجر', time: _parseTime(day['fajr'], baseDate)),
        _PrayerItem(name: 'الظهر', time: _parseTime(day['dhuhr'], baseDate)),
        _PrayerItem(name: 'العصر', time: _parseTime(day['asr'], baseDate)),
        _PrayerItem(name: 'المغرب', time: _parseTime(day['maghrib'], baseDate)),
        _PrayerItem(name: 'العشاء', time: _parseTime(day['isha'], baseDate)),
      ]);
    }

    final List<_PrayerItem> validPrayerItems = prayerItems
        .where((item) => item.time != null)
        .map(
          (item) => _PrayerItem(
        name: item.name,
        time: item.time!,
      ),
    )
        .toList();

    validPrayerItems.sort(
          (a, b) => a.time!.compareTo(b.time!),
    );

    for (final _PrayerItem item in validPrayerItems) {
      final DateTime prayerTime = item.time!;

      if (prayerTime.isAfter(now) || prayerTime.isAtSameMomentAs(now)) {
        final Duration remaining = prayerTime.difference(now);

        return _NextPrayerInfo(
          name: item.name,
          timeText: _formatTime(prayerTime),
          remainingText: _formatDuration(remaining),
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

    if (parts.length != 2) return null;

    final int? hour = int.tryParse(parts[0]);
    final int? minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return null;

    return DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      hour,
      minute,
    );
  }

  String _formatTime(DateTime dateTime) {
    int hour = dateTime.hour;
    final String minute = dateTime.minute.toString().padLeft(2, '0');

    final String period = hour >= 12 ? 'PM' : 'AM';

    hour = hour % 12;

    if (hour == 0) {
      hour = 12;
    }

    return '$hour:$minute';
  }

  String _formatDuration(Duration duration) {
    final Duration safeDuration =
    duration.isNegative ? Duration.zero : duration;

    final String hours = safeDuration.inHours.toString().padLeft(2, '0');
    final String minutes =
    (safeDuration.inMinutes % 60).toString().padLeft(2, '0');
    final String seconds =
    (safeDuration.inSeconds % 60).toString().padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_nextPrayerInfo == null) {
      return const SizedBox.shrink();
    }

    final ThemeData theme = Theme.of(context);
    final Size size = MediaQuery.sizeOf(context);

    final bool isPhone = size.width < 600;
    final bool isFoldLandscape = size.width >= 600 && size.shortestSide < 600;

    final _NextPrayerInfo nextPrayerInfo = _nextPrayerInfo!;

    final double cardHorizontalPadding = isPhone
        ? 12.w
        : isFoldLandscape
        ? 16
        : 22;

    final double cardVerticalPadding = isPhone
        ? 12.h
        : isFoldLandscape
        ? 14
        : 18;

    final double headerHeight = isPhone
        ? 40.h
        : isFoldLandscape
        ? 54
        : 72;

    final double headerGap = isPhone ? 12.h : 16;

    final double headerIconSize = isPhone
        ? 21.sp
        : isFoldLandscape
        ? 24
        : 30;

    final double headerTitleSize = isPhone
        ? 15.sp
        : isFoldLandscape
        ? 17
        : 24;

    final double innerHorizontalPadding = isPhone
        ? 12.w
        : isFoldLandscape
        ? 20
        : 28;

    final double innerVerticalPadding = isPhone
        ? 10.h
        : isFoldLandscape
        ? 14
        : 18;

    final double blackCardHeight = isPhone
        ? 70.h
        : isFoldLandscape
        ? 92
        : 112;

    final double timeSize = isPhone
        ? 17.sp
        : isFoldLandscape
        ? 23
        : 32;

    final double prayerNameSize = isPhone
        ? 18.sp
        : isFoldLandscape
        ? 25
        : 36;

    final double timeLabelSize = isPhone
        ? 9.sp
        : isFoldLandscape
        ? 11
        : 14;

    final double remainingSize = isPhone
        ? 10.sp
        : isFoldLandscape
        ? 13
        : 17;

    final double textGap = isPhone
        ? 2.h
        : isFoldLandscape
        ? 4
        : 6;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: isPhone ? AppLayoutConstants.mainCardWidth : double.infinity,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: cardHorizontalPadding,
            vertical: cardVerticalPadding,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(
              AppLayoutConstants.mainCardRadius,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: headerHeight,
                width: double.infinity,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        textDirection: TextDirection.rtl,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            color: Colors.white,
                            size: headerIconSize,
                          ),
                          SizedBox(width: isPhone ? 8.w : 10),
                          Text(
                            'الصلاة القادمة',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'cairo',
                              fontSize: headerTitleSize,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: _QiblaShortcutButton(
                        onTap: _openQiblaPage,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: headerGap),

              Container(
                width: double.infinity,
                height: blackCardHeight,
                padding: EdgeInsets.symmetric(
                  horizontal: innerHorizontalPadding,
                  vertical: innerVerticalPadding,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xff171B26),
                  borderRadius: BorderRadius.circular(
                    isPhone ? 16.r : 20,
                  ),
                ),

                /// مهم:
                /// Directionality.ltr هنا علشان أول عنصر يبقى أقصى الشمال
                /// وآخر عنصر يبقى أقصى اليمين، حتى لو الصفحة كلها RTL.
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // الساعة أقصى الشمال
                      Flexible(
                        flex: 4,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                nextPrayerInfo.timeText,
                                textAlign: TextAlign.left,
                                textDirection: TextDirection.ltr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'cairo',
                                  fontSize: timeSize,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.0,
                                ),
                              ),
                              SizedBox(height: textGap),
                              Text(
                                'الوقت',
                                textAlign: TextAlign.left,
                                textDirection: TextDirection.rtl,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'cairo',
                                  fontSize: timeLabelSize,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.6),
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(width: isPhone ? 10.w : 18),

                      // اسم الصلاة أقصى اليمين
                      Flexible(
                        flex: 7,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                nextPrayerInfo.name,
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.rtl,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'cairo',
                                  fontSize: prayerNameSize,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.0,
                                ),
                              ),
                              SizedBox(height: textGap),
                              Text(
                                'متبقي ${nextPrayerInfo.remainingText}',
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.rtl,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'cairo',
                                  fontSize: remainingSize,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.7),
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

class _QiblaShortcutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _QiblaShortcutButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final bool isPhone = size.width < 600;
    final bool isFoldLandscape = size.width >= 600 && size.shortestSide < 600;

    final double buttonWidth = isPhone
        ? 48.w
        : isFoldLandscape
        ? 64
        : 90;

    final double buttonHeight = isPhone
        ? 40.h
        : isFoldLandscape
        ? 54
        : 72;

    final double circleSize = isPhone
        ? 27.w
        : isFoldLandscape
        ? 36
        : 48;

    final double imageSize = isPhone
        ? 16.w
        : isFoldLandscape
        ? 23
        : 32;

    final double labelSize = isPhone
        ? 8.5.sp
        : isFoldLandscape
        ? 12
        : 14;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: buttonWidth,
        height: buttonHeight,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: circleSize,
                  height: circleSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.35),
                      width: isPhone ? 1.w : 1,
                    ),
                  ),
                  child: Image.asset(
                    'assets/icons/kaaba (1).png',
                    width: imageSize,
                    height: imageSize,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.explore_rounded,
                        color: Colors.white,
                        size: imageSize,
                      );
                    },
                  ),
                ),
                SizedBox(height: isPhone ? 2.h : 3),
                Text(
                  'القبلة',
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'cairo',
                    fontSize: labelSize,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withOpacity(0.95),
                    height: 1.0,
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

class _PrayerItem {
  final String name;
  final DateTime? time;

  const _PrayerItem({
    required this.name,
    required this.time,
  });
}

class _NextPrayerInfo {
  final String name;
  final String timeText;
  final String remainingText;

  const _NextPrayerInfo({
    required this.name,
    required this.timeText,
    required this.remainingText,
  });

  @override
  bool operator ==(Object other) {
    return other is _NextPrayerInfo &&
        other.name == name &&
        other.timeText == timeText &&
        other.remainingText == remainingText;
  }

  @override
  int get hashCode => Object.hash(name, timeText, remainingText);
}