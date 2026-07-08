import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:islamic_app/shared/widgets/app_main_components/custom_app_bar.dart';
import 'package:islamic_app/features/prayer/data/notifications/prayer_notification_settings_card.dart';
import 'package:islamic_app/features/islamic_events/settings/islamic_events_notification_settings_provider.dart';
import 'package:islamic_app/features/islamic_events/widgets/islamic_events_notification_settings_card.dart';
import 'package:islamic_app/features/recitations/widgets/recitation_notification_settings_card.dart';
import 'package:islamic_app/features/azkar/data/notifications/zekr_notification_settings_card.dart';
import 'package:islamic_app/features/azkar/data/notifications/zekr_notification_settings_provider.dart';
import 'package:islamic_app/features/hadith/data/notifications/hadith_notification_settings_card.dart';
import 'package:islamic_app/features/hadith/data/notifications/hadith_notification_settings_provider.dart';
import 'package:islamic_app/features/quran/Notification/quran_reminder_settings_card.dart';

class ReminderSettingsPage extends StatelessWidget {
  const ReminderSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: const CustomAppBar(
        category: CustomAppBarCategory(
          text: 'إعدادات التذكيرات',
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: 18.w,
            vertical: 16.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const QuranReminderSettingsCard(),

              SizedBox(height: 18.h),

              const PrayerNotificationSettingsCard(),

              SizedBox(height: 18.h),

              ChangeNotifierProvider(
                create: (_) => ZekrNotificationSettingsProvider(),
                child: const ZekrNotificationSettingsCard(),
              ),

              SizedBox(height: 18.h),

              ChangeNotifierProvider(
                create: (_) => HadithNotificationSettingsProvider(),
                child: const HadithNotificationSettingsCard(),
              ),

              SizedBox(height: 18.h),

              ChangeNotifierProvider(
                create: (_) => IslamicEventsNotificationSettingsProvider(),
                child: const IslamicEventsNotificationSettingsCard(),
              ),

              SizedBox(height: 18.h),

              const RecitationNotificationSettingsCard(),

              SizedBox(height: 28.h),
            ],
          ),
        ),
      ),
    );
  }
}
