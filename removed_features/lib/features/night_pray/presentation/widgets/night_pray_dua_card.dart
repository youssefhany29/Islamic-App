import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';
import 'package:share_plus/share_plus.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class NightPrayDuaCard extends StatelessWidget {
  final String dua;
  final VoidCallback onChangeDua;

  const NightPrayDuaCard({
    super.key,
    required this.dua,
    required this.onChangeDua,
  });

  Future<void> _shareDua(BuildContext context) async {
    AppHaptics.tap(context);

    await SharePlus.instance.share(
      ShareParams(
        text: '$dua\n\nمن تطبيق ديني في جيبي 🌙',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
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
                Icon(
                  Icons.volunteer_activism_rounded,
                  color: const Color(0xffffb300),
                  size: 18.sp,
                ),
                SizedBox(width: 7.w),
                Expanded(
                  child: Text(
                    'دعاء قيام الليل',
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

            SizedBox(height: 7.h),

            Text(
              dua,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.72),
                height: 1.45
),
            ),

            SizedBox(height: 10.h),

            Row(
              children: [
                Expanded(
                  child: _DuaButton(
                    text: 'تغيير الدعاء',
                    icon: Icons.refresh_rounded,
                    onTap: onChangeDua,
                  ),
                ),

                SizedBox(width: 8.w),

                Expanded(
                  child: _DuaButton(
                    text: 'مشاركة',
                    icon: Icons.share_rounded,
                    onTap: () => _shareDua(context),
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

class _DuaButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const _DuaButton({
    required this.text,
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
          height: 32.h,
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 14.sp,
              ),
              SizedBox(width: 5.w),
              Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w700,
                  color: Colors.white
),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
