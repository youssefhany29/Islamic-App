import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class NightPrayPlanCard extends StatelessWidget {
  final int selectedPlanIndex;
  final ValueChanged<int> onPlanSelected;

  const NightPrayPlanCard({
    super.key,
    required this.selectedPlanIndex,
    required this.onPlanSelected,
  });

  static const List<_NightPlan> _plans = [
    _NightPlan(
      title: 'خفيفة',
      subtitle: 'ركعتان + وتر',
      icon: Icons.spa_rounded,
    ),
    _NightPlan(
      title: 'متوسطة',
      subtitle: '٤ ركعات + دعاء',
      icon: Icons.auto_awesome_rounded,
    ),
    _NightPlan(
      title: 'قوية',
      subtitle: '٨ ركعات + قرآن',
      icon: Icons.workspace_premium_rounded,
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
            'خطة الليلة',
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
              color: Colors.white
),
          ),

          SizedBox(height: 4.h),

          Text(
            'اختار خطة بسيطة تناسب طاقتك الليلة، والمهم الاستمرار ولو بالقليل.',
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.caption(context).copyWith(
height: 1.4,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.68)
),
          ),

          SizedBox(height: 10.h),

          Row(
            children: List.generate(_plans.length, (index) {
              final plan = _plans[index];
              final bool selected = selectedPlanIndex == index;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 0 : 6.w,
                    right: index == _plans.length - 1 ? 0 : 6.w,
                  ),
                  child: Material(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14.r),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14.r),
                      onTap: () {
                        AppHaptics.tap(context);
                        onPlanSelected(index);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 9.h,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              plan.icon,
                              color: selected
                                  ? Colors.white
                                  : const Color(0xffffb300),
                              size: 18.sp,
                            ),
                            SizedBox(height: 5.h),
                            Text(
                              plan.title,
                              textAlign: TextAlign.center,
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
                              plan.subtitle,
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.68)
),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _NightPlan {
  final String title;
  final String subtitle;
  final IconData icon;

  const _NightPlan({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}