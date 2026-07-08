import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/shared/widgets/app_main_components/custom_app_bar.dart';
import 'package:islamic_app/core/adaptive/adaptive_side_navigation.dart';
import 'package:islamic_app/core/adaptive/adaptive_large_screen_shell.dart';
import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/home/presentation/adaptive/home_large_screen_navigation.dart';
import 'package:islamic_app/features/settings/app_settings_drawer.dart';
import 'package:islamic_app/features/quran/main_quraan_components/to_arabic_no_converter.dart';
import 'package:islamic_app/core/services/app_haptics.dart';
import 'quran_wird_storage.dart';
part 'create_khatma_widgets.dart';

class CreateKhatmaPage extends StatefulWidget {
  const CreateKhatmaPage({super.key});

  @override
  State<CreateKhatmaPage> createState() => _CreateKhatmaPageState();
}

class _CreateKhatmaPageState extends State<CreateKhatmaPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const String headerImageAsset =
      'assets/quran/create_khatma_header.png';

  final TextEditingController nameController = TextEditingController();

  int selectedDays = 30;
  bool isSaving = false;

  static const List<int> quickOptions = [7, 10, 15, 30, 60, 90];

  int get pagesPerDay {
    return (604 / selectedDays).ceil();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> createKhatma() async {
    AppHaptics.medium(context);
    if (isSaving) return;

    final khatmaName = nameController.text.trim();

    if (khatmaName.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.primary,
          elevation: 0,
          margin: EdgeInsets.only(left: 24.w, right: 24.w, bottom: 18.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
          content: Text(
            'اكتب اسم الورد أو الختمة أولًا',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: 11.sp,
              color: Colors.white,
            ),
          ),
          duration: const Duration(milliseconds: 1200),
        ),
      );

      return;
    }

    setState(() {
      isSaving = true;
    });

    await QuranWirdStorage.createKhatmaPlan(
      name: khatmaName,
      totalDays: selectedDays,
    );

    if (!mounted) return;

    setState(() {
      isSaving = false;
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        margin: EdgeInsets.only(left: 24.w, right: 24.w, bottom: 18.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        content: Text(
          'تم إنشاء "$khatmaName" بنجاح',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'cairo',
            fontSize: 11.sp,
            color: Colors.white,
          ),
        ),
        duration: const Duration(milliseconds: 1200),
      ),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;

    final fieldColor = isDark
        ? const Color(0xff222837)
        : theme.colorScheme.secondary;

    final softCardColor = isDark
        ? const Color(0xff222837)
        : theme.colorScheme.secondary;

    final unselectedChipColor = isDark
        ? const Color(0xff222837)
        : theme.colorScheme.secondary;

    final unselectedChipTextColor = isDark ? Colors.white70 : Colors.black87;

    final bool isLargeScreen = MediaQuery.sizeOf(context).width >= 600;

    if (isLargeScreen) {
      return _buildLargeScreenScaffold(
        context: context,
        textColor: textColor,
        secondaryTextColor: secondaryTextColor,
        fieldColor: fieldColor,
        softCardColor: softCardColor,
        unselectedChipColor: unselectedChipColor,
        unselectedChipTextColor: unselectedChipTextColor,
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(category: CustomAppBarCategory(text: 'إنشاء ختمة')),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeaderCard(
                      selectedDays: selectedDays,
                      pagesPerDay: pagesPerDay,
                    ),
                    SizedBox(height: 18.h),
                    Text(
                      'اسم الورد أو الختمة',
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    TextField(
                      controller: nameController,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                      cursorColor: theme.colorScheme.primary,
                      decoration: InputDecoration(
                        hintText: 'مثال: ورد رمضان، ختمة السفر، ورد يومي',
                        hintTextDirection: TextDirection.rtl,
                        hintStyle: TextStyle(
                          fontFamily: 'cairo',
                          fontSize: 10.5.sp,
                          color: secondaryTextColor,
                        ),
                        filled: true,
                        fillColor: fieldColor,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 12.h,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(
                          Icons.edit_note_rounded,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'اختر مدة الختمة',
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      alignment: WrapAlignment.end,
                      children: [
                        for (final days in quickOptions)
                          _DayChoiceChip(
                            days: days,
                            isSelected: selectedDays == days,
                            selectedColor: theme.colorScheme.primary,
                            unselectedColor: unselectedChipColor,
                            selectedTextColor: Colors.white,
                            unselectedTextColor: unselectedChipTextColor,
                            onTap: () {
                              AppHaptics.tap(context);
                              setState(() {
                                selectedDays = days;
                              });
                            },
                          ),
                      ],
                    ),
                    SizedBox(height: 22.h),
                    Container(
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        color: softCardColor,
                        borderRadius: BorderRadius.circular(18.r),
                      ),
                      child: Column(
                        children: [
                          Row(
                            textDirection: TextDirection.rtl,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'عدد الأيام',
                                style: TextStyle(
                                  fontFamily: 'cairo',
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                selectedDays.toString().toArabicNumbers,
                                style: TextStyle(
                                  fontFamily: 'cairo',
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: theme.colorScheme.primary,
                              inactiveTrackColor: isDark
                                  ? Colors.white24
                                  : Colors.black26,
                              thumbColor: theme.colorScheme.primary,
                              overlayColor: theme.colorScheme.primary
                                  .withOpacity(0.18),
                            ),
                            child: Slider(
                              min: 7,
                              max: 120,
                              divisions: 113,
                              value: selectedDays.toDouble(),
                              onChanged: (value) {
                                setState(() {
                                  selectedDays = value.round();
                                });
                              },
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            'سيكون وردك اليومي تقريبًا ${pagesPerDay.toString().toArabicNumbers} صفحة',
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'cairo',
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),
                    SizedBox(
                      height: 45.h,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : createKhatma,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: theme.colorScheme.primary,
                          disabledBackgroundColor: theme.colorScheme.primary
                              .withOpacity(0.45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                        child: Text(
                          isSaving ? 'جاري الحفظ...' : 'إنشاء الختمة',
                          style: TextStyle(
                            fontFamily: 'cairo',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      'يمكنك إنشاء أكثر من ورد، وكل ورد سيظهر داخل صفحة ورد اليوم.',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: 10.sp,
                        color: secondaryTextColor,
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

  Widget _buildLargeScreenScaffold({
    required BuildContext context,
    required Color textColor,
    required Color secondaryTextColor,
    required Color fieldColor,
    required Color softCardColor,
    required Color unselectedChipColor,
    required Color unselectedChipTextColor,
  }) {
    final theme = Theme.of(context);
    final Size size = MediaQuery.sizeOf(context);
    final bool isRealTablet = size.shortestSide >= 600;
    final double panelPadding = isRealTablet ? 22 : 14;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: adaptiveSidePanelColor(context),
      endDrawer: AppSettingsDrawer(),
      body: SafeArea(
        child: AdaptiveLargeScreenShell(
          navigationItems: homeLargeScreenNavigationItems(
            context,
            onHomeTap: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            onSettingsTap: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
          selectedNavigationId: 'quran',
          userName: 'المسلم',
          greetingMessage: 'رفيقك في كل حين',
          quickItems: const [],
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: EdgeInsets.all(panelPadding),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _LargeCreateKhatmaTitle(
                      onBack: () => Navigator.maybePop(context),
                    ),
                    const SizedBox(height: 14),
                    _LargeHeaderCard(
                      selectedDays: selectedDays,
                      pagesPerDay: pagesPerDay,
                      imageAsset: headerImageAsset,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'اسم الورد أو الختمة',
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: AppTextStyles.body(
                        context,
                      ).copyWith(fontWeight: FontWeight.w800, color: textColor),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: _LargeCreateKhatmaSizes.cardSubtitle(context),
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                      cursorColor: theme.colorScheme.primary,
                      decoration: InputDecoration(
                        hintText: 'مثال: ورد رمضان، ختمة السفر، ورد يومي',
                        hintTextDirection: TextDirection.rtl,
                        hintStyle: TextStyle(
                          fontFamily: 'cairo',
                          fontSize: _LargeCreateKhatmaSizes.cardSubtitle(
                            context,
                          ),
                          color: secondaryTextColor,
                        ),
                        filled: true,
                        fillColor: fieldColor,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(
                          Icons.edit_note_rounded,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'اختر مدة الختمة',
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: AppTextStyles.body(
                        context,
                      ).copyWith(fontWeight: FontWeight.w800, color: textColor),
                    ),
                    const SizedBox(height: 14),
                    _LargeDurationOptionsRow(
                      quickOptions: quickOptions,
                      selectedDays: selectedDays,
                      selectedColor: theme.colorScheme.primary,
                      unselectedColor: unselectedChipColor,
                      selectedTextColor: Colors.white,
                      unselectedTextColor: unselectedChipTextColor,
                      onSelectDays: (days) {
                        AppHaptics.tap(context);
                        setState(() => selectedDays = days);
                      },
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: softCardColor,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            textDirection: TextDirection.rtl,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'عدد الأيام',
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontFamily: 'cairo',
                                  fontSize:
                                      _LargeCreateKhatmaSizes.cardSubtitle(
                                        context,
                                      ),
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                selectedDays.toString().toArabicNumbers,
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontFamily: 'cairo',
                                  fontSize:
                                      _LargeCreateKhatmaSizes.cardSubtitle(
                                        context,
                                      ),
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: theme.colorScheme.primary,
                              inactiveTrackColor:
                                  theme.brightness == Brightness.dark
                                  ? Colors.white24
                                  : Colors.black26,
                              thumbColor: theme.colorScheme.primary,
                              overlayColor: theme.colorScheme.primary
                                  .withOpacity(0.18),
                            ),
                            child: Slider(
                              min: 7,
                              max: 120,
                              divisions: 113,
                              value: selectedDays.toDouble(),
                              onChanged: (value) {
                                setState(() => selectedDays = value.round());
                              },
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'سيكون وردك اليومي تقريبًا ${pagesPerDay.toString().toArabicNumbers} صفحة',
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontFamily: 'cairo',
                              fontSize: _LargeCreateKhatmaSizes.cardSubtitle(
                                context,
                              ),
                              fontWeight: FontWeight.w600,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : createKhatma,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: theme.colorScheme.primary,
                          disabledBackgroundColor: theme.colorScheme.primary
                              .withOpacity(0.45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          isSaving ? 'جاري الحفظ...' : 'إنشاء الختمة',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontFamily: 'cairo',
                            fontSize: _LargeCreateKhatmaSizes.actionLabel(
                              context,
                            ),
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
