import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/shared/widgets/app_main_components/custom_app_bar.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import 'package:islamic_app/features/azkar/data/models/zekr_item_model.dart';
import 'package:islamic_app/features/azkar/data/services/zekr_custom_storage_service.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';

class AddCustomZekrPage extends StatefulWidget {
  const AddCustomZekrPage({super.key, this.itemToEdit});

  final ZekrItemModel? itemToEdit;

  bool get isEditing => itemToEdit != null;

  @override
  State<AddCustomZekrPage> createState() => _AddCustomZekrPageState();
}

class _AddCustomZekrPageState extends State<AddCustomZekrPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _textController;
  late final TextEditingController _benefitController;
  late final TextEditingController _countController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final item = widget.itemToEdit;

    _titleController = TextEditingController(text: item?.title ?? '');
    _textController = TextEditingController(text: item?.text ?? '');
    _benefitController = TextEditingController(text: item?.benefit ?? '');
    _countController = TextEditingController(text: '${item?.count ?? 1}');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    _benefitController.dispose();
    _countController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;

    AppHaptics.tap(context);

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final int count = int.tryParse(_countController.text.trim()) ?? 1;
    final service = const ZekrCustomStorageService();

    if (widget.isEditing) {
      await service.updateCustomZekr(
        id: widget.itemToEdit!.id,
        title: _titleController.text.trim(),
        text: _textController.text.trim(),
        benefit: _benefitController.text.trim(),
        count: count <= 0 ? 1 : count,
      );
    } else {
      await service.addCustomZekr(
        title: _titleController.text.trim(),
        text: _textController.text.trim(),
        benefit: _benefitController.text.trim(),
        count: count <= 0 ? 1 : count,
      );
    }

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: CustomAppBar(
        category: CustomAppBarCategory(
          text: widget.isEditing ? 'تعديل الذكر' : 'إضافة ذكر',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 18.h),
          physics: const BouncingScrollPhysics(),
          children: [
            Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(
                      isDark ? 0.18 : 0.38,
                    ),
                    width: 1,
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        textDirection: TextDirection.rtl,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 42.w,
                            height: 42.w,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(
                                0.10,
                              ),
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            child: Icon(
                              widget.isEditing
                                  ? Icons.edit_rounded
                                  : Icons.edit_note_rounded,
                              color: theme.colorScheme.primary,
                              size: 24.sp,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    widget.isEditing
                                        ? 'عدّل الذكر الخاص بك'
                                        : 'أضف ذكر أو دعاء خاص بك',
                                    textAlign: TextAlign.right,
                                    textDirection: TextDirection.rtl,
                                    locale: const Locale('ar'),
                                    style: theme.textTheme.headlineLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          height: 1.3,
                                        ),
                                  ),
                                ),
                                SizedBox(height: 3.h),
                                SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    widget.isEditing
                                        ? 'غيّر النص أو العنوان أو عدد التكرار، وسيتم حفظ التعديل مباشرة.'
                                        : 'اكتب الذكر، وحدد عدد التكرار، وسيظهر في قسم أذكاري الخاصة.',
                                    textAlign: TextAlign.right,
                                    textDirection: TextDirection.rtl,
                                    locale: const Locale('ar'),
                                    softWrap: true,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.surface
                                          .withOpacity(0.64),
                                      height: 1.45,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 14.h),

                      _CustomTextField(
                        controller: _titleController,
                        label: 'عنوان اختياري',
                        hint: 'مثال: دعاء قبل المذاكرة',
                      ),

                      SizedBox(height: 10.h),

                      _CustomTextField(
                        controller: _textController,
                        label: 'نص الذكر',
                        hint: 'اكتب الذكر هنا',
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'اكتب نص الذكر أولًا';
                          }

                          return null;
                        },
                      ),

                      SizedBox(height: 10.h),

                      _CustomTextField(
                        controller: _countController,
                        label: 'عدد التكرار',
                        hint: '1',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          final int? count = int.tryParse(value?.trim() ?? '');

                          if (count == null || count <= 0) {
                            return 'اكتب رقم صحيح أكبر من 0';
                          }

                          return null;
                        },
                      ),

                      SizedBox(height: 10.h),

                      _CustomTextField(
                        controller: _benefitController,
                        label: 'ملاحظة أو فضل اختياري',
                        hint: 'مثال: يريح القلب ويذكرني بالتوكل',
                        maxLines: 3,
                      ),

                      SizedBox(height: 16.h),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _save,
                          icon: _isSaving
                              ? SizedBox(
                                  width: 16.w,
                                  height: 16.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  widget.isEditing
                                      ? Icons.check_rounded
                                      : Icons.save_rounded,
                                ),
                          label: Text(
                            _isSaving
                                ? 'جاري الحفظ...'
                                : widget.isEditing
                                ? 'حفظ التعديل'
                                : 'حفظ الذكر',
                            textDirection: TextDirection.rtl,
                          ),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: theme.colorScheme.primary,
                            disabledBackgroundColor: theme.colorScheme.primary
                                .withOpacity(0.45),
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.white.withOpacity(
                              0.70,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 11.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.r),
                            ),
                            textStyle: AppTextStyles.caption(
                              context,
                            ).copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomTextField extends StatelessWidget {
  const _CustomTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
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
          hintText: hint,
          alignLabelWithHint: maxLines > 1,
          labelStyle: AppTextStyles.caption(context).copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
          hintStyle: AppTextStyles.caption(context).copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.surface.withOpacity(0.42),
          ),
          filled: true,
          fillColor: theme.colorScheme.primary.withOpacity(
            isDark ? 0.10 : 0.045,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 11.h,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.28),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withOpacity(
                isDark ? 0.20 : 0.34,
              ),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 1.2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: const BorderSide(color: Color(0xffEF4444), width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: const BorderSide(color: Color(0xffEF4444), width: 1.2),
          ),
        ),
      ),
    );
  }
}
