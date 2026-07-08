import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:islamic_app/features/azkar/data/datasources/zekr_local_data.dart';
import 'package:islamic_app/features/azkar/data/services/zekr_progress_service.dart';
import 'package:islamic_app/core/adaptive/adaptive_side_navigation.dart';
import 'package:islamic_app/core/services/app_haptics.dart';
import 'package:islamic_app/core/services/user_profile_service.dart';
import 'package:islamic_app/features/home/presentation/adaptive/home_adaptive_dashboard.dart';
import 'package:islamic_app/features/home/presentation/adaptive/home_large_screen_navigation.dart';
import 'package:islamic_app/features/home/presentation/dashboard_customizer/dashboard_customize_service.dart';
import 'package:islamic_app/features/home/presentation/dashboard_customizer/editable_dashboard_shell.dart';
import 'package:islamic_app/features/home/presentation/phone/pages/phone_more_page.dart';
import 'package:islamic_app/features/home/presentation/phone/widgets/phone_continue_journey_carousel.dart';
import 'package:islamic_app/features/home/presentation/phone/widgets/phone_home_bottom_navigation.dart';
import 'package:islamic_app/features/home/presentation/phone/widgets/phone_home_dashboard_cards.dart';
import 'package:islamic_app/features/home/presentation/phone/widgets/phone_home_hero_section.dart';
import 'package:islamic_app/features/home/presentation/phone/widgets/phone_todays_focus_card.dart';
import 'package:islamic_app/features/home/presentation/tablet_dashboard/tablet_stats_dashboard_card.dart';
import 'package:islamic_app/features/home/presentation/widgets/AppCustomBar.dart';
import 'package:islamic_app/features/home/presentation/widgets/main_app_widgets/daily_greeting_messages.dart';
import 'package:islamic_app/features/home/presentation/widgets/main_app_widgets/icon_container.dart';
import 'package:islamic_app/features/home/presentation/widgets/main_app_widgets/next_prayer_card.dart';
import 'package:islamic_app/features/home/presentation/widgets/main_app_widgets/zekr_smart_start_card.dart';
import 'package:islamic_app/features/home/presentation/widgets/video_widgets/app_video_widget.dart';
import 'package:islamic_app/features/memorization/my_lessons_home_page.dart';
import 'package:islamic_app/features/prayer/data/services/location_service.dart';
import 'package:islamic_app/features/prayer/data/services/prayer_time_service.dart';
import 'package:islamic_app/features/prayer/data/services/prayer_widget_sync_service.dart';
import 'package:islamic_app/features/recitations/pages/recitations_home_page.dart';
import 'package:islamic_app/features/settings/app_settings_drawer.dart';
import 'package:islamic_app/shared/widgets/common_components/app_layout_constants.dart';
import '../prayer/pray_page.dart';
import '../quran/quran_page.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_today_task_model.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_plan_storage.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_session_result_storage.dart';
import 'package:islamic_app/features/quran/wird/quran_wird_progress_storage.dart';
import 'package:islamic_app/features/quran/wird/quran_wird_storage.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  static const double _prayerCacheLocationRefreshMeters = 5000;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final LocationService _locationService = LocationService();
  final PrayerTimeService _prayerTimeService = PrayerTimeService();
  final DashboardCustomizeService _customizeService =
      const DashboardCustomizeService();
  PhoneHomeTab _currentPhoneTab = PhoneHomeTab.home;

  List<Map<String, String>> _prayerWeek = [];

  bool _loadingPrayerTimes = true;
  bool _isEditMode = false;
  String _userName = 'ضيفنا';
  String _locationLabel = 'موقعك';

  bool _wirdCompleted = false;
  bool _azkarCompleted = false;
  bool _memorizationCompleted = false;

  DashboardCustomizeState _dashboardState = const DashboardCustomizeState(
    mainOrder: DashboardCustomizeService.defaultMainOrder,
    hiddenTileIds: <String>{},
    worshipOrder: DashboardCustomizeService.defaultWorshipOrder,
    videoWideMap: DashboardCustomizeService.defaultVideoWideMap,
  );

  Timer? _midnightTimer;
  Timer? _locationChangeTimer;
  Timer? _widgetNextPrayerTimer;
  bool _refreshingForLocationChange = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserName();
    _loadPrayerTimes();
    _loadDashboardState();
    _scheduleMidnightUpdate();
    _startLocationChangeMonitor();
    _loadDailyProgressSummary();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openPrayerPageFromInitialDeepLink();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    _locationChangeTimer?.cancel();
    _widgetNextPrayerTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _openPrayerPageFromInitialDeepLink();
      _refreshPrayerTimesIfLocationChanged();
    }
  }

  void _startLocationChangeMonitor() {
    _locationChangeTimer?.cancel();
    _locationChangeTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _refreshPrayerTimesIfLocationChanged(),
    );
  }

  Future<void> _loadDailyProgressSummary() async {
    final activeWirdPlans = await QuranWirdStorage.getActivePlans();
    final completedWirdPlans = await QuranWirdStorage.getCompletedPlans();

    bool wirdDone = false;

    for (final plan in [...activeWirdPlans, ...completedWirdPlans]) {
      final doneToday = await QuranWirdProgressStorage.wasCompletedToday(
        plan.id,
      );
      if (doneToday) {
        wirdDone = true;
        break;
      }
    }

    final memorizationTask = await MemorizationPlanStorage.getTodayTask();
    final bool memorizationDone = await _isMemorizationCompletedToday(
      memorizationTask,
    );

    final zekrProgressService = const ZekrProgressService();

    bool azkarDone = false;

    final dailyTargetCategories = ZekrLocalData.categories.where(
      (category) => category.isDailyTarget,
    );

    for (final category in dailyTargetCategories) {
      final items = ZekrLocalData.getBuiltInItems(category.id);
      if (items.isEmpty) continue;

      final completedCount = await zekrProgressService
          .getCompletedCountForCategory(category.id);

      if (completedCount >= items.length) {
        azkarDone = true;
        break;
      }
    }

    if (!mounted) return;

    setState(() {
      _wirdCompleted = wirdDone;
      _azkarCompleted = azkarDone;
      _memorizationCompleted = memorizationDone;
    });
  }

  Future<bool> _isMemorizationCompletedToday(
    MemorizationTodayTaskModel? task,
  ) async {
    if (task != null &&
        task.isAvailableToday &&
        (task.isCompleted ||
            task.status == MemorizationTodayTaskModel.statusCompleted)) {
      return true;
    }

    final results = await MemorizationSessionResultStorage.getResults();
    final now = DateTime.now();

    for (final result in results) {
      if (!_sameDay(result.completedAt, now)) continue;
      if (result.completedStep != 'completed') continue;
      if (result.taskType == 'weakReview') continue;

      if (task == null) return true;

      final exactTask = result.taskId == task.id;
      final sameRange =
          result.startGlobalAyahIndex == task.startGlobalAyahIndex &&
          result.endGlobalAyahIndex == task.endGlobalAyahIndex;
      final compatibleType =
          result.taskType == task.type ||
          (task.type == 'dailyNew' && result.taskType == 'dailyReview') ||
          (task.type == 'dailyReview' && result.taskType == 'dailyNew');

      if (exactTask || sameRange || compatibleType) return true;
    }

    return false;
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Loads the saved dashboard order, hidden cards, worship order, and video sizes.
  Future<void> _loadDashboardState() async {
    final state = await _customizeService.load();
    if (!mounted) return;

    setState(() {
      _dashboardState = state;
    });
  }

  // Saves dashboard customization after the local state is updated.
  Future<void> _saveDashboardState(DashboardCustomizeState state) async {
    setState(() {
      _dashboardState = state;
    });

    await _customizeService.save(state);
  }

  // Restores the dashboard to the default order and default visible cards.
  Future<void> _resetDashboardState() async {
    await _customizeService.reset();

    if (!mounted) return;

    setState(() {
      _dashboardState = const DashboardCustomizeState(
        mainOrder: DashboardCustomizeService.defaultMainOrder,
        hiddenTileIds: <String>{},
        worshipOrder: DashboardCustomizeService.defaultWorshipOrder,
        videoWideMap: DashboardCustomizeService.defaultVideoWideMap,
      );
    });
  }

  void _toggleEditMode() {
    AppHaptics.tap(context);

    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  // Reorders the main dashboard cards while the edit mode is enabled.
  void _swapMainTiles(String draggedId, String targetId) {
    if (draggedId == targetId) return;

    final order = List<String>.from(_dashboardState.mainOrder);
    final fromIndex = order.indexOf(draggedId);
    final toIndex = order.indexOf(targetId);

    if (fromIndex == -1 || toIndex == -1) return;

    order
      ..removeAt(fromIndex)
      ..insert(toIndex, draggedId);

    _saveDashboardState(_dashboardState.copyWith(mainOrder: order));
  }

  void _hideMainTile(String id) {
    if (!DashboardCustomizeService.canHide(id)) return;

    final hidden = Set<String>.from(_dashboardState.hiddenTileIds)..add(id);

    _saveDashboardState(_dashboardState.copyWith(hiddenTileIds: hidden));
  }

  void _restoreMainTile(String id) {
    final hidden = Set<String>.from(_dashboardState.hiddenTileIds)..remove(id);

    _saveDashboardState(_dashboardState.copyWith(hiddenTileIds: hidden));
  }

  void _toggleVideoWidth(String id) {
    if (!DashboardCustomizeService.isVideoTile(id)) return;

    final sizes = Map<String, bool>.from(_dashboardState.videoWideMap);
    sizes[id] = !(sizes[id] ?? false);

    _saveDashboardState(_dashboardState.copyWith(videoWideMap: sizes));
  }

  // Reorders the worship shortcuts inside the worship card only.
  void _reorderWorshipTiles(String draggedId, String targetId) {
    if (draggedId == targetId) return;

    final order = List<String>.from(_dashboardState.worshipOrder);
    final fromIndex = order.indexOf(draggedId);
    final toIndex = order.indexOf(targetId);

    if (fromIndex == -1 || toIndex == -1) return;

    order
      ..removeAt(fromIndex)
      ..insert(toIndex, draggedId);

    _saveDashboardState(_dashboardState.copyWith(worshipOrder: order));
  }

  Future<void> _showHiddenTiles() async {
    await showHiddenDashboardTilesSheet(
      context: context,
      state: _dashboardState,
      onRestore: _restoreMainTile,
    );
  }

  Future<void> _loadUserName() async {
    final String name = await const UserProfileService().getUserName();

    if (!mounted) return;

    setState(() {
      _userName = name.trim().isEmpty ? 'ضيفنا' : name.trim();
    });
  }

  // Uses cached prayer times first so the Home screen is useful even offline.
  Future<void> _loadPrayerTimes({bool forceRefresh = false}) async {
    if (!mounted) return;

    final List<Map<String, String>> cachedWeek = await _prayerTimeService
        .getCachedPrayerWeek();

    final String? cachedDate = await _prayerTimeService
        .getCachedPrayerWeekDate();

    final String todayKey = _todayStorageKey();

    if (!mounted) return;

    final bool hasCachedWeek = cachedWeek.isNotEmpty;
    final bool cacheIsForToday = cachedDate == todayKey;
    Position? refreshedPosition;
    String? refreshedLocationLabel;

    if (hasCachedWeek) {
      final cachedLocationLabel =
          await _locationService.getCachedLocationName() ?? 'موقعك';

      setState(() {
        _prayerWeek = cachedWeek;
        _locationLabel = cachedLocationLabel;
        _loadingPrayerTimes = false;
      });

      if (!forceRefresh && cacheIsForToday) {
        try {
          refreshedPosition = await _locationService.getCurrentLocation(
            forceFresh: false,
          );
          refreshedLocationLabel = await _locationService
              .getReadableLocationName(refreshedPosition);
          final cachedCoordinates = await _prayerTimeService
              .getCachedPrayerCoordinates();
          final cachedCountryIso = await _prayerTimeService
              .getCachedPrayerCountryIso();
          final currentCountryIso = await _prayerTimeService
              .getCountryIsoForPosition(refreshedPosition);

          if (cachedCoordinates != null) {
            final double distanceInMeters = Geolocator.distanceBetween(
              cachedCoordinates.latitude,
              cachedCoordinates.longitude,
              refreshedPosition.latitude,
              refreshedPosition.longitude,
            );
            final bool sameCountry =
                cachedCountryIso == null ||
                currentCountryIso == null ||
                cachedCountryIso == currentCountryIso;

            if (sameCountry &&
                distanceInMeters < _prayerCacheLocationRefreshMeters) {
              if (!mounted) return;

              setState(() {
                _locationLabel = refreshedLocationLabel!;
              });
              await _syncPrayerWidgetSnapshot();
              return;
            }
          }
        } catch (_) {
          _refreshLocationLabelOnly();
          await _syncPrayerWidgetSnapshot();
          return;
        }
      }
    } else {
      setState(() {
        _loadingPrayerTimes = true;
      });
    }

    try {
      final position =
          refreshedPosition ??
          await _locationService.getCurrentLocation(forceFresh: forceRefresh);

      final locationLabel =
          refreshedLocationLabel ??
          await _locationService.getReadableLocationName(position);

      final week = await _prayerTimeService.getWeekPrayerTimes(position);

      if (!mounted) return;

      setState(() {
        _prayerWeek = week;
        _locationLabel = locationLabel;
        _loadingPrayerTimes = false;
      });

      await _syncPrayerWidgetSnapshot();
    } catch (_) {
      final fallbackCachedWeek = hasCachedWeek
          ? cachedWeek
          : await _prayerTimeService.getCachedPrayerWeek();

      if (!mounted) return;

      final cachedLocationLabel =
          await _locationService.getCachedLocationName() ?? 'موقعك';

      setState(() {
        _prayerWeek = fallbackCachedWeek;
        _locationLabel = cachedLocationLabel;
        _loadingPrayerTimes = false;
      });

      await _syncPrayerWidgetSnapshot();
    }
  }

  Future<void> _refreshPrayerTimesIfLocationChanged() async {
    if (_refreshingForLocationChange || _loadingPrayerTimes) return;

    _refreshingForLocationChange = true;
    try {
      final cachedCoordinates = await _prayerTimeService
          .getCachedPrayerCoordinates();
      if (cachedCoordinates == null) return;

      final position = await _locationService.getCurrentLocation(
        forceFresh: false,
      );
      final cachedCountryIso = await _prayerTimeService
          .getCachedPrayerCountryIso();
      final currentCountryIso = await _prayerTimeService
          .getCountryIsoForPosition(position);
      final double distanceInMeters = Geolocator.distanceBetween(
        cachedCoordinates.latitude,
        cachedCoordinates.longitude,
        position.latitude,
        position.longitude,
      );
      final bool countryChanged =
          cachedCountryIso != null &&
          currentCountryIso != null &&
          cachedCountryIso != currentCountryIso;

      if (countryChanged ||
          distanceInMeters >= _prayerCacheLocationRefreshMeters) {
        await _loadPrayerTimes(forceRefresh: true);
      }
    } catch (_) {
      // Keep the cached prayer state if location is temporarily unavailable.
    } finally {
      _refreshingForLocationChange = false;
    }
  }

  Future<void> _refreshLocationLabelOnly() async {
    try {
      final position = await _locationService.getCurrentLocation(
        forceFresh: false,
      );

      final locationLabel = await _locationService.getReadableLocationName(
        position,
      );

      if (!mounted) return;

      setState(() {
        _locationLabel = locationLabel;
      });
      await _syncPrayerWidgetSnapshot();
    } catch (_) {
      // last saved location
    }
  }

  String _todayStorageKey() {
    final DateTime now = DateTime.now();

    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  // Refreshes prayer data after midnight so the next-prayer card does not stay on yesterday.
  void _scheduleMidnightUpdate() {
    _midnightTimer?.cancel();

    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);

    final delay = nextMidnight.difference(now);

    _midnightTimer = Timer(delay, () {
      _loadPrayerTimes(forceRefresh: true);
      _scheduleMidnightUpdate();
    });
  }

  void _openRecitationsPage() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RecitationsHomePage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    ).then((_) => _loadDailyProgressSummary());
  }

  void _showPodcastsComingSoon() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'البودكاست قريبًا',
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  void _openMyLessonsPage() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MyLessonsHomePage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    ).then((_) => _loadDailyProgressSummary());
  }

  void _onPhoneTabSelected(PhoneHomeTab tab) {
    AppHaptics.tap(context);

    if (tab == PhoneHomeTab.home) {
      setState(() => _currentPhoneTab = tab);
      return;
    }

    if (tab == PhoneHomeTab.quran) {
      _openPhonePage(const QuranPage());
      return;
    }

    if (tab == PhoneHomeTab.prayer) {
      _openPhonePage(const PrayPage());
      return;
    }

    if (tab == PhoneHomeTab.memorization) {
      _openPhonePage(const MyLessonsHomePage());
      return;
    }

    if (tab == PhoneHomeTab.more) {
      _openPhonePage(const PhoneMorePage());
      return;
    }
  }

  void _openPhonePage(Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    ).then((_) => _loadDailyProgressSummary());
  }

  Future<void> _syncPrayerWidgetSnapshot() async {
    final snapshot = await PrayerWidgetSyncService.instance.syncFromCache(
      prayerWeek: _prayerWeek,
      locationLabel: _locationLabel,
      isLoading: _loadingPrayerTimes,
    );
    _schedulePrayerWidgetNextChangeSync(snapshot.nextPrayerAtMillis);
  }

  void _schedulePrayerWidgetNextChangeSync(int nextPrayerAtMillis) {
    _widgetNextPrayerTimer?.cancel();

    if (nextPrayerAtMillis <= 0) return;

    final nextPrayerAt = DateTime.fromMillisecondsSinceEpoch(
      nextPrayerAtMillis,
    );
    final delay = nextPrayerAt
        .add(const Duration(minutes: 1))
        .difference(DateTime.now());

    if (delay.isNegative) return;

    _widgetNextPrayerTimer = Timer(delay, _syncPrayerWidgetSnapshot);
  }

  Future<void> _openPrayerPageFromInitialDeepLink() async {
    final shouldOpenPrayer = await PrayerWidgetSyncService.instance
        .consumeInitialPrayerDeepLink();

    if (!mounted || !shouldOpenPrayer) return;

    _openPhonePage(const PrayPage());
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool isLargeScreen = MediaQuery.sizeOf(context).width >= 600;
    final backgroundColor = isLargeScreen
        ? adaptiveSidePanelColor(context)
        : colors.background;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: backgroundColor,
      extendBody: true,
      extendBodyBehindAppBar: true,
      endDrawer: AppSettingsDrawer(
        onUserNameChanged: _loadUserName,
        onEditInterface: _toggleEditMode,
      ),
      body: ColoredBox(
        color: backgroundColor,
        child: SafeArea(
          top: true,
          bottom: false,
          child: HomeAdaptiveDashboard(
            header: Column(
              children: [
                SizedBox(
                  width: AppLayoutConstants.mainCardWidth,
                  child: const AppCustomBar(),
                ),
                SizedBox(height: 12.h),
                if (_isEditMode)
                  SizedBox(
                    width: AppLayoutConstants.mainCardWidth,
                    child: DashboardEditTopBar(
                      hiddenCount: _dashboardState.hiddenTileIds.length,
                      onDone: _toggleEditMode,
                      onReset: _resetDashboardState,
                      onShowHidden: _showHiddenTiles,
                    ),
                  ),
              ],
            ),
            phoneChildren: _buildDashboardChildren(),
            tileIds: _visibleDashboardIds(),
            buildTile: _buildEditableTile,
            navigationItems: homeLargeScreenNavigationItems(
              context,
              onSettingsTap: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
            userName: _userName,
            greetingMessage: DailyGreetingMessages.todayMessage(),
            quickItems: [
              AdaptiveSideQuickItem(
                label: 'تلاوة',
                icon: Icons.graphic_eq_rounded,
                onTap: _openRecitationsPage,
              ),
              AdaptiveSideQuickItem(
                label: 'بودكاست',
                icon: Icons.podcasts_rounded,
                onTap: _showPodcastsComingSoon,
              ),
              AdaptiveSideQuickItem(
                label: 'حلقة الحفظ',
                icon: Icons.menu_book_rounded,
                onTap: _openMyLessonsPage,
              ),
            ],
            phoneBottomNavigation: PhoneHomeBottomNavigation(
              currentTab: _currentPhoneTab,
              onTabSelected: _onPhoneTabSelected,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDashboardChildren() {
    final children = <Widget>[
      _buildPhoneHeroSection(),

      SizedBox(height: 12.h),

      const ZekrSmartStartCard(),

      SizedBox(height: 12.h),

      PhoneHomeProgressOverviewCard(
        wirdCompleted: _wirdCompleted,
        azkarCompleted: _azkarCompleted,
        memorizationCompleted: _memorizationCompleted,
      ),

      SizedBox(height: 12.h),

      PhoneContinueJourneyCarousel(onJourneyChanged: _loadDailyProgressSummary),

      SizedBox(height: 14.h),

      PhoneTodaysFocusCard(
        prayerWeek: _prayerWeek,
        isLoadingPrayerTimes: _loadingPrayerTimes,
        onTasksChanged: _loadDailyProgressSummary,
      ),
    ];

    final visibleOrder = _visiblePhoneDashboardIds();

    int index = 0;
    while (index < visibleOrder.length) {
      final id = visibleOrder[index];

      if (_shouldRenderAsHalfVideo(id)) {
        final nextIndex = index + 1;
        final hasNextHalfVideo =
            nextIndex < visibleOrder.length &&
            _shouldRenderAsHalfVideo(visibleOrder[nextIndex]);

        children.add(SizedBox(height: 12.h));

        if (hasNextHalfVideo) {
          final nextId = visibleOrder[nextIndex];

          children.add(
            SizedBox(
              width: AppLayoutConstants.mainCardWidth,
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(child: _buildEditableTile(id)),
                  SizedBox(width: 16.w),
                  Expanded(child: _buildEditableTile(nextId)),
                ],
              ),
            ),
          );

          index += 2;
          continue;
        }

        children.add(
          SizedBox(
            width: AppLayoutConstants.mainCardWidth,
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: AppLayoutConstants.halfCardWidth,
                child: _buildEditableTile(id),
              ),
            ),
          ),
        );

        index += 1;
        continue;
      }

      final tile = _buildEditableTile(id);

      if (tile is! SizedBox || tile.width != 0) {
        children.add(SizedBox(height: 12.h));
        children.add(tile);
      }

      index += 1;
    }

    return children;
  }

  Widget _buildPhoneHeroSection() {
    return PhoneHomeHeroSection(
      userName: _userName,
      greetingMessage: DailyGreetingMessages.todayMessage(),
      prayerWeek: _prayerWeek,
      isLoadingPrayerTimes: _loadingPrayerTimes,
      locationLabel: _locationLabel,
    );
  }

  List<String> _visibleDashboardIds() {
    return _dashboardState.mainOrder
        .where((id) => !_dashboardState.hiddenTileIds.contains(id))
        .toList(growable: false);
  }

  // Phone Home should focus on daily worship. Media stays reachable later through phone navigation.
  List<String> _visiblePhoneDashboardIds() {
    return _visibleDashboardIds()
        .where((id) {
          return id != DashboardTileIds.greeting &&
              id != DashboardTileIds.nextPrayer &&
              id != DashboardTileIds.azkar &&
              id != DashboardTileIds.worship &&
              id != DashboardTileIds.recitations &&
              id != DashboardTileIds.podcasts &&
              id != DashboardTileIds.lessons &&
              id != DashboardTileIds.tabletStats;
        })
        .toList(growable: false);
  }

  bool _shouldRenderAsHalfVideo(String id) {
    return DashboardCustomizeService.isVideoTile(id) &&
        !(_dashboardState.videoWideMap[id] ?? false);
  }

  Widget _buildEditableTile(String id) {
    final tile = _buildTileContent(id);
    if (tile == null) return const SizedBox.shrink();

    return EditableDashboardShell(
      id: id,
      title: DashboardCustomizeService.tileTitle(id),
      isEditMode: _isEditMode,
      isHidden: false,
      isWideVideo: _dashboardState.videoWideMap[id] ?? false,
      canHide: DashboardCustomizeService.canHide(id),
      canResize: DashboardCustomizeService.isVideoTile(id),
      allowChildInteractionInEditMode: id == DashboardTileIds.worship,
      onSwap: (draggedId) => _swapMainTiles(draggedId, id),
      onHide: () => _hideMainTile(id),
      onToggleVideoSize: () => _toggleVideoWidth(id),
      child: tile,
    );
  }

  Widget? _buildTileContent(String id) {
    switch (id) {
      case DashboardTileIds.greeting:
        return const SizedBox.shrink();

      case DashboardTileIds.nextPrayer:
        if (_loadingPrayerTimes) {
          return SizedBox(
            width: AppLayoutConstants.mainCardWidth,
            height: 90.h,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (_prayerWeek.isEmpty) return const SizedBox.shrink();

        return NextPrayerCard(prayerWeek: _prayerWeek);

      case DashboardTileIds.azkar:
        return const ZekrSmartStartCard();

      case DashboardTileIds.worship:
        return IconContainer(
          isEditMode: _isEditMode,
          worshipOrder: _dashboardState.worshipOrder,
          onWorshipReorder: _reorderWorshipTiles,
        );

      case DashboardTileIds.tabletStats:
        return const TabletStatsDashboardCard();

      case DashboardTileIds.recitations:
        return AppVideoTile(
          type: AppVideoTileType.recitations,
          isWide: _dashboardState.videoWideMap[id] ?? false,
        );

      case DashboardTileIds.podcasts:
        return AppVideoTile(
          type: AppVideoTileType.podcasts,
          isWide: _dashboardState.videoWideMap[id] ?? false,
        );

      case DashboardTileIds.lessons:
        return AppVideoTile(
          type: AppVideoTileType.lessons,
          isWide: _dashboardState.videoWideMap[id] ?? true,
        );

      default:
        return null;
    }
  }
}
