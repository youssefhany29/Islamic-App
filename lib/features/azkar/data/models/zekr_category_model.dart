import 'package:flutter/material.dart';

class ZekrCategoryModel {
  const ZekrCategoryModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isDailyTarget,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isDailyTarget;
}
