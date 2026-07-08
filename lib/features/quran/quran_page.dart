import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/features/quran/phone/pages/phone_quran_page_content.dart';
import 'package:islamic_app/features/quran/phone/daily_ayah/phone_quran_daily_ayah_card.dart';
import 'package:islamic_app/features/quran/phone/tools/phone_quran_tools_section.dart';
import 'package:islamic_app/features/quran/reader/quran_page_mapper.dart';
import 'package:islamic_app/shared/widgets/app_main_components/custom_app_bar.dart';
import 'package:islamic_app/features/quran/phone/reading_summary/phone_quran_reading_summary_info.dart';
import 'package:islamic_app/features/quran/phone/reading_summary/phone_quran_reading_summary_section.dart';
import 'package:islamic_app/features/quran/phone/widgets/phone_quran_hero_card.dart';
import 'package:islamic_app/features/quran/phone/widgets/phone_quran_quick_access_strip.dart';
import 'package:provider/provider.dart';
import 'package:islamic_app/core/theme/theme_provider.dart';
import 'package:islamic_app/features/quran/main_quraan_components/to_arabic_no_converter.dart';
import 'package:islamic_app/features/quran/reader/qpc_connected_mushaf_page.dart';
import 'package:islamic_app/features/quran/reader/qpc_ayah_search_page.dart';
import 'package:islamic_app/features/quran/reader/models/qpc_models.dart';
import 'package:islamic_app/features/quran/reader/theme/quran_reader_theme_controller.dart';
import 'package:islamic_app/features/quran/reader/data/qpc_mushaf_repository.dart';
import 'package:islamic_app/features/quran/reader/quran_reader_helpers.dart';
import 'package:islamic_app/features/quran/reader/quran_reader_storage.dart';
import 'package:islamic_app/features/quran/stats/quran_reading_stats_storage.dart';
import 'package:islamic_app/features/quran/wird/create_khatma_page.dart';
import 'package:islamic_app/features/quran/wird/daily_wird_page.dart';
import 'package:islamic_app/features/quran/wird/quran_wird_storage.dart';
import 'package:islamic_app/core/adaptive/adaptive_side_navigation.dart';
import 'package:islamic_app/core/adaptive/adaptive_large_screen_shell.dart';
import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/home/presentation/adaptive/home_large_screen_navigation.dart';
import 'package:islamic_app/features/settings/app_settings_drawer.dart';
import 'package:islamic_app/shared/widgets/common_components/app_layout_constants.dart';
import 'package:islamic_app/core/services/app_haptics.dart';
import '../home/presentation/phone/widgets/phone_home_bottom_navigation.dart';
import '../home/presentation/phone/widgets/phone_tab_scaffold.dart';
import 'main_quraan_components/index.dart';
import 'main_quraan_components/quran_bookmarks_page.dart';
import 'main_quraan_components/quran_parts_page.dart';
part 'quran_page_widgets.dart';

class QuranPage extends StatefulWidget {
  const QuranPage({super.key});

  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Future<_QuranHomeInfo> homeInfoFuture;
  late Future<QuranPhoneHeroInfo> heroInfoFuture;

  @override
  void initState() {
    super.initState();
    homeInfoFuture = _recordQuranEntryAndLoad();
    heroInfoFuture = _buildHeroInfoFuture(homeInfoFuture);

    // جهّز آخر موضع قراءة في الخلفية بمجرد دخول صفحة القرآن،
    // عشان القارئ يفتح فورًا تقريبًا بدل شاشة تحميل كل مرة.
    unawaited(_warmUpMushafReader());
  }

  Future<_QuranHomeInfo> _recordQuranEntryAndLoad() async {
    await QuranReadingStatsStorage.recordQuranActivity();
    return _loadHomeInfo();
  }

  Future<QuranPhoneHeroInfo> _buildHeroInfoFuture(
    Future<_QuranHomeInfo> source,
  ) async {
    final info = await source;

    return QuranPhoneHeroInfo(readPages: info.summary.completedPages);
  }

  void _refreshHomeInfo() {
    final nextHomeInfoFuture = _loadHomeInfo();

    setState(() {
      homeInfoFuture = nextHomeInfoFuture;
      heroInfoFuture = _buildHeroInfoFuture(nextHomeInfoFuture);
    });
  }

