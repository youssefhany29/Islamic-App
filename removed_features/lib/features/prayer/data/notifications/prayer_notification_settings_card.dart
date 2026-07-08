import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';
import 'package:islamic_app/features/prayer/data/notifications/prayer_sound_preview_player.dart';
import 'package:provider/provider.dart';

import 'package:islamic_app/shared/widgets/common_components/expandable_settings_card.dart';
import 'prayer_notification_settings_provider.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';

class PrayerNotificationSettingsCard extends StatelessWidget {
  const PrayerNotificationSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PrayerNotificationSettingsProvider>(context);

    return ExpandableSettingsCard(
      title: 'تذكير الصلاة',
      subtitle: 'اختار تذكيرات الصلاة، أصواتها، وتنبيهات التقدم اليومية.',
      icon: Icons.mosque_rounded,
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
                : 'تفعيل تذكيرات الصلاة',
            value: provider.enabled,
            onChanged: provider.isChanging
                ? null
                : (value) {
                    provider.setEnabled(value);
                  },
          ),

          SizedBox(height: 10.h),

          _SwitchSettingRow(
            title: 'تنبيه عند دخول وقت الصلاة',
            value: provider.notifyAtPrayerTime,
            onChanged: provider.enabled
                ? (value) {
                    provider.setNotifyAtPrayerTime(value);
                  }
                : null,
          ),

          SizedBox(height: 10.h),

          _SwitchSettingRow(
            title: 'إشعار حالة الصلاة الحية',
            value: provider.liveStatusEnabled,
            onChanged: (value) {
              provider.setLiveStatusEnabled(value);
            },
          ),

          SizedBox(height: 10.h),

          _SwitchSettingRow(
            title: 'تنبيه قبل الصلاة',
            value: provider.notifyBeforePrayer,
            onChanged: provider.enabled
                ? (value) {
                    provider.setNotifyBeforePrayer(value);
                  }
                : null,
          ),

          if (provider.notifyBeforePrayer) ...[
            SizedBox(height: 10.h),
            _BeforeMinutesSelector(
              selectedMinutes: provider.notifyBeforeMinutes,
              enabled: provider.enabled,
              onSelected: provider.setNotifyBeforeMinutes,
            ),
          ],

          SizedBox(height: 10.h),

          _PrayerSoundModeSection(provider: provider),

          SizedBox(height: 14.h),

          _SelectedPrayersSection(provider: provider),

          SizedBox(height: 14.h),

          _ProgressNotificationOptionsSection(provider: provider),

          SizedBox(height: 14.h),

          _NightPrayReminderSection(provider: provider),

          SizedBox(height: 12.h),

