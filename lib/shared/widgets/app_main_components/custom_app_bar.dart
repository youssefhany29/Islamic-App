import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.category,
    this.subtitle,
    this.showBackButton = true,
    this.onBackPressed,
    this.trailing,
    this.reserveLeadingSpace = false,
  });

  final CustomAppBarCategory category;
  final String? subtitle;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Widget? trailing;

  /// استخدمها لما يكون عندك زر يمين ومش عايز سهم رجوع شمال،
  /// عشان العنوان يفضل في النص ومايتزقش بسبب زر اليمين.
  final bool reserveLeadingSpace;

  @override
  Size get preferredSize =>
      Size.fromHeight(subtitle == null ? kToolbarHeight : 62.h);

  void _goBack(BuildContext context) {
    if (onBackPressed != null) {
      onBackPressed!();
      return;
    }
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bool hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: AppBar(
        centerTitle: true,
        toolbarHeight: preferredSize.height,
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 56.w,
        leading: showBackButton
            ? IconButton(
                onPressed: () => _goBack(context),
                icon: Icon(
                  Icons.arrow_back_ios_new_outlined,
                  size: 18.sp,
                  color: theme.iconTheme.color,
                ),
              )
            : reserveLeadingSpace
            ? SizedBox(width: 56.w)
            : null,
        actions: trailing == null
            ? null
            : [
                Padding(
                  padding: EdgeInsetsDirectional.only(end: 16.w),
                  child: Center(child: trailing),
                ),
              ],
        titleSpacing: 0,
        title: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                category.text,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.headline(context).copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16.sp,
                  height: 1.05,
                  color: theme.textTheme.headlineLarge?.color,
                ),
              ),
              if (hasSubtitle) ...[
                SizedBox(height: 3.h),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    color: colors.surface.withOpacity(0.56),
                    fontSize: 8.2.sp,
                    fontWeight: FontWeight.w500,
                    height: 1.05,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class CustomAppBarCategory {
  final String text;

  const CustomAppBarCategory({required this.text});
}
