import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';
import 'package:provider/provider.dart';

import 'package:islamic_app/shared/widgets/common_components/app_time_picker.dart';
import 'package:islamic_app/shared/widgets/common_components/expandable_settings_card.dart';
import '../notifications/hadith_notification_settings_provider.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';

class HadithNotificationSettingsCard extends StatelessWidget {
  const HadithNotificationSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<HadithNotificationSettingsProvider>(context);

    return ExpandableSettingsCard(
      title: 'إشعارات الأحاديث',
      subtitle: 'تذكير بتعلّم حديث جديد ومراجعة الأحاديث المحفوظة.',
      icon: Icons.auto_stories_rounded,
      initiallyExpanded: false,
      children: [
        if (!provider.isLoaded)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20.h),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          )
        else ...[
          _SwitchSettingRow(
            title: provider.isChanging
                ? 'جاري التحديث...'
                : 'تفعيل إشعارات الأحاديث',
            value: provider.enabled,
            onChanged: provider.isChanging
                ? null
                : (value) {
                    provider.setEnabled(value);
                  },
          ),

          SizedBox(height: 10.h),

          _TimeSettingRow(
            title: 'تذكير بتعلّم',
            enabled: provider.enabled && provider.learnEnabled,
            time: provider.learnTime,
            onSwitchChanged: provider.enabled
                ? (value) => provider.setLearnEnabled(value)
                : null,
            onPickTime: provider.enabled && provider.learnEnabled
                ? () => _pickTime(
                    context: context,
                    initialTime: provider.learnTime,
                    onPicked: provider.setLearnTime,
                  )
                : null,
          ),

          SizedBox(height: 10.h),

          _TimeSettingRow(
            title: 'تذكير بمراجعة',
            enabled: provider.enabled && provider.reviewEnabled,
            time: provider.reviewTime,
            onSwitchChanged: provider.enabled
                ? (value) => provider.setReviewEnabled(value)
                : null,
            onPickTime: provider.enabled && provider.reviewEnabled
                ? () => _pickTime(
                    context: context,
                    initialTime: provider.reviewTime,
                    onPicked: provider.setReviewTime,
                  )
                : null,
          ),

          SizedBox(height: 12.h),

          Text(
            provider.enabled
                ? 'تذكير المراجعة يظهر فقط لو خطة حفظ الأحاديث مفعّلة وفيه أحاديث مستحقة في يومها.'
                : 'فعّل إشعارات الأحاديث لاستخدام هذه الإعدادات.',
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.caption(context).copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.75),
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickTime({
    required BuildContext context,
    required TimeOfDay initialTime,
    required ValueChanged<TimeOfDay> onPicked,
  }) async {
    AppHaptics.tap(context);

    final picked = await showAppTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: 'اختر وقت التذكير',
    );

    if (picked == null) return;

    AppHaptics.light(context);
    onPicked(picked);
  }
}

class _SwitchSettingRow extends StatelessWidget {
  const _SwitchSettingRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onChanged != null;

    return Container(
      height: 42.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: const Color(0xff171B26),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.7.w),
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
                    : Colors.white.withOpacity(0.38),
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

class _TimeSettingRow extends StatelessWidget {
  const _TimeSettingRow({
    required this.title,
    required this.enabled,
    required this.time,
    required this.onSwitchChanged,
    required this.onPickTime,
  });

  final String title;
  final bool enabled;
  final TimeOfDay time;
  final ValueChanged<bool>? onSwitchChanged;
  final VoidCallback? onPickTime;

  String get _timeText {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final bool active = onSwitchChanged != null;

    return Container(
      height: 48.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xff171B26),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.7.w),
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
                color: active
                    ? Colors.white.withOpacity(0.88)
                    : Colors.white.withOpacity(0.38),
              ),
            ),
          ),

          SizedBox(width: 8.w),

          InkWell(
            onTap: onPickTime == null
                ? null
                : () {
                    AppHaptics.tap(context);
                    onPickTime!();
                  },
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(enabled ? 0.14 : 0.06),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: Colors.white.withOpacity(enabled ? 0.18 : 0.08),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    color: enabled
                        ? Colors.white
                        : Colors.white.withOpacity(0.35),
                    size: 15.sp,
                  ),
                  SizedBox(width: 5.w),
                  Text(
                    _timeText,
                    style: AppTextStyles.caption(context).copyWith(
                      fontWeight: FontWeight.w900,
                      color: enabled
                          ? Colors.white
                          : Colors.white.withOpacity(0.35),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(width: 8.w),

          Transform.scale(
            scale: 0.82,
            child: Switch.adaptive(
              value: enabled,
              activeColor: const Color(0xff21C58E),
              onChanged: onSwitchChanged == null
                  ? null
                  : (newValue) {
                      AppHaptics.tap(context);
                      onSwitchChanged!(newValue);
                    },
            ),
          ),
        ],
      ),
    );
  }
}
