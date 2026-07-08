import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/shared/widgets/common_components/app_layout_constants.dart';

class QuranPhoneHeroInfo {
  const QuranPhoneHeroInfo({
    required this.readPages,
  });

  final int readPages;
}

class PhoneQuranHeroCard extends StatelessWidget {
  const PhoneQuranHeroCard({
    super.key,
    required this.heroInfoFuture,
    required this.onOpenMushaf,
    required this.onOpenLastRead,
  });

  final Future<QuranPhoneHeroInfo> heroInfoFuture;
  final VoidCallback onOpenMushaf;
  final VoidCallback onOpenLastRead;

  static const int _mushafPagesCount = 604;

  @override
  Widget build(BuildContext context) {
    final bool isLargeScreen = MediaQuery.sizeOf(context).width >= 600;
    final colors = Theme.of(context).colorScheme;

    return FutureBuilder<QuranPhoneHeroInfo>(
      future: heroInfoFuture,
      builder: (context, snapshot) {
        final int readPages = (snapshot.data?.readPages ?? 0)
            .clamp(0, _mushafPagesCount)
            .toInt();

        final double progress =
        (readPages / _mushafPagesCount).clamp(0.0, 1.0).toDouble();
        final int progressPercent = (progress * 100).round();

        final String subtitle = snapshot.connectionState == ConnectionState.waiting
            ? 'جاري تجهيز بيانات قراءتك...'
            : readPages == 0
            ? 'افتح المصحف وسجل أول صفحة تقرأها'
            : 'قرأت $readPages صفحة حتى الآن';

        return SizedBox(
          width: isLargeScreen ? double.infinity : AppLayoutConstants.mainCardWidth,
          height: isLargeScreen ? 220 : 170.h,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22.r),
            child: Container(
              decoration: BoxDecoration(
                color: colors.primary,
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withOpacity(0.20),
                    blurRadius: 18.r,
                    offset: Offset(0, 9.h),
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/quraan/quran_background.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.centerLeft,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [
                              colors.primary,
                              colors.primary.withOpacity(0.90),
                              const Color(0xFF061827),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // نفس Stack/Gradient بتاع هيرو الهوم: اللون الأزرق يظهر ناحية النص من النص لليمين.
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.black.withOpacity(0.00),
                            colors.primary.withOpacity(0.20),
                            colors.primary.withOpacity(0.82),
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.04),
                            Colors.black.withOpacity(0.10),
                            Colors.black.withOpacity(0.28),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.fromLTRB(14.w, 13.h, 14.w, 12.h),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'تابع تلاوتك اليوم',
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.rtl,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.headline(context).copyWith(
                                    color: Colors.white,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w800,
                                    height: 1.02,
                                  ),
                                ),
                                SizedBox(height: 3.h),
                                Text(
                                  'كل صفحة تقرّبك من رضا الله',
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.rtl,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.caption(context).copyWith(
                                    color: Colors.white.withOpacity(0.72),
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w500,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        Positioned(
                          left: 0,
                          right: 0,
                          top: 68.h,
                          child: Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              Expanded(
                                child: _QuranHeroActionButton(
                                  title: 'فتح المصحف',
                                  icon: Icons.menu_book_rounded,
                                  isPrimary: true,
                                  onTap: onOpenMushaf,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: _QuranHeroActionButton(
                                  title: 'آخر موضع',
                                  icon: Icons.history_rounded,
                                  isPrimary: false,
                                  onTap: onOpenLastRead,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: _QuranHeroProgressStrip(
                            title: 'تقدم قراءتك',
                            subtitle: subtitle,
                            percent: progressPercent,
                            progress: progress,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuranHeroActionButton extends StatelessWidget {
  const _QuranHeroActionButton({
    required this.title,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color foreground = isPrimary ? const Color(0xFF0B2442) : Colors.white;

    return Material(
      color: isPrimary
          ? Colors.white.withOpacity(0.94)
          : Colors.white.withOpacity(0.12),
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Container(
          height: 34.h,
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isPrimary
                  ? Colors.white.withOpacity(0.30)
                  : Colors.white.withOpacity(0.58),
              width: 0.9.w,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                icon,
                size: 13.5.sp,
                color: foreground,
              ),
              SizedBox(width: 5.w),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    color: foreground,
                    fontSize: 8.4.sp,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuranHeroProgressStrip extends StatelessWidget {
  const _QuranHeroProgressStrip({
    required this.title,
    required this.subtitle,
    required this.percent,
    required this.progress,
  });

  final String title;
  final String subtitle;
  final int percent;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 39.h,
      padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.13),
        borderRadius: BorderRadius.circular(17.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double percentWidth = 32.w;
          final double gapAfterPercent = 6.w;
          final double gapBeforeText = 7.w;
          final double infoWidth = (constraints.maxWidth * 0.31)
              .clamp(88.w, 102.w)
              .toDouble();

          return Row(
            textDirection: TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: percentWidth,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$percent%',
                    textAlign: TextAlign.left,
                    textDirection: TextDirection.ltr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body(context).copyWith(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
              SizedBox(width: gapAfterPercent),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99.r),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0).toDouble(),
                    minHeight: 4.h,
                    backgroundColor: Colors.white.withOpacity(0.18),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
              SizedBox(width: gapBeforeText),
              SizedBox(
                width: infoWidth,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption(context).copyWith(
                          color: Colors.white,
                          fontSize: 8.sp,
                          fontWeight: FontWeight.w700,
                          height: 1.05,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption(context).copyWith(
                          color: Colors.white.withOpacity(0.60),
                          fontSize: 6.2.sp,
                          fontWeight: FontWeight.w400,
                          height: 1.05,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
