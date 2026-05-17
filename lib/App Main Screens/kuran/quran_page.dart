import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/App%20Main%20Screens/App%20Main%20Screens%20Components/custom_app_bar.dart';
import 'package:islamic_app/App%20Main%20Screens/kuran/main_quraan_components/to_arabic_no_converter.dart';
import 'package:islamic_app/App%20Main%20Screens/kuran/reader/quran_reader_page.dart';
import 'package:islamic_app/App%20Main%20Screens/kuran/reader/quran_reader_storage.dart';
import 'package:islamic_app/App%20Main%20Screens/kuran/wird/create_khatma_page.dart';
import 'package:islamic_app/App%20Main%20Screens/kuran/wird/daily_wird_page.dart';
import 'package:islamic_app/App%20Main%20Screens/kuran/wird/quran_wird_storage.dart';
import 'package:islamic_app/Common%20Components/SquareLogo.dart';

import 'main_quraan_components/constant.dart';
import 'main_quraan_components/index.dart';
import 'main_quraan_components/quran_bookmarks_page.dart';
import 'main_quraan_components/quran_parts_page.dart';

class QuranPage extends StatefulWidget {
  const QuranPage({super.key});

  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  late Future<_QuranHomeWirdInfo> homeWirdFuture;

  @override
  void initState() {
    super.initState();
    homeWirdFuture = _loadHomeWirdInfo();
  }

  void _refreshHomeWird() {
    setState(() {
      homeWirdFuture = _loadHomeWirdInfo();
    });
  }

