import 'package:adhan/adhan.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../Services/azan_player.dart';
import '../Services/notification_service.dart';

class PrayerTimeService {
  final NotificationService _notificationService = NotificationService();
  final AzanPlayer _azanPlayer = AzanPlayer();

  /// حساب مواقيت اليوم وجدولة الإشعارات والأذان
  Future<PrayerTimes> getPrayerTimes(Position position) async {
    final params = await _getCalculationParameters(position);
    final coords = Coordinates(position.latitude, position.longitude);
    final todayTimes = PrayerTimes.today(coords, params);

    await _notificationService.cancelAllNotifications();

    // إشعارات 5 دقائق قبل كل صلاة
    _schedulePrayerNotification(
        id: 1,
        prayerName: 'الفجر',
        prayerTime: todayTimes.fajr.subtract(Duration(minutes: 5)));
    _schedulePrayerNotification(
        id: 2,
        prayerName: 'الظهر',
        prayerTime: todayTimes.dhuhr.subtract(Duration(minutes: 5)));
    _schedulePrayerNotification(
        id: 3,
        prayerName: 'العصر',
        prayerTime: todayTimes.asr.subtract(Duration(minutes: 5)));
    _schedulePrayerNotification(
        id: 4,
        prayerName: 'المغرب',
        prayerTime: todayTimes.maghrib.subtract(Duration(minutes: 5)));
    _schedulePrayerNotification(
        id: 5,
        prayerName: 'العشاء',
        prayerTime: todayTimes.isha.subtract(Duration(minutes: 5)));

    // تشغيل الأذان عند الوقت
    _scheduleAzan(todayTimes.fajr, 10);
    _scheduleAzan(todayTimes.dhuhr, 20);
    _scheduleAzan(todayTimes.asr, 30);
    _scheduleAzan(todayTimes.maghrib, 40);
    _scheduleAzan(todayTimes.isha, 50);

    // Test notification after 1 second
    final testTime = DateTime.now().add(Duration(seconds: 1));
    _notificationService.scheduleNotification(
      id: 999,
      title: 'اختبار',
      body: 'لو شايف الإشعار يبقى كل حاجة تمام',
      scheduledDate: testTime,
    );

    return todayTimes;
  }

  /// حساب مواقيت الأسبوع
  Future<List<Map<String, String>>> getWeekPrayerTimes(Position position) async {
    final params = await _getCalculationParameters(position);
    final coords  = Coordinates(position.latitude, position.longitude);

    const arabicDays = [
      'الاثنين', 'الثلاثاء', 'الأربعاء',
      'الخميس',  'الجمعة',   'السبت',
      'الأحد'
    ];
    List<Map<String, String>> weekPrayers = [];

    // رقم اليوم اليومي (1 = الإثنين ... 7 = الأحد)
    int startIndex = DateTime.now().weekday - 1;

    for (int i = 0; i < 7; i++) {
      // نحسب اسم اليوم مع اللفّ حول المصفوفة
      String dayName = arabicDays[(startIndex + i) % 7];

      // حساب أوقات الصلاة لذلك اليوم
      final date = DateTime.now().add(Duration(days: i));
      final dc   = DateComponents.from(date);
      final times = PrayerTimes(coords, dc, params);

      weekPrayers.add({
        'day'    : dayName,
        'fajr'   : _formatTime(times.fajr),
        'dhuhr'  : _formatTime(times.dhuhr),
        'asr'    : _formatTime(times.asr),
        'maghrib': _formatTime(times.maghrib),
        'isha'   : _formatTime(times.isha),
      });
    }
    return weekPrayers;
  }


  void _schedulePrayerNotification({
    required int id,
    required String prayerName,
    required DateTime prayerTime,
  }) {
    _notificationService.scheduleNotification(
      id: id,
      title: 'موعد الصلاة',
      body: 'تبقى 5 دقائق على صلاة $prayerName',
      scheduledDate: prayerTime,
    );
  }

