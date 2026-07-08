import 'package:flutter/material.dart';

import 'adaptive_constraints.dart';

class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    required this.body,
    this.backgroundColor,
    this.appBar,
    this.endDrawer,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
  });

  final Widget body;
  final Color? backgroundColor;
  final PreferredSizeWidget? appBar;
  final Widget? endDrawer;
  final bool extendBody;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      endDrawer: endDrawer,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AdaptiveConstraints.centeredContentWidth(context),
          ),
          child: body,
        ),
      ),
    );
  }
}
