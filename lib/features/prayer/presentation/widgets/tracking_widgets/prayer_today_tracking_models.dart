import 'package:flutter/widgets.dart';

enum PrayerTodayRowState {
  completed,
  current,
  future,
  missed,
}

class PrayerTodayRowData {
  const PrayerTodayRowData({
    required this.prayerName,
    required this.timeText,
    required this.statusText,
    required this.state,
    required this.enabled,
    required this.onTap,
  });

  final String prayerName;
  final String timeText;
  final String statusText;
  final PrayerTodayRowState state;
  final bool enabled;
  final VoidCallback onTap;
}
