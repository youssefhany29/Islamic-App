import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class IconsMainWidget extends StatelessWidget {
  const IconsMainWidget({
    super.key, required this.category, required this.onTap
  });

  final Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 57.w,
        child: Column(
          children: [
            Container(
              height: 40.sp,
              width: 40.sp,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xff171B26),
                image: DecorationImage(image: AssetImage(category.image),
                ),
              ),
            ),
            Center(
              child: Text(
                 category.text,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Category {
  final String image;
  final String text;

  const Category({
    required this.image,
    required this.text
});

}