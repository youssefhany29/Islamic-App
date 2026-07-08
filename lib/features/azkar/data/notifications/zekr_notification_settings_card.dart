import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';
import 'package:provider/provider.dart';

import 'package:islamic_app/shared/widgets/common_components/app_time_picker.dart';
import 'package:islamic_app/shared/widgets/common_components/expandable_settings_card.dart';
import '../notifications/zekr_notification_settings_provider.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';

class ZekrNotificationSettingsCard extends StatelessWidget {
  const ZekrNotificationSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ZekrNotificationSettingsProvider>(context);

    return ExpandableSettingsCard(
      title: 'إشعارات الأذكار',
      subtitle: 'تذكير الصباح والمساء والنوم، وأذكار متغيرة طوال اليوم.',
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
                : 'تفعيل إشعارات الأذكار',
            value: provider.enabled,
            onChanged: provider.isChanging
                ? null
                : (value) {
                    provider.setEnabled(value);
                  },
          ),

          SizedBox(height: 10.h),

          _TimeSettingRow(
            title: 'أذكار الصباح',
            enabled: provider.enabled && provider.morningEnabled,
            time: provider.morningTime,
            onSwitchChanged: provider.enabled
                ? (value) => provider.setMorningEnabled(value)
                : null,
            onPickTime: provider.enabled && provider.morningEnabled
                ? () => _pickTime(
                    context: context,
                    initialTime: provider.morningTime,
                    onPicked: provider.setMorningTime,
                  )
                : null,
          ),

          SizedBox(height: 10.h),

          _TimeSettingRow(
            title: 'أذكار المساء',
            enabled: provider.enabled && provider.eveningEnabled,
            time: provider.eveningTime,
            onSwitchChanged: provider.enabled
                ? (value) => provider.setEveningEnabled(value)
                : null,
            onPickTime: provider.enabled && provider.eveningEnabled
                ? () => _pickTime(
                    context: context,
                    initialTime: provider.eveningTime,
                    onPicked: provider.setEveningTime,
                  )
                : null,
          ),

          SizedBox(height: 10.h),

          _TimeSettingRow(
            title: 'أذكار النوم',
            enabled: provider.enabled && provider.sleepEnabled,
            time: provider.sleepTime,
            onSwitchChanged: provider.enabled
                ? (value) => provider.setSleepEnabled(value)
                : null,
            onPickTime: provider.enabled && provider.sleepEnabled
                ? () => _pickTime(
                    context: context,
                    initialTime: provider.sleepTime,
                    onPicked: provider.setSleepTime,
                  )
                : null,
          ),

          SizedBox(height: 10.h),

          _TimeSettingRow(
            title: 'مراجعة الحفظ',
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

          _IntervalSettingRow(
            title: 'الصلاة على النبي ﷺ',
            subtitle: 'إشعار مستقل ومتكرر بالصلاة على النبي.',
            value: provider.salawatEnabled,
            intervalMinutes: provider.salawatIntervalMinutes,
            onChanged: provider.enabled
                ? (value) => provider.setSalawatEnabled(value)
                : null,
            onIntervalChanged: provider.enabled && provider.salawatEnabled
                ? provider.setSalawatIntervalMinutes
                : null,
          ),

          SizedBox(height: 10.h),

          _IntervalSettingRow(
            title: 'أدعية متغيرة',
            subtitle: 'دعاء مختلف في كل إشعار.',
            value: provider.duaRotationEnabled,
            intervalMinutes: provider.duaIntervalMinutes,
            onChanged: provider.enabled
                ? (value) => provider.setDuaRotationEnabled(value)
                : null,
            onIntervalChanged: provider.enabled && provider.duaRotationEnabled
                ? provider.setDuaIntervalMinutes
                : null,
          ),

          SizedBox(height: 10.h),

          _IntervalSettingRow(
            title: 'أذكار متغيرة',
            subtitle: 'ذكر مختلف في كل إشعار.',
            value: provider.zekrRotationEnabled,
            intervalMinutes: provider.zekrIntervalMinutes,
            onChanged: provider.enabled
                ? (value) => provider.setZekrRotationEnabled(value)
                : null,
            onIntervalChanged: provider.enabled && provider.zekrRotationEnabled
                ? provider.setZekrIntervalMinutes
                : null,
          ),

          SizedBox(height: 12.h),

          Text(
            provider.enabled
                ? 'إشعار مراجعة الحفظ لا يظهر إلا إذا كان عندك أذكار مستحقة في يومها. يمكنك أيضًا تخصيص أوقات الأذكار والإشعارات المتغيرة.'
                : 'فعّل إشعارات الأذكار لاستخدام هذه الإعدادات.',
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
            onTap: onPickTime,
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

class _IntervalSettingRow extends StatelessWidget {
  const _IntervalSettingRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.intervalMinutes,
    required this.onChanged,
    required this.onIntervalChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final int intervalMinutes;
  final ValueChanged<bool>? onChanged;
  final ValueChanged<int>? onIntervalChanged;

  String _intervalText(int minutes) {
    if (minutes == 1) return 'كل دقيقة';
    if (minutes == 15) return 'كل 15 دقيقة';
    if (minutes == 30) return 'كل 30 دقيقة';
    if (minutes == 60) return 'كل ساعة';
    if (minutes == 120) return 'كل ساعتين';
    if (minutes == 180) return 'كل 3 ساعات';

    return 'كل $minutes دقيقة';
  }

  @override
  Widget build(BuildContext context) {
    final bool active = onChanged != null;
    final bool controlsEnabled = value && onIntervalChanged != null;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xff171B26),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.7.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: AppTextStyles.caption(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: active
                            ? Colors.white.withOpacity(0.90)
                            : Colors.white.withOpacity(0.38),
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      subtitle,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      softWrap: true,
                      style: AppTextStyles.caption(context).copyWith(
                        fontWeight: FontWeight.w500,
                        color: active
                            ? Colors.white.withOpacity(0.62)
                            : Colors.white.withOpacity(0.30),
                        height: 1.4,
                      ),
                    ),
                  ],
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

          SizedBox(height: 8.h),

          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(controlsEnabled ? 0.14 : 0.06),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: Colors.white.withOpacity(
                    controlsEnabled ? 0.18 : 0.08,
                  ),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: intervalMinutes,
                  dropdownColor: const Color(0xff171B26),
                  iconEnabledColor: Colors.white,
                  iconDisabledColor: Colors.white.withOpacity(0.30),
                  style: AppTextStyles.caption(
                    context,
                  ).copyWith(fontWeight: FontWeight.w800, color: Colors.white),
                  items: const [1, 15, 30, 60, 120, 180]
                      .map(
                        (minutes) => DropdownMenuItem<int>(
                          value: minutes,
                          child: Text(
                            _intervalText(minutes),
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: controlsEnabled
                      ? (minutes) {
                          if (minutes == null) return;
                          AppHaptics.tap(context);
                          onIntervalChanged!(minutes);
                        }
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
