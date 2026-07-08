import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/features/prayer/presentation/widgets/tracking_widgets/prayer_tracking_stat_segment.dart';
import 'package:islamic_app/shared/widgets/common_components/app_layout_constants.dart';

class PrayerTrackingStatsCard extends StatelessWidget {
  const PrayerTrackingStatsCard({
    super.key,
    required this.completedPrayers,
    required this.totalPrayers,
    required this.currentStreak,
    required this.bestStreak,
    required this.isLoading,
    this.large = false,
  });

  final int completedPrayers;
  final int totalPrayers;
  final int currentStreak;
  final int bestStreak;
  final bool isLoading;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color cardColor = isDark ? colors.secondary : Colors.white;
    final Color textColor = colors.surface;
    final int safeTotal = totalPrayers <= 0 ? 1 : totalPrayers;
    final double progress = (completedPrayers / safeTotal).clamp(0.0, 1.0).toDouble();
    final int percent = (progress * 100).round();
    final int displayedBestStreak = bestStreak < currentStreak ? currentStreak : bestStreak;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: large ? double.infinity : AppLayoutConstants.mainCardWidth,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: large ? 14 : 8.w,
            vertical: large ? 12 : 10.h,
          ),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(
              large ? 22 : AppLayoutConstants.mainCardRadius,
            ),
            border: Border.all(
              color: textColor.withOpacity(isDark ? 0.08 : 0.055),
              width: large ? 0.8 : 0.8.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.14 : 0.045),
                blurRadius: large ? 16 : 16.r,
                offset: Offset(0, large ? 7 : 7.h),
              ),
            ],
          ),
          child: isLoading
              ? SizedBox(
            height: large ? 74 : 60.h,
            child: Center(
              child: CircularProgressIndicator(
                color: colors.primary,
                strokeWidth: 2.2,
              ),
            ),
          )
              : Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: PrayerTrackingNumberStatSegment(
                  large: large,
                  label: 'أيام متتالية',
                  value: currentStreak,
                  suffix: 'يوم',
                  textColor: textColor,
                  primaryColor: colors.primary,
                ),
              ),
              _StatsDivider(large: large, color: textColor),
              Expanded(
                child: PrayerTrackingNumberStatSegment(
                  large: large,
                  label: 'أفضل سلسلة',
                  value: displayedBestStreak,
                  suffix: 'يوم',
                  textColor: textColor,
                  primaryColor: colors.primary,
                ),
              ),
              _StatsDivider(large: large, color: textColor),
              Expanded(
                child: PrayerTrackingCompletionStatSegment(
                  large: large,
                  percent: percent,
                  progress: progress,
                  textColor: textColor,
                  primaryColor: colors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsDivider extends StatelessWidget {
  const _StatsDivider({
    required this.large,
    required this.color,
  });

  final bool large;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: large ? 1 : 1.w,
      height: large ? 52 : 42.h,
      margin: EdgeInsets.symmetric(horizontal: large ? 10 : 3.w),
      color: color.withOpacity(0.10),
    );
  }
}
