part of 'daily_wird_page.dart';

class _ReadingStatsCard extends StatefulWidget {
  final int refreshCounter;
  final bool large;

  const _ReadingStatsCard({required this.refreshCounter, this.large = false});

  @override
  State<_ReadingStatsCard> createState() => _ReadingStatsCardState();
}

class _ReadingStatsCardState extends State<_ReadingStatsCard> {
  late Future<QuranReadingStats> statsFuture;

  @override
  void initState() {
    super.initState();
    statsFuture = QuranReadingStatsStorage.getStats();
  }

  @override
  void didUpdateWidget(covariant _ReadingStatsCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.refreshCounter != widget.refreshCounter) {
      statsFuture = QuranReadingStatsStorage.getStats();
    }
  }

  Future<void> refreshStats() async {
    setState(() {
      statsFuture = QuranReadingStatsStorage.getStats();
    });
  }

  Future<void> confirmResetStats() async {
    AppHaptics.medium(context);

    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'إعادة ضبط الإحصائيات',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: TextStyle(fontFamily: 'cairo', fontWeight: FontWeight.w900),
          ),
          content: const Text(
            'هل تريد مسح إحصائيات القراءة والبدء من جديد؟',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: TextStyle(fontFamily: 'cairo'),
          ),
          actionsAlignment: MainAxisAlignment.start,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'cairo')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'إعادة',
                style: TextStyle(
                  fontFamily: 'cairo',
                  color: Colors.red,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldReset != true) return;

    await QuranReadingStatsStorage.resetStats();

    if (!mounted) return;

    await refreshStats();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
        content: Text(
          'تمت إعادة ضبط إحصائيات القراءة',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontFamily: 'cairo',
            fontSize: 11.sp,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool large = widget.large;

    return FutureBuilder<QuranReadingStats>(
      future: statsFuture,
      builder: (context, snapshot) {
        final stats = snapshot.data ?? QuranReadingStats.empty();

        return Container(
          padding: EdgeInsets.all(large ? 14 : 14.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary,
            borderRadius: BorderRadius.circular(large ? 20 : 20.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Text(
                    'إحصائيات قراءتك',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'cairo',
                      fontSize: large ? 13 : 14.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      height: 1.15,
                    ),
                  ),
                  SizedBox(width: large ? 10 : 10.w),
                  Material(
                    color: Colors.white.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(large ? 10 : 10.r),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(large ? 10 : 10.r),
                      onTap: confirmResetStats,
                      child: SizedBox(
                        width: large ? 30 : 30.w,
                        height: large ? 28 : 28.h,
                        child: Icon(
                          Icons.restart_alt_rounded,
                          size: large ? 17 : 17.sp,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              SizedBox(height: large ? 12 : 12.h),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: _StatsMiniBox(
                      title: 'أوراد مكتملة',
                      value: stats.totalCompletedWirds.toString(),
                      icon: Icons.check_circle_outline_rounded,
                      large: large,
                    ),
                  ),
                  SizedBox(width: large ? 8 : 8.w),
                  Expanded(
                    child: _StatsMiniBox(
                      title: 'صفحات مقروءة',
                      value: stats.totalCompletedPages.toString(),
                      icon: Icons.menu_book_rounded,
                      large: large,
                    ),
                  ),
                ],
              ),
              SizedBox(height: large ? 8 : 8.h),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: _StatsMiniBox(
                      title: 'ختمات مكتملة',
                      value: stats.totalCompletedKhatmas.toString(),
                      icon: Icons.verified_rounded,
                      large: large,
                    ),
                  ),
                  SizedBox(width: large ? 8 : 8.w),
                  Expanded(
                    child: _StatsMiniBox(
                      title: 'أيام متتالية',
                      value: stats.currentStreakDays.toString(),
                      icon: Icons.local_fire_department_rounded,
                      large: large,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatsMiniBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool large;

  const _StatsMiniBox({
    required this.title,
    required this.value,
    required this.icon,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(minHeight: large ? 70 : 82.h),
      padding: EdgeInsets.symmetric(
        vertical: large ? 8 : 10.h,
        horizontal: large ? 8 : 8.w,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.65),
        borderRadius: BorderRadius.circular(large ? 14 : 14.r),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: large ? 17 : 18.sp,
            color: theme.colorScheme.primary,
          ),
          SizedBox(height: large ? 5 : 6.h),
          Text(
            value.toArabicNumbers,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: large ? 13 : 14.sp,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
              height: 1.1,
            ),
          ),
          SizedBox(height: large ? 2 : 3.h),
          Text(
            title,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: large ? 8.5 : 8.2.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
              height: 1.15,
            ),
          ),
        ],
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

  static double cardTitle(BuildContext context) {
    if (!isLarge(context)) return 14.sp;
    return isFoldLandscape(context) ? 18 : 23;
  }

  static double cardSubtitle(BuildContext context) {
    if (!isLarge(context)) return 9.sp;
    return isFoldLandscape(context) ? 12 : 15;
  }

  static TextStyle? actionLabel(BuildContext context) {
    final base = Theme.of(context).textTheme.labelLarge;
    if (!isLarge(context)) return base;
    return base?.copyWith(
      fontSize: isFoldLandscape(context) ? 10.5 : 12,
      height: 1.15,
    );
  }
}
