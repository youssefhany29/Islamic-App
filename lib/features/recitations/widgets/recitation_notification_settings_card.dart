import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/features/recitations/settings/recitation_notification_settings_provider.dart';
import 'package:islamic_app/core/services/app_haptics.dart';
import 'package:provider/provider.dart';

import 'package:islamic_app/shared/widgets/common_components/expandable_settings_card.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class RecitationNotificationSettingsCard extends StatelessWidget {
  const RecitationNotificationSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider =
    Provider.of<RecitationNotificationSettingsProvider>(context);

    return ExpandableSettingsCard(
      title: 'إشعارات التلاوة',
      subtitle: 'إشعارات جوائز الاستماع وأهدافك الشخصية.',
      icon: Icons.headphones_rounded,
      initiallyExpanded: false,
      children: [
        if (!provider.isLoaded)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20.h),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          )
        else ...[
          _SwitchSettingRow(
            title: provider.isChanging
                ? 'جاري التحديث...'
                : 'تفعيل إشعارات التلاوة',
            value: provider.enabled,
            onChanged: provider.isChanging
                ? null
                : (value) {
              provider.setEnabled(value);
            },
          ),

          SizedBox(height: 10.h),

          _SwitchSettingRow(
            title: 'إشعارات جوائز الاستماع',
            value: provider.achievementNotificationsEnabled,
            onChanged: provider.enabled
                ? (value) {
              provider.setAchievementNotificationsEnabled(value);
            }
                : null,
          ),

          SizedBox(height: 10.h),

          _SwitchSettingRow(
            title: 'إشعارات أهدافي',
            value: provider.personalGoalNotificationsEnabled,
            onChanged: provider.enabled
                ? (value) {
              provider.setPersonalGoalNotificationsEnabled(value);
            }
                : null,
          ),

          SizedBox(height: 12.h),

          Text(
            provider.enabled
                ? 'سيتم إرسال إشعار عند فتح جائزة جديدة أو اكتمال هدف شخصي.'
                : 'فعّل إشعارات التلاوة لاستخدام هذه الإعدادات.',
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.75),
              height: 1.4
),
          ),
        ],
      ],
    );
  }
}

class _SwitchSettingRow extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SwitchSettingRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = onChanged != null;

    return Container(
      height: 42.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: const Color(0xff171B26),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 0.7.w,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w600,
                color: enabled
                    ? Colors.white.withOpacity(0.88)
                    : Colors.white.withOpacity(0.38)
),
            ),
          ),

          SizedBox(width: 10.w),

          Transform.scale(
            scale: 0.82,
            child: Switch.adaptive(
              value: value,
              activeColor: const Color(0xff21C58E),
              onChanged: onChanged == null
                  ? null
                  : (newValue) {
                AppHaptics.tap(context);
                onChanged!(newValue);
              },
            ),
          ),
        ],
      ),
    );
  }
}