import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/shared/widgets/app_main_components/custom_app_bar.dart';
import 'package:islamic_app/shared/widgets/common_components/SquareLogo.dart';

import 'package:islamic_app/core/services/app_haptics.dart';
import '../reader/qpc_connected_mushaf_page.dart';
import '../reader/quran_page_mapper.dart';
import '../reader/quran_reader_helpers.dart';
import 'constant.dart';
import 'to_arabic_no_converter.dart';

class QuranPartsPage extends StatefulWidget {
  const QuranPartsPage({super.key});

  @override
  State<QuranPartsPage> createState() => _QuranPartsPageState();
}

class _QuranPartsPageState extends State<QuranPartsPage> {
  late final Future<dynamic> quranFuture;

  static const List<_QuranPart> parts = [
    _QuranPart(partNumber: 1, startSura: 1, startAyah: 1, label: 'الفاتحة ١'),
    _QuranPart(
        partNumber: 2, startSura: 2, startAyah: 142, label: 'البقرة ١٤٢'),
    _QuranPart(
        partNumber: 3, startSura: 2, startAyah: 253, label: 'البقرة ٢٥٣'),
    _QuranPart(
        partNumber: 4, startSura: 3, startAyah: 93, label: 'آل عمران ٩٣'),
    _QuranPart(partNumber: 5, startSura: 4, startAyah: 24, label: 'النساء ٢٤'),
    _QuranPart(
        partNumber: 6, startSura: 4, startAyah: 148, label: 'النساء ١٤٨'),
    _QuranPart(partNumber: 7, startSura: 5, startAyah: 82, label: 'المائدة ٨٢'),
    _QuranPart(
        partNumber: 8, startSura: 6, startAyah: 111, label: 'الأنعام ١١١'),
    _QuranPart(partNumber: 9, startSura: 7, startAyah: 88, label: 'الأعراف ٨٨'),
    _QuranPart(
        partNumber: 10, startSura: 8, startAyah: 41, label: 'الأنفال ٤١'),
    _QuranPart(partNumber: 11, startSura: 9, startAyah: 93, label: 'التوبة ٩٣'),
    _QuranPart(partNumber: 12, startSura: 11, startAyah: 6, label: 'هود ٦'),
    _QuranPart(partNumber: 13, startSura: 12, startAyah: 53, label: 'يوسف ٥٣'),
    _QuranPart(partNumber: 14, startSura: 15, startAyah: 1, label: 'الحجر ١'),
    _QuranPart(partNumber: 15, startSura: 17, startAyah: 1, label: 'الإسراء ١'),
    _QuranPart(partNumber: 16, startSura: 18, startAyah: 75, label: 'الكهف ٧٥'),
    _QuranPart(
        partNumber: 17, startSura: 21, startAyah: 1, label: 'الأنبياء ١'),
    _QuranPart(
        partNumber: 18, startSura: 23, startAyah: 1, label: 'المؤمنون ١'),
    _QuranPart(
        partNumber: 19, startSura: 25, startAyah: 21, label: 'الفرقان ٢١'),
    _QuranPart(partNumber: 20, startSura: 27, startAyah: 56, label: 'النمل ٥٦'),
    _QuranPart(
        partNumber: 21, startSura: 29, startAyah: 46, label: 'العنكبوت ٤٦'),
    _QuranPart(
        partNumber: 22, startSura: 33, startAyah: 31, label: 'الأحزاب ٣١'),
    _QuranPart(partNumber: 23, startSura: 36, startAyah: 28, label: 'يس ٢٨'),
    _QuranPart(partNumber: 24, startSura: 39, startAyah: 32, label: 'الزمر ٣٢'),
    _QuranPart(partNumber: 25, startSura: 41, startAyah: 47, label: 'فصلت ٤٧'),
    _QuranPart(partNumber: 26, startSura: 46, startAyah: 1, label: 'الأحقاف ١'),
    _QuranPart(
        partNumber: 27, startSura: 51, startAyah: 31, label: 'الذاريات ٣١'),
    _QuranPart(
        partNumber: 28, startSura: 58, startAyah: 1, label: 'المجادلة ١'),
    _QuranPart(partNumber: 29, startSura: 67, startAyah: 1, label: 'الملك ١'),
    _QuranPart(partNumber: 30, startSura: 78, startAyah: 1, label: 'النبأ ١'),
  ];

  @override
  void initState() {
    super.initState();
    quranFuture = readJson();
  }

