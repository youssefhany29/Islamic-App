part of 'hadith_api_books_page.dart';

class _ImportHadithResult {
  const _ImportHadithResult({
    required this.category,
    required this.benefit,
    required this.lesson,
  });

  final HadithCategoryModel category;
  final String benefit;
  final String lesson;
}

class _ImportHadithSheet extends StatefulWidget {
  const _ImportHadithSheet({required this.hadith, required this.categories});

  final HadithApiHadithModel hadith;
  final List<HadithCategoryModel> categories;

  @override
  State<_ImportHadithSheet> createState() => _ImportHadithSheetState();
}

class _ImportHadithSheetState extends State<_ImportHadithSheet> {
  late HadithCategoryModel _selectedCategory;
  late TextEditingController _benefitController;
  late TextEditingController _lessonController;

  @override
  void initState() {
    super.initState();

    _selectedCategory = widget.categories.first;

    _benefitController = TextEditingController(
      text: 'يساعدني هذا الحديث على تحويل المعنى إلى سلوك يومي واضح.',
    );

    _lessonController = TextEditingController(
      text:
          'أتعلم منه أن أختار معنى واحدًا وأطبقه اليوم بدل الاكتفاء بالقراءة.',
    );
  }

  @override
  void dispose() {
    _benefitController.dispose();
    _lessonController.dispose();
    super.dispose();
  }

  void _save() {
    if (_benefitController.text.trim().isEmpty ||
        _lessonController.text.trim().isEmpty) {
      return;
    }

    Navigator.pop(
      context,
      _ImportHadithResult(
        category: _selectedCategory,
        benefit: _benefitController.text.trim(),
        lesson: _lessonController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isLargeScreen = _hadithLibraryLargeScreen(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: isLargeScreen ? 18 : 12.w,
            right: isLargeScreen ? 18 : 12.w,
            bottom:
                MediaQuery.of(context).viewInsets.bottom +
                (isLargeScreen ? 18 : 12.h),
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(isLargeScreen ? 18 : 14.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              borderRadius: BorderRadius.circular(isLargeScreen ? 28 : 24.r),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.28),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'إضافة الحديث إلى الكروت',
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: AppTextStyles.body(context).copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.surface,
                    ),
                  ),
                  SizedBox(height: isLargeScreen ? 7 : 6.h),
                  Text(
                    'اختار القسم، وعدّل الفائدة والنقطة المستفادة قبل الإضافة.',
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: AppTextStyles.caption(context).copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.surface.withOpacity(0.62),
                      height: 1.45,
                    ),
                  ),
                  SizedBox(height: isLargeScreen ? 14 : 12.h),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: isLargeScreen ? 8 : 8.w,
                    runSpacing: isLargeScreen ? 8 : 8.h,
                    children: widget.categories.map((category) {
                      final selected = category.id == _selectedCategory.id;

                      return InkWell(
                        borderRadius: BorderRadius.circular(
                          isLargeScreen ? 12 : 12.r,
                        ),
                        onTap: () {
                          AppHaptics.tap(context);
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: EdgeInsets.symmetric(
                            horizontal: isLargeScreen ? 12 : 10.w,
                            vertical: isLargeScreen ? 8 : 7.h,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.primary.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(
                              isLargeScreen ? 12 : 12.r,
                            ),
                          ),
                          child: Text(
                            category.title,
                            textDirection: TextDirection.rtl,
                            style: AppTextStyles.caption(context).copyWith(
                              fontWeight: FontWeight.w800,
                              color: selected
                                  ? Colors.white
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: isLargeScreen ? 14 : 12.h),
                  _ImportTextField(
                    controller: _benefitController,
                    label: 'ماذا يضيف لحياتك؟',
                    maxLines: 3,
                  ),
                  SizedBox(height: isLargeScreen ? 11 : 10.h),
                  _ImportTextField(
                    controller: _lessonController,
                    label: 'النقطة التي نتعلمها',
                    maxLines: 3,
                  ),
                  SizedBox(height: isLargeScreen ? 14 : 12.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isLargeScreen ? 13 : 11.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            isLargeScreen ? 16 : 15.r,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        textDirection: TextDirection.rtl,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            size: isLargeScreen ? 20 : 18.sp,
                          ),
                          SizedBox(width: isLargeScreen ? 7 : 6.w),
                          Text(
                            'إضافة إلى ${_selectedCategory.title}',
                            textDirection: TextDirection.rtl,
                            style: AppTextStyles.caption(
                              context,
                            ).copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
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

class _ImportTextField extends StatelessWidget {
  const _ImportTextField({
    required this.controller,
    required this.label,
    required this.maxLines,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isLargeScreen = _hadithLibraryLargeScreen(context);

    return TextField(
      controller: controller,
      maxLines: maxLines,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      cursorColor: theme.colorScheme.primary,
      style: AppTextStyles.caption(context).copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.surface,
        height: 1.45,
      ),
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
        labelStyle: AppTextStyles.caption(context).copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
        ),
        filled: true,
        fillColor: theme.colorScheme.primary.withOpacity(0.055),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isLargeScreen ? 14 : 12.w,
          vertical: isLargeScreen ? 12 : 10.h,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isLargeScreen ? 16 : 14.r),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.28),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isLargeScreen ? 16 : 14.r),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.28),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isLargeScreen ? 16 : 14.r),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.2),
        ),
      ),
    );
  }
}