  void _scheduleAzan(DateTime prayerTime, int id) {
    _notificationService
        .scheduleNotification(
          id: 100 + id,
          title: 'الأذان',
          body: 'حان وقت الصلاة',
          scheduledDate: prayerTime,
        )
        .then((_) => _azanPlayer.playAzan());
  }

  Future<CalculationParameters> _getCalculationParameters(
      Position position) async {
    final placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    final place = placemarks.first;
    final iso = place.isoCountryCode;

    CalculationParameters params;
    switch (iso) {
      case 'EG': // Egypt
        params = CalculationMethod.egyptian.getParameters();
        params.madhab = Madhab.hanafi;
        params.fajrAngle = 19.5;
        params.ishaAngle = 17.5;
        break;

      case 'TR': // Turkey
        params = CalculationMethod.turkey.getParameters();
        params.madhab = Madhab.shafi;
        params.fajrAngle = 18.0;
        params.ishaAngle = 17.0;
        break;

      case 'IR': // Iran (Tehran)
        params = CalculationMethod.tehran.getParameters();
        params.madhab = Madhab.shafi;
        params.fajrAngle = 17.7;
        params.ishaAngle = 14.0;
        break;

      case 'SA': // Saudi Arabia (Umm al-Qura)
        params = CalculationMethod.umm_al_qura.getParameters();
        params.madhab = Madhab.shafi;
        params.fajrAngle = 18.5;
        params.ishaInterval = 90; // minutes after Maghrib
        break;

      case 'OM': case 'BH': // Oman, Bahrain (Umm al-Qura)
      params = CalculationMethod.umm_al_qura.getParameters();
      params.madhab = Madhab.shafi;
      params.fajrAngle = 18.5;
      params.ishaInterval = 90;
      break;

      case 'AE': // United Arab Emirates (Dubai)
        params = CalculationMethod.dubai.getParameters();
        params.madhab = Madhab.shafi;
        params.fajrAngle = 18.2;
        params.ishaAngle = 18.2;
        break;

      case 'QA': // Qatar
        params = CalculationMethod.qatar.getParameters();
        params.madhab = Madhab.shafi;
        params.fajrAngle = 18.0;
        params.ishaInterval = 90;
        break;

      case 'KW': // Kuwait
        params = CalculationMethod.kuwait.getParameters();
        params.madhab = Madhab.shafi;
        params.fajrAngle = 18.0;
        params.ishaAngle = 17.5;
        break;

      case 'PK': case 'IN': case 'BD': // Pakistan, India, Bangladesh (Karachi)
      params = CalculationMethod.karachi.getParameters();
      params.madhab = Madhab.hanafi;
      params.fajrAngle = 18.0;
      params.ishaAngle = 18.0;
      break;

      case 'SG': // Singapore
        params = CalculationMethod.singapore.getParameters();
        params.madhab = Madhab.shafi;
        params.fajrAngle = 20.0;
        params.ishaAngle = 18.0;
        break;

      case 'US': case 'CA': case 'AU': // North America (ISNA)
      params = CalculationMethod.north_america.getParameters();
      params.madhab = Madhab.shafi;
      params.fajrAngle = 15.0;
      params.ishaAngle = 15.0;
      break;

      case 'GB': case 'FR': case 'DE': case 'NL': case 'ES': case 'IT': // Europe (MWL)
      params = CalculationMethod.muslim_world_league.getParameters();
      params.madhab = Madhab.shafi;
      params.fajrAngle = 18.0;
      params.ishaAngle = 17.0;
      break;

      default: // fallback to MWL
        params = CalculationMethod.muslim_world_league.getParameters();
        params.madhab = Madhab.shafi;
        params.fajrAngle = 18.0;
        params.ishaAngle = 17.0;
    }
    return params;
  }

  String _formatTime(DateTime dt) =>
      dt.hour.toString().padLeft(2, '0') +
      ':' +
      dt.minute.toString().padLeft(2, '0');

  String _getArabicDayName(int wd) {
    const arabicDays = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد'
    ];
    return arabicDays[wd - 1];
  }
}
