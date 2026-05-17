import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_provider.dart';

class AppCustomBar extends StatelessWidget {
  const AppCustomBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {

    final themeProvider = Provider.of<ThemeProvider>(context);

    return Padding(
      padding: const EdgeInsets.only(right: 20.0, left: 20,top: 42),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
            icon: Image.asset(
              themeProvider.themeData.brightness == Brightness.dark
              ? 'assets/icons/sun.png'
              : 'assets/icons/moon.png',
              width: 20.w,
              height: 20.h,
            ),
          ),
          Text(
            'ديني في جيبي',
            style: TextStyle(
              fontSize: 18.sp,
              fontFamily: 'cairo',
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Image.asset(
              themeProvider.themeData.brightness == Brightness.dark
              ? 'assets/icons/menuWhite.png'
              : 'assets/icons/menu (1).png',
              width: 20.w,
              height: 20.h,
            ),
          )
        ],
      ),
    );
  }
}
