import 'package:geolocator/geolocator.dart';

class LocationService {
  Future getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      throw Exception('يرجى تفعيل خدمة الموقع');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('تم رفض إذن الموقع');
      }
      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        throw Exception('الأذونات مرفوضة نهائيًا، افتح إعدادات التطبيق');
      }
    }

    return Geolocator.getCurrentPosition();
  }
}