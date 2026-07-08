import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/shared/widgets/app_main_components/custom_app_bar.dart';
import 'package:islamic_app/features/quran/main_quraan_components/to_arabic_no_converter.dart';
import 'package:islamic_app/core/adaptive/adaptive_side_navigation.dart';
import 'package:islamic_app/core/adaptive/adaptive_large_screen_shell.dart';
import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/home/presentation/adaptive/home_large_screen_navigation.dart';
import 'package:islamic_app/features/settings/app_settings_drawer.dart';
import 'package:islamic_app/core/services/app_haptics.dart';
import '../reader/qpc_connected_mushaf_page.dart';
import '../reader/quran_reader_helpers.dart';
import '../reader/quran_reader_storage.dart';
import '../reader/quran_page_mapper.dart';
import '../stats/quran_reading_stats_storage.dart';
import 'create_khatma_page.dart';
import 'quran_wird_storage.dart';
import 'quran_wird_progress_storage.dart';
part 'daily_wird_widgets.dart';
part 'daily_wird_header_widgets.dart';
part 'daily_wird_plan_widgets.dart';
part 'daily_wird_stats_widgets.dart';

class DailyWirdPage extends StatefulWidget {
  const DailyWirdPage({super.key});

  @override
  State<DailyWirdPage> createState() => _DailyWirdPageState();
}

