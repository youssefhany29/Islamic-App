import 'package:flutter/material.dart';
import 'package:islamic_app/features/hadith/ahadeth_page.dart';
import 'package:islamic_app/features/islamic_events/pages/islamic_events_page.dart';
import 'package:islamic_app/features/night_pray/night_pray_page.dart';
import 'package:islamic_app/features/prayer/pray_page.dart';
import 'package:islamic_app/features/azkar/zekr_page.dart';
import 'package:islamic_app/features/quran/quran_page.dart';
import 'package:islamic_app/core/adaptive/adaptive_side_navigation.dart';

List<AdaptiveNavItem> homeLargeScreenNavigationItems(
    BuildContext context, {
      VoidCallback? onHomeTap,
      VoidCallback? onSettingsTap,
    }) {
  return [
    AdaptiveNavItem(
      id: 'home',
      label: 'الرئيسية',
      icon: Icons.home_outlined,
      onTap: onHomeTap ?? () {},
    ),
    AdaptiveNavItem(
      id: 'azkar',
      label: 'الأذكار',
      icon: Icons.wb_sunny_outlined,
      onTap: () => _push(context, const ZekrPage()),
    ),
    AdaptiveNavItem(
      id: 'prayer',
      label: 'مواقيت الصلاة',
      icon: Icons.access_time_outlined,
      onTap: () => _push(context, const PrayPage()),
    ),
    AdaptiveNavItem(
      id: 'quran',
      label: 'القرآن',
      icon: Icons.menu_book_outlined,
      onTap: () => _push(context, const QuranPage()),
    ),
    AdaptiveNavItem(
      id: 'night_prayer',
      label: 'قيام الليل',
      icon: Icons.nightlight_round,
      onTap: () => _push(context, const NightPrayPage()),
    ),
    AdaptiveNavItem(
      id: 'hadith',
      label: 'الأحاديث',
      icon: Icons.library_books_outlined,
      onTap: () => _push(context, const Ahadethpage()),
    ),
    AdaptiveNavItem(
      id: 'events',
      label: 'المناسبات',
      icon: Icons.calendar_month_outlined,
      onTap: () => _push(context, const IslamicEventsPage()),
    ),
    if (onSettingsTap != null)
      AdaptiveNavItem(
        id: 'settings',
        label: 'الإعدادات',
        icon: Icons.settings_outlined,
        onTap: onSettingsTap,
      ),
  ];
}

void _push(BuildContext context, Widget page) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => page,
    ),
  );
}
