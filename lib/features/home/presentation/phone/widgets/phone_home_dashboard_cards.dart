import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/shared/widgets/common_components/app_layout_constants.dart';

class PhoneHomeProgressOverviewCard extends StatelessWidget {
  const PhoneHomeProgressOverviewCard({
    super.key,
    required this.wirdCompleted,
    required this.azkarCompleted,
    required this.memorizationCompleted,
  });

  final bool wirdCompleted;
  final bool azkarCompleted;
  final bool memorizationCompleted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = colors.surface;
    final Color cardColor = isDark ? colors.secondary : Colors.white;

    final int completedTasks =
        (wirdCompleted ? 1 : 0) +
            (azkarCompleted ? 1 : 0) +
            (memorizationCompleted ? 1 : 0);

    final double progressValue = completedTasks / 3.0;

    final String progressText = switch (completedTasks) {
      0 => 'ابدأ أول مهمة اليوم',
      1 => 'أنجزت مهمة من ٣',
      2 => 'أنجزت مهمتين من ٣',
      3 => 'أكملت جميع مهام اليوم',
      _ => '',
    };

    return SizedBox(
      width: AppLayoutConstants.mainCardWidth,
      child: Container(
        height: 92.h,
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 11.h),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(
            color: textColor.withOpacity(isDark ? 0.08 : 0.055),
            width: 0.8.w,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.14 : 0.045),
              blurRadius: 16.r,
              offset: Offset(0, 7.h),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(3.1415926535),
                  child: Icon(
                    Icons.trending_up_rounded,
                    color: colors.primary,
                    size: 22.sp,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 34.w,
              top: 10.h,
              bottom: 10.h,
              child: Container(
                width: 1.w,
                color: textColor.withOpacity(0.12),
              ),
            ),
            Positioned(
              right: 47.w,
              top: 5.h,
              bottom: 5.h,
              width: 150.w,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'تقدمك اليوم',
                    textAlign: TextAlign.right,
                    style: AppTextStyles.body(context).copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    'تقدمك في الورد والأذكار والحفظ',
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(context).copyWith(
                      color: textColor.withOpacity(0.50),
                      fontWeight: FontWeight.w500,
                      fontSize: 8.sp,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    progressText,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(context).copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 8.6.sp,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: _ProgressRing(
                  value: progressValue,
                  color: colors.primary,
                  backgroundColor: textColor.withOpacity(0.10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.value,
    required this.color,
    required this.backgroundColor,
  });

  final double value;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54.w,
      height: 54.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 54.w,
            height: 54.w,
            child: CircularProgressIndicator(
              value: value.clamp(0.0, 1.0),
              strokeWidth: 4.3.w,
              backgroundColor: backgroundColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            '${(value * 100).round()}%',
            textDirection: TextDirection.ltr,
            style: AppTextStyles.caption(context).copyWith(
              color: Theme.of(context).colorScheme.surface,
              fontWeight: FontWeight.w700,
              fontSize: 12.sp,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class PhoneHomeWorshipCards extends StatelessWidget {
  const PhoneHomeWorshipCards({
    super.key,
    required this.onWirdTap,
    required this.onAzkarTap,
    required this.onMemorizationTap,
    required this.wirdCompleted,
    required this.azkarCompleted,
    required this.memorizationCompleted,
  });

  final VoidCallback onWirdTap;
  final VoidCallback onAzkarTap;
  final VoidCallback onMemorizationTap;

  final bool wirdCompleted;
  final bool azkarCompleted;
  final bool memorizationCompleted;

  @override
  Widget build(BuildContext context) {
    final double wirdProgress = wirdCompleted ? 1.0 : 0.0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: AppLayoutConstants.mainCardWidth,
        child: Row(
          children: [
            Expanded(
              child: _WorshipMiniCard(
                icon: Icons.menu_book_rounded,
                title: 'الحفظ',
                subtitle: memorizationCompleted
                    ? 'مهمة اليوم مكتملة\nأحسنت الاستمرار'
                    : 'مهمة الحفظ اليوم\nلم تكتمل بعد',
                buttonText: memorizationCompleted ? 'تم' : 'ابدأ',
                onTap: onMemorizationTap,
              ),
            ),
            SizedBox(width: 9.w),
            Expanded(
              child: _WorshipMiniCard(
                icon: Icons.radio_button_unchecked_rounded,
                title: 'أذكارك',
                subtitle: azkarCompleted
                    ? 'أذكار اليوم مكتملة\nحصّنت يومك'
                    : 'أذكار اليوم\nلم تكتمل بعد',
                buttonText: azkarCompleted ? 'تم' : 'اذكر الله',
                onTap: onAzkarTap,
              ),
            ),
            SizedBox(width: 9.w),
            Expanded(
              child: _WorshipMiniCard(
                icon: Icons.bookmark_border_rounded,
                title: 'أكمل وردك',
                subtitle: wirdCompleted
                    ? 'ورد اليوم مكتمل\nبارك الله فيك'
                    : 'ورد القرآن اليوم\nلم يكتمل بعد',
                progress: wirdProgress,
                onTap: onWirdTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorshipMiniCard extends StatelessWidget {
  const _WorshipMiniCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.buttonText,
    this.progress,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonText;
  final double? progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = colors.surface;
    final Color cardColor = isDark ? colors.secondary : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(
            minHeight: 126.h,
          ),
          padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 8.h),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: textColor.withOpacity(isDark ? 0.08 : 0.055),
              width: 0.8.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.12 : 0.04),
                blurRadius: 12.r,
                offset: Offset(0, 6.h),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(isDark ? 0.16 : 0.075),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: colors.primary,
                  size: 17.sp,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 10.sp,
                  height: 1.05,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  color: textColor.withOpacity(0.50),
                  fontWeight: FontWeight.w500,
                  fontSize: 7.sp,
                  height: 1.15,
                ),
              ),
              SizedBox(height: 6.h),
              if (progress != null)
                Container(
                  height: 25.h,
                  alignment: Alignment.center,
                  child: Row(
                    textDirection: TextDirection.ltr,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '${((progress ?? 0) * 100).round()}%',
                        style: AppTextStyles.caption(context).copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 7.8.sp,
                          height: 1,
                        ),
                      ),
                      SizedBox(width: 5.w),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99.r),
                          child: LinearProgressIndicator(
                            value: progress!.clamp(0.0, 1.0),
                            minHeight: 4.2.h,
                            backgroundColor: textColor.withOpacity(0.075),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  height: 25.h,
                  constraints: BoxConstraints(maxWidth: 84.w),
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(isDark ? 0.16 : 0.075),
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    textDirection: TextDirection.rtl,
                    children: [
                      Flexible(
                        child: Text(
                          buttonText ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption(context).copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 7.4.sp,
                            height: 1,
                          ),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(3.1415926535),
                        child: Icon(
                          Icons.chevron_left_rounded,
                          color: colors.primary,
                          size: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}