import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/home/presentation/phone/liquid/liquid_glass_tab_highlight.dart';

enum PhoneHomeTab {
  home,
  quran,
  prayer,
  memorization,
  more,
}

class PhoneHomeBottomNavigation extends StatelessWidget {
  const PhoneHomeBottomNavigation({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  final PhoneHomeTab currentTab;
  final ValueChanged<PhoneHomeTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: colors.primary.withOpacity(0.92),
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 16,
              sigmaY: 16,
            ),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.92),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 18.r,
                    offset: Offset(0, -6.h),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                left: false,
                right: false,
                bottom: true,
                minimum: EdgeInsets.zero,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 8.w,
                    right: 8.w,
                    top: 5.h,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final tabs = PhoneHomeTab.values;
                      final selectedIndex = tabs.indexOf(currentTab);
                      final itemWidth = constraints.maxWidth / tabs.length;

                      return SizedBox(
                        height: 44.h,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: (tabs.length - 1 - selectedIndex) * itemWidth,
                              top: 0,
                              bottom: 4.h,
                              width: itemWidth,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 3.w),
                                child: const LiquidGlassTabHighlight(),
                              ),
                            ),
                            Row(
                              textDirection: TextDirection.rtl,
                              children: tabs.map((tab) {
                                return Expanded(
                                  child: _PhoneHomeNavItem(
                                    tab: tab,
                                    selected: currentTab == tab,
                                    onTap: () => onTabSelected(tab),
                                  ),
                                );
                              }).toList(growable: false),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhoneHomeNavItem extends StatelessWidget {
  const _PhoneHomeNavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final PhoneHomeTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = Colors.white;
    final inactiveColor = Colors.white.withOpacity(0.62);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 2.w,
          vertical: 3.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _icon,
              size: selected ? 18.sp : 16.5.sp,
              color: selected ? activeColor : inactiveColor,
            ),
            SizedBox(height: 3.h),
            Text(
              _label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
                fontSize: 7.5.sp,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                color: selected ? activeColor : inactiveColor,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData get _icon {
    switch (tab) {
      case PhoneHomeTab.home:
        return Icons.home_rounded;
      case PhoneHomeTab.quran:
        return Icons.menu_book_rounded;
      case PhoneHomeTab.prayer:
        return Icons.access_time_rounded;
      case PhoneHomeTab.memorization:
        return Icons.psychology_alt_rounded;
      case PhoneHomeTab.more:
        return Icons.grid_view_rounded;
    }
  }

  String get _label {
    switch (tab) {
      case PhoneHomeTab.home:
        return 'الرئيسية';
      case PhoneHomeTab.quran:
        return 'القرآن';
      case PhoneHomeTab.prayer:
        return 'الصلاة';
      case PhoneHomeTab.memorization:
        return 'الحفظ';
      case PhoneHomeTab.more:
        return 'المزيد';
    }
  }
}