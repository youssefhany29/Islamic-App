import 'package:flutter/material.dart';

import 'package:islamic_app/features/memorization/presentation/widgets/analytics/analytics_ui.dart';

class ReviewScheduleColors {
  const ReviewScheduleColors._();

  static const Color memorization = AnalyticsColors.blue;
  static const Color review = AnalyticsColors.orange;
  static const Color rescue = AnalyticsColors.red;
  static const Color test = AnalyticsColors.purple;

  static Color taskColor(String taskType, {bool isRescue = false}) {
    if (isRescue || taskType == 'weakReview') return rescue;
    if (taskType == 'selfTest') return test;
    if (taskType == 'dailyReview') return review;
    return memorization;
  }

  static IconData taskIcon(String taskType, {bool isRescue = false}) {
    if (isRescue || taskType == 'weakReview') return Icons.healing_rounded;
    if (taskType == 'selfTest') return Icons.fact_check_rounded;
    if (taskType == 'dailyReview') return Icons.repeat_rounded;
    return Icons.menu_book_rounded;
  }
}

class ReviewScheduleText {
  const ReviewScheduleText._();

  static String monthTitle(DateTime month) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];

    return '${months[month.month - 1]} ${month.year}';
  }

  static String dayName(DateTime date) {
    const days = [
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];

    return days[date.weekday - 1];
  }

  static String dateTitle(DateTime date) {
    return '${dayName(date)} ${date.day}';
  }
}
