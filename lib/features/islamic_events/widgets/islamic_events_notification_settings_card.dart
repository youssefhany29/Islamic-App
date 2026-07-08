import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/features/islamic_events/settings/islamic_events_notification_settings_provider.dart';
import 'package:islamic_app/core/services/app_haptics.dart';
import 'package:provider/provider.dart';

import 'package:islamic_app/shared/widgets/common_components/expandable_settings_card.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class IslamicEventsNotificationSettingsCard extends StatelessWidget {
  const IslamicEventsNotificationSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider =
    Provider.of<IslamicEventsNotificationSettingsProvider>(context);

    return ExpandableSettingsCard(
      title: 'تذكير المناسبات',
      subtitle: 'اختار تذكيرات الصيام، رمضان، العيد، ويوم عرفة.',
      icon: Icons.event_available_rounded,
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
                : 'تفعيل تذكيرات المناسبات',
            value: provider.enabled,
            onChanged: provider.isChanging
                ? null
                : (value) {
              provider.setEnabled(value);
            },
          ),
          SizedBox(height: 10.h),
          _SwitchSettingRow(
            title: 'تنبيه قبل المناسبة',
            value: provider.notifyBeforeEvent,
            onChanged: provider.enabled
                ? (value) {
              provider.setNotifyBeforeEvent(value);
            }
                : null,
          ),
          if (provider.notifyBeforeEvent) ...[
            SizedBox(height: 10.h),
            _BeforeDaysSelector(
              selectedDays: provider.notifyBeforeDays,
              enabled: provider.enabled,
              onSelected: provider.setNotifyBeforeDays,
            ),
          ],
          SizedBox(height: 14.h),
          _EventsTypesSection(
            provider: provider,
          ),
          SizedBox(height: 12.h),
          Text(
            provider.enabled
                ? 'سيتم إرسال تذكير قبل المناسبة حسب الوقت الذي تختاره.'
                : 'فعّل تذكيرات المناسبات لاستخدام هذه الإعدادات.',
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
                color: enabled ? Colors.white : Colors.white.withOpacity(0.45)
),
            ),
          ),
          Transform.scale(
            scale: 0.75,
            child: Switch(
              value: value,
              onChanged: onChanged == null
                  ? null
                  : (value) {
                AppHaptics.tap(context);
                onChanged!(value);
              },
              activeColor: Colors.white,
              activeTrackColor: const Color(0xff21C58E),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.black,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

class _BeforeDaysSelector extends StatelessWidget {
  final int selectedDays;
  final bool enabled;
  final ValueChanged<int> onSelected;

  const _BeforeDaysSelector({
    required this.selectedDays,
    required this.enabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const options = [1, 2, 3];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: const Color(0xff171B26),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 0.7.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'وقت التنبيه قبل المناسبة',
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w700,
              color: enabled ? Colors.white : Colors.white.withOpacity(0.45)
),
          ),
          SizedBox(height: 8.h),
          Row(
            children: options.map((days) {
              final bool selected = selectedDays == days;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3.w),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12.r),
                    onTap: enabled
                        ? () {
                      AppHaptics.tap(context);
                      onSelected(days);
                    }
                        : null,
                    child: Container(
                      height: 32.h,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xff21C58E)
                            : Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: selected
                              ? const Color(0xff21C58E)
                              : Colors.white.withOpacity(0.14),
                          width: 0.8.w,
                        ),
                      ),
                      child: Text(
                        days == 1 ? 'يوم' : '$days أيام',
                        style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w700,
                          color: enabled ? Colors.white : Colors.white38
),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _EventsTypesSection extends StatelessWidget {
  final IslamicEventsNotificationSettingsProvider provider;

  const _EventsTypesSection({
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final bool sectionEnabled = provider.enabled;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: const Color(0xff171B26),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 0.7.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'أنواع التذكيرات',
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
              color:
              sectionEnabled ? Colors.white : Colors.white.withOpacity(0.45)
),
          ),
          SizedBox(height: 10.h),
          _SwitchSettingRow(
            title: 'تذكيرات الصيام',
            value: provider.fastingRemindersEnabled,
            onChanged: sectionEnabled
                ? (value) {
              provider.setFastingRemindersEnabled(value);
            }
                : null,
          ),
          SizedBox(height: 10.h),
          _SwitchSettingRow(
            title: 'رمضان والعشر الأواخر',
            value: provider.ramadanRemindersEnabled,
            onChanged: sectionEnabled
                ? (value) {
              provider.setRamadanRemindersEnabled(value);
            }
                : null,
          ),
          SizedBox(height: 10.h),
          _SwitchSettingRow(
            title: 'تهاني العيد',
            value: provider.eidGreetingsEnabled,
            onChanged: sectionEnabled
                ? (value) {
              provider.setEidGreetingsEnabled(value);
            }
                : null,
          ),
          SizedBox(height: 10.h),
          _SwitchSettingRow(
            title: 'مناسبات أخرى',
            value: provider.specialDaysEnabled,
            onChanged: sectionEnabled
                ? (value) {
              provider.setSpecialDaysEnabled(value);
            }
                : null,
          ),
        ],
      ),
    );
  }
}
