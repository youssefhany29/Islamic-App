import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/intro_pages/intro_page_1.dart';
import 'package:islamic_app/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'App Main Screens/PrayerPage/Services/notification_service.dart';
import 'App Main Screens/kuran/constant.dart';
import 'MainPage/main_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final seenIntro = prefs.getBool('seen_intro') ?? false;
  await NotificationService().init();   // <<< مهم جداً
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown
  ]);
  runApp(
      ChangeNotifierProvider(
        create: (context) => ThemeProvider(),
        child: MyApp(seenIntro: seenIntro),
      )
  );
}

class MyApp extends StatefulWidget {
  final bool seenIntro;
  const MyApp({super.key , required this.seenIntro});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  void initState() {
    WidgetsBinding
        .instance
        .addPostFrameCallback(

            (_) async{
          await readJson();
          await getSettings();
        }
    );
    super.initState();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
        designSize: Size(292, 630),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: Provider.of<ThemeProvider>(context).themeData,
            builder: (context ,widget){

              final isDark = Theme.of(context).brightness == Brightness.dark;

              SystemChrome.setSystemUIOverlayStyle(
                SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: isDark
                  ? Brightness.light
                      : Brightness.dark,
                  statusBarBrightness: isDark
                    ? Brightness.dark
                      : Brightness.light,
                )
              );
              return ColoredBox(
                color: Theme.of(context).colorScheme.background,
                child: widget!,
              );
            },
            home: widget.seenIntro ? const MainPage() : const IntroPage1(),
          );
        });
  }
}