          Text(
            provider.enabled
                ? 'سيتم استخدام آخر مواقيت صلاة محفوظة لديك عند جدولة تذكيرات الصلوات.'
                : 'تذكيرات الصلاة مغلقة، لكن يمكنك تفعيل قيام الليل من نفس الكارت بشكل مستقل.',
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
                color: enabled ? Colors.white : Colors.white.withOpacity(0.45),
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

class _BeforeMinutesSelector extends StatelessWidget {
  final int selectedMinutes;
  final bool enabled;
  final ValueChanged<int> onSelected;

  const _BeforeMinutesSelector({
    required this.selectedMinutes,
    required this.enabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const options = [5, 10, 15];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: const Color(0xff171B26),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'وقت التنبيه قبل الصلاة',
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.caption(context).copyWith(
              fontWeight: FontWeight.w700,
              color: enabled ? Colors.white : Colors.white.withOpacity(0.45),
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: options.map((minutes) {
              final bool selected = selectedMinutes == minutes;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3.w),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12.r),
                    onTap: enabled
                        ? () {
                            AppHaptics.tap(context);
                            onSelected(minutes);
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
                        '$minutes دقائق',
                        style: AppTextStyles.caption(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: enabled ? Colors.white : Colors.white38,
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

class _PrayerSoundModeSection extends StatelessWidget {
  final PrayerNotificationSettingsProvider provider;

  const _PrayerSoundModeSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    final bool sectionEnabled = provider.enabled && provider.notifyAtPrayerTime;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: const Color(0xff171B26),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'صوت تنبيه الصلاة',
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.caption(context).copyWith(
              fontWeight: FontWeight.w800,
              color: sectionEnabled
                  ? Colors.white
                  : Colors.white.withOpacity(0.45),
            ),
          ),

          SizedBox(height: 8.h),

          _SwitchSettingRow(
            title: 'تفعيل صوت التنبيه',
            value: provider.prayerSoundEnabled,
            onChanged: sectionEnabled
                ? (value) {
                    provider.setPrayerSoundEnabled(value);
                  }
                : null,
          ),

          if (provider.prayerSoundEnabled) ...[
            SizedBox(height: 10.h),

            _SoundModeOption(
              title: 'حان الآن موعد الصلاة',
              subtitle: 'صوت لموعد الصلاة',
              icon: Icons.record_voice_over_rounded,
              selected: provider.soundMode == PrayerSoundMode.prayerVoice,
              enabled: sectionEnabled,
              onTap: () {
                provider.setSoundMode(PrayerSoundMode.prayerVoice);
              },
            ),

            if (provider.soundMode == PrayerSoundMode.prayerVoice) ...[
              SizedBox(height: 10.h),
              _PrayerVoicePreviewSection(enabled: sectionEnabled),
            ],

            SizedBox(height: 8.h),

            _SoundModeOption(
              title: 'صوت الأذان',
              subtitle: 'اختيار مؤذن معين لجميع الصلوات',
              icon: Icons.mosque_rounded,
              selected: provider.soundMode == PrayerSoundMode.azan,
              enabled: sectionEnabled,
              onTap: () {
                provider.setSoundMode(PrayerSoundMode.azan);
              },
            ),

            if (provider.soundMode == PrayerSoundMode.azan) ...[
              SizedBox(height: 10.h),
              _AzanSoundSelector(provider: provider),
            ],
          ],
        ],
      ),
    );
  }
}

class _SoundModeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _SoundModeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = selected
        ? const Color(0xff21C58E)
        : Colors.white.withOpacity(0.08);

    final Color borderColor = selected
        ? const Color(0xff21C58E)
        : Colors.white.withOpacity(0.14);

    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: enabled
          ? () {
              AppHaptics.tap(context);
              onTap();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        height: 58.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: borderColor, width: 0.8.w),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 205.w,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        title,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption(context).copyWith(
                          fontWeight: FontWeight.w800,
                          color: enabled ? Colors.white : Colors.white38,
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),

                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        subtitle,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption(context).copyWith(
                          fontWeight: FontWeight.w500,
                          color: enabled
                              ? Colors.white.withOpacity(0.72)
                              : Colors.white30,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Align(
              alignment: Alignment.centerLeft,
              child: Icon(
                selected ? Icons.radio_button_checked_rounded : icon,
                color: enabled ? Colors.white : Colors.white38,
                size: 18.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerVoicePreviewSection extends StatelessWidget {
  final bool enabled;

  const _PrayerVoicePreviewSection({required this.enabled});

  @override
  Widget build(BuildContext context) {
    final List<_PrayerVoiceOption> options = const [
      _PrayerVoiceOption(sound: 'prayer_fajr', title: 'الفجر'),
      _PrayerVoiceOption(sound: 'prayer_dhuhr', title: 'الظهر'),
      _PrayerVoiceOption(sound: 'prayer_asr', title: 'العصر'),
      _PrayerVoiceOption(sound: 'prayer_maghrib', title: 'المغرب'),
      _PrayerVoiceOption(sound: 'prayer_isha', title: 'العشاء'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'استمع للأصوات',
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: AppTextStyles.caption(context).copyWith(
            fontWeight: FontWeight.w700,
            color: enabled ? Colors.white.withOpacity(0.85) : Colors.white38,
          ),
        ),

        SizedBox(height: 8.h),

        Column(
          children: options.map((option) {
            return Padding(
              padding: EdgeInsets.only(bottom: 7.h),
              child: _PreviewSoundRow(
                title: option.title,
                soundName: option.sound,
                selected: false,
                enabled: enabled,
                onSelect: null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PrayerVoiceOption {
  final String sound;
  final String title;

  const _PrayerVoiceOption({required this.sound, required this.title});
}

class _AzanSoundSelector extends StatelessWidget {
  final PrayerNotificationSettingsProvider provider;

  const _AzanSoundSelector({required this.provider});

  @override
  Widget build(BuildContext context) {
    final List<_AzanOption> options = const [
      _AzanOption(sound: 'azan_1', title: 'المؤذن الأول'),
      _AzanOption(sound: 'azan_2', title: 'المؤذن الثاني'),
      _AzanOption(sound: 'azan_3', title: 'المؤذن الثالث'),
      _AzanOption(sound: 'azan_4', title: 'المؤذن الرابع'),
      _AzanOption(sound: 'azan_5', title: 'المؤذن الخامس'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'اختيار المؤذن',
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: AppTextStyles.caption(context).copyWith(
            fontWeight: FontWeight.w700,
            color: provider.enabled
                ? Colors.white.withOpacity(0.85)
                : Colors.white38,
          ),
        ),

        SizedBox(height: 8.h),

        Column(
          children: options.map((option) {
            final bool selected = provider.selectedAzanSound == option.sound;

            return Padding(
              padding: EdgeInsets.only(bottom: 7.h),
              child: _PreviewSoundRow(
                title: option.title,
                soundName: option.sound,
                selected: selected,
                enabled: provider.enabled,
                onSelect: () {
                  provider.setSelectedAzanSound(option.sound);
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _AzanOption {
  final String sound;
  final String title;

  const _AzanOption({required this.sound, required this.title});
}

class _PreviewSoundRow extends StatelessWidget {
  final String title;
  final String soundName;
  final bool selected;
  final bool enabled;
  final VoidCallback? onSelect;

  const _PreviewSoundRow({
    required this.title,
    required this.soundName,
    required this.selected,
    required this.enabled,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final previewPlayer = PrayerSoundPreviewPlayer();

    return InkWell(
      borderRadius: BorderRadius.circular(14.r),
      onTap: enabled && onSelect != null
          ? () {
              AppHaptics.tap(context);
              onSelect!();
            }
          : null,
      child: Container(
        width: double.infinity,
        height: 38.h,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xff21C58E)
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: selected
                ? const Color(0xff21C58E)
                : Colors.white.withOpacity(0.14),
            width: 0.8.w,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(left: 34.w),
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: enabled ? Colors.white : Colors.white38,
                  ),
                ),
              ),
            ),

            Align(
              alignment: Alignment.centerLeft,
              child: ValueListenableBuilder<String?>(
                valueListenable: previewPlayer.currentSoundName,
                builder: (context, currentSoundName, child) {
                  final bool isPlaying = currentSoundName == soundName;

                  return InkWell(
                    borderRadius: BorderRadius.circular(20.r),
                    onTap: enabled
                        ? () {
                            AppHaptics.tap(context);
                            previewPlayer.toggleSound(soundName);
                          }
                        : null,
                    child: Icon(
                      isPlaying
                          ? Icons.stop_circle_rounded
                          : Icons.play_circle_fill_rounded,
                      color: enabled ? Colors.white : Colors.white38,
                      size: 21.sp,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedPrayersSection extends StatelessWidget {
  final PrayerNotificationSettingsProvider provider;

  const _SelectedPrayersSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: const Color(0xff171B26),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'الصلوات المختارة',
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: provider.enabled
                        ? Colors.white
                        : Colors.white.withOpacity(0.45),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              _SmallTextButton(
                title: 'الكل',
                enabled: provider.enabled,
                onTap: provider.selectAllPrayers,
              ),
              SizedBox(width: 6.w),
              _SmallTextButton(
                title: 'إلغاء',
                enabled: provider.enabled,
                onTap: provider.clearSelectedPrayers,
              ),
            ],
          ),

          SizedBox(height: 8.h),

          Column(
            children: PrayerNotificationSettingsProvider.defaultPrayers.map((
              prayer,
            ) {
              final bool selected = provider.selectedPrayers.contains(prayer);

              return Padding(
                padding: EdgeInsets.only(bottom: 7.h),
                child: _SelectedPrayerRow(
                  title: prayer,
                  selected: selected,
                  enabled: provider.enabled,
                  onTap: () {
                    provider.togglePrayerSelection(prayer);
                  },
                ),
              );
            }).toList(),
          ),

          SizedBox(height: 1.h),

          Text(
            provider.selectedPrayersText,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(context).copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.62),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedPrayerRow extends StatelessWidget {
  final String title;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _SelectedPrayerRow({
    required this.title,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14.r),
      onTap: enabled
          ? () {
              AppHaptics.tap(context);
              onTap();
            }
          : null,
      child: Container(
        width: double.infinity,
        height: 38.h,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xff21C58E)
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: selected
                ? const Color(0xff21C58E)
                : Colors.white.withOpacity(0.14),
            width: 0.8.w,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(left: 34.w),
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: enabled ? Colors.white : Colors.white38,
                  ),
                ),
              ),
            ),

            Align(
              alignment: Alignment.centerLeft,
              child: Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: enabled ? Colors.white : Colors.white38,
                size: 21.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressNotificationOptionsSection extends StatelessWidget {
  final PrayerNotificationSettingsProvider provider;

  const _ProgressNotificationOptionsSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: const Color(0xff171B26),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'تنبيهات التقدم والتحفيز',
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.caption(context).copyWith(
              fontWeight: FontWeight.w800,
              color: provider.enabled
                  ? Colors.white
                  : Colors.white.withOpacity(0.45),
            ),
          ),

          SizedBox(height: 8.h),

          _SwitchSettingRow(
            title: 'تذكيرات تسجيل الصلاة',
            value: provider.progressRemindersEnabled,
            onChanged: provider.enabled
                ? (value) {
                    provider.setProgressRemindersEnabled(value);
                  }
                : null,
          ),

          SizedBox(height: 8.h),

          _SwitchSettingRow(
            title: 'ملخص صلوات اليوم',
            value: provider.dailySummaryEnabled,
            onChanged: provider.enabled
                ? (value) {
                    provider.setDailySummaryEnabled(value);
                  }
                : null,
          ),

          SizedBox(height: 8.h),

          _SwitchSettingRow(
            title: 'إشعارات الإنجازات',
            value: provider.achievementNotificationsEnabled,
            onChanged: provider.enabled
                ? (value) {
                    provider.setAchievementNotificationsEnabled(value);
                  }
                : null,
          ),

          SizedBox(height: 8.h),

          _SwitchSettingRow(
            title: 'تذكير أذكار بعد الصلاة',
            value: provider.afterPrayerAzkarReminderEnabled,
            onChanged: provider.enabled
                ? (value) {
                    provider.setAfterPrayerAzkarReminderEnabled(value);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

class _NightPrayReminderSection extends StatelessWidget {
  final PrayerNotificationSettingsProvider provider;

  const _NightPrayReminderSection({required this.provider});

  Future<void> _pickTime(BuildContext context) async {
    AppHaptics.tap(context);

    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: provider.nightPrayReminderTime,
      helpText: 'اختار وقت تذكير قيام الليل',
      cancelText: 'إلغاء',
      confirmText: 'حفظ',
      builder: (context, child) {
        final ColorScheme colorScheme = ColorScheme.fromSeed(
          seedColor: const Color(0xff23456B),
          brightness: Brightness.light,
          primary: const Color(0xff23456B),
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: const Color(0xff202124),
        );

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: colorScheme,
              dialogBackgroundColor: Colors.white,
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xff23456B),
                  textStyle: const TextStyle(
                    fontFamily: 'cairo',
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              timePickerTheme: TimePickerThemeData(
                backgroundColor: Colors.white,
                hourMinuteColor: const Color(0xff23456B),
                hourMinuteTextColor: Colors.white,
                dayPeriodColor: MaterialStateColor.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return const Color(0xff23456B);
                  }
                  return Colors.white;
                }),
                dayPeriodTextColor: MaterialStateColor.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return Colors.white;
                  }
                  return const Color(0xff0F172A);
                }),
                dialBackgroundColor: const Color(0xffF2F3F8),
                dialHandColor: const Color(0xff23456B),
                dialTextColor: const Color(0xff0F172A),
                entryModeIconColor: const Color(0xff23456B),
                helpTextStyle: AppTextStyles.caption(context).copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xff0F172A),
                ),
              ),
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );

    if (selectedTime == null) return;

    await provider.setNightPrayReminderTime(selectedTime);
  }

  @override
  Widget build(BuildContext context) {
    final bool sectionEnabled = !provider.isChanging;
    final bool canPickTime =
        sectionEnabled && provider.nightPrayReminderEnabled;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: const Color(0xff171B26),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Icon(
                Icons.nightlight_round,
                color: sectionEnabled ? Colors.white : Colors.white38,
                size: 18.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'قيام الليل',
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: sectionEnabled
                        ? Colors.white
                        : Colors.white.withOpacity(0.45),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 8.h),

          _SwitchSettingRow(
            title: 'ذكرني بقيام الليل',
            value: provider.nightPrayReminderEnabled,
            onChanged: sectionEnabled
                ? (value) {
                    provider.setNightPrayReminderEnabled(value);
                  }
                : null,
          ),

          if (provider.nightPrayReminderEnabled) ...[
            SizedBox(height: 8.h),
            InkWell(
              borderRadius: BorderRadius.circular(14.r),
              onTap: canPickTime ? () => _pickTime(context) : null,
              child: Container(
                width: double.infinity,
                height: 42.h,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
                decoration: BoxDecoration(
                  color: const Color(0xffFFF8EA).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: const Color(0xffFFF8EA).withOpacity(0.22),
                    width: 0.8.w,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: canPickTime ? Colors.white : Colors.white38,
                      size: 20.sp,
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      provider.nightPrayReminderTimeText,
                      style: AppTextStyles.caption(context).copyWith(
                        fontWeight: FontWeight.w800,
                        color: canPickTime ? Colors.white : Colors.white38,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        'وقت التذكير',
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: AppTextStyles.caption(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: canPickTime
                              ? Colors.white.withOpacity(0.86)
                              : Colors.white38,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'سيصلك تذكير يومي في الوقت المختار حتى لو تذكيرات الصلوات غير مفعّلة.',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.caption(context).copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.62),
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SmallTextButton extends StatelessWidget {
  final String title;
  final bool enabled;
  final VoidCallback onTap;

  const _SmallTextButton({
    required this.title,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10.r),
      onTap: enabled
          ? () {
              AppHaptics.tap(context);
              onTap();
            }
          : null,
      child: Container(
        height: 26.h,
        padding: EdgeInsets.symmetric(horizontal: 9.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Text(
          title,
          style: AppTextStyles.caption(context).copyWith(
            fontWeight: FontWeight.w700,
            color: enabled ? Colors.white : Colors.white38,
          ),
        ),
      ),
    );
  }
}
