import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class AfterPrayerDuaCard extends StatelessWidget {
  final bool large;
  final String dua;
  final VoidCallback onChangeDua;
  final VoidCallback onOpenAzkar;

  const AfterPrayerDuaCard({
    super.key,
    this.large = false,
    required this.dua,
    required this.onChangeDua,
    required this.onOpenAzkar,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: large ? 10 : 12.w,
          vertical: large ? 9 : 11.h,
        ),
        decoration: BoxDecoration(
          color: const Color(0xff171B26),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'دعاء بعد الصلاة',
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
                  color: Colors.white
),
              ),
            ),

            SizedBox(height: large ? 6 : 7.h),

            Align(
              alignment: Alignment.centerRight,
              child: Text(
                dua,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.72),
                  height: 1.45
),
              ),
            ),

            SizedBox(height: large ? 8 : 10.h),

            Row(
              children: [
                Expanded(
                  child: _SmallActionButton(
                    large: large,
                    title: 'أذكار بعد الصلاة',
                    icon: Icons.menu_book_rounded,
                    onTap: onOpenAzkar,
                  ),
                ),
                SizedBox(width: large ? 8 : 8.w),
                Expanded(
                  child: _SmallActionButton(
                    large: large,
                    title: 'تغيير الدعاء',
                    icon: Icons.refresh_rounded,
                    onTap: onChangeDua,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  final bool large;
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _SmallActionButton({
    required this.large,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primary,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: () {
          AppHaptics.tap(context);
          onTap();
        },
        child: Container(
          height: large ? 30 : 32.h,
          padding: EdgeInsets.symmetric(horizontal: large ? 7 : 8.w),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w700,
                    color: Colors.white
),
                ),
              ),
              SizedBox(width: large ? 5 : 5.w),
              Icon(
                icon,
                color: Colors.white,
                size: large ? 13 : 14.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
