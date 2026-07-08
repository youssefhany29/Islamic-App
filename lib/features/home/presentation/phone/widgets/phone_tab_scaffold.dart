import 'package:flutter/material.dart';

import 'package:islamic_app/features/home/presentation/phone/pages/phone_more_page.dart';
import 'package:islamic_app/features/home/presentation/phone/widgets/phone_home_bottom_navigation.dart';
import 'package:islamic_app/features/memorization/my_lessons_home_page.dart';
import 'package:islamic_app/features/prayer/pray_page.dart';
import 'package:islamic_app/features/quran/quran_page.dart';

class PhoneTabScaffold extends StatelessWidget {
  const PhoneTabScaffold({
    super.key,
    required this.currentTab,
    required this.body,
    this.appBar,
    this.backgroundColor,
    this.extendBody = true,
    this.drawer,
    this.endDrawer,
  });

  final PhoneHomeTab currentTab;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;
  final bool extendBody;
  final Widget? drawer;
  final Widget? endDrawer;

  void _goToTab(BuildContext context, PhoneHomeTab tab) {
    if (tab == currentTab) return;

    if (tab == PhoneHomeTab.home) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    final Widget page;

    switch (tab) {
      case PhoneHomeTab.quran:
        page = const QuranPage();
        break;
      case PhoneHomeTab.prayer:
        page = const PrayPage();
        break;
      case PhoneHomeTab.memorization:
        page = const MyLessonsHomePage();
        break;
      case PhoneHomeTab.more:
        page = const PhoneMorePage();
        break;
      case PhoneHomeTab.home:
        page = const SizedBox.shrink();
        break;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      backgroundColor ?? Theme.of(context).colorScheme.background,
      appBar: appBar,
      drawer: drawer,
      endDrawer: endDrawer,
      extendBody: extendBody,
      body: body,
      bottomNavigationBar: PhoneHomeBottomNavigation(
        currentTab: currentTab,
        onTabSelected: (tab) => _goToTab(context, tab),
      ),
    );
  }
}
