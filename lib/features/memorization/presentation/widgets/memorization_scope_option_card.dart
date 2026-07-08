import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/features/memorization/data/models/memorization_scope_option.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class MemorizationScopeOptionCard extends StatelessWidget {
  const MemorizationScopeOptionCard({
    super.key,
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final MemorizationScopeOption option;
  final bool isSelected;
  final VoidCallback onTap;

  IconData get _icon {
    switch (option.type) {
      case MemorizationScopeType.surah:
        return Icons.menu_book_rounded;
      case MemorizationScopeType.juz:
        return Icons.library_books_rounded;
      case MemorizationScopeType.hizb:
        return Icons.chrome_reader_mode_rounded;
      case MemorizationScopeType.pages:
        return Icons.article_rounded;
      case MemorizationScopeType.ayahs:
        return Icons.format_list_numbered_rtl_rounded;
      case MemorizationScopeType.wholeQuran:
        return Icons.auto_stories_rounded;
      case MemorizationScopeType.knownMemorized:
        return Icons.verified_rounded;
      case MemorizationScopeType.weakSpots:
        return Icons.flag_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color cardColor = isSelected
        ? theme.colorScheme.primary.withOpacity(0.075)
        : theme.colorScheme.secondary;
    final Color primaryColor = theme.colorScheme.primary;
    final Color textColor = theme.colorScheme.surface;
    final Color subTextColor = theme.colorScheme.surface.withOpacity(0.62);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22.r),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: double.infinity,
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(
              color: isSelected
                  ? primaryColor.withOpacity(0.85)
                  : theme.colorScheme.outline.withOpacity(0.20),
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 46.w,
                height: 46.w,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(isSelected ? 0.16 : 0.08),
                  borderRadius: BorderRadius.circular(17.r),
                ),
                child: Icon(
                  _icon,
                  color: primaryColor,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 11.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      textDirection: TextDirection.rtl,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            option.title,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
                              color: textColor,
                              height: 1.28
),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 20.w,
                          height: 20.w,
                          margin: EdgeInsets.only(top: 1.h),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? primaryColor : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? primaryColor
                                  : theme.colorScheme.outline.withOpacity(0.45),
                              width: 1.2,
                            ),
                          ),
                          child: isSelected
                              ? Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 14.sp,
                          )
                              : null,
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      option.subtitle,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w600,
                        color: subTextColor,
                        height: 1.45
),
                    ),
                    SizedBox(height: 9.h),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 9.w,
                          vertical: 4.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                        child: Text(
                          option.badge,
                          textDirection: TextDirection.rtl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
                            color: primaryColor,
                            height: 1
),
                        ),
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
  }
}
