import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../MainPage/main_page.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key, required this.category});

  final CustomAppBarCategory category;

  @override
  // ارتفاع الـ AppBar القياسي
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.background,
      leading: IconButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => MainPage(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        },
        icon: Icon(Icons.arrow_back_ios_new_outlined),
      ),
      title: Text(
        category.text,
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          fontFamily: 'cairo',
        ),
      ),
      elevation: 0, // لو عايز تخفي الظل
    );
  }
}

class CustomAppBarCategory {
  final String text;
  const CustomAppBarCategory({required this.text});
}
