import 'package:flutter/material.dart';

abstract class TabletDashboardCardBase extends StatelessWidget {
  const TabletDashboardCardBase({super.key});

  String get title;
  String get subtitle;

  Widget buildCardContent(BuildContext context);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);

    final bool isFoldLandscape =
        size.width >= 600 && size.shortestSide < 600;

    final double horizontalPadding = isFoldLandscape ? 16 : 22;
    final double verticalPadding = isFoldLandscape ? 14 : 20;
    final double radius = isFoldLandscape ? 20 : 24;
    final double titleSize = isFoldLandscape ? 18 : 23;
    final double subtitleSize = isFoldLandscape ? 12 : 15;
    final double headerGap = isFoldLandscape ? 14 : 18;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              width: double.infinity,
              child: Text(
                title,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: titleSize,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.15,
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: Text(
                subtitle,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: subtitleSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.72),
                  height: 1.25,
                ),
              ),
            ),
            SizedBox(height: headerGap),
            Expanded(
              child: buildCardContent(context),
            ),
          ],
        ),
      ),
    );
  }
}