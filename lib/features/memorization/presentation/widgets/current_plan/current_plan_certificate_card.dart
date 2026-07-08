import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/memorization/results/models/memorization_course_certificate.dart';

class CurrentPlanCertificateCard extends StatelessWidget {
  const CurrentPlanCertificateCard({
    super.key,
    required this.certificate,
    required this.onTap,
  });

  final MemorizationCourseCertificate certificate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.secondary,
      borderRadius: BorderRadius.circular(22.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22.r),
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                color: colors.primary,
                size: 32.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'شهادة إتمام رمزية',
                      maxLines: 3,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.body(context).copyWith(
                        color: colors.surface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'درجتك النهائية ${certificate.finalScore}% • اضغط لعرض الشهادة',
                      maxLines: 3,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.caption(
                        context,
                      ).copyWith(color: colors.surface.withOpacity(0.65)),
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
