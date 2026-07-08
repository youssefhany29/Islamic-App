import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/quran/phone/tools/quran_tool_tile.dart';
import 'package:islamic_app/shared/widgets/common_components/app_layout_constants.dart';

class PhoneQuranToolsSection extends StatelessWidget {
  const PhoneQuranToolsSection({
    super.key,
    required this.onOpenParts,
    required this.onOpenBookmarks,
    required this.onOpenKhatmas,
    required this.onOpenIndex,
    this.onOpenGeometryProbe,
    this.onOpenSvgReaderExperiment,
  });

  final VoidCallback onOpenParts;
  final VoidCallback onOpenBookmarks;
  final VoidCallback onOpenKhatmas;
  final VoidCallback onOpenIndex;
  final VoidCallback? onOpenGeometryProbe;
  final VoidCallback? onOpenSvgReaderExperiment;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = colors.surface;
    final Color cardColor = isDark ? colors.secondary : Colors.white;
    final Color borderColor = textColor.withOpacity(isDark ? 0.08 : 0.06);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: AppLayoutConstants.mainCardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _QuranToolsHeader(
              title: 'أدوات القرآن',
              subtitle: 'كل ما تحتاجه في مكان واحد',
              textColor: textColor,
              primaryColor: colors.primary,
            ),
            SizedBox(height: 12.h),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: QuranToolTile(
                    title: 'العلامات المحفوظة',
                    icon: Icons.bookmark_rounded,
                    textColor: textColor,
                    primaryColor: colors.primary,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    onTap: onOpenBookmarks,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: QuranToolTile(
                    title: 'الأجزاء',
                    icon: Icons.format_list_bulleted_rounded,
                    textColor: textColor,
                    primaryColor: colors.primary,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    onTap: onOpenParts,
                  ),
                ),
              ],
            ),
            SizedBox(height: 9.h),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: QuranToolTile(
                    title: 'الفهرس',
                    icon: Icons.menu_book_outlined,
                    textColor: textColor,
                    primaryColor: colors.primary,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    onTap: onOpenIndex,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: QuranToolTile(
                    title: 'الختمات',
                    icon: Icons.sync_rounded,
                    textColor: textColor,
                    primaryColor: colors.primary,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    onTap: onOpenKhatmas,
                  ),
                ),
              ],
            ),
            if (onOpenGeometryProbe != null) ...[
              SizedBox(height: 9.h),
              QuranToolTile(
                title: 'QPC geometry probe',
                icon: Icons.bug_report_rounded,
                textColor: textColor,
                primaryColor: colors.primary,
                cardColor: cardColor,
                borderColor: borderColor,
                onTap: onOpenGeometryProbe!,
              ),
            ],
            if (onOpenSvgReaderExperiment != null) ...[
              SizedBox(height: 9.h),
              QuranToolTile(
                title: 'Hybrid SVG Quran Reader Experiment',
                icon: Icons.image_search_rounded,
                textColor: textColor,
                primaryColor: colors.primary,
                cardColor: cardColor,
                borderColor: borderColor,
                onTap: onOpenSvgReaderExperiment!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuranToolsHeader extends StatelessWidget {
  const _QuranToolsHeader({
    required this.title,
    required this.subtitle,
    required this.textColor,
    required this.primaryColor,
  });

  final String title;
  final String subtitle;
  final Color textColor;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 38.w,
          height: 38.w,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.work_rounded, size: 18.sp, color: primaryColor),
        ),
        SizedBox(width: 9.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body(context).copyWith(
                  color: textColor,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                subtitle,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  color: textColor.withOpacity(0.56),
                  fontSize: 8.6.sp,
                  fontWeight: FontWeight.w500,
                  height: 1.05,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
