import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
Future<TimeOfDay?> showAppTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  required String helpText,
}) {
  final Color primaryColor = Theme.of(context).colorScheme.primary;

  return showTimePicker(
    context: context,
    initialTime: initialTime,
    helpText: helpText,
    cancelText: 'إلغاء',
    confirmText: 'حفظ',
    initialEntryMode: TimePickerEntryMode.dial,
    builder: (context, child) {
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
                onSurface: const Color(0xff111827),
              ),
              dialogBackgroundColor: Colors.white,
              timePickerTheme: TimePickerThemeData(
                backgroundColor: Colors.white,

                /// دي أهم واحدة: أرقام الساعة والدقائق تبقى بيضة.
                hourMinuteColor: primaryColor,
                hourMinuteTextColor: Colors.white,
                hourMinuteTextStyle: AppTextStyles.display(context).copyWith(
fontWeight: FontWeight.w900,
                  color: Colors.white
),

                dialBackgroundColor: const Color(0xffF2F4F7),
                dialHandColor: primaryColor,
                dialTextColor: MaterialStateColor.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return Colors.white;
                  }
                  return const Color(0xff111827);
                }),

                dayPeriodColor: MaterialStateColor.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return primaryColor;
                  }
                  return const Color(0xffF2F4F7);
                }),
                dayPeriodTextColor: MaterialStateColor.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return Colors.white;
                  }
                  return const Color(0xff111827);
                }),

                entryModeIconColor: primaryColor,

                helpTextStyle: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
                  color: const Color(0xff111827)
),

                cancelButtonStyle: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                  textStyle: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800
),
                ),
                confirmButtonStyle: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                  textStyle: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800
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
}