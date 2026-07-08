import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import '../pages/memorization_manual_test_page.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class ManualMemorizationTestCard extends StatelessWidget {
  const ManualMemorizationTestCard({super.key});

  Future<void> _openManualTest(BuildContext context) async {
    AppHaptics.tap(context);

    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const MemorizationManualTestPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24.r),
        onTap: () => _openManualTest(context),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.13),
            ),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.11),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(
                  Icons.fact_check_rounded,
                  color: theme.colorScheme.primary,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'اختبرني',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
                        color: theme.colorScheme.surface
),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'اختبار حر في أي وقت: اختر الصعوبة، النطاق، وهل يكون عشوائيًا أو من البداية.',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w600,
                        color: theme.colorScheme.surface.withOpacity(0.58),
                        height: 1.4
),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Icons.arrow_back_ios_new_rounded,
                color: theme.colorScheme.surface.withOpacity(0.45),
                size: 14.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
