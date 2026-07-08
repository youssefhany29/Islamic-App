import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:islamic_app/core/theme/theme_provider.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class AppCustomBar extends StatelessWidget {
  const AppCustomBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Padding(
      padding: EdgeInsets.only(
        right: 0.w,
        left: 0.w,
        top: 14.h,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(
              minWidth: 44.w,
              minHeight: 44.h,
            ),
            onPressed: () {
              Provider.of<ThemeProvider>(
                context,
                listen: false,
              ).toggleTheme();
            },
            icon: Image.asset(
              themeProvider.themeData.brightness == Brightness.dark
                  ? 'assets/icons/sun.png'
                  : 'assets/icons/moon.png',
              width: 22.w,
              height: 22.h,
            ),
          ),

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'رَفيقُ الْمُسْلِمِ',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body(context).copyWith(
fontWeight: FontWeight.w800
),
              ),
              SizedBox(height: 1.h),
              Text(
                'رفيقك اليومي للعبادة',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.58)
),
              ),
            ],
          ),

          Builder(
            builder: (drawerContext) {
              return IconButton(
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(
                  minWidth: 44.w,
                  minHeight: 44.h,
                ),
                onPressed: () {
                  Scaffold.of(drawerContext).openEndDrawer();
                },
                icon: Image.asset(
                  themeProvider.themeData.brightness == Brightness.dark
                      ? 'assets/icons/menuWhite.png'
                      : 'assets/icons/menu (1).png',
                  width: 22.w,
                  height: 22.h,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
