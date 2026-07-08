import 'package:flutter/widgets.dart';

import 'home_tablet_layout.dart';

class HomeFoldableLayout extends StatelessWidget {
  const HomeFoldableLayout({
    super.key,
    required this.tileIds,
    required this.buildTile,
  });

  final List<String> tileIds;
  final Widget Function(String id) buildTile;

  @override
  Widget build(BuildContext context) {
    return HomeTabletLayout(
      tileIds: tileIds,
      buildTile: buildTile,
    );
  }
}