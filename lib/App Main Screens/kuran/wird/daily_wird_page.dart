import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/App%20Main%20Screens/App%20Main%20Screens%20Components/custom_app_bar.dart';
import 'package:islamic_app/App%20Main%20Screens/kuran/main_quraan_components/to_arabic_no_converter.dart';

import '../main_quraan_components/constant.dart';
import '../reader/quran_reader_page.dart';
import '../stats/quran_reading_stats_storage.dart';
import 'create_khatma_page.dart';
import 'quran_wird_storage.dart';

class DailyWirdPage extends StatefulWidget {
  const DailyWirdPage({super.key});

  @override
  State<DailyWirdPage> createState() => _DailyWirdPageState();
}

class _DailyWirdPageState extends State<DailyWirdPage> {
  List<QuranDailyWird> activeWirds = [];
  List<QuranKhatmaPlan> completedPlans = [];

  bool isLoading = true;
  int statsRefreshCounter = 0;

  @override
  void initState() {
    super.initState();
    loadWirds();
  }

  Future<void> loadWirds() async {
    setState(() {
      isLoading = true;
    });

    final loadedActiveWirds = await QuranWirdStorage.buildTodayWirds();
    final loadedCompletedPlans = await QuranWirdStorage.getCompletedPlans();

    if (!mounted) return;

    setState(() {
      activeWirds = loadedActiveWirds;
      completedPlans = loadedCompletedPlans;
      statsRefreshCounter++;
      isLoading = false;
    });
  }

