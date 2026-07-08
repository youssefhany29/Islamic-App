import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NextPrayerContent extends StatelessWidget {
  const NextPrayerContent({
    super.key,
    required this.prayerName,
    required this.timeText,
    required this.remainingText,
    this.isCompact = true,
  });

  final String prayerName;
  final String timeText;
  final String remainingText;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final double containerHeight = isCompact ? 70.h : 92.h;
    final double horizontalPadding = isCompact ? 12.w : 20.w;
    final double verticalPadding = isCompact ? 10.h : 14.h;

    final double timeSize = isCompact ? 17.sp : 23.sp;
    final double prayerNameSize = isCompact ? 18.sp : 25.sp;
    final double timeLabelSize = isCompact ? 9.sp : 11.sp;
    final double remainingSize = isCompact ? 10.sp : 13.sp;

    return Container(
      width: double.infinity,
      height: containerHeight,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: const Color(0xff171B26),
        borderRadius: BorderRadius.circular(isCompact ? 16.r : 20.r),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              flex: 4,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _PrayerTimeColumn(
                  timeText: timeText,
                  timeSize: timeSize,
                  timeLabelSize: timeLabelSize,
                ),
              ),
            ),
            SizedBox(width: isCompact ? 10.w : 18.w),
            Flexible(
              flex: 7,
              child: Align(
                alignment: Alignment.centerRight,
                child: _PrayerNameColumn(
                  prayerName: prayerName,
                  remainingText: remainingText,
                  prayerNameSize: prayerNameSize,
                  remainingSize: remainingSize,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerTimeColumn extends StatelessWidget {
  const _PrayerTimeColumn({
    required this.timeText,
    required this.timeSize,
    required this.timeLabelSize,
  });

  final String timeText;
  final double timeSize;
  final double timeLabelSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          timeText,
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'cairo',
            fontSize: timeSize,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'الوقت',
          textAlign: TextAlign.left,
          textDirection: TextDirection.rtl,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'cairo',
            fontSize: timeLabelSize,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.6),
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

class _PrayerNameColumn extends StatelessWidget {
  const _PrayerNameColumn({
    required this.prayerName,
    required this.remainingText,
    required this.prayerNameSize,
    required this.remainingSize,
  });

  final String prayerName;
  final String remainingText;
  final double prayerNameSize;
  final double remainingSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          prayerName,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'cairo',
            fontSize: prayerNameSize,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'متبقي $remainingText',
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'cairo',
            fontSize: remainingSize,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.7),
            height: 1.1,
          ),
        ),
      ],
    );
  }
}