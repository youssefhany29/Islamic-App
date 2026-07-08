import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class MemorizationPlanNameCard extends StatefulWidget {
  const MemorizationPlanNameCard({
    super.key,
    required this.initialName,
    required this.onChanged,
    this.focusNode,
    this.showErrorHighlight = false,
  });

  /// مثال مقترح فقط، لا يكتب داخل الحقل تلقائيًا.
  final String initialName;
  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;
  final bool showErrorHighlight;

  @override
  State<MemorizationPlanNameCard> createState() =>
      _MemorizationPlanNameCardState();
}

class _MemorizationPlanNameCardState extends State<MemorizationPlanNameCard> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    widget.onChanged('');
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = widget.showErrorHighlight;
    final suggestedName = widget.initialName.trim().isEmpty
        ? 'مثال: تثبيت سورة البقرة'
        : 'مثال: ${widget.initialName.trim()}';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      padding: EdgeInsets.all(13.w),
      decoration: BoxDecoration(
        color: hasError
            ? theme.colorScheme.error.withOpacity(0.08)
            : theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color: hasError
              ? theme.colorScheme.error.withOpacity(0.76)
              : theme.colorScheme.outline.withOpacity(0.14),
          width: hasError ? 1.5 : 1,
        ),
        boxShadow: hasError
            ? [
          BoxShadow(
            color: theme.colorScheme.error.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: hasError
                      ? theme.colorScheme.error.withOpacity(0.12)
                      : theme.colorScheme.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  Icons.edit_note_rounded,
                  color: hasError
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                  size: 21.sp,
                ),
              ),
              SizedBox(width: 9.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'اسم الخطة',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
                        color: theme.colorScheme.surface
),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      hasError
                          ? 'اكتب اسمًا بسيطًا للخطة حتى نكمل.'
                          : 'اختار اسمًا يساعدك تعرف رحلتك بسهولة.',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w600,
                        color: hasError
                            ? theme.colorScheme.error.withOpacity(0.88)
                            : theme.colorScheme.surface.withOpacity(0.55),
                        height: 1.35
),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: controller,
            focusNode: widget.focusNode,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            onChanged: (value) => widget.onChanged(value.trim()),
            cursorColor:
            hasError ? theme.colorScheme.error : theme.colorScheme.primary,
            style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w700,
              color: theme.colorScheme.surface
),
            decoration: InputDecoration(
              hintText: suggestedName,
              hintTextDirection: TextDirection.rtl,
              hintStyle: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w500,
                color: theme.colorScheme.surface.withOpacity(0.34)
),
              filled: true,
              fillColor: theme.colorScheme.background.withOpacity(0.40),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 11.h,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(
                  color: hasError
                      ? theme.colorScheme.error.withOpacity(0.65)
                      : theme.colorScheme.outline.withOpacity(0.12),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(
                  color: hasError
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                  width: 1.4,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
