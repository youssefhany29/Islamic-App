import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

class IconsMainWidget extends StatelessWidget {
  const IconsMainWidget({
    super.key,
    required this.category,
    required this.onTap,
  });

  final Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);

    final bool isPhone = screenSize.width < 600;
    final bool isFoldLandscape =
        screenSize.width >= 600 && screenSize.shortestSide < 600;
    final bool isTablet = screenSize.shortestSide >= 600;

    final double borderRadius = isPhone
        ? 14.r
        : isFoldLandscape
        ? 12
        : 14;

    final double tileHeight = isPhone
        ? 74.h
        : isFoldLandscape
        ? 58
        : 68;

    final double horizontalPadding = isPhone
        ? 5.w
        : isFoldLandscape
        ? 5
        : 7;

    final double verticalPadding = isPhone
        ? 6.h
        : isFoldLandscape
        ? 5
        : 6;

    final double maxIconSize = isPhone
        ? 34.sp
        : isFoldLandscape
        ? 23
        : 29;

    final double minIconSize = isPhone
        ? 26.0
        : isFoldLandscape
        ? 18.0
        : 22.0;

    final double iconTextSpacing = isPhone
        ? 4.h
        : isFoldLandscape
        ? 3
        : 4;

    final TextStyle? baseTextStyle = Theme.of(context).textTheme.labelLarge;

    final TextStyle? adaptiveTextStyle = isPhone
        ? baseTextStyle
        : baseTextStyle?.copyWith(
      fontSize: isFoldLandscape ? 10.5 : 12,
      height: 1.15,
    );

    return Material(
      color: const Color(0xff171B26),
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: () {
          AppHaptics.tap(context);
          onTap();
        },
        child: SizedBox(
          height: tileHeight,
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double iconSize = math.min(
                  maxIconSize,
                  math.max(minIconSize, constraints.maxHeight * 0.44),
                );

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Flexible(
                      flex: 6,
                      child: Center(
                        child: Image.asset(
                          category.image,
                          width: iconSize,
                          height: iconSize,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    SizedBox(height: iconTextSpacing),

                    Flexible(
                      flex: 4,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            category.text,
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: adaptiveTextStyle,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
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