  Future<void> openQuranReader({
    required BuildContext context,
    required dynamic quranData,
    required _QuranPart part,
  }) async {
    AppHaptics.tap(context);

    await QuranPageMapper.load();

    final initialSuraIndex = part.startSura - 1;
    final initialAyahIndex = part.startAyah - 1;

    final globalAyahIndex = QuranReaderHelpers.getGlobalAyahIndex(
      suraIndex: initialSuraIndex,
      ayahIndex: initialAyahIndex,
    );

    final initialMushafPageNumber =
        QuranPageMapper.getPageNumberForGlobalAyah(globalAyahIndex);

    if (!context.mounted) return;

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            QpcConnectedMushafPage(
          initialPage: initialMushafPageNumber,
          initialGlobalAyahIndex: globalAyahIndex,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isLargeScreen = MediaQuery.sizeOf(context).width >= 600;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: FutureBuilder<dynamic>(
          future: quranFuture,
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

            if (isLargeScreen) {
              return _buildLargeScreenContent(context, quranData, isDark);
            }

            return _buildPhoneContent(context, quranData, isDark);
          },
        ),
      ),
    );
  }

  Widget _buildPhoneContent(BuildContext context, List quranData, bool isDark) {
    final theme = Theme.of(context);

    return Column(
      children: [
        CustomAppBar(
          category: CustomAppBarCategory(text: 'الأجزاء'),
        ),
        SizedBox(height: 12.h),
        SquareLogo(
          category: SquareLogoCategory(
            image: 'assets/icons/QuRan.png',
          ),
        ),
        SizedBox(height: 14.h),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Container(
              width: double.infinity,
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
                    padding: EdgeInsets.only(
                      top: 12.h,
                      right: 14.w,
                      left: 14.w,
                      bottom: 8.h,
                    ),
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Text(
                          'الأجزاء',
                          style: TextStyle(
                            fontFamily: 'cairo',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${parts.length.toString().toArabicNumbers} جزء',
                          style: TextStyle(
                            fontFamily: 'cairo',
                            fontSize: 9.sp,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.only(
                        left: 10.w,
                        right: 10.w,
                        bottom: 12.h,
                      ),
                      itemCount: parts.length,
                      separatorBuilder: (_, __) => SizedBox(height: 8.h),
                      itemBuilder: (context, index) {
                        final part = parts[index];

                        return _PartTile(
                          part: part,
                          isDark: isDark,
                          onTap: () async {
                            await openQuranReader(
                              context: context,
                              quranData: quranData,
                              part: part,
                            );
                          },
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
  }

  Widget _buildLargeScreenContent(
      BuildContext context, List quranData, bool isDark) {
    final theme = Theme.of(context);
    final bool isFold = _QuranAdaptiveSizes.isFoldLandscape(context);
    final int crossAxisCount = isFold ? 2 : 3;
    final double horizontalPadding = isFold ? 18 : 26;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding:
            EdgeInsets.fromLTRB(horizontalPadding, 18, horizontalPadding, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LargePageTitle(
              title: 'الأجزاء',
              subtitle: '${parts.length.toString().toArabicNumbers} جزء',
              onBack: () => Navigator.maybePop(context),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(isFold ? 14 : 18),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        const Text(
                          'الأجزاء',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontFamily: 'cairo',
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${parts.length.toString().toArabicNumbers} جزء',
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            fontFamily: 'cairo',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: GridView.builder(
                        physics: const ClampingScrollPhysics(),
                        padding: EdgeInsets.zero,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: isFold ? 8 : 10,
                          crossAxisSpacing: isFold ? 8 : 10,
                          mainAxisExtent: isFold ? 62 : 68,
                        ),
                        itemCount: parts.length,
                        itemBuilder: (context, index) {
                          final part = parts[index];

                          return _PartTile(
                            part: part,
                            isDark: isDark,
                            large: true,
                            onTap: () async {
                              await openQuranReader(
                                context: context,
                                quranData: quranData,
                                part: part,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
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
  final bool large;

  const _PartTile({
    required this.part,
    required this.isDark,
    required this.onTap,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        isDark ? const Color(0xff171B26) : const Color(0xffDEE9EF);

    final textColor = isDark ? Colors.white : Colors.black;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(large ? 14 : 12.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(large ? 14 : 12.r),
        onTap: () {
          AppHaptics.tap(context);
          onTap();
        },
        child: Container(
          height: large ? 62 : 42.h,
          padding: EdgeInsets.symmetric(horizontal: large ? 14 : 12.w),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Text(
                'الجزء ${part.partNumber.toString().toArabicNumbers}',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: large ? 13 : 11.sp,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              SizedBox(width: large ? 10 : 10.w),
              Expanded(
                child: Text(
                  part.label,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'cairo',
                    fontSize: large ? 10.5 : 9.sp,
                    fontWeight: FontWeight.w600,
                    color: textColor.withOpacity(0.65),
                  ),
                ),
              ),
              Icon(
                Icons.arrow_back_ios_new_rounded,
                size: large ? 13 : 12.sp,
                color: textColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LargePageTitle extends StatelessWidget {
  const _LargePageTitle({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                title,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body(context).copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onBackground,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onBackground.withOpacity(0.55),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _RoundBackButton(onTap: onBack),
      ],
    );
  }
}

class _RoundBackButton extends StatelessWidget {
  const _RoundBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xff222837)
              : theme.colorScheme.secondary.withOpacity(0.96),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 18,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _QuranAdaptiveSizes {
  const _QuranAdaptiveSizes._();

  static bool isFoldLandscape(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width >= 600 && size.shortestSide < 600;
  }

  static double pageTitle(BuildContext context) {
    return isFoldLandscape(context) ? 18 : 23;
  }

  static double subtitle(BuildContext context) {
    return isFoldLandscape(context) ? 11 : 13;
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
