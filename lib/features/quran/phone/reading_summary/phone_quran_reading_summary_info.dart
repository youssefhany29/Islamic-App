class PhoneQuranReadingSummaryInfo {
  const PhoneQuranReadingSummaryInfo({
    required this.readPages,
    required this.completedWirds,
    required this.currentStreakDays,
    required this.activeKhatmas,
    required this.nearestKhatmaProgressPercent,
  });

  final int readPages;
  final int completedWirds;
  final int currentStreakDays;
  final int activeKhatmas;
  final int nearestKhatmaProgressPercent;

  double get nearestKhatmaProgress =>
      (nearestKhatmaProgressPercent / 100).clamp(0.0, 1.0).toDouble();
}
