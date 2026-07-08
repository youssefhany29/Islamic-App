import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/quran_reader_theme.dart';

class QpcSurahHeaderLine extends StatelessWidget {
  const QpcSurahHeaderLine({
    super.key,
    required this.surahNumber,
    required this.lineHeight,
    required this.readerTheme,
  });

  final int? surahNumber;
  final double lineHeight;
  final QuranReaderTheme readerTheme;

  @override
  Widget build(BuildContext context) {
    final int? number = surahNumber;

    if (number == null || number < 1 || number > 114) {
      return const SizedBox.expand();
    }

    final String surahNameGlyph = String.fromCharCode(0xE000 + number);

    final double fontSize = (lineHeight * 1.55).clamp(32.0, 72.0).toDouble();

    return Padding(
      padding: EdgeInsets.only(
        left: 3.w,
        right: 3.w,
        top: 0,
        bottom: 3.h,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: double.infinity,
          height: (lineHeight * 0.86).clamp(30.0, 58.0).toDouble(),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(9.r),
            border: Border.all(
              color: readerTheme.textColor.withOpacity(0.82),
              width: 1.15,
            ),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                surahNameGlyph,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontFamily: 'surahNameV2',
                  fontSize: fontSize,
                  height: 1.0,
                  color: readerTheme.textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
