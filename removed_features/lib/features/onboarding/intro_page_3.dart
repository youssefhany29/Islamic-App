import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/shared/widgets/common_components/no_animation_page_route.dart';
import 'package:islamic_app/features/home/main_page.dart';
import 'package:islamic_app/core/services/user_profile_service.dart';

class IntroPage3 extends StatelessWidget {
  final String userName;

  const IntroPage3({
    super.key,
    required this.userName,
  });

  bool _isLargeScreen(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    return size.shortestSide >= 600 || (size.width >= 700 && size.height >= 500);
  }

  Future<void> _completeIntroAndNavigate(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    await const UserProfileService().setUserName(userName);
    await prefs.setBool('seen_intro', true);

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      NoAnimationPageRoute(
        page: const MainPage(),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool large = _isLargeScreen(context);
    final Size screen = MediaQuery.sizeOf(context);
    final ThemeData theme = Theme.of(context);

    final double horizontalPadding = large ? 52 : 24.w;
    final double verticalPadding = large ? 22 : 18.h;
    final double maxContentWidth = large ? 760 : double.infinity;

    final double animationSize = large
        ? (screen.shortestSide * 0.30).clamp(220.0, 300.0)
        : (screen.height * 0.34).clamp(190.0, 310.0);

    return SafeArea(
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        body: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxContentWidth,
                minHeight: screen.height - (verticalPadding * 2) - 24,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'خطط ذكية لعبادتك',
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
                  SizedBox(height: large ? 8 : 8.h),
                  Text(
                    'التطبيق يساعدك تبني عادة ثابتة للصلاة، القرآن، الأذكار، وقيام الليل.',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headline(context).copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                      color: theme.colorScheme.surface.withOpacity(0.72),
                    ),
                  ),
                  SizedBox(height: large ? 18 : 12.h),
                  SizedBox(
                    width: animationSize,
                    height: animationSize,
                    child: Lottie.asset(
                      'assets/animation/smart_plan.json',
                      repeat: true,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: large ? 18 : 12.h),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: large ? 18 : 12.w,
                        vertical: large ? 16 : 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(large ? 22 : 18.r),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.16),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: large
                          ? Row(
                        textDirection: TextDirection.rtl,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Expanded(
                            child: _FeatureRow(
                              icon: Icons.access_time_rounded,
                              title: 'تنظيم يومك',
                              subtitle: 'تابع الصلاة والورد اليومي بدون زحمة.',
                            ),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: _FeatureRow(
                              icon: Icons.auto_graph_rounded,
                              title: 'تقدم واضح',
                              subtitle: 'اعرف إنجازك اليومي وأيامك المتتالية بسهولة.',
                            ),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: _FeatureRow(
                              icon: Icons.psychology_alt_rounded,
                              title: 'خطط قادمة',
                              subtitle: 'خطط للحفظ والمراجعة والختمة بطريقة أذكى بإذن الله.',
                            ),
                          ),
                        ],
                      )
                          : Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const _FeatureRow(
                            icon: Icons.access_time_rounded,
                            title: 'تنظيم يومك',
                            subtitle: 'تابع الصلاة والورد اليومي بدون زحمة.',
                          ),
                          SizedBox(height: 10.h),
                          const _FeatureRow(
                            icon: Icons.auto_graph_rounded,
                            title: 'تقدم واضح',
                            subtitle: 'اعرف إنجازك اليومي وأيامك المتتالية بسهولة.',
                          ),
                          SizedBox(height: 10.h),
                          const _FeatureRow(
                            icon: Icons.psychology_alt_rounded,
                            title: 'خطط قادمة',
                            subtitle:
                            'خطط للحفظ والمراجعة والختمة بطريقة أذكى بإذن الله.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: large ? 22 : 14.h),
                  SizedBox(
                    width: double.infinity,
                    height: large ? 52 : 42.h,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(large ? 16 : 12.r),
                        ),
                      ),
                      onPressed: () => _completeIntroAndNavigate(context),
                      child: Text(
                        'ابدأ الآن',
                        style: AppTextStyles.caption(context).copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  bool _isLargeScreen(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    return size.shortestSide >= 600 || (size.width >= 700 && size.height >= 500);
  }

  @override
  Widget build(BuildContext context) {
    final bool large = _isLargeScreen(context);

    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: large ? 40 : 34.w,
          height: large ? 40 : 34.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xff171B26),
            borderRadius: BorderRadius.circular(large ? 14 : 12.r),
          ),
          child: Icon(
            icon,
            color: const Color(0xff21C58E),
            size: large ? 21 : 18.sp,
          ),
        ),
        SizedBox(width: large ? 10 : 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                title,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.25,
                ),
              ),
              SizedBox(height: large ? 3 : 2.h),
              Text(
                subtitle,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                maxLines: large ? 3 : 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                  color: Colors.white.withOpacity(0.72),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
