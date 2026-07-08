import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_user_type.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class MemorizationUserTypeCard extends StatelessWidget {
  const MemorizationUserTypeCard({
    super.key,
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  final MemorizationUserType type;
  final bool isSelected;
  final VoidCallback onTap;

  IconData get _icon {
    switch (type) {
      case MemorizationUserType.beginner:
        return Icons.menu_book_rounded;
      case MemorizationUserType.returning:
        return Icons.restore_rounded;
      case MemorizationUserType.strong:
        return Icons.verified_rounded;
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
    final Color borderColor = isSelected
        ? primaryColor.withOpacity(0.85)
        : theme.colorScheme.outline.withOpacity(0.20);

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
              color: borderColor,
              width: isSelected ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(isSelected ? 0.10 : 0.035),
                blurRadius: isSelected ? 18 : 12,
                offset: Offset(0, isSelected ? 7.h : 4.h),
              ),
            ],
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 46.w,
                height: 46.w,
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor.withOpacity(0.16)
                      : primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(17.r),
                  border: Border.all(
                    color: isSelected
                        ? primaryColor.withOpacity(0.36)
                        : primaryColor.withOpacity(0.12),
                  ),
                ),
                child: Icon(
                  _icon,
                  color: primaryColor,
                  size: 25.sp,
                ),
              ),
              SizedBox(width: 11.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Expanded(
                          child: Text(
                            type.title,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
                              color: textColor,
                              height: 1.2
),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 20.w,
                          height: 20.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? primaryColor
                                : Colors.transparent,
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
                      type.subtitle,
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