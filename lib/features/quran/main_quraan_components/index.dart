import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/shared/widgets/app_main_components/custom_app_bar.dart';

import 'package:islamic_app/shared/widgets/common_components/SquareLogo.dart';
import 'package:islamic_app/core/services/app_haptics.dart';
import '../reader/qpc_connected_mushaf_page.dart';
import '../reader/quran_page_mapper.dart';
import '../reader/quran_reader_helpers.dart';
import 'arabic_sura_number.dart';
import 'constant.dart';
import 'to_arabic_no_converter.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({Key? key}) : super(key: key);

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  final TextEditingController searchController = TextEditingController();

  late final Future<dynamic> quranFuture;

  Timer? searchDebounce;
  String searchText = '';

  static double listTileHeight = 56.0;

  @override
  void initState() {
    super.initState();
    quranFuture = readJson();
  }

  List<int> get filteredIndexes {
    final text = searchText.trim();

    if (text.isEmpty) {
      return List.generate(114, (index) => index);
    }

    return List.generate(114, (index) => index).where((index) {
      final suraName = arabicName[index]['name'].toString();
      final suraNumber = arabicName[index]['surah'].toString();

      return suraName.contains(text) || suraNumber.contains(text);
    }).toList();
  }

  void onSearchTextChanged(String value) {
    searchDebounce?.cancel();

    searchDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;

      setState(() {
        searchText = value;
      });
    });
  }

  void clearSearch() {
    searchDebounce?.cancel();
    searchController.clear();

    setState(() {
      searchText = '';
    });
  }

  @override
  void dispose() {
    searchDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> openQuranReader({
    required BuildContext context,
    required dynamic quranData,
    required int suraIndex,
  }) async {
    AppHaptics.tap(context);

    await QuranPageMapper.load();

    final globalAyahIndex = QuranReaderHelpers.getGlobalAyahIndex(
      suraIndex: suraIndex,
      ayahIndex: 0,
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
      body: ColoredBox(
        color: theme.colorScheme.background,
        child: SafeArea(
          child: FutureBuilder<dynamic>(
            future: quranFuture,
            builder: (
                BuildContext context,
                AsyncSnapshot<dynamic> snapshot,
                ) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'حدث خطأ أثناء تحميل القرآن',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'cairo',
                      fontSize: 12.sp,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return Center(
                  child: Text(
                    'لا توجد بيانات',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'cairo',
                      fontSize: 12.sp,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                );
              }

              if (isLargeScreen) {
                return _buildLargeScreenContent(context, snapshot.data);
              }

              return _buildPhoneContent(context, snapshot.data);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneContent(BuildContext context, dynamic quranData) {
    final theme = Theme.of(context);

    return Column(
      children: [
        CustomAppBar(
          category: CustomAppBarCategory(text: 'القرآن'),
        ),
        SizedBox(height: 12.h),
        SquareLogo(
          category: SquareLogoCategory(
            image: 'assets/icons/QuRan.png',
          ),
        ),
        SizedBox(height: 14.h),
        _SearchBox(
          controller: searchController,
          onChanged: onSearchTextChanged,
          onClear: clearSearch,
        ),
        SizedBox(height: 12.h),
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
                          'السور',
                          style: TextStyle(
                            fontFamily: 'cairo',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${filteredIndexes.length.toString().toArabicNumbers} سورة',
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
                    child: filteredIndexes.isEmpty
                        ? Center(
                      child: Text(
                        'لا توجد سورة بهذا الاسم',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: 'cairo',
                          fontSize: 12.sp,
                          color: Colors.white,
                        ),
                      ),
                    )
                        : ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(14.r),
                        topRight: Radius.circular(14.r),
                      ),
                      child: ListView.builder(
                        physics: const ClampingScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemExtent: listTileHeight.h,
                        cacheExtent: listTileHeight.h * 8,
                        itemCount: filteredIndexes.length,
                        itemBuilder: (context, listIndex) {
                          final suraIndex = filteredIndexes[listIndex];

                          return _SuraListTile(
                            index: suraIndex,
                            height: listTileHeight.h,
                            onTap: () async {
                              await openQuranReader(
                                context: context,
                                quranData: quranData,
                                suraIndex: suraIndex,
                              );
                            },
                          );
                        },
                      ),
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

  Widget _buildLargeScreenContent(BuildContext context, dynamic quranData) {
    final theme = Theme.of(context);
    final bool isFold = _QuranAdaptiveSizes.isFoldLandscape(context);
    final double horizontalPadding = isFold ? 18 : 26;
    final int crossAxisCount = isFold ? 2 : 3;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          18,
          horizontalPadding,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LargePageTitle(
              title: 'فهرس السور',
              subtitle: '${filteredIndexes.length.toString().toArabicNumbers} سورة',
              onBack: () => Navigator.maybePop(context),
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isFold ? 520 : 680),
              child: _SearchBox(
                controller: searchController,
                onChanged: onSearchTextChanged,
                onClear: clearSearch,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
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
                          'السور',
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
                          '${filteredIndexes.length.toString().toArabicNumbers} سورة',
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
                      child: filteredIndexes.isEmpty
                          ? const Center(
                        child: Text(
                          'لا توجد سورة بهذا الاسم',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontFamily: 'cairo',
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      )
                          : GridView.builder(
                        physics: const ClampingScrollPhysics(),
                        padding: EdgeInsets.zero,
                        gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: isFold ? 8 : 10,
                          crossAxisSpacing: isFold ? 8 : 10,
                          mainAxisExtent: isFold ? 60 : 66,
                        ),
                        itemCount: filteredIndexes.length,
                        itemBuilder: (context, listIndex) {
                          final suraIndex = filteredIndexes[listIndex];

                          return _SuraListTile(
                            index: suraIndex,
                            height: isFold ? 60 : 66,
                            large: true,
                            onTap: () async {
                              await openQuranReader(
                                context: context,
                                quranData: quranData,
                                suraIndex: suraIndex,
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

class _SearchBox extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBox({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  State<_SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<_SearchBox> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(updateClearButton);
  }

  void updateClearButton() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(updateClearButton);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isLargeScreen = MediaQuery.sizeOf(context).width >= 600;

    final backgroundColor =
    isDark ? const Color(0xff222837) : theme.colorScheme.secondary;

    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white60 : Colors.black45;
    final iconColor = isDark ? Colors.white70 : Colors.black54;

    final hasText = widget.controller.text.trim().isNotEmpty;

    return Container(
      height: isLargeScreen ? 42 : 35.h,
      margin: EdgeInsets.symmetric(horizontal: isLargeScreen ? 0 : 16.w),
      padding: EdgeInsets.symmetric(horizontal: isLargeScreen ? 14 : 12.w),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(isLargeScreen ? 20 : 22.r),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: TextField(
          controller: widget.controller,
          onChanged: widget.onChanged,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontFamily: 'cairo',
            fontSize: isLargeScreen ? 12 : 12.5.sp,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
          cursorColor: theme.colorScheme.primary,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'البحث عن السورة',
            hintTextDirection: TextDirection.rtl,
            hintStyle: TextStyle(
              fontFamily: 'cairo',
              fontSize: isLargeScreen ? 11.5 : 12.sp,
              fontWeight: FontWeight.w500,
              color: hintColor,
            ),
            suffixIcon: Icon(
              Icons.search_rounded,
              size: isLargeScreen ? 19 : 18.sp,
              color: iconColor,
            ),
            suffixIconConstraints: BoxConstraints(
              minWidth: isLargeScreen ? 30 : 28.w,
              minHeight: isLargeScreen ? 24 : 22.h,
            ),
            prefixIcon: hasText
                ? GestureDetector(
              onTap: () {
                AppHaptics.tap(context);
                widget.onClear();
              },
              child: Icon(
                Icons.close_rounded,
                size: isLargeScreen ? 18 : 18.sp,
                color: iconColor,
              ),
            )
                : null,
            prefixIconConstraints: BoxConstraints(
              minWidth: isLargeScreen ? 28 : 25.w,
              minHeight: isLargeScreen ? 28 : 25.h,
            ),
            contentPadding: EdgeInsets.only(
              top: isLargeScreen ? 12 : 11.h,
              bottom: isLargeScreen ? 9 : 8.h,
            ),
          ),
        ),
      ),
    );
  }
}

class _SuraListTile extends StatelessWidget {
  final int index;
  final double height;
  final VoidCallback onTap;
  final bool large;

  const _SuraListTile({
    required this.index,
    required this.height,
    required this.onTap,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEven = index % 2 == 0;

    return Material(
      color: isEven ? const Color(0xffFDF7E6) : const Color(0xffFDFBF0),
      borderRadius: BorderRadius.circular(large ? 14 : 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(large ? 14 : 0),
        onTap: () {
          AppHaptics.tap(context);
          onTap();
        },
        child: SizedBox(
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(large ? 14 : 0),
              border: large
                  ? null
                  : const Border(
                bottom: BorderSide(
                  color: Color(0xffDDD6C2),
                  width: 0.5,
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: large ? 12 : 10.w),
              child: Row(
                textDirection: TextDirection.rtl,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        arabicName[index]['name'],
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        strutStyle: StrutStyle(
                          fontSize: large ? 21 : 20.sp,
                          height: 1.05,
                          forceStrutHeight: true,
                        ),
                        style: TextStyle(
                          fontFamily: 'quran',
                          fontSize: large ? 21 : 20.sp,
                          height: 1.05,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: large ? 8 : 8.w),
                  SizedBox(
                    width: large ? 68 : 58.w,
                    child: Center(
                      child: Text(
                        'آياتها ${noOfVerses[index].toString().toArabicNumbers}',
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: 'cairo',
                          fontSize: large ? 9.5 : 9.sp,
                          height: 1,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: large ? 8 : 8.w),
                  SizedBox(
                    width: large ? 46 : 52.w,
                    height: height,
                    child: Center(
                      child: Transform.translate(
                        offset: Offset(0, large ? -3 : -3.h),
                        child: ArabicSuraNumber(i: index),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: _QuranAdaptiveSizes.pageTitle(context),
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
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: _QuranAdaptiveSizes.subtitle(context),
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
