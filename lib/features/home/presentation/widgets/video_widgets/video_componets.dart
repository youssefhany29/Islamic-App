import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class VideoComponents extends StatelessWidget {
  const VideoComponents({
    super.key,
    required this.onTap,
    required this.category,
    this.width,
    this.height,
    this.imageWidth,
    this.imageHeight,
  });

  final VoidCallback onTap;
  final Category category;

  final double? width;
  final double? height;
  final double? imageWidth;
  final double? imageHeight;

  @override
  Widget build(BuildContext context) {
    final cardWidth = width ?? 128.w;
    final cardHeight = height ?? 90.h;
    final innerImageWidth = imageWidth ?? 100.w;
    final innerImageHeight = imageHeight ?? 72.h;

    return GestureDetector(
      onTap: () {
        AppHaptics.tap(context);
        onTap();
      },
      child: Container(
        width: cardWidth,
        height: cardHeight,
        padding: EdgeInsets.symmetric(vertical: 2.h),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.all(Radius.circular(16.r)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double safeImageWidth = innerImageWidth.clamp(40.w, constraints.maxWidth).toDouble();
            final double safeImageHeight = innerImageHeight.clamp(40.h, constraints.maxHeight).toDouble();

            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: safeImageHeight,
                  width: safeImageWidth,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(16.r)),
                    image: DecorationImage(
                      image: AssetImage(category.image),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Container(
                  height: safeImageHeight,
                  width: safeImageWidth,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.all(Radius.circular(16.r)),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      category.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption(context).copyWith(
color: Colors.white,
fontWeight: FontWeight.bold
),
                    ),
                  ),
                ),
              ],
            );
          },
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
    required this.text,
  });
}