class _DailyWirdPageState extends State<DailyWirdPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<QuranDailyWird> activeWirds = [];
  List<QuranKhatmaPlan> completedPlans = [];
  Map<String, QuranWirdProgress?> wirdProgressByPlanId = {};

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

    final loadedProgress = <String, QuranWirdProgress?>{};
    for (final wird in loadedActiveWirds) {
      loadedProgress[wird.planId] = await QuranWirdProgressStorage.getProgress(
        wird.planId,
      );
    }

    if (!mounted) return;

    setState(() {
      activeWirds = loadedActiveWirds;
      completedPlans = loadedCompletedPlans;
      wirdProgressByPlanId = loadedProgress;
      statsRefreshCounter++;
      isLoading = false;
    });
  }

  Future<void> openCreateKhatma() async {
    AppHaptics.tap(context);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateKhatmaPage()),
    );

    if (result == true) {
      await loadWirds();
    }
  }

  Future<void> openWirdReader(QuranDailyWird wird) async {
    AppHaptics.tap(context);

    final savedProgress = await QuranWirdProgressStorage.getProgress(
      wird.planId,
    );
    final lastRead = await QuranReaderStorage.getLastRead();

    if (!mounted) return;

    final int wirdStartGlobalAyahIndex = wird.fromGlobalAyahIndex;
    final int wirdEndGlobalAyahIndex = wird.toGlobalAyahIndex;

    int clampInsideWird(int globalAyahIndex) {
      return globalAyahIndex
          .clamp(wirdStartGlobalAyahIndex, wirdEndGlobalAyahIndex)
          .toInt();
    }

    int resumeGlobalAyahIndex = wirdStartGlobalAyahIndex;

    // 1) ابدأ من تقدم الورد لو موجود، لكن لا نثق في رقم الصفحة المخزن وحده.
    // الصفحة تتعاد حسابها من السورة/الآية حتى لا يفتح على صفحة قديمة أو صفحة 1 بالغلط.
    if (savedProgress != null) {
      final savedGlobalAyahIndex = QuranReaderHelpers.getGlobalAyahIndex(
        suraIndex: savedProgress.suraIndex,
        ayahIndex: savedProgress.ayahIndex,
      );

      resumeGlobalAyahIndex = clampInsideWird(savedGlobalAyahIndex);
    }

    // 2) لو آخر قراءة الحقيقية داخل نفس حدود ورد اليوم ومتقدمة عن Progress الورد،
    // استخدمها بدل Progress قديم اتخزن غلط عند أول الورد.
    if (lastRead != null) {
      final lastReadGlobalAyahIndex = QuranReaderHelpers.getGlobalAyahIndex(
        suraIndex: lastRead.suraIndex,
        ayahIndex: lastRead.ayahIndex,
      );

      final bool lastReadInsideThisWird =
          lastReadGlobalAyahIndex >= wirdStartGlobalAyahIndex &&
          lastReadGlobalAyahIndex <= wirdEndGlobalAyahIndex;

      if (lastReadInsideThisWird &&
          (savedProgress == null ||
              lastReadGlobalAyahIndex > resumeGlobalAyahIndex)) {
        resumeGlobalAyahIndex = lastReadGlobalAyahIndex;
      }
    }

    resumeGlobalAyahIndex = clampInsideWird(resumeGlobalAyahIndex);

    final resumePosition = QuranReaderHelpers.getPositionFromGlobalIndex(
      resumeGlobalAyahIndex,
    );

    final int initialSuraIndex = resumePosition.suraIndex;
    final int initialAyahIndex = resumePosition.ayahIndex;
    final int initialMushafPageNumber =
        QuranPageMapper.getPageNumberForGlobalAyah(resumeGlobalAyahIndex);

    // نحفظ نسخة مصححة من Progress قبل الفتح، عشان الكارت والقارئ يبقوا متفقين.
    await QuranWirdProgressStorage.saveProgress(
      planId: wird.planId,
      suraIndex: initialSuraIndex,
      ayahIndex: initialAyahIndex,
      mushafPageNumber: initialMushafPageNumber,
      viewMode: 'qpc_connected',
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QpcConnectedMushafPage(
          initialPage: initialMushafPageNumber,
          initialGlobalAyahIndex: resumeGlobalAyahIndex,
          saveAsLastRead: false,
          saveAsMushafOpenProgress: false,
          wirdPlanId: wird.planId,
          wirdStartGlobalAyahIndex: wird.fromGlobalAyahIndex,
          wirdEndGlobalAyahIndex: wird.toGlobalAyahIndex,
        ),
      ),
    );

    if (!mounted) return;
    await loadWirds();
  }

  Future<void> markWirdCompleted(QuranDailyWird wird) async {
    AppHaptics.medium(context);

    final activePlansBefore = await QuranWirdStorage.getActivePlans();

    final currentPlan = activePlansBefore.firstWhere(
      (plan) => plan.id == wird.planId,
    );

    final willCompleteKhatma =
        currentPlan.completedDays + 1 >= currentPlan.totalDays;

    final completedPages = (wird.toPageNumber - wird.fromPageNumber + 1).clamp(
      1,
      604,
    );

    await QuranWirdStorage.markPlanTodayWirdCompleted(wird.planId);
    await QuranWirdProgressStorage.clearProgress(wird.planId);

    await QuranReadingStatsStorage.recordCompletedWird(
      completedPages: completedPages,
      completedKhatma: willCompleteKhatma,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        margin: EdgeInsets.only(left: 24.w, right: 24.w, bottom: 18.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        content: Text(
          willCompleteKhatma
              ? 'مبارك! تم إكمال ختمة "${wird.planName}"'
              : 'تم حفظ ورد "${wird.planName}"',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontFamily: 'cairo',
            fontSize: 11.sp,
            color: Colors.white,
          ),
        ),
        duration: const Duration(milliseconds: 1200),
      ),
    );

    await loadWirds();
  }

  Future<void> deleteActiveWird(QuranDailyWird wird) async {
    await QuranWirdStorage.deleteActivePlan(wird.planId);
    await QuranWirdProgressStorage.markTodayCompleted(wird.planId);
    await QuranWirdProgressStorage.clearProgress(wird.planId);
    await loadWirds();
  }

  Future<void> deleteCompletedPlan(QuranKhatmaPlan plan) async {
    await QuranWirdStorage.deleteCompletedPlan(plan.id);
    await loadWirds();
  }

  Future<void> confirmDeleteActiveWird(QuranDailyWird wird) async {
    AppHaptics.medium(context);

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
    AppHaptics.medium(context);

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
    final width = MediaQuery.sizeOf(context).width;
    final bool isLargeScreen = width >= 600;

    final Widget content = isLoading
        ? Center(
            child: CircularProgressIndicator(color: theme.colorScheme.primary),
          )
        : isLargeScreen
        ? _buildLargeScreenContent(context)
        : _buildPhoneContent(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isLargeScreen
          ? adaptiveSidePanelColor(context)
          : theme.colorScheme.background,
      endDrawer: AppSettingsDrawer(),
      body: SafeArea(
        child: isLargeScreen
            ? AdaptiveLargeScreenShell(
                navigationItems: homeLargeScreenNavigationItems(
                  context,
                  onHomeTap: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  onSettingsTap: () =>
                      _scaffoldKey.currentState?.openEndDrawer(),
                ),
                selectedNavigationId: 'quran',
                userName: 'المسلم',
                greetingMessage: 'رفيقك في كل حين',
                quickItems: [
                  AdaptiveSideQuickItem(
                    label: 'إنشاء ختمة',
                    icon: Icons.add_circle_outline_rounded,
                    onTap: openCreateKhatma,
                  ),
                ],
                body: content,
              )
            : Column(
                children: [
                  CustomAppBar(
                    category: CustomAppBarCategory(text: 'ورد اليوم'),
                  ),
                  Expanded(child: content),
                ],
              ),
      ),
    );
  }

  Widget _buildPhoneContent(BuildContext context) {
    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      children: _buildPhoneSections(context),
    );
  }

  List<Widget> _buildPhoneSections(BuildContext context) {
    return [
      _PageHeader(
        activeCount: activeWirds.length,
        completedCount: completedPlans.length,
        onCreateKhatma: openCreateKhatma,
      ),
      SizedBox(height: 14.h),
      _ReadingStatsCard(refreshCounter: statsRefreshCounter),
      SizedBox(height: 16.h),
      ..._buildActiveWirdSection(context),
      SizedBox(height: 10.h),
      ..._buildCompletedPlansSection(context),
      SizedBox(height: 18.h),
    ];
  }

  Widget _buildLargeScreenContent(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final bool landscape = size.width > size.height;
    final bool isRealTablet = size.shortestSide >= 600;
    final double gap = 16;
    final double panelPadding = isRealTablet ? 22 : 14;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.all(panelPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LargePageTitle(
              title: 'ورد اليوم',
              onBack: () => Navigator.maybePop(context),
            ),
            SizedBox(height: gap),
            if (landscape)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  textDirection: TextDirection.rtl,
                  children: [
                    Expanded(
                      child: _PageHeader(
                        activeCount: activeWirds.length,
                        completedCount: completedPlans.length,
                        onCreateKhatma: openCreateKhatma,
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: _ReadingStatsCard(
                        refreshCounter: statsRefreshCounter,
                        large: true,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              _PageHeader(
                activeCount: activeWirds.length,
                completedCount: completedPlans.length,
                onCreateKhatma: openCreateKhatma,
              ),
              SizedBox(height: gap),
              _ReadingStatsCard(
                refreshCounter: statsRefreshCounter,
                large: true,
              ),
            ],
            SizedBox(height: gap),
            ..._buildActiveWirdSection(context),
            SizedBox(height: gap),
            ..._buildCompletedPlansSection(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActiveWirdSection(BuildContext context) {
    if (activeWirds.isEmpty) {
      return [
        _NoActiveWirdCard(
          onCreatePlan: openCreateKhatma,
          large: MediaQuery.sizeOf(context).width >= 600,
        ),
      ];
    }

    return [
      _SectionTitle(
        title: 'الأوراد الحالية',
        subtitle: '${activeWirds.length.toString().toArabicNumbers} ورد نشط',
      ),
      SizedBox(height: 10.h),
      for (final wird in activeWirds) ...[
        _ActiveWirdCard(
          wird: wird,
          progress: wirdProgressByPlanId[wird.planId],
          large: MediaQuery.sizeOf(context).width >= 600,
          onOpenReader: () => openWirdReader(wird),
          onMarkCompleted: () => markWirdCompleted(wird),
          onDelete: () => confirmDeleteActiveWird(wird),
        ),
        SizedBox(height: 12.h),
      ],
    ];
  }

  List<Widget> _buildCompletedPlansSection(BuildContext context) {
    return [
      _SectionTitle(
        title: 'الختمات المكتملة',
        subtitle: '${completedPlans.length.toString().toArabicNumbers} ختمة',
      ),
      SizedBox(height: 10.h),
      if (completedPlans.isEmpty)
        const _NoCompletedPlansCard()
      else
        for (final plan in completedPlans) ...[
          _CompletedPlanCard(
            plan: plan,
            large: MediaQuery.sizeOf(context).width >= 600,
            onDelete: () => confirmDeleteCompletedPlan(plan),
          ),
          SizedBox(height: 10.h),
        ],
    ];
  }

  List<AdaptiveNavItem> _largeScreenNavigationItems(BuildContext context) {
    return [
      AdaptiveNavItem(
        id: 'quran',
        label: 'القرآن',
        icon: Icons.menu_book_outlined,
        onTap: () => Navigator.maybePop(context),
      ),
      AdaptiveNavItem(
        id: 'daily_wird',
        label: 'ورد اليوم',
        icon: Icons.check_circle_outline_rounded,
        onTap: () {},
      ),
      AdaptiveNavItem(
        id: 'create_khatma',
        label: 'إنشاء ختمة',
        icon: Icons.auto_stories_outlined,
        onTap: openCreateKhatma,
      ),
    ];
  }
}
