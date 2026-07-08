import 'package:flutter/material.dart';

import '../theme/quran_reader_theme.dart';

class QpcBasmallahLine extends StatelessWidget {
  const QpcBasmallahLine({
    super.key,
    required this.lineHeight,
    required this.readerTheme,
  });

  final double lineHeight;
  final QuranReaderTheme readerTheme;

  @override
  Widget build(BuildContext context) {
    /// ثابت حسب ارتفاع السطر فقط.
    /// لا يعتمد على طول السورة ولا عدد الآيات.
    final double fontSize = (lineHeight * 0.82).clamp(20.0, 34.0).toDouble();

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Text(
          String.fromCharCode(0xFDFD),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          maxLines: 1,
          softWrap: false,
          style: TextStyle(
            fontFamily: 'quranCommon',
            fontSize: fontSize,
            height: 1.0,
            color: readerTheme.textColor,
          ),
        ),
      ),
    );
  }
}