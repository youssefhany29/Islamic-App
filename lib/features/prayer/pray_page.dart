import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';
import 'package:geolocator/geolocator.dart';
import 'package:islamic_app/features/prayer/phone/widgets/phone_prayer_hero_card.dart';
import 'package:islamic_app/features/prayer/presentation/widgets/following_pray.dart';
import 'package:provider/provider.dart';
import 'package:islamic_app/shared/widgets/common_components/app_layout_constants.dart';
import 'package:islamic_app/core/adaptive/adaptive_side_navigation.dart';
import 'package:islamic_app/core/adaptive/adaptive_large_screen_shell.dart';
import 'package:islamic_app/core/adaptive/prayer_adaptive.dart';
import 'package:islamic_app/features/home/presentation/adaptive/home_large_screen_navigation.dart';
import 'package:islamic_app/features/settings/app_settings_drawer.dart';
import 'package:islamic_app/shared/widgets/app_main_components/custom_app_bar.dart';
import 'package:islamic_app/features/prayer/presentation/widgets/table_widgets/pray_table.dart';
import 'package:islamic_app/features/prayer/presentation/widgets/summary_widgets/prayer_day_summary_card.dart';
import 'package:islamic_app/features/prayer/data/services/location_service.dart';
import 'package:islamic_app/features/prayer/data/services/prayer_time_service.dart';
import 'package:islamic_app/features/prayer/data/notifications/prayer_notification_settings_provider.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';

import '../home/presentation/phone/widgets/phone_home_bottom_navigation.dart';
import '../home/presentation/phone/widgets/phone_tab_scaffold.dart';

class PrayPage extends StatefulWidget {
  const PrayPage({super.key});

  @override
  State<PrayPage> createState() => _PrayPageState();
}

