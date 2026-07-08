import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LiquidGlassTabHighlight extends StatelessWidget {
  const LiquidGlassTabHighlight({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 18,
          sigmaY: 18,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.22),
                Colors.white.withOpacity(0.13),
                Colors.white.withOpacity(0.07),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.22),
              width: 0.7,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 12.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
        ),
      ),
    );
  }
}