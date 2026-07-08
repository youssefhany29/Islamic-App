import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/analytics/analytics_ui.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/analytics/memorization_analytics_data.dart';

class AnalyticsStatsGrid extends StatelessWidget {
  const AnalyticsStatsGrid({super.key, required this.data});

  final MemorizationAnalyticsData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: AnalyticsStatCard(
                title: 'الاختبارات',
                value: '${data.testsCount}',
                unit: 'اختبارات',
                icon: Icons.fact_check_rounded,
                iconColor: const Color(0xFF244F7B),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(child: MasteryPercentCard(percent: data.masteryPercent)),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: AnalyticsStatCard(
                title: 'المراجعة',
                value: '${data.reviewPages}',
                unit: 'صفحة',
                icon: Icons.description_rounded,
                iconColor: const Color(0xFF36A88F),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: AnalyticsStatCard(
                title: 'الحفظ',
                value: '${data.memorizedPages}',
                unit: 'صفحة',
                icon: Icons.library_books_rounded,
                iconColor: const Color(0xFF5266D8),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class MasteryPercentCard extends StatelessWidget {
  const MasteryPercentCard({super.key, required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 102.h,
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 10.h),
      decoration: AnalyticsDecorations.outerCard(context),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'الإتقان العام',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    color: AnalyticsThemeColors.textSecondary(context, 0.74),
                    fontSize: 9.2.sp,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '$percent%',
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headline(context).copyWith(
                    color: AnalyticsThemeColors.textPrimary(context),
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                SizedBox(height: 9.h),
                SizedBox(
                  width: 52.w,
                  height: 13.h,
                  child: const CustomPaint(
                    painter: MiniTrendPainter(color: AnalyticsColors.green),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 9.w),
          SizedBox(
            width: 44.w,
            height: 44.w,
            child: CircularProgressIndicator(
              value: (percent / 100).clamp(0.0, 1.0).toDouble(),
              strokeWidth: 3.5.w,
              strokeCap: StrokeCap.round,
              backgroundColor: AnalyticsThemeColors.textSecondary(
                context,
                0.12,
              ),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AnalyticsColors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnalyticsStatCard extends StatelessWidget {
  const AnalyticsStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 102.h,
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 10.h),
      decoration: AnalyticsDecorations.outerCard(context),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    color: AnalyticsThemeColors.textSecondary(context, 0.74),
                    fontSize: 9.2.sp,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  value,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headline(context).copyWith(
                    color: AnalyticsThemeColors.textPrimary(context),
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  unit,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    color: AnalyticsThemeColors.textSecondary(context, 0.50),
                    fontSize: 8.8.sp,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(icon, color: iconColor, size: 20.sp),
          ),
        ],
      ),
    );
  }
}

class MiniTrendPainter extends CustomPainter {
  const MiniTrendPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(0, size.height * 0.70)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.45,
        size.width * 0.26,
        size.height * 0.92,
        size.width * 0.42,
        size.height * 0.58,
      )
      ..cubicTo(
        size.width * 0.58,
        size.height * 0.24,
        size.width * 0.70,
        size.height * 0.66,
        size.width * 0.82,
        size.height * 0.42,
      )
      ..quadraticBezierTo(
        size.width * 0.92,
        size.height * 0.20,
        size.width,
        size.height * 0.32,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant MiniTrendPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
