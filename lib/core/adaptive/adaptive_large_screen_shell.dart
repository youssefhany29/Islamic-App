import 'package:flutter/material.dart';

import 'adaptive_side_navigation.dart';

class AdaptiveLargeScreenShell extends StatelessWidget {
  const AdaptiveLargeScreenShell({
    super.key,
    required this.body,
    required this.navigationItems,
    required this.selectedNavigationId,
    required this.userName,
    required this.greetingMessage,
    required this.quickItems,
  });

  final Widget body;
  final List<AdaptiveNavItem> navigationItems;
  final String selectedNavigationId;
  final String userName;
  final String greetingMessage;
  final List<AdaptiveSideQuickItem> quickItems;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);

    final bool isVeryWide = size.width >= 1200;
    final double sideNavWidth = isVeryWide ? 300 : 260;

    final MediaQueryData currentMediaQuery = MediaQuery.of(context);

    return ColoredBox(
      color: adaptiveSidePanelColor(context),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdaptiveSideNavigation(
            width: sideNavWidth,
            items: navigationItems,
            selectedId: selectedNavigationId,
            userName: userName,
            greetingMessage: greetingMessage,
            quickItems: quickItems,
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
              child: ColoredBox(
                color: colors.background,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    isVeryWide ? 28 : 20,
                    0,
                    isVeryWide ? 28 : 20,
                    isVeryWide ? 28 : 20,
                  ),
                  child: Center(
                    child: MediaQuery(
                      data: currentMediaQuery.copyWith(
                        textScaler: TextScaler.linear(isVeryWide ? 0.88 : 0.84),
                      ),
                      child: body,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
