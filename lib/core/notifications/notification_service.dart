import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:islamic_app/features/prayer/pray_page.dart';
import 'package:islamic_app/features/azkar/zekr_page.dart';
import 'package:islamic_app/features/hadith/ahadeth_page.dart';
import 'package:islamic_app/features/home/main_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._internal();

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  static const String openHomePayload = 'open_home';
  static const String openPrayerPayload = 'open_prayer_page';
  static const String openZekrPayload = 'open_zekr_page';
  static const String openHadithPayload = 'open_hadith_page';

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  FlutterLocalNotificationsPlugin get plugin => _notificationsPlugin;

  static const String _generalChannelId = 'general_reminders_channel';
  static const String _generalChannelName = 'General Reminders';
  static const String _generalChannelDescription =
      'General reminders for the app.';

  static const AndroidNotificationChannel _generalAndroidChannel =
  AndroidNotificationChannel(
    _generalChannelId,
    _generalChannelName,
    description: _generalChannelDescription,
    importance: Importance.high,
  );

  Future<void> init() async {
    await _initializeTimeZone();

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse:
      notificationTapBackgroundHandler,
    );

    final NotificationAppLaunchDetails? launchDetails =
    await _notificationsPlugin.getNotificationAppLaunchDetails();

    final NotificationResponse? launchResponse =
        launchDetails?.notificationResponse;

    if (launchDetails?.didNotificationLaunchApp ?? false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationPayload(launchResponse?.payload);
      });
    }

    await createAndroidNotificationChannel(_generalAndroidChannel);

    debugPrint('✅ NotificationService initialized');
    debugPrint('🌍 Current timezone used by app: ${tz.local.name}');
    debugPrint('🕒 Dart DateTime.now(): ${DateTime.now()}');
    debugPrint('🕒 TZDateTime.now(tz.local): ${tz.TZDateTime.now(tz.local)}');
  }

  Future<void> _initializeTimeZone() async {
    tz.initializeTimeZones();

    try {
      final dynamic currentTimeZone =
      await FlutterTimezone.getLocalTimezone();

      debugPrint('🌍 Raw timezone value: $currentTimeZone');

      String timeZoneName;

      if (currentTimeZone is String) {
        timeZoneName = currentTimeZone;
      } else {
        timeZoneName = currentTimeZone.identifier.toString();
      }

      tz.setLocalLocation(
        tz.getLocation(timeZoneName),
      );

      debugPrint('🌍 Device timezone detected: $timeZoneName');
    } catch (error) {
      debugPrint('⚠️ Failed to detect device timezone: $error');

      final Duration offset = DateTime.now().timeZoneOffset;
      final int offsetHours = offset.inHours;

      final String fallbackTimeZone = _etcGmtTimeZoneFromOffset(offsetHours);

      tz.setLocalLocation(
        tz.getLocation(fallbackTimeZone),
      );

      debugPrint('🌍 Fallback timezone used from device offset: $fallbackTimeZone');
    }
  }

  String _etcGmtTimeZoneFromOffset(int offsetHours) {
    if (offsetHours == 0) {
      return 'Etc/UTC';
    }

    // ملاحظة مهمة:
    // Etc/GMT signs are reversed.
    // UTC+3 = Etc/GMT-3
    // UTC-5 = Etc/GMT+5
    if (offsetHours > 0) {
      return 'Etc/GMT-$offsetHours';
    }

    return 'Etc/GMT+${offsetHours.abs()}';
  }


  static void _onNotificationTap(NotificationResponse response) {
    _handleNotificationPayload(response.payload);
  }

  static void _handleNotificationPayload(String? payload) {
    switch (payload) {
      case openPrayerPayload:
        NotificationService().openPrayerPageFromNotification();
        break;

      case openZekrPayload:
        NotificationService().openZekrPageFromNotification();
        break;

      case openHadithPayload:
      case 'open_hadith':
        NotificationService().openHadithPageFromNotification();
        break;

      case openHomePayload:
        NotificationService().openHomeFromNotification();
        break;

      default:
        NotificationService().openHomeFromNotification();
        break;
    }
  }

  void openHomeFromNotification() {
    final navigator = navigatorKey.currentState;

    if (navigator == null) {
      debugPrint('⚠️ Navigator is not ready for notification tap.');
      return;
    }

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const MainPage(),
      ),
          (route) => false,
    );
  }

  void openPrayerPageFromNotification() {
    final navigator = navigatorKey.currentState;

    if (navigator == null) {
      debugPrint('⚠️ Navigator is not ready for notification tap.');
      return;
    }

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const MainPage(),
      ),
          (route) => false,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigator.push(
        MaterialPageRoute(
          builder: (context) => const PrayPage(),
        ),
      );
    });
  }


  void openZekrPageFromNotification() {
    final navigator = navigatorKey.currentState;

    if (navigator == null) {
      debugPrint('⚠️ Navigator is not ready for notification tap.');
      return;
    }

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const MainPage(),
      ),
          (route) => false,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigator.push(
        MaterialPageRoute(
          builder: (context) => const ZekrPage(),
        ),
      );
    });
  }

  void openHadithPageFromNotification() {
    final navigator = navigatorKey.currentState;

    if (navigator == null) {
      debugPrint('⚠️ Navigator is not ready for notification tap.');
      return;
    }

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const MainPage(),
      ),
          (route) => false,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigator.push(
        MaterialPageRoute(
          builder: (context) => const Ahadethpage(),
        ),
      );
    });
  }

  Future<void> createAndroidNotificationChannel(
      AndroidNotificationChannel channel,
      ) async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<bool> requestNotificationPermission() async {
    final PermissionStatus status = await Permission.notification.request();

    debugPrint('🔔 Notification permission: $status');

    return status.isGranted;
  }

  NotificationDetails _generalNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _generalChannelId,
        _generalChannelName,
        channelDescription: _generalChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  Future<void> showTestNotification() async {
    await _notificationsPlugin.show(
      1,
      'ديني في جيبي 🌙',
      'تم تفعيل إشعارات التذكير بنجاح',
      _generalNotificationDetails(),
      payload: openHomePayload,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> printPendingNotifications({
    bool detailed = false,
  }) async {
    if (!kDebugMode) return;

    final List<PendingNotificationRequest> pendingNotifications =
    await _notificationsPlugin.pendingNotificationRequests();

    debugPrint('📋 Pending Notifications Count: ${pendingNotifications.length}');

    if (!detailed) return;

    for (final notification in pendingNotifications) {
      debugPrint(
        '➡️ ID: ${notification.id}, Title: ${notification.title}, Body: ${notification.body}',
      );
    }
  }
}

@pragma('vm:entry-point')
void notificationTapBackgroundHandler(NotificationResponse response) {
  debugPrint('🔔 Notification tapped in background: ${response.payload}');
}