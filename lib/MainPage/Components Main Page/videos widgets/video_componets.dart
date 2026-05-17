import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class VideoComponents extends StatelessWidget {
  const VideoComponents({
    super.key,
    required this.onTap,
    required this.category,
  });

  final VoidCallback onTap;
  final Category category;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.all(Radius.circular(16))
        ),
        width: 128.w,
        height: 90.h,
        padding: EdgeInsets.symmetric(vertical: 2.h),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 72.h,
              width: 100.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                image: DecorationImage(
                  image: AssetImage(
                    category.image,
                  ),
                ),
              ),
            ),
            Container(
              height: 72.h,
              width: 100.w,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4), // لون داكن بشفافية
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
            Text(
              category.text,
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp),
            )
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
    required this.image, required this.text
  });

}
