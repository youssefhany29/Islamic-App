import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class NightPrayVirtuesCard extends StatelessWidget {
  const NightPrayVirtuesCard({super.key});

  static const List<_VirtueItem> _virtues = [
    _VirtueItem(
      title: 'أفضل النوافل',
      subtitle: 'من أفضل الصلوات بعد الفريضة.',
      icon: Icons.workspace_premium_rounded,
    ),
    _VirtueItem(
      title: 'وقت خلوة',
      subtitle: 'تجمع فيه بين الصلاة والدعاء والقرآن.',
      icon: Icons.nights_stay_rounded,
    ),
    _VirtueItem(
      title: 'طمأنينة القلب',
      subtitle: 'ركعات قليلة بخشوع أفضل من كثرة بلا حضور.',
      icon: Icons.favorite_rounded,
    ),
  ];

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
          Text(
            'من فضائل قيام الليل',
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
              color: Colors.white
),
          ),

          SizedBox(height: 9.h),

          Column(
            children: _virtues.map((virtue) {
              return Padding(
                padding: EdgeInsets.only(bottom: 7.h),
                child: _VirtueLine(virtue: virtue),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _VirtueLine extends StatelessWidget {
  final _VirtueItem virtue;

  const _VirtueLine({
    required this.virtue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Container(
          width: 28.w,
          height: 28.w,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(9.r),
          ),
          child: Icon(
            virtue.icon,
            color: const Color(0xffffb300),
            size: 16.sp,
          ),
        ),

        SizedBox(width: 8.w),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                virtue.title,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
                  color: Colors.white
),
              ),
              SizedBox(height: 2.h),
              Text(
                virtue.subtitle,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.66)
),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VirtueItem {
  final String title;
  final String subtitle;
  final IconData icon;

  const _VirtueItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}