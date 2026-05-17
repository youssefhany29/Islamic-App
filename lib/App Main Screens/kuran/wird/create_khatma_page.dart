import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/App%20Main%20Screens/App%20Main%20Screens%20Components/custom_app_bar.dart';
import 'package:islamic_app/App%20Main%20Screens/kuran/main_quraan_components/to_arabic_no_converter.dart';
import 'quran_wird_storage.dart';

class CreateKhatmaPage extends StatefulWidget {
  const CreateKhatmaPage({super.key});

  @override
  State<CreateKhatmaPage> createState() => _CreateKhatmaPageState();
}

class _CreateKhatmaPageState extends State<CreateKhatmaPage> {
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
    nameController.text = 'ورد رمضان';
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> createKhatma() async {
    if (isSaving) return;

    final khatmaName = nameController.text.trim();

    if (khatmaName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.primary,
          content: const Text(
            'اكتب اسم الورد أو الختمة أولًا',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
        content: Text(
          'تم إنشاء "$khatmaName" بنجاح',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
        ),
      ),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onBackground;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              category: CustomAppBarCategory(text: 'إنشاء ختمة'),
            ),
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
                      decoration: InputDecoration(
                        hintText: 'مثال: ورد رمضان، ختمة السفر، ورد يومي',
                        hintTextDirection: TextDirection.rtl,
                        filled: true,
                        fillColor: theme.colorScheme.secondary,
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
                            onTap: () {
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
                        color: theme.colorScheme.secondary,
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
                                  color: Colors.black87,
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
                          Slider(
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
                          SizedBox(height: 6.h),
                          Text(
                            'سيكون وردك اليومي تقريبًا ${pagesPerDay.toString().toArabicNumbers} صفحة',
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'cairo',
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
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
                          disabledBackgroundColor:
                          theme.colorScheme.primary.withOpacity(0.45),
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
                        color: textColor.withOpacity(0.55),
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

class _HeaderCard extends StatelessWidget {
  final int selectedDays;
  final int pagesPerDay;

  const _HeaderCard({
    required this.selectedDays,
    required this.pagesPerDay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(22.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'خطة ختمة جديدة',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'اكتب اسم الورد، واختر عدد الأيام، وسنقسم المصحف إلى ورد يومي بالصفحات.',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: 11.sp,
              height: 1.6,
              color: Colors.white.withOpacity(0.82),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: _MiniInfoBox(
                  title: 'المدة',
                  value: '${selectedDays.toString().toArabicNumbers} يوم',
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _MiniInfoBox(
                  title: 'ورد يومي',
                  value: '${pagesPerDay.toString().toArabicNumbers} صفحة',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniInfoBox extends StatelessWidget {
  final String title;
  final String value;

  const _MiniInfoBox({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        children: [
          Text(
            title,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: 9.sp,
              color: Colors.white.withOpacity(0.72),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayChoiceChip extends StatelessWidget {
  final int days;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayChoiceChip({
    required this.days,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
        decoration: BoxDecoration(
          color:
          isSelected ? theme.colorScheme.primary : theme.colorScheme.secondary,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Text(
          '${days.toString().toArabicNumbers} يوم',
          style: TextStyle(
            fontFamily: 'cairo',
            fontSize: 11.sp,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}