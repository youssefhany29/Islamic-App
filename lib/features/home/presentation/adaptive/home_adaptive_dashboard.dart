import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/shared/widgets/common_components/app_layout_constants.dart';
import 'package:islamic_app/core/adaptive/adaptive_constraints.dart';
import 'package:islamic_app/core/adaptive/adaptive_large_screen_shell.dart';
import 'package:islamic_app/core/adaptive/adaptive_side_navigation.dart';
import '../dashboard_customizer/dashboard_customize_service.dart';
import 'home_foldable_layout.dart';
import 'home_tablet_layout.dart';

class HomeAdaptiveDashboard extends StatelessWidget {
  const HomeAdaptiveDashboard({
    super.key,
    required this.header,
    required this.phoneChildren,
    required this.tileIds,
    required this.buildTile,
    required this.navigationItems,
    required this.userName,
    required this.greetingMessage,
    required this.quickItems,
    this.selectedNavigationId = 'home',
    this.phoneBottomNavigation,
  });

  final Widget header;
  final List<Widget> phoneChildren;
  final List<String> tileIds;
  final Widget Function(String id) buildTile;
  final List<AdaptiveNavItem> navigationItems;
  final String selectedNavigationId;
  final String userName;
  final String greetingMessage;
  final List<AdaptiveSideQuickItem> quickItems;
  final Widget? phoneBottomNavigation;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (AdaptiveConstraints.isCompactWidth(width)) {
      return Stack(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.vertical,
            padding: EdgeInsets.only(
              bottom: phoneBottomNavigation == null
                  ? 14.h
                  : MediaQuery.paddingOf(context).bottom + 82.h,
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppLayoutConstants.pageHorizontalPadding,
                ),
                child: Column(
                  children: [
                    header,
                    ...phoneChildren,
                  ],
                ),
              ),
            ),
          ),
          if (phoneBottomNavigation != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: phoneBottomNavigation!,
            ),
        ],
      );
    }

    final largeTileIds = _largeScreenTileIds();

    final Widget largeScreenBody = AdaptiveConstraints.isExpandedWidth(width)
        ? HomeFoldableLayout(
      tileIds: largeTileIds,
      buildTile: buildTile,
    )
        : HomeTabletLayout(
      tileIds: largeTileIds,
      buildTile: buildTile,
    );

    return AdaptiveLargeScreenShell(
      navigationItems: navigationItems,
      selectedNavigationId: selectedNavigationId,
      userName: userName,
      greetingMessage: greetingMessage,
      quickItems: quickItems,
      body: largeScreenBody,
    );
  }

  List<String> _largeScreenTileIds() {
    final ids = tileIds.where((id) {
      return id != DashboardTileIds.greeting &&
          id != DashboardTileIds.worship &&
          id != DashboardTileIds.recitations &&
          id != DashboardTileIds.podcasts &&
          id != DashboardTileIds.lessons;
    }).toList(growable: true);

    if (!ids.contains(DashboardTileIds.tabletStats)) {
      final azkarIndex = ids.indexOf(DashboardTileIds.azkar);

      if (azkarIndex == -1) {
        ids.add(DashboardTileIds.tabletStats);
      } else {
        ids.insert(azkarIndex + 1, DashboardTileIds.tabletStats);
      }
    }

    return ids;
  }
}