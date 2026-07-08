import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/shared/widgets/common_components/no_animation_page_route.dart';
import 'intro_page_3.dart';

class IntroPage2 extends StatefulWidget {
  const IntroPage2({super.key});

  @override
  State<IntroPage2> createState() => _IntroPage2State();
}

class _IntroPage2State extends State<IntroPage2> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();

  bool _isLargeScreen(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    return size.shortestSide >= 600 || (size.width >= 700 && size.height >= 500);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _goToSmartPlanPage() {
    Navigator.push(
      context,
      NoAnimationPageRoute(
        page: IntroPage3(
          userName: _nameController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool large = _isLargeScreen(context);
    final Size screen = MediaQuery.sizeOf(context);
    final ThemeData theme = Theme.of(context);

    final double horizontalPadding = large ? 52 : 24.w;
    final double verticalPadding = large ? 22 : 18.h;
    final double maxContentWidth = large ? 680 : double.infinity;

    final double animationSize = large
        ? (screen.shortestSide * 0.28).clamp(210.0, 280.0)
        : (screen.height * 0.32).clamp(180.0, 285.0);

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
                  SizedBox(height: large ? 8 : 8.h),
                  Text(
                    'خلينا نجهز تجربتك الشخصية',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headline(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.surface.withOpacity(0.72),
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: large ? 18 : 10.h),
                  SizedBox(
                    width: animationSize,
                    height: animationSize,
                    child: Lottie.asset(
                      'assets/animation/Animation - 1748091381430.json',
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'اسمك إيه؟',
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            style: AppTextStyles.caption(context).copyWith(
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: large ? 6 : 5.h),
                          Text(
                            'هنستخدمه في الصفحة الرئيسية عشان نحس إن التطبيق قريب منك.',
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption(context).copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.45,
                              color: Colors.white.withOpacity(0.78),
                            ),
                          ),
                          SizedBox(height: large ? 12 : 10.h),
                          TextField(
                            controller: _nameController,
                            focusNode: _nameFocusNode,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            maxLength: 24,
                            style: AppTextStyles.caption(context).copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: 'اكتب اسمك هنا',
                              hintTextDirection: TextDirection.rtl,
                              hintStyle: AppTextStyles.caption(context).copyWith(
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.48),
                              ),
                              filled: true,
                              fillColor: const Color(0xff171B26),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: large ? 16 : 12.w,
                                vertical: large ? 14 : 10.h,
                              ),
                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(large ? 16 : 14.r),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSubmitted: (_) => _goToSmartPlanPage(),
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
                      onPressed: _goToSmartPlanPage,
                      child: Text(
                        'التالي',
                        style: AppTextStyles.caption(context).copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: large ? 10 : 8.h),
                  TextButton(
                    onPressed: _goToSmartPlanPage,
                    child: Text(
                      'تخطي الاسم',
                      style: AppTextStyles.caption(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.surface.withOpacity(0.66),
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