class _PrayPageState extends State<PrayPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final LocationService _locationService = LocationService();
  final PrayerTimeService _prayerTimeService = PrayerTimeService();

  List<Map<String, String>> _prayerWeek = [];

  bool _loading = true;
  bool _refreshingInBackground = false;
  bool _usingCachedData = false;

  String? _error;
  String? _cachedDate;
  String _locationLabel = 'موقعك';
  DateTime? _lastUpdatedAt;

  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    _loadCachedLocationName();
    _loadPrayerTimes();
    _scheduleMidnightUpdate();
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCachedLocationName() async {
    final cachedName = await _locationService.getCachedLocationName();

    if (!mounted || cachedName == null || cachedName.trim().isEmpty) return;

    setState(() {
      _locationLabel = cachedName.trim();
    });
  }

  Future<void> _loadPrayerTimes({
    bool forceRefresh = false,
  }) async {
    if (!mounted) return;

    final cachedWeek = await _prayerTimeService.getCachedPrayerWeek();
    final cachedDate = await _prayerTimeService.getCachedPrayerWeekDate();
    final todayKey = _todayStorageKey();

    if (!mounted) return;

    final hasValidCachedWeek = cachedWeek.isNotEmpty;
    final cacheIsForToday = cachedDate == todayKey;

    if (hasValidCachedWeek) {
      setState(() {
        _prayerWeek = cachedWeek;
        _cachedDate = cachedDate;
        _usingCachedData = !cacheIsForToday;
        _loading = false;
        _error = null;
        _lastUpdatedAt ??= DateTime.now();
      });

      if (!forceRefresh && cacheIsForToday) {
        return;
      }

      setState(() {
        _refreshingInBackground = true;
      });
    } else {
      setState(() {
        _loading = true;
        _refreshingInBackground = false;
        _error = null;
        _usingCachedData = false;
      });
    }

    try {
      final position = await _locationService.getCurrentLocation(
        forceFresh: forceRefresh,
      );
      final locationNameFuture = _locationService.getReadableLocationName(
        position,
      );
      final week = await _prayerTimeService.getWeekPrayerTimes(position);
      final locationName = await locationNameFuture;

      await _reschedulePrayerNotificationsIfNeeded();

      if (!mounted) return;

      setState(() {
        _prayerWeek = week;
        _cachedDate = todayKey;
        _loading = false;
        _refreshingInBackground = false;
        _usingCachedData = false;
        _error = null;
        _locationLabel = locationName.trim().isEmpty
            ? 'موقعك'
            : locationName.trim();
        _lastUpdatedAt = DateTime.now();
      });
    } catch (error) {
      if (!mounted) return;

      if (hasValidCachedWeek) {
        setState(() {
          _prayerWeek = cachedWeek;
          _cachedDate = cachedDate;
          _usingCachedData = true;
          _loading = false;
          _refreshingInBackground = false;
          _error = error.toString();
          _lastUpdatedAt ??= DateTime.now();
        });
      } else {
        await _loadCachedPrayerTimes(
          errorMessage: error.toString(),
        );
      }
    }
  }

  Future<void> _reschedulePrayerNotificationsIfNeeded() async {
    if (!mounted) return;

    try {
      final provider = Provider.of<PrayerNotificationSettingsProvider>(
        context,
        listen: false,
      );

      await provider.refreshPrayerNotificationsAfterPrayerTimesUpdated();
    } catch (error) {
      debugPrint(
        '⚠️ Prayer notifications were not refreshed after prayer times update: $error',
      );
    }
  }

  Future<void> _loadCachedPrayerTimes({
    required String errorMessage,
  }) async {
    final cachedWeek = await _prayerTimeService.getCachedPrayerWeek();
    final cachedDate = await _prayerTimeService.getCachedPrayerWeekDate();

    if (!mounted) return;

    if (cachedWeek.isNotEmpty) {
      setState(() {
        _prayerWeek = cachedWeek;
        _cachedDate = cachedDate;
        _usingCachedData = true;
        _loading = false;
        _refreshingInBackground = false;
        _error = errorMessage;
        _lastUpdatedAt ??= DateTime.now();
      });
    } else {
      setState(() {
        _prayerWeek = [];
        _cachedDate = null;
        _usingCachedData = false;
        _loading = false;
        _refreshingInBackground = false;
        _error = errorMessage;
      });
    }
  }

  void _scheduleMidnightUpdate() {
    _midnightTimer?.cancel();

    final now = DateTime.now();
    final nextMidnight = DateTime(
      now.year,
      now.month,
      now.day + 1,
    );

    final delay = nextMidnight.difference(now);

    _midnightTimer = Timer(delay, () {
      _loadPrayerTimes(forceRefresh: true);
      _scheduleMidnightUpdate();
    });
  }

  Future<void> _openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> _openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  String _todayStorageKey() {
    final now = DateTime.now();

    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isLargeScreen = MediaQuery.sizeOf(context).width >= 600;

    if (!isLargeScreen) {
      return PhoneTabScaffold(
        currentTab: PhoneHomeTab.prayer,
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: const CustomAppBar(
          showBackButton: false,
          category: CustomAppBarCategory(
            text: 'الصلاة',
          ),
        ),
        body: _buildPhoneBody(context),
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
          selectedNavigationId: 'prayer',
          userName: 'المسلم',
          greetingMessage: 'رفيقك في كل حين',
          quickItems: [
            AdaptiveSideQuickItem(
              label: 'تحديث الصلاة',
              icon: Icons.refresh_rounded,
              onTap: () => _loadPrayerTimes(forceRefresh: true),
            ),
          ],
          body: _buildLargeBody(context),
        ),
      ),
    );
  }

  Widget _buildPhoneBody(BuildContext context) {
    final double bottomNavSafeSpace =
        MediaQuery.paddingOf(context).bottom + 104.h;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      padding: EdgeInsets.only(bottom: bottomNavSafeSpace),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppLayoutConstants.pageHorizontalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 10.h),
              if (_loading)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.h),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_prayerWeek.isNotEmpty) ...[
                if (_refreshingInBackground)
                  Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: _BackgroundRefreshCard(),
                  ),
                if (_usingCachedData)
                  Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: _CachedDataWarningCard(
                      cachedDate: _cachedDate,
                      onRetry: () => _loadPrayerTimes(forceRefresh: true),
                      onOpenLocationSettings: _openLocationSettings,
                      onOpenAppSettings: _openAppSettings,
                    ),
                  ),
                PhonePrayerHeroCard(
                  prayerWeek: _prayerWeek,
                  locationLabel: _locationLabel,
                  isLoadingPrayerTimes: _loading,
                  lastUpdatedAt: _lastUpdatedAt,
                  onRefresh: () => _loadPrayerTimes(forceRefresh: true),
                ),
                SizedBox(height: 10.h),
                PrayTable(
                  prayerWeek: _prayerWeek,
                ),
                SizedBox(height: 12.h),
                FollowingPray(
                  prayerWeek: _prayerWeek,
                ),
              ] else
                _PrayerTimesErrorCard(
                  errorMessage: _error,
                  onRetry: () => _loadPrayerTimes(forceRefresh: true),
                  onOpenLocationSettings: _openLocationSettings,
                  onOpenAppSettings: _openAppSettings,
                ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLargeBody(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final bool landscape = size.width > size.height;
    final double padding = PrayerAdaptive.pagePadding(context);
    final double gap = PrayerAdaptive.sectionGap(context);

    final Widget loading = Center(
      child: CircularProgressIndicator(
        color: Theme.of(context).colorScheme.primary,
      ),
    );

    final List<Widget> statusCards = [
      if (_refreshingInBackground) const _BackgroundRefreshCard(large: true),
      if (_usingCachedData)
        _CachedDataWarningCard(
          cachedDate: _cachedDate,
          onRetry: () => _loadPrayerTimes(forceRefresh: true),
          onOpenLocationSettings: _openLocationSettings,
          onOpenAppSettings: _openAppSettings,
          large: true,
        ),
    ];

    final Widget mainPrayerContent = _prayerWeek.isNotEmpty
        ? Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...[
          for (final card in statusCards) ...[
            card,
            SizedBox(height: gap),
          ],
        ],
        PrayerDaySummaryCard(
          prayerWeek: _prayerWeek,
          usingCachedData: _usingCachedData,
          cachedDate: _cachedDate,
          onRefresh: () => _loadPrayerTimes(forceRefresh: true),
          large: true,
        ),
        SizedBox(height: gap),
        PrayTable(
          prayerWeek: _prayerWeek,
          large: true,
        ),
      ],
    )
        : _PrayerTimesErrorCard(
      errorMessage: _error,
      onRetry: () => _loadPrayerTimes(forceRefresh: true),
      onOpenLocationSettings: _openLocationSettings,
      onOpenAppSettings: _openAppSettings,
      large: true,
    );

    final Widget trackingContent = FollowingPray(
      prayerWeek: _prayerWeek,
      large: true,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PrayerLargeHeader(
              onRefresh: () => _loadPrayerTimes(forceRefresh: true),
            ),
            SizedBox(height: gap),
            if (_loading)
              SizedBox(
                height: 320,
                child: loading,
              )
            else if (landscape)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    flex: 6,
                    child: mainPrayerContent,
                  ),
                  SizedBox(width: gap),
                  Expanded(
                    flex: 5,
                    child: trackingContent,
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  mainPrayerContent,
                  SizedBox(height: gap),
                  trackingContent,
                ],
              ),
          ],
        ),
      ),
    );
  }
}


