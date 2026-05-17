import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.category,
    this.showBackButton = true,
  });

  final CustomAppBarCategory category;
  final bool showBackButton;

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  void _goBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.background,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
        onPressed: () => _goBack(context),
        icon: Icon(
          Icons.arrow_back_ios_new_outlined,
          color: Theme.of(context).iconTheme.color,
        ),
      )
          : null,
      title: Text(
        category.text,
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          fontFamily: 'cairo',
          color: Theme.of(context).textTheme.headlineLarge?.color,
        ),
      ),
    );
  }
}

class CustomAppBarCategory {
  final String text;

  const CustomAppBarCategory({
    required this.text,
  });
}