import 'package:flutter/material.dart';

enum IslamicEventType {
  fasting,
  greeting,
  specialDay,
  reminder,
}

class IslamicEventModel {
  final String title;
  final String subtitle;
  final String hijriDateText;
  final DateTime gregorianDate;
  final IconData icon;
  final IslamicEventType type;
  final bool isToday;

  const IslamicEventModel({
    required this.title,
    required this.subtitle,
    required this.hijriDateText,
    required this.gregorianDate,
    required this.icon,
    required this.type,
    required this.isToday,
  });
}