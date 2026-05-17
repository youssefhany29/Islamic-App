import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/App%20Main%20Screens/App%20Main%20Screens%20Components/custom_app_bar.dart';

import '../../../Common Components/SquareLogo.dart';
import '../reader/quran_reader_page.dart';
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

  void openQuranReader({
    required BuildContext context,
    required dynamic quranData,
    required int suraIndex,
  }) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            QuranReaderPage(
              arabic: quranData[0],
              initialSuraIndex: suraIndex,
              initialAyahIndex: 0,
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
                                  physics:
                                  const ClampingScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  itemExtent: listTileHeight.h,
                                  cacheExtent: listTileHeight.h * 8,
                                  itemCount: filteredIndexes.length,
                                  itemBuilder: (context, listIndex) {
                                    final suraIndex =
                                    filteredIndexes[listIndex];

                                    return _SuraListTile(
                                      index: suraIndex,
                                      height: listTileHeight.h,
                                      onTap: () {
                                        openQuranReader(
                                          context: context,
                                          quranData: snapshot.data,
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
            },
          ),
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

    final backgroundColor =
    isDark ? const Color(0xff222837) : theme.colorScheme.secondary;

    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white60 : Colors.black45;
    final iconColor = isDark ? Colors.white70 : Colors.black54;

    final hasText = widget.controller.text.trim().isNotEmpty;

    return Container(
      height: 35.h,
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22.r),
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
            fontSize: 12.5.sp,
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
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: hintColor,
            ),
            suffixIcon: Icon(
              Icons.search_rounded,
              size: 18.sp,
              color: iconColor,
            ),
            suffixIconConstraints: BoxConstraints(
              minWidth: 28.w,
              minHeight: 22.h,
            ),
            prefixIcon: hasText
                ? GestureDetector(
              onTap: widget.onClear,
              child: Icon(
                Icons.close_rounded,
                size: 18.sp,
                color: iconColor,
              ),
            )
                : null,
            prefixIconConstraints: BoxConstraints(
              minWidth: 25.w,
              minHeight: 25.h,
            ),
            contentPadding: EdgeInsets.only(
              top: 11.h,
              bottom: 8.h,
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

  const _SuraListTile({
    required this.index,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEven = index % 2 == 0;

    return Material(
      color: isEven ? const Color(0xffFDF7E6) : const Color(0xffFDFBF0),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xffDDD6C2),
                  width: 0.5,
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
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
                          fontSize: 20.sp,
                          height: 1.05,
                          forceStrutHeight: true,
                        ),
                        style: TextStyle(
                          fontFamily: 'quran',
                          fontSize: 20.sp,
                          height: 1.05,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  SizedBox(
                    width: 58.w,
                    child: Center(
                      child: Text(
                        'آياتها ${noOfVerses[index].toString().toArabicNumbers}',
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: 'cairo',
                          fontSize: 9.sp,
                          height: 1,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  SizedBox(
                    width: 52.w,
                    height: height,
                    child: Center(
                      child: Transform.translate(
                        offset: Offset(0, -3.h),
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