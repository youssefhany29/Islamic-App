import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/quran_reader_theme.dart';

class QpcPageMetaHeader extends StatelessWidget {
  const QpcPageMetaHeader({
    super.key,
    required this.readerTheme,
    required this.surahName,
    required this.juzNumber,
  });

  final QuranReaderTheme readerTheme;
  final String surahName;
  final int juzNumber;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            Text(
              'الجزء ${_arabicNumber(juzNumber)}',
              style: _style,
            ),
            const Spacer(),
            Text(
              surahName,
              style: _style,
            ),
          ],
        ),
      ),
    );
  }

  TextStyle get _style {
    return TextStyle(
      fontFamily: 'cairo',
      fontSize: 11.sp,
      height: 1.2,
      fontWeight: FontWeight.w900,
      color: readerTheme.secondaryTextColor.withOpacity(0.88),
    );
  }

  String _arabicNumber(int value) {
    const List<String> digits = <String>[
      '٠',
      '١',
      '٢',
      '٣',
      '٤',
      '٥',
      '٦',
      '٧',
      '٨',
      '٩',
    ];

    return value.toString().split('').map((char) {
      final int? digit = int.tryParse(char);
      return digit == null ? char : digits[digit];
    }).join();
  }
}