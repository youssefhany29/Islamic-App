part of 'quran_page.dart';

class _QuranAppBarSearchButton extends StatelessWidget {
  const _QuranAppBarSearchButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Container(
          width: 38.w,
          height: 38.w,
          decoration: BoxDecoration(
            color: isDark
                ? colors.secondary.withOpacity(0.92)
                : colors.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Icon(Icons.search_rounded, size: 18.sp, color: colors.primary),
        ),
      ),
    );
  }
}

class _MainPageTypographySizes {
  const _MainPageTypographySizes._();

  static bool isFoldLandscape(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width >= 600 && size.shortestSide < 600;
  }

  static bool isLarge(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 600;
  }

  // Same values used by MainPage/tablet_dashboard/tablet_dashboard_card_base.dart
  static double cardTitle(BuildContext context) {
    if (!isLarge(context)) return 13.sp;
    return isFoldLandscape(context) ? 18 : 23;
  }

  static double cardSubtitle(BuildContext context) {
    if (!isLarge(context)) return 8.5.sp;
    return isFoldLandscape(context) ? 12 : 15;
  }

  // Same values used by MainPage/Components Main Page/Main App Widget/icons_main_widget.dart
  static TextStyle? actionLabel(BuildContext context) {
    final base = Theme.of(context).textTheme.labelLarge;
    if (!isLarge(context)) {
      return base?.copyWith(fontSize: 11.sp);
    }
    return base?.copyWith(
      fontSize: isFoldLandscape(context) ? 10.5 : 12,
      height: 1.15,
    );
  }
}

