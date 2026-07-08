import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/analytics/analytics_ui.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/analytics/memorization_analytics_data.dart';

class AnalyticsMasteryChartBlock extends StatelessWidget {
  const AnalyticsMasteryChartBlock({
    super.key,
    required this.period,
    required this.points,
    required this.labels,
  });

  final MemorizationAnalyticsPeriod period;
  final List<double> points;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(13.w, 13.h, 13.w, 14.h),
      decoration: AnalyticsDecorations.innerCard(context, radius: 18.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'تطور الإتقان',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(context).copyWith(
              color: AnalyticsThemeColors.textPrimary(context),
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          SizedBox(height: 13.h),
          SizedBox(
            height: 155.h,
            width: double.infinity,
            child: CustomPaint(
              painter: MasteryChartPainter(
                points: points,
                labels: labels,
                lineColor: AnalyticsColors.blue,
                gridColor: AnalyticsThemeColors.textSecondary(context, 0.10),
                textColor: AnalyticsThemeColors.textSecondary(context, 0.62),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MasteryChartPainter extends CustomPainter {
  const MasteryChartPainter({
    required this.points,
    required this.labels,
    required this.lineColor,
    required this.gridColor,
    required this.textColor,
  });

  final List<double> points;
  final List<String> labels;
  final Color lineColor;
  final Color gridColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    final chartRect = Rect.fromLTWH(
      34.w,
      8.h,
      math.max(0, size.width - 44.w),
      math.max(0, size.height - 35.h),
    );

    _drawGrid(canvas, chartRect);

    final safePoints = points.isEmpty ? const <double>[0, 0] : points;
    final path = Path();
    final circlePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.3.w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (int index = 0; index < safePoints.length; index++) {
      final denominator = math.max(1, safePoints.length - 1);
      final x = chartRect.left + chartRect.width * (index / denominator);
      final y = chartRect.bottom -
          chartRect.height * (safePoints[index].clamp(0, 100) / 100);

      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);

    for (int index = 0; index < safePoints.length; index++) {
      final denominator = math.max(1, safePoints.length - 1);
      final x = chartRect.left + chartRect.width * (index / denominator);
      final y = chartRect.bottom -
          chartRect.height * (safePoints[index].clamp(0, 100) / 100);

      if (index == 0 ||
          index == safePoints.length - 1 ||
          (index < labels.length && labels[index].isNotEmpty)) {
        canvas.drawCircle(Offset(x, y), 3.2.w, circlePaint);
      }
    }

    _drawLabels(canvas, chartRect);
  }

  void _drawGrid(Canvas canvas, Rect chartRect) {
    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8.w;

    for (final value in const [0, 25, 50, 75, 100]) {
      final y = chartRect.bottom - chartRect.height * (value / 100);
      canvas.drawLine(Offset(chartRect.left, y), Offset(chartRect.right, y), gridPaint);
      _drawText(
        canvas,
        '$value%',
        Offset(0, y - 5.h),
        textColor,
        7.2.sp,
        TextAlign.left,
        30.w,
      );
    }
  }

  void _drawLabels(Canvas canvas, Rect chartRect) {
    for (int index = 0; index < labels.length; index++) {
      final label = labels[index];
      if (label.isEmpty) continue;

      final denominator = math.max(1, labels.length - 1);
      final x = chartRect.left + chartRect.width * (index / denominator);
      final align = index == 0
          ? TextAlign.left
          : index == labels.length - 1
              ? TextAlign.right
              : TextAlign.center;

      _drawText(
        canvas,
        label,
        Offset(x - 24.w, chartRect.bottom + 10.h),
        textColor,
        7.2.sp,
        align,
        48.w,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    Color color,
    double fontSize,
    TextAlign textAlign,
    double maxWidth,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.rtl,
      textAlign: textAlign,
      maxLines: 1,
    )..layout(maxWidth: maxWidth);

    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant MasteryChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.labels != labels ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.textColor != textColor;
  }
}
