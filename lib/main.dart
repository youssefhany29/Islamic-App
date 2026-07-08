import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/features/onboarding/intro_page_1.dart';
import 'package:islamic_app/features/settings/notifications_settings_provider.dart';
import 'package:islamic_app/features/settings/prayer_background_style_provider.dart';
import 'package:islamic_app/core/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:islamic_app/core/notifications/notification_service.dart';
import 'package:islamic_app/core/adaptive/adaptive_orientation_policy.dart';
import 'package:islamic_app/features/recitations/settings/recitation_notification_settings_provider.dart';
import 'package:islamic_app/features/quran/main_quraan_components/constant.dart';
import 'package:islamic_app/features/home/main_page.dart';
import 'package:islamic_app/features/prayer/data/notifications/prayer_notification_settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.youssef.islamic_app.recitation_audio',
    androidNotificationChannelName: 'تشغيل التلاوة',
    androidNotificationOngoing: true,
  );

  /// مهم:
  /// لا تقفل التطبيق Portrait هنا.
  /// نخلي النظام يفتح التطبيق على وضع الجهاز الحالي،
  /// وبعد ما MediaQuery يبقى متاح، AdaptiveOrientationPolicy هيقفل
  /// الموبايل والفولد فقط، ويسيب التابلت حر.
  await SystemChrome.setPreferredOrientations([]);

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  final prefs = await SharedPreferences.getInstance();
  final seenIntro = prefs.getBool('seen_intro') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (context) => NotificationsSettingsProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => PrayerNotificationSettingsProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => RecitationNotificationSettingsProvider(),
        ),
        ChangeNotifierProvider(create: (_) => PrayerBackgroundStyleProvider()),
      ],
      child: MyApp(seenIntro: seenIntro),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool seenIntro;

  const MyApp({super.key, required this.seenIntro});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _startedInitialServices = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startInitialServicesOnce();
    });
  }

  Future<void> _startInitialServicesOnce() async {
    if (_startedInitialServices) return;

    _startedInitialServices = true;

    try {
      await NotificationService().init();
    } catch (error) {
      debugPrint('❌ NotificationService init failed: $error');
    }

    try {
      await readJson();
      await getSettings();
    } catch (error) {
      debugPrint('❌ Quran initial loading failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(292, 630),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: NotificationService.navigatorKey,
          debugShowCheckedModeBanner: false,
          themeAnimationDuration: Duration.zero,
          themeAnimationCurve: Curves.linear,
          theme: context.watch<ThemeProvider>().themeData,
          builder: (context, widget) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            AdaptiveOrientationPolicy.applyForContext(context);

            SystemChrome.setSystemUIOverlayStyle(
              SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: isDark
                    ? Brightness.light
                    : Brightness.dark,
                statusBarBrightness: isDark
                    ? Brightness.dark
                    : Brightness.light,
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarDividerColor: Colors.transparent,
                systemNavigationBarIconBrightness: isDark
                    ? Brightness.light
                    : Brightness.dark,
                systemNavigationBarContrastEnforced: false,
              ),
            );

            return ColoredBox(
              color: Theme.of(context).colorScheme.background,
              child: widget ?? const SizedBox.shrink(),
            );
          },
          home: widget.seenIntro ? const MainPage() : const IntroPage1(),
        );
      },
    );
  }
}
