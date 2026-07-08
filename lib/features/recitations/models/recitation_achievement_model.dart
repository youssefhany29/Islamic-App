import 'package:flutter/material.dart';

class RecitationAchievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int requiredValue;
  final int currentValue;
  final bool earned;

  const RecitationAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.requiredValue,
    required this.currentValue,
    required this.earned,
  });

  double get progress {
    if (requiredValue <= 0) return earned ? 1 : 0;
    return (currentValue / requiredValue).clamp(0.0, 1.0);
  }
}
