import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/shared/widgets/common_components/no_animation_page_route.dart';
import 'intro_page_2.dart';

class IntroPage1 extends StatelessWidget {
  const IntroPage1({super.key});

  bool _isLargeScreen(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    return size.shortestSide >= 600 ||
        (size.width >= 700 && size.height >= 500);
  }

  @override
  Widget build(BuildContext context) {
    final bool large = _isLargeScreen(context);
    final Size screen = MediaQuery.sizeOf(context);
    final ThemeData theme = Theme.of(context);

    final double horizontalPadding = large ? 56 : 24.w;
    final double maxContentWidth = large ? 760 : double.infinity;

    final double animationSize = large
        ? (screen.shortestSide * 0.34).clamp(230.0, 330.0)
        : (screen.height * 0.32).clamp(230.0, 330.0);

    final double buttonWidth = large ? 560 : 272.w;
    final double buttonHeight = large ? 52 : 40.h;
    final double topSpace = large ? 26 : 34.h;
    final double contentGap = large ? 16 : 10.h;
    final double animationGap = large ? 22 : 12.h;

    return SafeArea(
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        body: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: large ? 22 : 14.h,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxContentWidth,
                minHeight: large ? screen.height - 70 : screen.height - 40,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: topSpace),
                  Text(
                    'ديني في جيبي',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.display(context).copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.surface,
                      height: 1.15,
                      letterSpacing: 0,
                    ),
                  ),
                  SizedBox(height: contentGap),
                  Text(
                    'رفيقك اليومي للصلاة، القرآن، الأذكار، والحفظ',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    maxLines: large ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headline(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.surface.withOpacity(0.82),
                      height: 1.45,
                      letterSpacing: 0,
                    ),
                  ),
                  SizedBox(height: animationGap),
                  SizedBox(
                    width: animationSize,
                    height: animationSize,
                    child: Lottie.asset(
                      'assets/animation/Animation - 1748091415849.json',
                      repeat: true,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: large ? 34 : 20.h),
                  SizedBox(
                    width: buttonWidth,
                    height: buttonHeight,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            large ? 16 : 12.r,
                          ),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          NoAnimationPageRoute(page: const IntroPage2()),
                        );
                      },
                      child: Text(
                        'التالي',
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: AppTextStyles.caption(context).copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: large ? 18 : 14.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
