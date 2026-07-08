import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  static const String _cachedLocationNameKey = 'cached_location_display_name';

  Future<Position> getCurrentLocation({
    bool forceFresh = false,
  }) async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('خدمة الموقع غير مفعلة');
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        throw Exception('تم رفض إذن الموقع');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('إذن الموقع مرفوض نهائيًا');
    }

    if (!forceFresh) {
      final Position? lastKnownPosition =
      await Geolocator.getLastKnownPosition();

      if (lastKnownPosition != null &&
          _isUsableCachedPosition(lastKnownPosition)) {
        return lastKnownPosition;
      }
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 15),
    );
  }

  Future<String> getReadableLocationName(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        return await getCachedLocationName() ?? 'موقعك';
      }

      final place = placemarks.first;

      debugPrint('======================');
      debugPrint('country: ${place.country}');
      debugPrint('administrativeArea: ${place.administrativeArea}');
      debugPrint('subAdministrativeArea: ${place.subAdministrativeArea}');
      debugPrint('locality: ${place.locality}');
      debugPrint('subLocality: ${place.subLocality}');
      debugPrint('street: ${place.street}');
      debugPrint('name: ${place.name}');
      debugPrint('======================');

      final rawName = _firstValid([
        place.subLocality,
        place.locality,
        place.subAdministrativeArea,
        place.administrativeArea,
        place.country,
      ]);

      if (rawName == null) {
        return await getCachedLocationName() ?? 'موقعك';
      }

      final name = _normalizeLocationName(rawName);

      await _cacheLocationName(name);
      return name;
    } catch (_) {
      return await getCachedLocationName() ?? 'موقعك';
    }
  }

  Future<String?> getCachedLocationName() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_cachedLocationNameKey);

    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }

  Future<void> clearCachedLocationName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedLocationNameKey);
  }

  Future<void> _cacheLocationName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedLocationNameKey, name.trim());
  }

  String? _firstValid(List<String?> values) {
    for (final value in values) {
      final clean = value?.trim();

      if (clean != null && clean.isNotEmpty) {
        return clean;
      }
    }

    return null;
  }

  String _normalizeLocationName(String name) {
    final clean = name.trim();

    const Map<String, String> replacements = {
      "District d'Ariha": "أريحا",
      "Ariha District": "أريحا",
      "Ariha": "أريحا",
      "Gouvernorat d'Idleb": "إدلب",
      "Idlib Governorate": "إدلب",
      "Idleb": "إدلب",
      "Idlib": "إدلب",
      "Syria": "سوريا",
      "Syrian Arab Republic": "سوريا",
      "Türkiye": "تركيا",
      "Turkey": "تركيا",
      "İstanbul": "إسطنبول",
      "Istanbul": "إسطنبول",
      "Cairo": "القاهرة",
      "Egypt": "مصر",
    };

    return replacements[clean] ?? clean;
  }

  bool _isUsableCachedPosition(Position position) {
    final DateTime? timestamp = position.timestamp;

    if (timestamp == null) {
      return true;
    }

    final Duration age = DateTime.now().difference(timestamp);
    return age.inHours <= 12;
  }
}