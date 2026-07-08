import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class NightPrayBestTimeCard extends StatelessWidget {
  final String? nightRangeText;
  final String? lastThirdStartText;
  final bool hasPrayerTimes;

  const NightPrayBestTimeCard({
    super.key,
    required this.nightRangeText,
    required this.lastThirdStartText,
    required this.hasPrayerTimes,
  });

  @override
  Widget build(BuildContext context) {
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
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 30.w,
                height: 30.w,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.dark_mode_rounded,
                  color: const Color(0xffffb300),
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'أفضل وقت لقيام الليل',
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
                    color: Colors.white
),
                ),
              ),
            ],
          ),

          SizedBox(height: 8.h),

          Text(
            'اختيارات قيام الليل تُفتح فقط من بعد العشاء إلى قبل الفجر، وأفضل أوقاته الثلث الأخير من الليل.',
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(context).copyWith(
height: 1.5,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.72)
),
          ),

          SizedBox(height: 10.h),

          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: 10.w,
              vertical: 9.h,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(13.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.10),
                width: 0.8.w,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _TimeLine(
                  label: 'وقت الليل',
                  value: hasPrayerTimes
                      ? (nightRangeText ?? 'غير متاح الآن')
                      : 'يظهر بعد توفر مواقيت الصلاة',
                ),
                SizedBox(height: 6.h),
                _TimeLine(
                  label: 'بداية الثلث الأخير',
                  value: hasPrayerTimes
                      ? (lastThirdStartText ?? 'غير متاح الآن')
                      : 'افتح صفحة الصلاة مرة واحدة لتحديث المواقيت',
                  highlight: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeLine extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _TimeLine({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Text(
          label,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.62)
),
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.left,
            textDirection: TextDirection.rtl,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
              color: highlight ? const Color(0xff21C58E) : Colors.white
),
          ),
        ),
      ],
    );
  }
}