  Future<void> _warmUpMushafReader({int? preferredPage}) async {
    final QuranLastRead? mushafProgress =
        await QuranReaderStorage.getMushafOpenProgress();

    final int pageNumber =
        (preferredPage ?? mushafProgress?.mushafPageNumber ?? 1)
            .clamp(1, 604)
            .toInt();

    await QpcMushafRepository.instance.initialize();

    // حمّل الصفحة الحالية فقط قبل فتح القارئ، والباقي يتجهز في الخلفية.
    await QpcMushafRepository.instance.loadPage(pageNumber);
    unawaited(
      QpcMushafRepository.instance.warmUpPagesAround(pageNumber, radius: 2),
    );
  }

  Future<void> _resetReadPages(BuildContext context) async {
    AppHaptics.tap(context);

    await QuranReadingStatsStorage.resetReadPages();

    if (!mounted) return;

    _refreshHomeInfo();
    _showQuranSnackBar(context: context, message: 'تم تصفير الصفحات المقروءة');
  }

  Future<void> _openPageWithoutAnimation(
    BuildContext context,
    Widget page,
  ) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );

    if (!mounted) return;
    _refreshHomeInfo();
  }

  Future<void> _openQuranFromStart(BuildContext context) async {
    AppHaptics.tap(context);

    final mushafProgress = await QuranReaderStorage.getMushafOpenProgress();

    await _warmUpMushafReader(
      preferredPage: mushafProgress?.mushafPageNumber ?? 1,
    );

    if (!context.mounted) return;

    await _openPageWithoutAnimation(
      context,
      QpcConnectedMushafPage(
        initialPage: mushafProgress?.mushafPageNumber ?? 1,
        initialGlobalAyahIndex: mushafProgress == null
            ? null
            : QuranReaderHelpers.getGlobalAyahIndex(
                suraIndex: mushafProgress.suraIndex,
                ayahIndex: mushafProgress.ayahIndex,
              ),
        saveAsLastRead: false,
        saveAsMushafOpenProgress: true,
      ),
    );
  }

  Future<void> _openLastRead(BuildContext context) async {
    AppHaptics.tap(context);

    final lastRead = await QuranReaderStorage.getLastRead();

    if (!context.mounted) return;

    if (lastRead == null) {
      _showQuranSnackBar(
        context: context,
        message: 'لا يوجد آخر موضع قراءة محفوظ حتى الآن',
      );
      return;
    }

    await _warmUpMushafReader(preferredPage: lastRead.mushafPageNumber);

    if (!context.mounted) return;

    await _openPageWithoutAnimation(
      context,
      QpcConnectedMushafPage(
        initialPage: lastRead.mushafPageNumber,
        initialGlobalAyahIndex: QuranReaderHelpers.getGlobalAyahIndex(
          suraIndex: lastRead.suraIndex,
          ayahIndex: lastRead.ayahIndex,
        ),
      ),
    );
  }

  Future<void> _openQuranSearch(BuildContext context) async {
    AppHaptics.tap(context);

    final QuranReaderThemeController themeController =
        QuranReaderThemeController.instance;
    await themeController.init();

    if (!context.mounted) return;

    final QpcAyahKey? target = await Navigator.of(context).push<QpcAyahKey>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return QpcAyahSearchPage(readerTheme: themeController.theme);
        },
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );

    if (target == null || !context.mounted) {
      return;
    }

    await QuranPageMapper.load();

    final int globalAyahIndex = QuranReaderHelpers.getGlobalAyahIndex(
      suraIndex: (target.surah - 1).clamp(0, 113).toInt(),
      ayahIndex: target.ayah - 1,
    );

    final int pageNumber = QuranPageMapper.getPageNumberForGlobalAyah(
      globalAyahIndex,
    );

    await _warmUpMushafReader(preferredPage: pageNumber);

    if (!context.mounted) return;

    await _openPageWithoutAnimation(
      context,
      QpcConnectedMushafPage(
        initialPage: pageNumber,
        initialGlobalAyahIndex: globalAyahIndex,
        saveAsLastRead: true,
        saveAsMushafOpenProgress: true,
      ),
    );
  }

  Future<void> _openCreateKhatmaPage(BuildContext context) async {
    AppHaptics.tap(context);

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateKhatmaPage()),
    );

    if (!mounted) return;

    _refreshHomeInfo();
  }

  Future<void> _openDailyWirdPage(BuildContext context) async {
    AppHaptics.tap(context);

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DailyWirdPage()),
    );

    if (!mounted) return;

    _refreshHomeInfo();
  }

  void _showQuranSnackBar({
    required BuildContext context,
    required String message,
  }) {
    final theme = Theme.of(context);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
        margin: EdgeInsets.only(left: 24.w, right: 24.w, bottom: 18.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        content: Text(
          message,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption(context).copyWith(color: Colors.white),
        ),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final bool isLargeScreen = width >= 600;

    final Widget content = isLargeScreen
        ? _buildLargeScreenContent(context)
        : _buildPhoneContent(context);

    if (!isLargeScreen) {
      return PhoneTabScaffold(
        currentTab: PhoneHomeTab.quran,
        backgroundColor: theme.colorScheme.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              CustomAppBar(
                category: const CustomAppBarCategory(text: 'القرآن'),
                subtitle: 'رفيقك اليومي للتلاوة والحفظ',
                showBackButton: false,
                reserveLeadingSpace: true,
                trailing: _QuranAppBarSearchButton(
                  onTap: () => _openQuranSearch(context),
                ),
              ),
              SizedBox(height: 10.h),
              Expanded(child: content),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: adaptiveSidePanelColor(context),
      endDrawer: AppSettingsDrawer(),
      body: SafeArea(
        child: AdaptiveLargeScreenShell(
          navigationItems: homeLargeScreenNavigationItems(
            context,
            onHomeTap: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            onSettingsTap: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
          selectedNavigationId: 'quran',
          userName: 'المسلم',
          greetingMessage: 'رفيقك في كل حين',
          quickItems: _largeScreenQuickItems(context),
          body: content,
        ),
      ),
    );
  }

  Widget _buildPhoneContent(BuildContext context) {
    return PhoneQuranPageContent(
      heroCard: _buildStartReadingCard(context),
      quickAccessCard: _buildQuickAccessStrip(context),
      readingSummaryCard: _buildReadingSummaryCard(context),
      toolsCard: _buildQuranToolsCard(context),
      dailyAyahCard: _buildDailyAyahCard(context),
    );
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
            const _LargePageTitle(title: 'القرآن', centered: true),
            SizedBox(height: gap),
            if (landscape)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  textDirection: TextDirection.rtl,
                  children: [
                    Expanded(child: _buildReadingSummaryCard(context)),
                    SizedBox(width: gap),
                    Expanded(child: _buildStartReadingCard(context)),
                  ],
                ),
              )
            else ...[
              _buildStartReadingCard(context),
              SizedBox(height: gap),
              _buildReadingSummaryCard(context),
            ],
            SizedBox(height: gap),
            _buildQuranToolsCard(context),
            SizedBox(height: gap),
            _buildDailyAyahCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStartReadingCard(BuildContext context) {
    return PhoneQuranHeroCard(
      heroInfoFuture: heroInfoFuture,
      onOpenMushaf: () => _openQuranFromStart(context),
      onOpenLastRead: () => _openLastRead(context),
    );
  }

  Widget _buildQuickAccessStrip(BuildContext context) {
    return PhoneQuranQuickAccessStrip(
      infoFuture: _buildQuickAccessInfo(),
      onOpenWird: () => _openDailyWirdPage(context),
      onOpenLastRead: () => _openLastRead(context),
    );
  }

  Future<PhoneQuranQuickAccessInfo> _buildQuickAccessInfo() async {
    final activeWirds = await QuranWirdStorage.buildTodayWirds();
    final lastRead = await QuranReaderStorage.getLastRead();

    String wirdSubtitle = 'لا يوجد ورد محدد اليوم';

    if (activeWirds.isNotEmpty) {
      final wird = activeWirds.first;

      wirdSubtitle = _formatQuickAccessRange(
        fromSuraName: QuranWirdStorage.getSuraName(wird.fromSuraIndex),
        fromAyah: wird.fromAyahIndex + 1,
        toSuraName: QuranWirdStorage.getSuraName(wird.toSuraIndex),
        toAyah: wird.toAyahIndex + 1,
      );
    }

    String lastReadSubtitle = 'لا توجد قراءة محفوظة';

    if (lastRead != null) {
      lastReadSubtitle = _formatQuickAccessPoint(
        suraName: QuranWirdStorage.getSuraName(lastRead.suraIndex),
        ayah: lastRead.ayahIndex + 1,
      );
    }

    return PhoneQuranQuickAccessInfo(
      wirdSubtitle: wirdSubtitle,
      lastReadSubtitle: lastReadSubtitle,
    );
  }

  String _formatQuickAccessRange({
    required String fromSuraName,
    required int fromAyah,
    required String toSuraName,
    required int toAyah,
  }) {
    return 'من ${_formatQuickAccessPoint(suraName: fromSuraName, ayah: fromAyah)} '
        'ل ${_formatQuickAccessPoint(suraName: toSuraName, ayah: toAyah)}';
  }

  String _formatQuickAccessPoint({
    required String suraName,
    required int ayah,
  }) {
    return '$suraName - ${_ltrNumber(ayah)}';
  }

  String _ltrNumber(Object value) {
    return '\u2066${value.toString()}\u2069';
  }

  Widget _buildReadingSummaryCard(BuildContext context) {
    return FutureBuilder<_QuranHomeInfo>(
      future: homeInfoFuture,
      builder: (context, snapshot) {
        final summary = snapshot.data?.summary ?? _QuranHomeSummary.empty();

        return PhoneQuranReadingSummarySection(
          info: PhoneQuranReadingSummaryInfo(
            readPages: summary.completedPages,
            completedWirds: summary.completedWirds,
            currentStreakDays: summary.currentStreakDays,
            activeKhatmas: summary.activePlansCount,
            nearestKhatmaProgressPercent: summary.currentPlanProgressPercent,
          ),
        );
      },
    );
  }

  Widget _buildQuranToolsCard(BuildContext context) {
    return PhoneQuranToolsSection(
      onOpenBookmarks: () async {
        await _openPageWithoutAnimation(context, const QuranBookmarksPage());
      },
      onOpenParts: () async {
        await QuranReadingStatsStorage.recordQuranActivity();
        if (!context.mounted) return;
        await _openPageWithoutAnimation(context, const QuranPartsPage());
      },
      onOpenIndex: () async {
        await QuranReadingStatsStorage.recordQuranActivity();
        if (!context.mounted) return;
        await _openPageWithoutAnimation(context, const IndexPage());
      },
      onOpenKhatmas: () => _openDailyWirdPage(context),
    );
  }

  Widget _buildDailyAyahCard(BuildContext context) {
    return const PhoneQuranDailyAyahCard();
  }

  _QuranHomeColors _quranHomeColors(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return _QuranHomeColors(
      buttonColor: isDark ? const Color(0xff0E1320) : const Color(0xff111827),
      buttonBorderColor: isDark
          ? Colors.white.withOpacity(0.08)
          : Colors.white.withOpacity(0.07),
      outerCardColor: theme.colorScheme.primary,
      outerCardBorderColor: theme.colorScheme.primary.withOpacity(0.95),
    );
  }

  List<AdaptiveNavItem> _largeScreenNavigationItems(BuildContext context) {
    return [
      AdaptiveNavItem(
        id: 'quran',
        label: 'القرآن',
        icon: Icons.menu_book_outlined,
        onTap: () {},
      ),
      AdaptiveNavItem(
        id: 'daily_wird',
        label: 'ورد اليوم',
        icon: Icons.check_circle_outline_rounded,
        onTap: () => _openDailyWirdPage(context),
      ),
      AdaptiveNavItem(
        id: 'create_khatma',
        label: 'إنشاء ختمة',
        icon: Icons.auto_stories_outlined,
        onTap: () => _openCreateKhatmaPage(context),
      ),
      AdaptiveNavItem(
        id: 'bookmarks',
        label: 'العلامات',
        icon: Icons.bookmark_border_rounded,
        onTap: () =>
            _openPageWithoutAnimation(context, const QuranBookmarksPage()),
      ),
      AdaptiveNavItem(
        id: 'parts',
        label: 'الأجزاء',
        icon: Icons.view_list_rounded,
        onTap: () => _openPageWithoutAnimation(context, const QuranPartsPage()),
      ),
      AdaptiveNavItem(
        id: 'index',
        label: 'الفهرس',
        icon: Icons.format_list_bulleted_rounded,
        onTap: () => _openPageWithoutAnimation(context, const IndexPage()),
      ),
    ];
  }

  List<AdaptiveSideQuickItem> _largeScreenQuickItems(BuildContext context) {
    return [
      AdaptiveSideQuickItem(
        label: 'فتح المصحف',
        icon: Icons.menu_book_rounded,
        onTap: () => _openQuranFromStart(context),
      ),
      AdaptiveSideQuickItem(
        label: 'آخر قراءة',
        icon: Icons.history_rounded,
        onTap: () => _openLastRead(context),
      ),
    ];
  }
}
