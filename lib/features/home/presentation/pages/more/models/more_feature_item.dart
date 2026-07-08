import 'package:flutter/widgets.dart';

class MoreFeatureItem {
  const MoreFeatureItem({
    required this.title,
    required this.subtitle,
    required this.asset,
    required this.page,
  });

  final String title;
  final String subtitle;
  final String asset;
  final Widget page;
}