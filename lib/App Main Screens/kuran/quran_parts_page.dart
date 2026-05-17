import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'constant.dart';
import 'surah_builder.dart';

class QuranPartsPage extends StatelessWidget {
  const QuranPartsPage({super.key});

  static const List<_QuranPart> parts = [
    _QuranPart(partNumber: 1, startSura: 1, startAyah: 1, label: 'الفاتحة ١'),
    _QuranPart(partNumber: 2, startSura: 2, startAyah: 142, label: 'البقرة ١٤٢'),
    _QuranPart(partNumber: 3, startSura: 2, startAyah: 253, label: 'البقرة ٢٥٣'),
    _QuranPart(partNumber: 4, startSura: 3, startAyah: 93, label: 'آل عمران ٩٣'),
    _QuranPart(partNumber: 5, startSura: 4, startAyah: 24, label: 'النساء ٢٤'),
    _QuranPart(partNumber: 6, startSura: 4, startAyah: 148, label: 'النساء ١٤٨'),
    _QuranPart(partNumber: 7, startSura: 5, startAyah: 82, label: 'المائدة ٨٢'),
    _QuranPart(partNumber: 8, startSura: 6, startAyah: 111, label: 'الأنعام ١١١'),
    _QuranPart(partNumber: 9, startSura: 7, startAyah: 88, label: 'الأعراف ٨٨'),
    _QuranPart(partNumber: 10, startSura: 8, startAyah: 41, label: 'الأنفال ٤١'),
    _QuranPart(partNumber: 11, startSura: 9, startAyah: 93, label: 'التوبة ٩٣'),
    _QuranPart(partNumber: 12, startSura: 11, startAyah: 6, label: 'هود ٦'),
    _QuranPart(partNumber: 13, startSura: 12, startAyah: 53, label: 'يوسف ٥٣'),
    _QuranPart(partNumber: 14, startSura: 15, startAyah: 1, label: 'الحجر ١'),
    _QuranPart(partNumber: 15, startSura: 17, startAyah: 1, label: 'الإسراء ١'),
    _QuranPart(partNumber: 16, startSura: 18, startAyah: 75, label: 'الكهف ٧٥'),
    _QuranPart(partNumber: 17, startSura: 21, startAyah: 1, label: 'الأنبياء ١'),
    _QuranPart(partNumber: 18, startSura: 23, startAyah: 1, label: 'المؤمنون ١'),
    _QuranPart(partNumber: 19, startSura: 25, startAyah: 21, label: 'الفرقان ٢١'),
    _QuranPart(partNumber: 20, startSura: 27, startAyah: 56, label: 'النمل ٥٦'),
    _QuranPart(partNumber: 21, startSura: 29, startAyah: 46, label: 'العنكبوت ٤٦'),
    _QuranPart(partNumber: 22, startSura: 33, startAyah: 31, label: 'الأحزاب ٣١'),
    _QuranPart(partNumber: 23, startSura: 36, startAyah: 28, label: 'يس ٢٨'),
    _QuranPart(partNumber: 24, startSura: 39, startAyah: 32, label: 'الزمر ٣٢'),
    _QuranPart(partNumber: 25, startSura: 41, startAyah: 47, label: 'فصلت ٤٧'),
    _QuranPart(partNumber: 26, startSura: 46, startAyah: 1, label: 'الأحقاف ١'),
    _QuranPart(partNumber: 27, startSura: 51, startAyah: 31, label: 'الذاريات ٣١'),
    _QuranPart(partNumber: 28, startSura: 58, startAyah: 1, label: 'المجادلة ١'),
    _QuranPart(partNumber: 29, startSura: 67, startAyah: 1, label: 'الملك ١'),
    _QuranPart(partNumber: 30, startSura: 78, startAyah: 1, label: 'النبأ ١'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: FutureBuilder(
          future: readJson(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return const Center(
                child: Text('حدث خطأ أثناء تحميل بيانات القرآن'),
              );
            }

            final quranData = snapshot.data as List;

            return Column(
              children: [
                _PartsHeader(theme: theme),
                SizedBox(height: 16.h),
                Image.asset(
                  'assets/icons/QuRan.png',
                  width: 64.w,
                  height: 64.w,
                ),
                SizedBox(height: 16.h),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24.r),
                          topRight: Radius.circular(24.r),
                        ),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 12.h,
                            ),
                            child: Row(
                              textDirection: TextDirection.rtl,
                              children: [
                                Text(
                                  'الأجزاء',
                                  style: TextStyle(
                                    fontFamily: 'cairo',
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '٣٠ جزء',
                                  style: TextStyle(
                                    fontFamily: 'cairo',
                                    fontSize: 10.sp,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.separated(
                              padding: EdgeInsets.only(bottom: 12.h),
                              itemCount: parts.length,
                              separatorBuilder: (_, __) => SizedBox(height: 8.h),
                              itemBuilder: (context, index) {
                                final part = parts[index];

                                return Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                                  child: _PartTile(
                                    part: part,
                                    isDark: isDark,
                                    onTap: () {
                                      fabIsClicked = true;

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => SurahBuilder(
                                            arabic: quranData[0],
                                            sura: part.startSura - 1,
                                            suraName: arabicName[part.startSura - 1]['name'],
                                            ayah: part.startAyah - 1,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PartsHeader extends StatelessWidget {
  final ThemeData theme;

  const _PartsHeader({
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46.h,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18.sp,
                  color: theme.textTheme.headlineLarge?.color,
                ),
              ),
            ),
            Text(
              'الأجزاء',
              style: TextStyle(
                fontFamily: 'cairo',
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: theme.textTheme.headlineLarge?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PartTile extends StatelessWidget {
  final _QuranPart part;
  final bool isDark;
  final VoidCallback onTap;

  const _PartTile({
    required this.part,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDark
        ? const Color(0xff171B26)
        : const Color(0xffDEE9EF);

    final textColor = isDark ? Colors.white : Colors.black;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: Container(
          height: 42.h,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Text(
                'الجزء ${part.partNumber}',
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  part.label,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontFamily: 'cairo',
                    fontSize: 9.sp,
                    color: textColor.withOpacity(0.6),
                  ),
                ),
              ),
              Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 12.sp,
                color: textColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuranPart {
  final int partNumber;
  final int startSura;
  final int startAyah;
  final String label;

  const _QuranPart({
    required this.partNumber,
    required this.startSura,
    required this.startAyah,
    required this.label,
  });
}