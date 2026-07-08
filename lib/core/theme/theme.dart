import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
//224368FF
//041E3EFF
ThemeData lightMode = ThemeData(
    brightness: Brightness.light,
    canvasColor: Colors.white,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.light(
        background: Colors.white,
        primary: Color(0xff224368),
        secondary: Color(0xffDEE9EF),
        tertiary: Colors.white,
        outline: Color(0xffDEE9EF),
        surface: Colors.black),

    textTheme: TextTheme(
        headlineLarge: TextStyle(
            fontSize: 16.sp, color: Colors.black, fontFamily: 'cairo', fontWeight: FontWeight.w500,
        ),
        headlineMedium: TextStyle(
            fontSize: 16.sp, color: Colors.white, fontFamily: 'cairo', fontWeight: FontWeight.w500,
        ),
        headlineSmall: TextStyle(
            fontSize: 12.sp, color: Colors.white, fontFamily: 'cairo', fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
            fontSize: 12.sp, color: Colors.white, fontFamily: 'cairo', fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
            fontSize: 10.sp, color: Colors.black, fontFamily: 'cairo', fontWeight: FontWeight.w400,
        ),
        labelSmall: TextStyle(
            fontSize: 8.sp, color: Colors.white70, fontFamily: 'cairo', fontWeight: FontWeight.w700,
        ),
    ),
);

ThemeData darkMode = ThemeData(
    brightness: Brightness.dark,
    canvasColor: Color(0xff171B26),
    scaffoldBackgroundColor: Color(0xff171B26), // هنا لون الخلفية الداكن
    colorScheme: ColorScheme.dark(
        background: Color(0xff171B26),
        primary: Color(0xff005349),
        secondary: Color(0xff171B26),
        tertiary: Color(0xff171B26),
        outline: Colors.white,
        surface: Colors.white),

    textTheme: TextTheme(
        headlineLarge: TextStyle(
            fontSize: 16.sp, color: Colors.white, fontFamily: 'cairo', fontWeight: FontWeight.w500,
        ),
        headlineMedium: TextStyle(
            fontSize: 16.sp, color: Colors.white, fontFamily: 'cairo', fontWeight: FontWeight.w500,
        ),
        headlineSmall: TextStyle(
            fontSize: 12.sp, color: Colors.white, fontFamily: 'cairo', fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          fontSize: 12.sp, color: Colors.white, fontFamily: 'cairo', fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
            fontSize: 10.sp, color: Colors.black, fontFamily: 'cairo', fontWeight: FontWeight.bold,
        ),
        labelSmall: TextStyle(
            fontSize: 8.sp, color: Colors.white70, fontFamily: 'cairo', fontWeight: FontWeight.w700,
        ),
    ),
);
