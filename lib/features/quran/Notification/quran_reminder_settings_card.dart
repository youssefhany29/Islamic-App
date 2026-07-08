import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/features/quran/Notification/quran_reminder_preferences.dart';
import 'package:islamic_app/features/quran/Notification/quran_reminder_scheduler.dart';
import 'package:islamic_app/core/services/app_haptics.dart';
import 'package:islamic_app/features/settings/notifications_settings_provider.dart';
import 'package:provider/provider.dart';

class QuranReminderSettingsCard extends StatefulWidget {
  const QuranReminderSettingsCard({super.key});

  @override
  State<QuranReminderSettingsCard> createState() =>
      _QuranReminderSettingsCardState();
}

class _QuranReminderSettingsCardState extends State<QuranReminderSettingsCard> {
  QuranReminderSettings _settings = const QuranReminderSettings(
    enabled: false,
    hour: QuranReminderPreferences.defaultHour,
    minute: QuranReminderPreferences.defaultMinute,
  );

  bool _isLoading = true;
  bool _isChanging = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await QuranReminderPreferences.getSettings();

    if (!mounted) return;

    setState(() {
      _settings = settings;
      _isLoading = false;
    });
  }

  Future<void> _setReminderEnabled({
    required bool value,
    required bool globalNotificationsEnabled,
  }) async {
    if (_isChanging || _isLoading) return;

    AppHaptics.tap(context);

    if (value && !globalNotificationsEnabled) {
      _showMessage('فعّل زر الإشعارات العام أولًا من الإعدادات');
      return;
    }

    setState(() {
      _isChanging = true;
    });

    await QuranReminderPreferences.setReminderEnabled(value);

    if (value) {
      await QuranReminderScheduler().scheduleDailyQuranReminder(
        hour: _settings.hour,
        minute: _settings.minute,
      );
    } else {
      await QuranReminderScheduler().cancelDailyQuranReminder();
    }

    if (!mounted) return;

    setState(() {
      _settings = _settings.copyWith(enabled: value);
      _isChanging = false;
    });

    _showMessage(value ? 'تم تفعيل تذكير الورد' : 'تم إيقاف تذكير الورد');
  }

  Future<void> _pickReminderTime({
    required bool globalNotificationsEnabled,
  }) async {
    if (_isChanging || _isLoading) return;

    AppHaptics.tap(context);

    if (!globalNotificationsEnabled) {
      _showMessage('فعّل زر الإشعارات العام أولًا من الإعدادات');
      return;
    }

    if (!_settings.enabled) {
      _showMessage('فعّل تذكير الورد أولًا');
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _settings.hour,
        minute: _settings.minute,
      ),
      helpText: 'اختار وقت تذكير الورد',
      cancelText: 'إلغاء',
      confirmText: 'حفظ',
      initialEntryMode: TimePickerEntryMode.dial,
      builder: (context, child) {
        final Color primaryColor = Theme.of(context).colorScheme.primary;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              alwaysUse24HourFormat: false,
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: primaryColor,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black,
                ),
                timePickerTheme: TimePickerThemeData(
                  backgroundColor: Colors.white,
                  hourMinuteColor: primaryColor,
                  hourMinuteTextColor: Colors.white,
                  dialBackgroundColor: const Color(0xffF2F4F7),
                  dialHandColor: primaryColor,
                  entryModeIconColor: primaryColor,
                  helpTextStyle: TextStyle(
                    fontFamily: 'cairo',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  cancelButtonStyle: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                    textStyle: TextStyle(
                      fontFamily: 'cairo',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  confirmButtonStyle: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                    textStyle: TextStyle(
                      fontFamily: 'cairo',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );

    if (pickedTime == null) return;

    setState(() {
      _isChanging = true;
    });

    await QuranReminderPreferences.setReminderTime(
      hour: pickedTime.hour,
      minute: pickedTime.minute,
    );

    final updatedSettings = _settings.copyWith(
      hour: pickedTime.hour,
      minute: pickedTime.minute,
    );

    if (updatedSettings.enabled) {
      await QuranReminderScheduler().scheduleDailyQuranReminder(
        hour: updatedSettings.hour,
        minute: updatedSettings.minute,
      );
    }

    if (!mounted) return;

    setState(() {
      _settings = updatedSettings;
      _isChanging = false;
    });

    _showMessage('تم حفظ وقت تذكير الورد');
  }

  void _showMessage(String message) {
    final theme = Theme.of(context);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
        margin: EdgeInsets.only(
          left: 24.w,
          right: 24.w,
          bottom: 18.h,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        content: Text(
          message,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'cairo',
            fontSize: 11.sp,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notificationsProvider =
    Provider.of<NotificationsSettingsProvider>(context);

    final bool globalNotificationsEnabled =
        notificationsProvider.notificationsEnabled;

    final bool showTimeButton =
        !_isLoading && _settings.enabled && globalNotificationsEnabled;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(22.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _QuranReminderTitleHeader(
              isEnabled: globalNotificationsEnabled,
            ),

            SizedBox(height: 12.h),

            if (_isLoading)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              )
            else ...[
              _SwitchSettingRow(
                title: _isChanging
                    ? 'جاري التحديث...'
                    : 'تفعيل تذكير الورد',
                value: _settings.enabled,
                onChanged: _isChanging
                    ? null
                    : (value) => _setReminderEnabled(
                  value: value,
                  globalNotificationsEnabled:
                  globalNotificationsEnabled,
                ),
              ),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: showTimeButton
                    ? Padding(
                  key: const ValueKey('quran-reminder-time-button'),
                  padding: EdgeInsets.only(top: 10.h),
                  child: _ReminderTimeButton(
                    timeText: _settings.timeText,
                    enabled: !_isChanging,
                    onTap: () => _pickReminderTime(
                      globalNotificationsEnabled:
                      globalNotificationsEnabled,
                    ),
                  ),
                )
                    : const SizedBox.shrink(
                  key: ValueKey('quran-reminder-time-hidden'),
                ),
              ),

              SizedBox(height: 10.h),

              Text(
                _reminderStatusText(
                  globalNotificationsEnabled: globalNotificationsEnabled,
                ),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: 9.5.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.72),
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _reminderStatusText({
    required bool globalNotificationsEnabled,
  }) {
    if (!globalNotificationsEnabled) {
      return 'الإشعارات العامة مقفولة، فعّلها أولًا لتشغيل تذكير الورد.';
    }

    if (_settings.enabled) {
      return 'سيصلك تذكير يومي في الوقت المختار.';
    }

    return 'تذكير الورد متوقف، فعّله لو حبيت يصلك تنبيه يومي.';
  }
}

class _QuranReminderTitleHeader extends StatelessWidget {
  final bool isEnabled;

  const _QuranReminderTitleHeader({
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'تذكير الورد',
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'cairo',
                    fontSize: 15.5.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'فعّل تذكير ورد القرآن اليومي واختار الوقت المناسب.',
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'cairo',
                    fontSize: 9.5.sp,
                    fontWeight: FontWeight.w500,
                    color: isEnabled
                        ? Colors.white.withOpacity(0.76)
                        : Colors.white.withOpacity(0.48),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 10.w),

          Icon(
            Icons.menu_book_rounded,
            color: isEnabled
                ? const Color(0xff21C58E)
                : Colors.white.withOpacity(0.35),
            size: 24.sp,
          ),
        ],
      ),
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
              style: TextStyle(
                fontFamily: 'cairo',
                fontSize: 11.sp,
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

class _ReminderTimeButton extends StatelessWidget {
  final String timeText;
  final bool enabled;
  final VoidCallback onTap;

  const _ReminderTimeButton({
    required this.timeText,
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
        height: 42.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: const Color(0xff171B26),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: Colors.white.withOpacity(0.12),
            width: 0.8.w,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              color: enabled ? Colors.white : Colors.white38,
              size: 20.sp,
            ),
            SizedBox(width: 10.w),
            Text(
              timeText,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontFamily: 'cairo',
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: enabled ? Colors.white : Colors.white38,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                'وقت التذكير',
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: enabled
                      ? Colors.white.withOpacity(0.86)
                      : Colors.white38,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
