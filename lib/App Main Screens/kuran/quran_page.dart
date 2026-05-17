import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/App%20Main%20Screens/App%20Main%20Screens%20Components/custom_app_bar.dart';
import 'package:islamic_app/App%20Main%20Screens/kuran/quran_parts_page.dart';
import 'package:islamic_app/Common%20Components/SquareLogo.dart';

import 'index.dart';

class QuranPage extends StatelessWidget {
  const QuranPage({super.key});

  void _openPageWithoutAnimation(BuildContext context, Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final pageBackground = theme.colorScheme.background;
    final cardColor = theme.colorScheme.primary;
    final buttonColor =
    isDark ? const Color(0xff171B26) : theme.colorScheme.secondary;
    final buttonTextColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              category: CustomAppBarCategory(text: 'القرآن'),
            ),

            SizedBox(height: 14.h),

            SquareLogo(
              category: SquareLogoCategory(
                image: 'assets/icons/QuRan.png',
              ),
            ),

            SizedBox(height: 14.h),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: Column(
                  children: [
                    _MainQuranCard(
                      color: cardColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _CardTitle(title: 'ورد اليوم'),
                          SizedBox(height: 8.h),
                          _SmallInfoButton(
                            title: 'سورة الكهف',
                            subtitle: 'من الآية (١) إلى الآية (٢٠)',
                            backgroundColor: buttonColor,
                            textColor: buttonTextColor,
                            icon: Icons.check_circle_outline,
                            onTap: () {},
                          ),

                          SizedBox(height: 14.h),

                          _CardTitle(title: 'تتبع قراءتك'),
                          SizedBox(height: 8.h),
                          _SmallInfoButton(
                            title: 'سورة البقرة',
                            subtitle: 'من الآية (٢٠) إلى الآية (٤٠)',
                            backgroundColor: buttonColor,
                            textColor: buttonTextColor,
                            icon: Icons.arrow_back_ios_new_rounded,
                            onTap: () {},
                          ),

                          SizedBox(height: 12.h),

                          _LargeButton(
                            title: 'إنشاء ختمة',
                            backgroundColor: buttonColor,
                            textColor: buttonTextColor,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24.h),

                    _MainQuranCard(
                      color: cardColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _CardTitle(title: 'القرآن'),
                          SizedBox(height: 10.h),

                          _LargeButton(
                            title: 'الأجزاء',
                            backgroundColor: buttonColor,
                            textColor: buttonTextColor,
                            onTap: () {
                              _openPageWithoutAnimation(
                                context,
                                const QuranPartsPage(),
                              );
                            },
                          ),

                          SizedBox(height: 8.h),

                          _LargeButton(
                            title: 'الفهرس',
                            backgroundColor: buttonColor,
                            textColor: buttonTextColor,
                            onTap: () {
                              _openPageWithoutAnimation(
                                context,
                                const IndexPage(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 18.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainQuranCard extends StatelessWidget {
  final Color color;
  final Widget child;

  const _MainQuranCard({
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  final String title;

  const _CardTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textDirection: TextDirection.rtl,
      style: TextStyle(
        fontFamily: 'cairo',
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }
}

class _SmallInfoButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;
  final VoidCallback onTap;

  const _SmallInfoButton({
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: Container(
          height: 34.h,
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Text(
                title,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  subtitle,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'cairo',
                    fontSize: 7.5.sp,
                    color: textColor.withOpacity(0.55),
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              Icon(
                icon,
                size: 13.sp,
                color: textColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LargeButton extends StatelessWidget {
  final String title;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;

  const _LargeButton({
    required this.title,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          height: 34.h,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 12.sp,
                color: textColor,
              ),
              SizedBox(width: 8.w),
              Text(
                title,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}