class _PrayerLargeHeader extends StatelessWidget {
  const _PrayerLargeHeader({
    required this.onRefresh,
  });

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isFoldLandscape = PrayerAdaptive.isFoldLandscape(context);

    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'الصلاة',
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: AppTextStyles.display(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onBackground,
                    height: 1.1),
              ),
              const SizedBox(height: 4),
              Text(
                'تابع المواقيت والسنن وتقدّم صلاتك اليومية',
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onBackground.withOpacity(0.56),
                    height: 1.2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: theme.colorScheme.secondary.withOpacity(0.96),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onRefresh,
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.refresh_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BackgroundRefreshCard extends StatelessWidget {
  const _BackgroundRefreshCard({this.large = false});

  final bool large;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: large ? double.infinity : AppLayoutConstants.mainCardWidth,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: large ? 12 : 12.w,
            vertical: large ? 8 : 9.h,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.25),
              width: 0.7.w,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: large ? 16 : 16.w,
                height: large ? 16 : 16.w,
                child: CircularProgressIndicator(
                  strokeWidth: large ? 2 : 2.w,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(width: large ? 8 : 8.w),
              Expanded(
                child: Text(
                  'يتم تحديث مواقيت الصلاة في الخلفية...',
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context)
                          .colorScheme
                          .surface
                          .withOpacity(0.75)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CachedDataWarningCard extends StatelessWidget {
  final String? cachedDate;
  final VoidCallback onRetry;
  final VoidCallback onOpenLocationSettings;
  final VoidCallback onOpenAppSettings;
  final bool large;

  const _CachedDataWarningCard({
    required this.cachedDate,
    required this.onRetry,
    required this.onOpenLocationSettings,
    required this.onOpenAppSettings,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return _StatusCard(
      title: 'يتم عرض آخر مواقيت محفوظة',
      message: cachedDate == null
          ? 'تعذر تحديث المواقيت حاليًا. يمكنك تشغيل الموقع ثم إعادة المحاولة.'
          : 'آخر تحديث محفوظ: $cachedDate',
      icon: Icons.info_outline_rounded,
      iconColor: Colors.amber,
      onRetry: onRetry,
      onOpenLocationSettings: onOpenLocationSettings,
      onOpenAppSettings: onOpenAppSettings,
      large: large,
    );
  }
}

class _PrayerTimesErrorCard extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onOpenLocationSettings;
  final VoidCallback onOpenAppSettings;
  final bool large;

  const _PrayerTimesErrorCard({
    required this.errorMessage,
    required this.onRetry,
    required this.onOpenLocationSettings,
    required this.onOpenAppSettings,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return _StatusCard(
      title: 'تعذر تحميل مواقيت الصلاة',
      message:
      'تأكد من تشغيل الموقع والسماح للتطبيق باستخدامه، ثم اضغط إعادة المحاولة.',
      icon: Icons.location_off_rounded,
      iconColor: Colors.redAccent,
      onRetry: onRetry,
      onOpenLocationSettings: onOpenLocationSettings,
      onOpenAppSettings: onOpenAppSettings,
      large: large,
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onRetry;
  final VoidCallback onOpenLocationSettings;
  final VoidCallback onOpenAppSettings;
  final bool large;

  const _StatusCard({
    required this.title,
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.onRetry,
    required this.onOpenLocationSettings,
    required this.onOpenAppSettings,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: large ? double.infinity : AppLayoutConstants.mainCardWidth,
        child: Container(
          padding: EdgeInsets.all(large ? 12 : 12.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(
              AppLayoutConstants.mainCardRadius,
            ),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.35),
              width: large ? 0.8 : 0.8.w,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: iconColor,
                size: large ? 22 : 25.sp,
              ),
              SizedBox(height: large ? 8 : 8.h),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.surface),
              ),
              SizedBox(height: large ? 6 : 6.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context)
                        .colorScheme
                        .surface
                        .withOpacity(0.75)),
              ),
              SizedBox(height: large ? 12 : 12.h),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      title: 'إعادة المحاولة',
                      icon: Icons.refresh_rounded,
                      onTap: onRetry,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _ActionButton(
                      title: 'إعدادات الموقع',
                      icon: Icons.location_on_rounded,
                      onTap: onOpenLocationSettings,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              _ActionButton(
                title: 'إعدادات التطبيق',
                icon: Icons.settings_rounded,
                onTap: onOpenAppSettings,
                fullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool fullWidth;

  const _ActionButton({
    required this.title,
    required this.icon,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = InkWell(
      borderRadius: BorderRadius.circular(14.r),
      onTap: () {
        AppHaptics.tap(context);
        onTap();
      },
      child: Container(
        height: 34.h,
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 15.sp,
            ),
            SizedBox(width: 5.w),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context)
                    .copyWith(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    if (fullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }
}
