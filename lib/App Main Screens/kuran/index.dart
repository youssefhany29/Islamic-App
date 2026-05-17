import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/App%20Main%20Screens/App%20Main%20Screens%20Components/custom_app_bar.dart';

import '../../Common Components/SquareLogo.dart';
import 'arabic_sura_number.dart';
import 'surah_builder.dart';
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

    searchDebounce = Timer(const Duration(milliseconds: 500), () {
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
                return const Center(
                  child: Text('حدث خطأ أثناء تحميل القرآن'),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: Text('لا توجد بيانات'),
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

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: _SearchBox(
                      controller: searchController,
                      isDark: isDark,
                      onChanged: onSearchTextChanged,
                      onClear: clearSearch,
                    ),
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
                                  itemExtent: 38.h,
                                  itemCount: filteredIndexes.length,
                                  itemBuilder: (context, listIndex) {
                                    final suraIndex =
                                    filteredIndexes[listIndex];

                                    return _SuraListTile(
                                      index: suraIndex,
                                      onTap: () {
                                        fabIsClicked = false;

                                        Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            pageBuilder: (
                                                context,
                                                animation,
                                                secondaryAnimation,
                                                ) =>
                                                SurahBuilder(
                                                  arabic: snapshot.data[0],
                                                  sura: suraIndex,
                                                  suraName:
                                                  arabicName[suraIndex]
                                                  ['name'],
                                                  ayah: 0,
                                                ),
                                            transitionDuration:
                                            Duration.zero,
                                            reverseTransitionDuration:
                                            Duration.zero,
                                          ),
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
  final bool isDark;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBox({
    required this.controller,
    required this.isDark,
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
    final textColor = widget.isDark ? Colors.white : Colors.black;
    final hintColor = widget.isDark ? Colors.white54 : Colors.black45;
    final fillColor =
    widget.isDark ? const Color(0xff171B26) : const Color(0xffDEE9EF);

    return SizedBox(
      height: 34.h,
      child: TextField(
        controller: widget.controller,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        onChanged: widget.onChanged,
        style: TextStyle(
          fontFamily: 'cairo',
          fontSize: 10.sp,
          color: textColor,
        ),
        decoration: InputDecoration(
          hintText: 'البحث عن السورة',
          hintTextDirection: TextDirection.rtl,
          hintStyle: TextStyle(
            fontFamily: 'cairo',
            fontSize: 9.sp,
            color: hintColor,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 16.sp,
            color: widget.isDark ? Colors.white70 : Colors.black54,
          ),
          suffixIcon: widget.controller.text.isEmpty
              ? null
              : IconButton(
            onPressed: widget.onClear,
            icon: Icon(
              Icons.close,
              size: 15.sp,
              color: widget.isDark ? Colors.white60 : Colors.black45,
            ),
          ),
          filled: true,
          fillColor: fillColor,
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18.r),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _SuraListTile extends StatelessWidget {
  final int index;
  final VoidCallback onTap;

  const _SuraListTile({
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEven = index % 2 == 0;

    return Material(
      color: isEven ? const Color(0xffFDF7E6) : const Color(0xffFDFBF0),
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 38.h,
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Color(0xffDDD6C2),
                width: 0.4,
              ),
            ),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: Text(
                  arabicName[index]['name'],
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'quran',
                    fontSize: 22.sp,
                    color: Colors.black87,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                'آياتها ${noOfVerses[index].toString().toArabicNumbers}',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: 8.sp,
                  color: Colors.black54,
                ),
              ),
              SizedBox(width: 8.w),
              ArabicSuraNumber(i: index),
            ],
          ),
        ),
      ),
    );
  }
}