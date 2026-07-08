import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';

class TinyPrayerProgressCircle extends StatelessWidget {
  const TinyPrayerProgressCircle({
    super.key,
    required this.progress,
    required this.color,
    this.percent,
    this.large = false,
  });

  final double progress;
  final Color color;
  final int? percent;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final Color trackColor = Theme.of(context).colorScheme.surface.withOpacity(
      Theme.of(context).brightness == Brightness.dark ? 0.12 : 0.10,
    );

    final double size = large ? 42 : 36.w;
    final double strokeWidth = large ? 3.6 : 3.w;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0).toDouble(),
              strokeWidth: strokeWidth,
              strokeCap: StrokeCap.round,
              backgroundColor: trackColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          if (percent != null)
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$percent%',
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                maxLines: 1,
                style: AppTextStyles.caption(context).copyWith(
                  color: color,
                  fontSize: large ? 8.5 : 8.sp,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