  Future<void> openCreateKhatma() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateKhatmaPage(),
      ),
    );

    if (result == true) {
      await loadWirds();
    }
  }

  Future<void> openWirdReader(QuranDailyWird wird) async {
    final quranData = await readJson();

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuranReaderPage(
          arabic: quranData[0],
          initialSuraIndex: wird.fromSuraIndex,
          initialAyahIndex: wird.fromAyahIndex,
          initialViewMode: QuranReaderViewMode.pngMushaf,
          initialMushafPageNumber: wird.fromPageNumber,
        ),
      ),
    );
  }


  Future<void> markWirdCompleted(QuranDailyWird wird) async {
    final activePlansBefore = await QuranWirdStorage.getActivePlans();

    final currentPlan = activePlansBefore.firstWhere(
          (plan) => plan.id == wird.planId,
    );

    final willCompleteKhatma =
        currentPlan.completedDays + 1 >= currentPlan.totalDays;

    final completedPages =
    (wird.toPageNumber - wird.fromPageNumber + 1).clamp(1, 604);

    await QuranWirdStorage.markPlanTodayWirdCompleted(wird.planId);

    await QuranReadingStatsStorage.recordCompletedWird(
      completedPages: completedPages,
      completedKhatma: willCompleteKhatma,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
        content: Text(
          willCompleteKhatma
              ? 'مبارك! تم إكمال ختمة "${wird.planName}"'
              : 'تم تسجيل ورد "${wird.planName}"',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'cairo',
            fontSize: 11.sp,
            color: Colors.white,
          ),
        ),
      ),
    );

    await loadWirds();
  }

  Future<void> deleteActiveWird(QuranDailyWird wird) async {
    await QuranWirdStorage.deleteActivePlan(wird.planId);
    await loadWirds();
  }

  Future<void> deleteCompletedPlan(QuranKhatmaPlan plan) async {
    await QuranWirdStorage.deleteCompletedPlan(plan.id);
    await loadWirds();
  }

  Future<void> confirmDeleteActiveWird(QuranDailyWird wird) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return _DeleteConfirmDialog(
          title: 'حذف الورد',
          message: 'هل تريد حذف "${wird.planName}" من الأوراد الحالية؟',
        );
      },
    );

    if (shouldDelete == true) {
      await deleteActiveWird(wird);
    }
  }

  Future<void> confirmDeleteCompletedPlan(QuranKhatmaPlan plan) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return _DeleteConfirmDialog(
          title: 'حذف الختمة',
          message: 'هل تريد حذف "${plan.name}" من الختمات المكتملة؟',
        );
      },
    );

    if (shouldDelete == true) {
      await deleteCompletedPlan(plan);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              category: CustomAppBarCategory(text: 'ورد اليوم'),
            ),
            Expanded(
              child: isLoading
                  ? Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              )
                  : RefreshIndicator(
                onRefresh: loadWirds,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                  children: [
                    _PageHeader(
                      activeCount: activeWirds.length,
                      completedCount: completedPlans.length,
                      onCreateKhatma: openCreateKhatma,
                    ),

                    SizedBox(height: 14.h),

                    _ReadingStatsCard(
                      refreshCounter: statsRefreshCounter,
                    ),

                    SizedBox(height: 16.h),

                    if (activeWirds.isEmpty)
                      _NoActiveWirdCard(
                        onCreatePlan: openCreateKhatma,
                      )
                    else ...[
                      _SectionTitle(
                        title: 'الأوراد الحالية',
                        subtitle:
                        '${activeWirds.length.toString().toArabicNumbers} ورد نشط',
                      ),
                      SizedBox(height: 10.h),
                      for (final wird in activeWirds) ...[
                        _ActiveWirdCard(
                          wird: wird,
                          onOpenReader: () => openWirdReader(wird),
                          onMarkCompleted: () =>
                              markWirdCompleted(wird),
                          onDelete: () => confirmDeleteActiveWird(wird),
                        ),
                        SizedBox(height: 12.h),
                      ],
                    ],

                    SizedBox(height: 10.h),

                    _SectionTitle(
                      title: 'الختمات المكتملة',
                      subtitle:
                      '${completedPlans.length.toString().toArabicNumbers} ختمة',
                    ),

                    SizedBox(height: 10.h),

                    if (completedPlans.isEmpty)
                      const _NoCompletedPlansCard()
                    else
                      for (final plan in completedPlans) ...[
                        _CompletedPlanCard(
                          plan: plan,
                          onDelete: () =>
                              confirmDeleteCompletedPlan(plan),
                        ),
                        SizedBox(height: 10.h),
                      ],

                    SizedBox(height: 18.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final int activeCount;
  final int completedCount;
  final VoidCallback onCreateKhatma;

  const _PageHeader({
    required this.activeCount,
    required this.completedCount,
    required this.onCreateKhatma,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(22.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'متابعة الأوراد والختمات',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: 17.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'أنشئ أكثر من ورد، وتابع تقدم كل ختمة بشكل مستقل.',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: 10.5.sp,
              height: 1.5,
              color: Colors.white.withOpacity(0.82),
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: _HeaderMiniBox(
                  title: 'أوراد نشطة',
                  value: activeCount.toString().toArabicNumbers,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _HeaderMiniBox(
                  title: 'مكتملة',
                  value: completedCount.toString().toArabicNumbers,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          SizedBox(
            width: double.infinity,
            height: 40.h,
            child: ElevatedButton.icon(
              onPressed: onCreateKhatma,
              icon: Icon(
                Icons.add_rounded,
                size: 18.sp,
                color: Colors.black87,
              ),
              label: Text(
                'إنشاء ورد جديد',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: theme.colorScheme.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderMiniBox extends StatelessWidget {
  final String title;
  final String value;

  const _HeaderMiniBox({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        children: [
          Text(
            title,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: 9.sp,
              color: Colors.white.withOpacity(0.75),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      textDirection: TextDirection.rtl,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: 'cairo',
            fontSize: 14.sp,
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onBackground,
          ),
        ),
        Text(
          subtitle,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: 'cairo',
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onBackground.withOpacity(0.55),
          ),
        ),
      ],
    );
  }
}

class _NoActiveWirdCard extends StatelessWidget {
  final VoidCallback onCreatePlan;

  const _NoActiveWirdCard({
    required this.onCreatePlan,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        children: [
          Icon(
            Icons.auto_stories_rounded,
            size: 42.sp,
            color: theme.colorScheme.primary,
          ),
          SizedBox(height: 10.h),
          Text(
            'لا توجد أوراد حالية',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'أنشئ وردًا جديدًا مثل ورد رمضان أو ختمة يومية.',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: 10.sp,
              height: 1.5,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 38.h,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onCreatePlan,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: Text(
                'إنشاء ورد',
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveWirdCard extends StatelessWidget {
  final QuranDailyWird wird;
  final VoidCallback onOpenReader;
  final VoidCallback onMarkCompleted;
  final VoidCallback onDelete;

  const _ActiveWirdCard({
    required this.wird,
    required this.onOpenReader,
    required this.onMarkCompleted,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final fromSuraName = QuranWirdStorage.getSuraName(wird.fromSuraIndex);
    final toSuraName = QuranWirdStorage.getSuraName(wird.toSuraIndex);

    final fromAyah = (wird.fromAyahIndex + 1).toString().toArabicNumbers;
    final toAyah = (wird.toAyahIndex + 1).toString().toArabicNumbers;

    final fromPage = wird.fromPageNumber.toString().toArabicNumbers;
    final toPage = wird.toPageNumber.toString().toArabicNumbers;

    final dayNumber = wird.dayNumber.toString().toArabicNumbers;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  size: 17.sp,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      wird.planName,
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      'اليوم $dayNumber',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 19.sp,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _InfoLine(
            icon: Icons.place_outlined,
            text: 'من سورة $fromSuraName آية $fromAyah - صفحة $fromPage',
          ),
          SizedBox(height: 7.h),
          _InfoLine(
            icon: Icons.flag_outlined,
            text: 'إلى سورة $toSuraName آية $toAyah - صفحة $toPage',
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onMarkCompleted,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    'تم الورد',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'cairo',
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: onOpenReader,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    'ابدأ القراءة',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'cairo',
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Icon(
          icon,
          size: 15.sp,
          color: Colors.black45,
        ),
        SizedBox(width: 7.w),
        Expanded(
          child: Text(
            text,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: 9.8.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompletedPlanCard extends StatelessWidget {
  final QuranKhatmaPlan plan;
  final VoidCallback onDelete;

  const _CompletedPlanCard({
    required this.plan,
    required this.onDelete,
  });

  String get completedDateText {
    final date = plan.completedAt;

    if (date == null) {
      return 'اكتملت الختمة';
    }

    final day = date.day.toString().toArabicNumbers;
    final month = date.month.toString().toArabicNumbers;
    final year = date.year.toString().toArabicNumbers;

    return 'اكتملت بتاريخ $day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(13.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withOpacity(0.72),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(
            Icons.verified_rounded,
            color: theme.colorScheme.primary,
            size: 24.sp,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  plan.name,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'cairo',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  completedDateText,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'cairo',
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 18.sp,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoCompletedPlansCard extends StatelessWidget {
  const _NoCompletedPlansCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withOpacity(0.65),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Text(
        'لم تكتمل أي ختمة بعد',
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'cairo',
          fontSize: 10.5.sp,
          fontWeight: FontWeight.w700,
          color: Colors.black54,
        ),
      ),
    );
  }
}

class _DeleteConfirmDialog extends StatelessWidget {
  final String title;
  final String message;

  const _DeleteConfirmDialog({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        title,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontFamily: 'cairo',
          fontWeight: FontWeight.w900,
        ),
      ),
      content: Text(
        message,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontFamily: 'cairo',
        ),
      ),
      actionsAlignment: MainAxisAlignment.start,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(
            'إلغاء',
            style: TextStyle(fontFamily: 'cairo'),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            'حذف',
            style: TextStyle(
              fontFamily: 'cairo',
              color: Colors.red,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadingStatsCard extends StatefulWidget {
  final int refreshCounter;

  const _ReadingStatsCard({
    required this.refreshCounter,
  });

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
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'إعادة ضبط الإحصائيات',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'cairo',
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'هل تريد مسح إحصائيات القراءة والبدء من جديد؟',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'cairo',
            ),
          ),
          actionsAlignment: MainAxisAlignment.start,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'إلغاء',
                style: TextStyle(
                  fontFamily: 'cairo',
                ),
              ),
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
          textAlign: TextAlign.center,
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

    return FutureBuilder<QuranReadingStats>(
      future: statsFuture,
      builder: (context, snapshot) {
        final stats = snapshot.data ?? QuranReadingStats.empty();

        return Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary,
            borderRadius: BorderRadius.circular(20.r),
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
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Material(
                    color: Colors.white.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(10.r),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10.r),
                      onTap: confirmResetStats,
                      child: SizedBox(
                        width: 30.w,
                        height: 28.h,
                        child: Icon(
                          Icons.restart_alt_rounded,
                          size: 17.sp,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: _StatsMiniBox(
                      title: 'أوراد مكتملة',
                      value: stats.totalCompletedWirds.toString(),
                      icon: Icons.check_circle_outline_rounded,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _StatsMiniBox(
                      title: 'صفحات مقروءة',
                      value: stats.totalCompletedPages.toString(),
                      icon: Icons.menu_book_rounded,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: _StatsMiniBox(
                      title: 'ختمات مكتملة',
                      value: stats.totalCompletedKhatmas.toString(),
                      icon: Icons.verified_rounded,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _StatsMiniBox(
                      title: 'أيام متتالية',
                      value: stats.currentStreakDays.toString(),
                      icon: Icons.local_fire_department_rounded,
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

  const _StatsMiniBox({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.65),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 18.sp,
            color: theme.colorScheme.primary,
          ),
          SizedBox(height: 6.h),
          Text(
            value.toArabicNumbers,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            title,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: 8.5.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}