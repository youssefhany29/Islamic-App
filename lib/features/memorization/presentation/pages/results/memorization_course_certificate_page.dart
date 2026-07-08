import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/memorization/results/models/memorization_course_certificate.dart';

class MemorizationCourseCertificatePage extends StatelessWidget {
  const MemorizationCourseCertificatePage({
    super.key,
    required this.certificate,
    this.onOpenCompletedPlans,
  });

  final MemorizationCourseCertificate certificate;
  final VoidCallback? onOpenCompletedPlans;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('شهادة الإتمام الرمزية')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(18.w),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: colors.secondary,
              borderRadius: BorderRadius.circular(26.r),
              border: Border.all(color: colors.primary.withOpacity(0.35)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.workspace_premium_rounded,
                  size: 58.sp,
                  color: colors.primary,
                ),
                SizedBox(height: 12.h),
                Text(
                  'شهادة إتمام رمزية',
                  maxLines: 3,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headline(context).copyWith(
                    color: colors.surface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 12.h),
                _line(context, 'الاسم', certificate.userName),
                _line(context, 'الخطة', certificate.planName),
                _line(context, 'النطاق', certificate.scopeTitle),
                _line(context, 'الالتزام', '${certificate.commitmentPercent}%'),
                _line(
                  context,
                  'متوسط الاختبارات',
                  certificate.testsEnabled
                      ? '${certificate.testsAveragePercent}%'
                      : 'لم تكن الاختبارات مفعّلة في هذه الخطة',
                ),
                _line(context, 'الدرجة النهائية', '${certificate.finalScore}%'),
                _line(
                  context,
                  'الأيام المكتملة',
                  '${certificate.completedDays} يوم',
                ),
                SizedBox(height: 14.h),
                Text(
                  certificate.finalScore >= 85
                      ? 'أتممت الرحلة بثبات رائع، بارك الله في جهدك.'
                      : 'أتممت الرحلة، واستمرار المراجعة هو أجمل ما يحفظ هذا الإنجاز.',
                  maxLines: 3,
                  softWrap: true,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(context).copyWith(
                    color: colors.surface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  MemorizationCourseCertificate.disclaimer,
                  maxLines: 3,
                  softWrap: true,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption(context).copyWith(
                    color: colors.surface.withOpacity(0.65),
                    height: 1.5,
                  ),
                ),
                if (onOpenCompletedPlans != null) ...[
                  SizedBox(height: 12.h),
                  OutlinedButton.icon(
                    onPressed: onOpenCompletedPlans,
                    icon: const Icon(Icons.workspace_premium_rounded),
                    label: const Text('الخطط المكتملة'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _line(BuildContext context, String label, String value) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: 9.h),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110.w,
            child: Text(
              label,
              maxLines: 3,
              textAlign: TextAlign.right,
              style: AppTextStyles.caption(
                context,
              ).copyWith(color: colors.primary, fontWeight: FontWeight.w900),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 3,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: AppTextStyles.caption(
                context,
              ).copyWith(color: colors.surface, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
