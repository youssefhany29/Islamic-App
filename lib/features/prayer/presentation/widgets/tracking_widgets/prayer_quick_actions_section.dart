import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/prayer/presentation/widgets/tracking_widgets/prayer_quick_action_tile.dart';
import 'package:islamic_app/shared/widgets/common_components/app_layout_constants.dart';

class PrayerQuickActionsSection extends StatelessWidget {
  const PrayerQuickActionsSection({
    super.key,
    required this.onAfterPrayerAzkarTap,
    required this.onQiblaTap,
    required this.onRemindersTap,
    this.large = false,
  });

  final VoidCallback onAfterPrayerAzkarTap;
  final VoidCallback onQiblaTap;
  final VoidCallback onRemindersTap;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = colors.surface;

    final double width = large
        ? double.infinity
        : AppLayoutConstants.mainCardWidth;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: large ? 44 : 32.w,
                  height: large ? 44 : 32.w,
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(isDark ? 0.16 : 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.settings_suggest_rounded,
                    color: colors.primary,
                    size: large ? 22 : 16.sp,
                  ),
                ),
                SizedBox(width: large ? 12 : 8.w),
                Expanded(
                  child: Text(
                    'أدوات مهمة',
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body(context).copyWith(
                      color: textColor,
                      fontSize: large ? 22 : 12.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.05,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: large ? 16 : 10.h),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: PrayerQuickActionTile(
                    title: 'أذكار بعد الصلاة',
                    icon: Icons.bookmark_border_rounded,
                    onTap: onAfterPrayerAzkarTap,
                    large: large,
                  ),
                ),
                SizedBox(width: large ? 16 : 10.w),
                Expanded(
                  child: PrayerQuickActionTile(
                    title: 'اتجاه القبلة',
                    icon: Icons.explore_outlined,
                    onTap: onQiblaTap,
                    large: large,
                  ),
                ),
                SizedBox(width: large ? 16 : 10.w),
                Expanded(
                  child: PrayerQuickActionTile(
                    title: 'التذكيرات',
                    icon: Icons.notifications_none_rounded,
                    onTap: onRemindersTap,
                    large: large,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
