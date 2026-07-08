import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/quran_reader_theme.dart';

class QpcPageNumberBadge extends StatelessWidget {
  const QpcPageNumberBadge({
    super.key,
    required this.pageNumber,
    required this.readerTheme,
  });

  final int pageNumber;
  final QuranReaderTheme readerTheme;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 42.w,
        height: 24.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: readerTheme.pageBadgeBackground,
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(
            color: readerTheme.pageBadgeBorder.withOpacity(0.75),
            width: 1,
          ),
        ),
        child: Text(
          '$pageNumber',
          style: TextStyle(
            fontFamily: 'cairo',
            fontSize: 10.sp,
            fontWeight: FontWeight.w900,
            color: readerTheme.pageBadgeText,
            height: 1,
          ),
        ),
      ),
    );
  }
}