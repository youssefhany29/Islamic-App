import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class NightPrayHowToPrayCard extends StatelessWidget {
  const NightPrayHowToPrayCard({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = [
      'توضأ واستحضر النية بهدوء.',
      'صلِّ ركعتين ركعتين حسب استطاعتك.',
      'أطل السجود وادعُ الله بما في قلبك.',
      'اختم بالوتر إن لم تكن صليته.',
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 11.h,
      ),
      decoration: BoxDecoration(
        color: const Color(0xff171B26),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'كيف أصلي قيام الليل؟',
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
              color: Colors.white
),
          ),

          SizedBox(height: 9.h),

          for (int i = 0; i < steps.length; i++) ...[
            _StepLine(
              number: i + 1,
              text: steps[i],
            ),
            if (i != steps.length - 1) SizedBox(height: 7.h),
          ],
        ],
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  final int number;
  final String text;

  const _StepLine({
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 22.w,
          height: 22.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            '$number',
            style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
              color: Colors.white
),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.caption(context).copyWith(
height: 1.35,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.74)
),
          ),
        ),
      ],
    );
  }
}