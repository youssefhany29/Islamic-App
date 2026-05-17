import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SquareLogo extends StatelessWidget {
  const SquareLogo({
    super.key, required this.category
  });

  final SquareLogoCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60.w,
      height: 60.h,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        image: DecorationImage(
            image: AssetImage(category.image),
            fit: BoxFit.contain
        ),
      ),
    );
  }
}

class SquareLogoCategory {
  final String image;

  const SquareLogoCategory({
    required this.image
});
}