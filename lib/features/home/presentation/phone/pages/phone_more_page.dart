import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/azkar/zekr_page.dart';
import 'package:islamic_app/features/hadith/ahadeth_page.dart';
import 'package:islamic_app/features/recitations/pages/recitations_home_page.dart';

import '../../../../../shared/widgets/app_main_components/custom_app_bar.dart';
import '../../../../islamic_events/pages/islamic_events_page.dart';
import '../widgets/phone_home_bottom_navigation.dart';
import '../widgets/phone_tab_scaffold.dart';

class PhoneMorePage extends StatelessWidget {
  const PhoneMorePage({super.key});

  void _openPage(BuildContext context, Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            insetPadding: EdgeInsets.symmetric(horizontal: 25.w),
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 16.h),
              decoration: BoxDecoration(
                color: isDark ? colors.secondary : Colors.white,
                borderRadius: BorderRadius.circular(22.r),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.06),
                  width: 0.8.w,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 50.w,
                      height: 50.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF2FF),
                        borderRadius: BorderRadius.circular(17.r),
                      ),
                      child: Text(
                        '🎙️',
                        style: TextStyle(fontSize: 27.sp, height: 1),
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    'البودكاست قريبًا',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: AppTextStyles.body(context).copyWith(
                      color: colors.surface,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'نعمل على تجهيز تجربة البودكاست لتكون متاحة قريبًا بإذن الله.',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: AppTextStyles.caption(context).copyWith(
                      color: colors.surface.withOpacity(0.62),
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 11.h),
                    ),
                    child: Text(
                      'تمام',
                      style: AppTextStyles.caption(context).copyWith(
                        color: Colors.white,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                      ),
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return PhoneTabScaffold(
      currentTab: PhoneHomeTab.more,
      backgroundColor: colors.background,
      appBar: const CustomAppBar(
        showBackButton: false,
        category: CustomAppBarCategory(text: 'المزيد'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 96.h),
          children: [
            _MoreTile(
              title: 'الأذكار',
              subtitle: 'أذكار الصباح والمساء والنوم',
              emoji: '🤲',
              iconBackgroundColor: const Color(0xFFFFF2D8),
              onTap: () => _openPage(context, const ZekrPage()),
            ),
            _MoreTile(
              title: 'الأحاديث',
              subtitle: 'تعلّم واحفظ الأحاديث',
              emoji: '📜',
              iconBackgroundColor: const Color(0xFFFFF0DD),
              onTap: () => _openPage(context, const Ahadethpage()),
            ),
            _MoreTile(
              title: 'التلاوات',
              subtitle: 'استمع للقرآن بأصوات مختلفة',
              emoji: '🎧',
              iconBackgroundColor: const Color(0xFFE5FAEF),
              onTap: () => _openPage(context, const RecitationsHomePage()),
            ),
            _MoreTile(
              title: 'المناسبات الإسلامية',
              subtitle: 'الأيام الفاضلة والتذكيرات',
              emoji: '🕌',
              iconBackgroundColor: const Color(0xFFFFEEDF),
              onTap: () => _openPage(
                context,
                const IslamicEventsPage(),
              ),
            ),
            _MoreTile(
              title: 'البودكاست',
              subtitle: 'استمع لمحتوى نافع أثناء يومك',
              emoji: '🎙️',
              iconBackgroundColor: const Color(0xFFEAF2FF),
              isComingSoon: true,
              onTap: () => _showComingSoon(context),
            ),
          ].map((child) {
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: child,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.iconBackgroundColor,
    required this.onTap,
    this.isComingSoon = false,
  });

  final String title;
  final String subtitle;
  final String emoji;
  final Color iconBackgroundColor;
  final VoidCallback onTap;
  final bool isComingSoon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(18.r),
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: 60.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
        decoration: BoxDecoration(
          color: isDark ? colors.secondary : Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.06),
            width: 0.8.w,
          ),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 45.w,
              height: 45.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark
                    ? iconBackgroundColor.withOpacity(0.16)
                    : iconBackgroundColor,
                borderRadius: BorderRadius.circular(17.r),
              ),
              child: Text(
                emoji,
                style: TextStyle(fontSize: 20.sp, height: 1),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    textDirection: TextDirection.rtl,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body(context).copyWith(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            color: colors.surface,
                            height: 1.1,
                          ),
                        ),
                      ),
                      if (isComingSoon) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECE8FF),
                            borderRadius: BorderRadius.circular(999.r),
                          ),
                          child: Text(
                            'قريبًا',
                            textDirection: TextDirection.rtl,
                            style: AppTextStyles.caption(context).copyWith(
                              color: const Color(0xFF6C63D8),
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    textDirection: TextDirection.rtl,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          subtitle,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption(context).copyWith(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w600,
                            color: colors.surface.withOpacity(0.58),
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: colors.primary,
              size: 14.sp,
            ),
          ],
        ),
      ),
    );
  }
}
