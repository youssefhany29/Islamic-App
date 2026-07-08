import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/shared/widgets/common_components/app_layout_constants.dart';

class PhoneQuranQuickAccessInfo {
  const PhoneQuranQuickAccessInfo({
    required this.wirdSubtitle,
    required this.lastReadSubtitle,
  });

  final String wirdSubtitle;
  final String lastReadSubtitle;

  factory PhoneQuranQuickAccessInfo.loading() {
    return const PhoneQuranQuickAccessInfo(
      wirdSubtitle: 'جاري تجهيز ورد اليوم...',
      lastReadSubtitle: 'جاري تجهيز آخر قراءة...',
    );
  }
}

class PhoneQuranQuickAccessStrip extends StatelessWidget {
  const PhoneQuranQuickAccessStrip({
    super.key,
    required this.infoFuture,
    required this.onOpenWird,
    required this.onOpenLastRead,
  });

  final Future<PhoneQuranQuickAccessInfo> infoFuture;
  final VoidCallback onOpenWird;
  final VoidCallback onOpenLastRead;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = colors.surface;
    final Color cardColor = isDark ? colors.secondary : Colors.white;

    return FutureBuilder<PhoneQuranQuickAccessInfo>(
      future: infoFuture,
      builder: (context, snapshot) {
        final info = snapshot.data ?? PhoneQuranQuickAccessInfo.loading();

        return Directionality(
          textDirection: TextDirection.rtl,
          child: SizedBox(
            width: AppLayoutConstants.mainCardWidth,
            child: Container(
              constraints: BoxConstraints(minHeight: 60.h),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(22.r),
                border: Border.all(
                  color: textColor.withOpacity(isDark ? 0.08 : 0.055),
                  width: 0.8.w,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.14 : 0.045),
                    blurRadius: 16.r,
                    offset: Offset(0, 7.h),
                  ),
                ],
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: _QuickAccessSegment(
                      title: 'ورد اليوم',
                      subtitle: info.wirdSubtitle,
                      icon: Icons.calendar_month_rounded,
                      textColor: textColor,
                      primaryColor: colors.primary,
                      onTap: onOpenWird,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Container(
                      width: 1.w,
                      height: 35.h,
                      color: textColor.withOpacity(0.10),
                    ),
                  ),
                  Expanded(
                    child: _QuickAccessSegment(
                      title: 'آخر قراءة',
                      subtitle: info.lastReadSubtitle,
                      icon: Icons.bookmark_border_rounded,
                      textColor: textColor,
                      primaryColor: colors.primary,
                      onTap: onOpenLastRead,
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

class _QuickAccessSegment extends StatelessWidget {
  const _QuickAccessSegment({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.textColor,
    required this.primaryColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color textColor;
  final Color primaryColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: 54.h),
            child: Row(
              textDirection: TextDirection.ltr,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 28.w,
                  height: 28.w,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 14.sp,
                    color: primaryColor,
                  ),
                ),
                SizedBox(width: 7.w),
                Expanded(
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            title,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption(context).copyWith(
                              color: textColor.withOpacity(0.62),
                              fontSize: 8.5.sp,
                              fontWeight: FontWeight.w500,
                              height: 1.05,
                            ),
                          ),
                        ),
                        SizedBox(height: 3.h),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            subtitle,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            maxLines: 2,
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                            textWidthBasis: TextWidthBasis.parent,
                            style: AppTextStyles.caption(context).copyWith(
                              color: textColor,
                              fontSize: 6.sp,
                              fontWeight: FontWeight.w700,
                              height: 1.18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