  void _openPageWithoutAnimation(BuildContext context, Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  QuranReaderViewMode _parseViewMode(String savedMode) {
    return QuranReaderViewMode.values.firstWhere(
          (mode) => mode.name == savedMode,
      orElse: () => QuranReaderViewMode.continuous,
    );
  }

  Future<void> _openLastRead(BuildContext context) async {
    final lastRead = await QuranReaderStorage.getLastRead();

    if (!context.mounted) return;

    if (lastRead == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لا يوجد آخر موضع قراءة محفوظ حتى الآن',
            textDirection: TextDirection.rtl,
          ),
        ),
      );
      return;
    }

    final quranData = await readJson();

    if (!context.mounted) return;

    _openPageWithoutAnimation(
      context,
      QuranReaderPage(
        arabic: quranData[0],
        initialSuraIndex: lastRead.suraIndex,
        initialAyahIndex: lastRead.ayahIndex,
        initialViewMode: _parseViewMode(lastRead.viewMode),
        initialMushafPageNumber: lastRead.mushafPageNumber,
      ),
    );
  }

  Future<void> _openCreateKhatmaPage(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateKhatmaPage(),
      ),
    );

    if (!mounted) return;

    _refreshHomeWird();
  }

  Future<void> _openDailyWirdPage(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DailyWirdPage(),
      ),
    );

    if (!mounted) return;

    _refreshHomeWird();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final pageBackground = theme.colorScheme.background;
    final cardColor = theme.colorScheme.primary;
    final buttonColor =
    isDark ? const Color(0xff171B26) : theme.colorScheme.secondary;
    final buttonTextColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              category: CustomAppBarCategory(text: 'القرآن'),
            ),
            SizedBox(height: 14.h),
            SquareLogo(
              category: SquareLogoCategory(
                image: 'assets/icons/QuRan.png',
              ),
            ),
            SizedBox(height: 14.h),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: Column(
                  children: [
                    _MainQuranCard(
                      color: cardColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const _CardTitle(title: 'ورد اليوم'),
                          SizedBox(height: 8.h),
                          FutureBuilder<_QuranHomeWirdInfo>(
                            future: homeWirdFuture,
                            builder: (context, snapshot) {
                              final wirdInfo = snapshot.data;

                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return _SmallInfoButton(
                                  title: 'جاري تحميل الأوراد...',
                                  subtitle: 'برجاء الانتظار',
                                  backgroundColor: buttonColor,
                                  textColor: buttonTextColor,
                                  icon: Icons.hourglass_empty_rounded,
                                  onTap: () {},
                                );
                              }

                              if (wirdInfo == null ||
                                  !wirdInfo.hasActiveWirds) {
                                return _SmallInfoButton(
                                  title: 'لا توجد أوراد حالية',
                                  subtitle: 'اضغط لإنشاء ورد أو ختمة جديدة',
                                  backgroundColor: buttonColor,
                                  textColor: buttonTextColor,
                                  icon: Icons.add_circle_outline_rounded,
                                  onTap: () {
                                    _openCreateKhatmaPage(context);
                                  },
                                );
                              }

                              return _SmallInfoButton(
                                title: wirdInfo.title,
                                subtitle: wirdInfo.subtitle,
                                backgroundColor: buttonColor,
                                textColor: buttonTextColor,
                                icon: Icons.check_circle_outline,
                                onTap: () {
                                  _openDailyWirdPage(context);
                                },
                              );
                            },
                          ),
                          SizedBox(height: 14.h),
                          const _CardTitle(title: 'تتبع قراءتك'),
                          SizedBox(height: 8.h),
                          _SmallInfoButton(
                            title: 'آخر موضع قراءة',
                            subtitle: 'اضغط للرجوع إلى آخر مكان وقفت عنده',
                            backgroundColor: buttonColor,
                            textColor: buttonTextColor,
                            icon: Icons.arrow_back_ios_new_rounded,
                            onTap: () {
                              _openLastRead(context);
                            },
                          ),
                          SizedBox(height: 12.h),
                          _LargeButton(
                            title: 'إنشاء ختمة',
                            backgroundColor: buttonColor,
                            textColor: buttonTextColor,
                            onTap: () {
                              _openCreateKhatmaPage(context);
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),
                    _MainQuranCard(
                      color: cardColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const _CardTitle(title: 'القرآن'),
                          SizedBox(height: 10.h),
                          _LargeButton(
                            title: 'العلامات المحفوظة',
                            backgroundColor: buttonColor,
                            textColor: buttonTextColor,
                            onTap: () {
                              _openPageWithoutAnimation(
                                context,
                                const QuranBookmarksPage(),
                              );
                            },
                          ),
                          SizedBox(height: 8.h),
                          _LargeButton(
                            title: 'الأجزاء',
                            backgroundColor: buttonColor,
                            textColor: buttonTextColor,
                            onTap: () {
                              _openPageWithoutAnimation(
                                context,
                                const QuranPartsPage(),
                              );
                            },
                          ),
                          SizedBox(height: 8.h),
                          _LargeButton(
                            title: 'الفهرس',
                            backgroundColor: buttonColor,
                            textColor: buttonTextColor,
                            onTap: () {
                              _openPageWithoutAnimation(
                                context,
                                const IndexPage(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 18.h),
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

class _MainQuranCard extends StatelessWidget {
  final Color color;
  final Widget child;

  const _MainQuranCard({
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  final String title;

  const _CardTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textDirection: TextDirection.rtl,
      style: TextStyle(
        fontFamily: 'cairo',
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }
}

class _SmallInfoButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;
  final VoidCallback onTap;

  const _SmallInfoButton({
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: Container(
          height: 38.h,
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                icon,
                size: 14.sp,
                color: textColor,
              ),
              SizedBox(width: 7.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        height: 1,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: 7.2.sp,
                        color: textColor.withOpacity(0.58),
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LargeButton extends StatelessWidget {
  final String title;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;

  const _LargeButton({
    required this.title,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          height: 34.h,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 12.sp,
                color: textColor,
              ),
              SizedBox(width: 8.w),
              Text(
                title,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuranHomeWirdInfo {
  final bool hasActiveWirds;
  final String title;
  final String subtitle;

  const _QuranHomeWirdInfo({
    required this.hasActiveWirds,
    required this.title,
    required this.subtitle,
  });
}

Future<_QuranHomeWirdInfo> _loadHomeWirdInfo() async {
  final activeWirds = await QuranWirdStorage.buildTodayWirds();

  if (activeWirds.isEmpty) {
    return const _QuranHomeWirdInfo(
      hasActiveWirds: false,
      title: '',
      subtitle: '',
    );
  }

  final firstWird = activeWirds.first;

  final fromSuraName = QuranWirdStorage.getSuraName(firstWird.fromSuraIndex);
  final toSuraName = QuranWirdStorage.getSuraName(firstWird.toSuraIndex);

  final fromAyah = (firstWird.fromAyahIndex + 1).toString().toArabicNumbers;
  final toAyah = (firstWird.toAyahIndex + 1).toString().toArabicNumbers;

  final fromPage = firstWird.fromPageNumber.toString().toArabicNumbers;
  final toPage = firstWird.toPageNumber.toString().toArabicNumbers;

  final activeCount = activeWirds.length.toString().toArabicNumbers;

  final suraRange = fromSuraName == toSuraName
      ? 'سورة $fromSuraName'
      : 'من $fromSuraName إلى $toSuraName';

  final title = activeWirds.length == 1
      ? firstWird.planName
      : '$activeCount أوراد حالية';

  final subtitle = activeWirds.length == 1
      ? '$suraRange | ص $fromPage إلى ص $toPage | آية $fromAyah إلى آية $toAyah'
      : '${firstWird.planName}: $suraRange | ص $fromPage إلى ص $toPage';

  return _QuranHomeWirdInfo(
    hasActiveWirds: true,
    title: title,
    subtitle: subtitle,
  );
}