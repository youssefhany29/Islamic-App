import 'package:flutter/material.dart';

import '../dashboard_customizer/dashboard_customize_service.dart';
import '../tablet_dashboard/tablet_stats_dashboard_card.dart';

class HomeTabletLayout extends StatelessWidget {
  const HomeTabletLayout({
    super.key,
    required this.tileIds,
    required this.buildTile,
  });

  final List<String> tileIds;
  final Widget Function(String id) buildTile;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final bool landscape = size.width > size.height;
    final bool isRealTablet = size.shortestSide >= 600;

    final double gap = 16;
    final double panelPadding = isRealTablet ? 22 : 14;

    final bool hasNextPrayer = tileIds.contains(DashboardTileIds.nextPrayer);
    final bool hasAzkar = tileIds.contains(DashboardTileIds.azkar);
    final bool hasDailyChange = tileIds.contains(DashboardTileIds.dailyChange);
    final bool hasStats = tileIds.contains(DashboardTileIds.tabletStats);

    final List<String> remainingIds = tileIds.where((id) {
      return id != DashboardTileIds.nextPrayer &&
          id != DashboardTileIds.azkar &&
          id != DashboardTileIds.worship &&
          id != DashboardTileIds.dailyChange &&
          id != DashboardTileIds.tabletStats;
    }).toList(growable: false);

    final double dashboardPairHeight = _dashboardPairHeight(
      size: size,
      isRealTablet: isRealTablet,
      landscape: landscape,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          panelPadding,
          panelPadding,
          panelPadding,
          panelPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasNextPrayer)
              SizedBox(
                width: double.infinity,
                child: buildTile(DashboardTileIds.nextPrayer),
              ),
            if (hasNextPrayer && hasAzkar) const SizedBox(height: 16),
            if (hasAzkar)
              SizedBox(
                width: double.infinity,
                child: buildTile(DashboardTileIds.azkar),
              ),
            if (hasAzkar && (hasStats || hasDailyChange))
              const SizedBox(height: 16),
            if (hasStats || hasDailyChange)
              _TabletDashboardPair(
                landscape: landscape,
                height: dashboardPairHeight,
                gap: gap,
                hasStats: hasStats,
                hasDailyChange: hasDailyChange,
                buildTile: buildTile,
              ),
            if (hasStats || hasDailyChange) ...[
              const SizedBox(height: 16),
              const TabletTodaySmartStrip(),
            ],
            if (remainingIds.isNotEmpty) ...[
              SizedBox(height: gap),
              _ResponsiveTileWrap(
                tileIds: remainingIds,
                buildTile: buildTile,
                minTileWidth: isRealTablet ? 320 : 250,
                gap: gap,
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _dashboardPairHeight({
    required Size size,
    required bool isRealTablet,
    required bool landscape,
  }) {
    if (!isRealTablet) {
      if (landscape) return 340;
      return 320;
    }

    if (landscape) {
      return 430;
    }

    return 410;
  }
}

class _TabletDashboardPair extends StatelessWidget {
  const _TabletDashboardPair({
    required this.landscape,
    required this.height,
    required this.gap,
    required this.hasStats,
    required this.hasDailyChange,
    required this.buildTile,
  });

  final bool landscape;
  final double height;
  final double gap;
  final bool hasStats;
  final bool hasDailyChange;
  final Widget Function(String id) buildTile;

  @override
  Widget build(BuildContext context) {
    if (landscape) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: Row(
          textDirection: TextDirection.ltr,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasDailyChange)
              Expanded(
                child: SizedBox(
                  height: height,
                  child: buildTile(DashboardTileIds.dailyChange),
                ),
              ),
            if (hasDailyChange && hasStats) SizedBox(width: gap),
            if (hasStats)
              Expanded(
                child: SizedBox(
                  height: height,
                  child: buildTile(DashboardTileIds.tabletStats),
                ),
              ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasStats)
          SizedBox(
            width: double.infinity,
            height: height,
            child: buildTile(DashboardTileIds.tabletStats),
          ),
        if (hasStats && hasDailyChange) SizedBox(height: gap),
        if (hasDailyChange)
          SizedBox(
            width: double.infinity,
            height: height,
            child: buildTile(DashboardTileIds.dailyChange),
          ),
      ],
    );
  }
}

class _ResponsiveTileWrap extends StatelessWidget {
  const _ResponsiveTileWrap({
    required this.tileIds,
    required this.buildTile,
    required this.minTileWidth,
    required this.gap,
  });

  final List<String> tileIds;
  final Widget Function(String id) buildTile;
  final double minTileWidth;
  final double gap;

  @override
  Widget build(BuildContext context) {
    if (tileIds.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final int columns = _columnCount(
          width: constraints.maxWidth,
          minTileWidth: minTileWidth,
          gap: gap,
          itemCount: tileIds.length,
        );

        final double tileWidth =
            (constraints.maxWidth - (gap * (columns - 1))) / columns;

        return Wrap(
          textDirection: TextDirection.rtl,
          alignment: WrapAlignment.center,
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final id in tileIds)
              SizedBox(
                width: tileWidth,
                child: buildTile(id),
              ),
          ],
        );
      },
    );
  }

  int _columnCount({
    required double width,
    required double minTileWidth,
    required double gap,
    required int itemCount,
  }) {
    final int possible = ((width + gap) / (minTileWidth + gap)).floor();

    return possible.clamp(1, itemCount).toInt();
  }
}