class _QuranPhoneHeader extends StatelessWidget {
  const _QuranPhoneHeader();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Padding(
      padding: EdgeInsets.only(right: 0.w, left: 0.w, top: 14.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 44.w, minHeight: 44.h),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
            icon: Image.asset(
              themeProvider.themeData.brightness == Brightness.dark
                  ? 'assets/icons/sun.png'
                  : 'assets/icons/moon.png',
              width: 22.w,
              height: 22.h,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'القرآن',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body(
                  context,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 1.h),
              Text(
                'اقرأ وتابع وردك اليومي',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withOpacity(0.58),
                ),
              ),
            ],
          ),
          Builder(
            builder: (drawerContext) {
              return IconButton(
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 44.w, minHeight: 44.h),
                onPressed: () {
                  Scaffold.of(drawerContext).openEndDrawer();
                },
                icon: Image.asset(
                  themeProvider.themeData.brightness == Brightness.dark
                      ? 'assets/icons/menuWhite.png'
                      : 'assets/icons/menu (1).png',
                  width: 22.w,
                  height: 22.h,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LargePageTitle extends StatelessWidget {
  const _LargePageTitle({required this.title, this.centered = false});

  final String title;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: Text(
        title,
        textDirection: TextDirection.rtl,
        textAlign: centered ? TextAlign.center : TextAlign.right,
        style: AppTextStyles.display(context).copyWith(
          fontWeight: FontWeight.w900,
          color: theme.colorScheme.onBackground,
          height: 1.15,
        ),
      ),
    );
  }
}

class _QuranHomeColors {
  const _QuranHomeColors({
    required this.buttonColor,
    required this.buttonBorderColor,
    required this.outerCardColor,
    required this.outerCardBorderColor,
  });

  final Color buttonColor;
  final Color buttonBorderColor;
  final Color outerCardColor;
  final Color outerCardBorderColor;
}

class _MainQuranCard extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final Widget child;

  const _MainQuranCard({
    required this.color,
    required this.borderColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLargeScreen = MediaQuery.sizeOf(context).width >= 600;

    return SizedBox(
      width: isLargeScreen ? double.infinity : AppLayoutConstants.mainCardWidth,
      child: Container(
        padding: isLargeScreen
            ? const EdgeInsets.all(16)
            : EdgeInsets.all(AppLayoutConstants.mainCardPadding),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(
            AppLayoutConstants.mainCardRadius,
          ),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 16,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _CardTitle({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: double.infinity,
          child: Text(
            title,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body(context).copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: 4.h),
          SizedBox(
            width: double.infinity,
            child: Text(
              subtitle!,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(
                  MediaQuery.sizeOf(context).width >= 600 ? 0.82 : 0.62,
                ),
                height: 1.25,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.title,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLargeScreen = MediaQuery.sizeOf(context).width >= 600;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Container(
          height: isLargeScreen ? 68 : 58.h,
          padding: EdgeInsets.symmetric(horizontal: isLargeScreen ? 12 : 10.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: isLargeScreen ? 22 : 19.sp, color: textColor),
              SizedBox(height: 6.h),
              Text(
                title,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: isLargeScreen ? 12 : 10.sp,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallInfoButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final IconData icon;
  final VoidCallback onTap;

  const _SmallInfoButton({
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLargeScreen = MediaQuery.sizeOf(context).width >= 600;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: () {
          AppHaptics.tap(context);
          onTap();
        },
        child: Container(
          constraints: BoxConstraints(minHeight: isLargeScreen ? 60 : 68.h),
          padding: EdgeInsets.symmetric(
            horizontal: isLargeScreen ? 14 : 10.w,
            vertical: isLargeScreen ? 8 : 9.h,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(icon, size: isLargeScreen ? 20 : 17.sp, color: textColor),
              SizedBox(width: isLargeScreen ? 10 : 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: MediaQuery.sizeOf(context).width >= 600
                            ? _MainPageTypographySizes.actionLabel(
                                context,
                              )?.fontSize
                            : 10.2.sp,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        height: 1.15,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      subtitle,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: MediaQuery.sizeOf(context).width >= 600
                            ? _MainPageTypographySizes.cardSubtitle(context) *
                                  0.75
                            : 7.4.sp,
                        color: textColor.withOpacity(0.60),
                        height: 1.15,
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

class _LargeButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onTap;

  const _LargeButton({
    required this.title,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: () {
          AppHaptics.tap(context);
          onTap();
        },
        child: Container(
          width: double.infinity,
          height: MediaQuery.sizeOf(context).width >= 600 ? 42 : 40.h,
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.sizeOf(context).width >= 600 ? 14 : 12.w,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                icon,
                size: MediaQuery.sizeOf(context).width >= 600 ? 16 : 17.sp,
                color: textColor,
              ),
              SizedBox(width: 9.w),
              Expanded(
                child: Text(
                  title,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'cairo',
                    fontSize: MediaQuery.sizeOf(context).width >= 600
                        ? _MainPageTypographySizes.actionLabel(
                            context,
                          )?.fontSize
                        : 11.sp,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_back_ios_new_rounded,
                size: MediaQuery.sizeOf(context).width >= 600 ? 10 : 11.sp,
                color: textColor.withOpacity(0.75),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadingStatBox extends StatelessWidget {
  final String title;
  final String value;
  final Color backgroundColor;
  final Color borderColor;

  const _ReadingStatBox({
    required this.title,
    required this.value,
    required this.backgroundColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minHeight: MediaQuery.sizeOf(context).width >= 600 ? 58 : 56.h,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.sizeOf(context).width >= 600 ? 12 : 8.w,
        vertical: MediaQuery.sizeOf(context).width >= 600 ? 7 : 7.h,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: MediaQuery.sizeOf(context).width >= 600 ? 14 : 12.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            title,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: MediaQuery.sizeOf(context).width >= 600 ? 9.5 : 8.2.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.62),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuranHomeInfo {
  final bool hasActiveWirds;
  final String title;
  final String subtitle;
  final _QuranHomeSummary summary;

  const _QuranHomeInfo({
    required this.hasActiveWirds,
    required this.title,
    required this.subtitle,
    required this.summary,
  });
}

class _QuranHomeSummary {
  final int completedWirds;
  final int completedPages;
  final int completedKhatmas;
  final int currentStreakDays;
  final int activePlansCount;
  final int currentPlanProgressPercent;
  final String note;

  const _QuranHomeSummary({
    required this.completedWirds,
    required this.completedPages,
    required this.completedKhatmas,
    required this.currentStreakDays,
    required this.activePlansCount,
    required this.currentPlanProgressPercent,
    required this.note,
  });

  factory _QuranHomeSummary.empty() {
    return const _QuranHomeSummary(
      completedWirds: 0,
      completedPages: 0,
      completedKhatmas: 0,
      currentStreakDays: 0,
      activePlansCount: 0,
      currentPlanProgressPercent: 0,
      note: '',
    );
  }
}

Future<_QuranHomeInfo> _loadHomeInfo() async {
  final activePlans = await QuranWirdStorage.getActivePlans();
  final completedPlans = await QuranWirdStorage.getCompletedPlans();
  final activeWirds = await QuranWirdStorage.buildTodayWirds();
  final savedStats = await QuranReadingStatsStorage.getStats();

  final summary = _buildHomeSummary(
    activePlans: activePlans,
    completedPlans: completedPlans,
    savedStats: savedStats,
  );

  if (activeWirds.isEmpty) {
    return _QuranHomeInfo(
      hasActiveWirds: false,
      title: '',
      subtitle: '',
      summary: summary,
    );
  }

  final firstWird = activeWirds.first;

  final fromSuraName = QuranWirdStorage.getSuraName(firstWird.fromSuraIndex);
  final toSuraName = QuranWirdStorage.getSuraName(firstWird.toSuraIndex);

  final fromAyah = (firstWird.fromAyahIndex + 1).toString().toArabicNumbers;
  final toAyah = (firstWird.toAyahIndex + 1).toString().toArabicNumbers;

  final fromPage = firstWird.fromPageNumber.toString().toArabicNumbers;
  final toPage = firstWird.toPageNumber.toString().toArabicNumbers;

  final activeCount = activeWirds.length.toString().toArabicNumbers;

  final suraRange = fromSuraName == toSuraName
      ? 'سورة $fromSuraName'
      : 'من $fromSuraName إلى $toSuraName';

  final title = activeWirds.length == 1
      ? firstWird.planName
      : '$activeCount أوراد حالية';

  final subtitle = activeWirds.length == 1
      ? '$suraRange | ص $fromPage إلى ص $toPage | آية $fromAyah إلى آية $toAyah'
      : '${firstWird.planName}: $suraRange | ص $fromPage إلى ص $toPage';

  return _QuranHomeInfo(
    hasActiveWirds: true,
    title: title,
    subtitle: subtitle,
    summary: summary,
  );
}

_QuranHomeSummary _buildHomeSummary({
  required List<QuranKhatmaPlan> activePlans,
  required List<QuranKhatmaPlan> completedPlans,
  required QuranReadingStats savedStats,
}) {
  int completedWirdsFromPlans = 0;
  for (final plan in activePlans) {
    final safeTotalDays = plan.totalDays <= 0 ? 30 : plan.totalDays;
    final safeCompletedDays = plan.completedDays
        .clamp(0, safeTotalDays)
        .toInt();

    completedWirdsFromPlans += safeCompletedDays;
  }

  for (final plan in completedPlans) {
    final safeTotalDays = plan.totalDays <= 0 ? 30 : plan.totalDays;
    final safeCompletedDays = plan.completedDays <= 0
        ? safeTotalDays
        : plan.completedDays.clamp(0, safeTotalDays).toInt();

    completedWirdsFromPlans += safeCompletedDays;
  }

  final firstActivePlan = activePlans.isEmpty ? null : activePlans.first;

  final int currentPlanProgressPercent;
  if (firstActivePlan == null || firstActivePlan.totalDays <= 0) {
    currentPlanProgressPercent = 0;
  } else {
    currentPlanProgressPercent =
        ((firstActivePlan.completedDays / firstActivePlan.totalDays) * 100)
            .clamp(0, 100)
            .toDouble()
            .round();
  }

  final completedWirds =
      savedStats.totalCompletedWirds > completedWirdsFromPlans
      ? savedStats.totalCompletedWirds
      : completedWirdsFromPlans;

  final completedPages = savedStats.totalReadPages;

  final completedKhatmas =
      savedStats.totalCompletedKhatmas > completedPlans.length
      ? savedStats.totalCompletedKhatmas
      : completedPlans.length;

  final note = completedPages == 0
      ? 'ابدأ القراءة من المصحف أو الفهرس أو الأجزاء وسيتم حساب صفحات المصحف التي تزورها هنا فقط.'
      : '';

  return _QuranHomeSummary(
    completedWirds: completedWirds,
    completedPages: completedPages,
    completedKhatmas: completedKhatmas,
    currentStreakDays: savedStats.currentStreakDays,
    activePlansCount: activePlans.length,
    currentPlanProgressPercent: currentPlanProgressPercent,
    note: note,
  );
}
