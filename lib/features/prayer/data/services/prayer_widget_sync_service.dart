import 'package:flutter/services.dart';
import 'package:islamic_app/features/home/presentation/phone/widgets/prayer_hero_background_resolver.dart';
import 'package:islamic_app/features/prayer/data/services/location_service.dart';
import 'package:islamic_app/features/prayer/data/services/prayer_time_service.dart';
import 'package:islamic_app/features/settings/prayer_background_style_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrayerWidgetSnapshot {
  const PrayerWidgetSnapshot({
    required this.prayerName,
    required this.prayerKey,
    required this.timeText,
    required this.remainingText,
    required this.locationLabel,
    required this.backgroundAsset,
    required this.updatedAtMillis,
    required this.nextPrayerAtMillis,
    required this.followingPrayerName,
    required this.followingPrayerTime,
    required this.isLoading,
    required this.hasData,
    this.backgroundFilePath,
  });

  final String prayerName;
  final String prayerKey;
  final String timeText;
  final String remainingText;
  final String locationLabel;
  final String backgroundAsset;
  final int updatedAtMillis;
  final int nextPrayerAtMillis;
  final String followingPrayerName;
  final String followingPrayerTime;
  final bool isLoading;
  final bool hasData;
  final String? backgroundFilePath;

  Map<String, Object?> toMap() {
    return {
      'prayerName': prayerName,
      'prayerKey': prayerKey,
      'timeText': timeText,
      'remainingText': remainingText,
      'locationLabel': locationLabel,
      'backgroundAsset': backgroundAsset,
      'backgroundFilePath': backgroundFilePath,
      'updatedAtMillis': updatedAtMillis,
      'nextPrayerAtMillis': nextPrayerAtMillis,
      'followingPrayerName': followingPrayerName,
      'followingPrayerTime': followingPrayerTime,
      'isLoading': isLoading,
      'hasData': hasData,
    };
  }
}

class PrayerWidgetSyncService {
  PrayerWidgetSyncService._();

  static final PrayerWidgetSyncService instance = PrayerWidgetSyncService._();

  static const MethodChannel _channel = MethodChannel(
    'com.youssef.islamic_app/prayer_widget',
  );

  static const String liveStatusEnabledKey = 'prayer_live_status_enabled';

  static const String _prefix = 'prayer_widget_';

  final PrayerTimeService _prayerTimeService = const PrayerTimeService();
  final LocationService _locationService = LocationService();

  Future<PrayerWidgetSnapshot> syncFromCache({
    List<Map<String, String>>? prayerWeek,
    String? locationLabel,
    bool isLoading = false,
  }) async {
    final List<Map<String, String>> week =
        prayerWeek ?? await _prayerTimeService.getCachedPrayerWeek();
    final String cleanLocation =
        _cleanLabel(locationLabel) ??
        await _locationService.getCachedLocationName() ??
        'موقعك';

    final DateTime now = DateTime.now();
    final String? countryIso = await _prayerTimeService
        .getCachedPrayerCountryIso();
    final PrayerBackgroundStyle backgroundStyle =
        await const PrayerBackgroundStyleService().load();
    final String backgroundAsset = PrayerHeroBackgroundResolver.resolve(
      prayerWeek: week,
      countryIso: countryIso,
      now: now,
      backgroundStyle: backgroundStyle,
    );
    final _NextPrayerInfo? info = _calculateNextPrayer(week, now: now);

    final PrayerWidgetSnapshot snapshot = PrayerWidgetSnapshot(
      prayerName: info?.name ?? 'الصلاة',
      prayerKey: info?.assetKey ?? 'maghrib',
      timeText: info?.timeText ?? '--:--',
      remainingText: info?.remainingText ?? '--:--:--',
      locationLabel: cleanLocation,
      backgroundAsset: backgroundAsset,
      backgroundFilePath: null,
      updatedAtMillis: now.millisecondsSinceEpoch,
      nextPrayerAtMillis: info?.time.millisecondsSinceEpoch ?? 0,
      followingPrayerName: info?.followingPrayerName ?? '—',
      followingPrayerTime: info?.followingPrayerTime ?? '—',
      isLoading: isLoading,
      hasData: info != null,
    );

    await _saveSnapshot(snapshot);
    await _sendSnapshotToNative(snapshot);
    return snapshot;
  }

  Future<void> setLiveStatusEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(liveStatusEnabledKey, enabled);
    try {
      await _channel.invokeMethod<void>('setPrayerLiveStatusEnabled', {
        'enabled': enabled,
      });
    } catch (_) {
      // Non-mobile targets do not expose this native bridge.
    }

    if (enabled) {
      await syncFromCache();
    }
  }

  Future<bool> isLiveStatusEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(liveStatusEnabledKey) ?? false;
  }

  Future<bool> consumeInitialPrayerDeepLink() async {
    try {
      final bool? shouldOpen = await _channel.invokeMethod<bool>(
        'consumeInitialPrayerDeepLink',
      );
      return shouldOpen ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveSnapshot(PrayerWidgetSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    final map = snapshot.toMap();

    await prefs.setString('${_prefix}prayerName', snapshot.prayerName);
    await prefs.setString('${_prefix}prayerKey', snapshot.prayerKey);
    await prefs.setString('${_prefix}timeText', snapshot.timeText);
    await prefs.setString('${_prefix}remainingText', snapshot.remainingText);
    await prefs.setString('${_prefix}locationLabel', snapshot.locationLabel);
    await prefs.setString(
      '${_prefix}backgroundAsset',
      snapshot.backgroundAsset,
    );
    await prefs.setString(
      '${_prefix}backgroundFilePath',
      snapshot.backgroundFilePath ?? '',
    );
    await prefs.setInt('${_prefix}updatedAtMillis', snapshot.updatedAtMillis);
    await prefs.setInt(
      '${_prefix}nextPrayerAtMillis',
      snapshot.nextPrayerAtMillis,
    );
    await prefs.setString(
      '${_prefix}followingPrayerName',
      snapshot.followingPrayerName,
    );
    await prefs.setString(
      '${_prefix}followingPrayerTime',
      snapshot.followingPrayerTime,
    );
    await prefs.setBool('${_prefix}isLoading', snapshot.isLoading);
    await prefs.setBool('${_prefix}hasData', snapshot.hasData);

    for (final entry in map.entries) {
      final value = entry.value;
      if (value is String) {
        await prefs.setString(entry.key, value);
      } else if (value is int) {
        await prefs.setInt(entry.key, value);
      } else if (value is bool) {
        await prefs.setBool(entry.key, value);
      }
    }
  }

  Future<void> _sendSnapshotToNative(PrayerWidgetSnapshot snapshot) async {
    try {
      await _channel.invokeMethod<void>(
        'syncPrayerWidgetSnapshot',
        snapshot.toMap(),
      );
    } catch (_) {
      // Desktop/web builds and partially configured native targets can ignore it.
    }
  }

  _NextPrayerInfo? _calculateNextPrayer(
    List<Map<String, String>> prayerWeek, {
    DateTime? now,
  }) {
    if (prayerWeek.isEmpty) return null;

    final DateTime currentTime = now ?? DateTime.now();
    final List<_PrayerItem> prayerItems = [];

    for (int dayOffset = 0; dayOffset < prayerWeek.length; dayOffset++) {
      final Map<String, String> day = prayerWeek[dayOffset];
      final DateTime baseDate =
          _parseDate(day['date']) ??
          DateTime(
            currentTime.year,
            currentTime.month,
            currentTime.day + dayOffset,
          );

      prayerItems.addAll([
        _PrayerItem(
          name: 'الفجر',
          assetKey: 'fajr',
          time: _parseTime(day['fajr'], baseDate),
        ),
        _PrayerItem(
          name: 'الشروق',
          assetKey: 'sunrise',
          time: _parseTime(day['sunrise'], baseDate),
        ),
        _PrayerItem(
          name: 'الظهر',
          assetKey: 'dhuhr',
          time: _parseTime(day['dhuhr'], baseDate),
        ),
        _PrayerItem(
          name: 'العصر',
          assetKey: 'asr',
          time: _parseTime(day['asr'], baseDate),
        ),
        _PrayerItem(
          name: 'المغرب',
          assetKey: 'maghrib',
          time: _parseTime(day['maghrib'], baseDate),
        ),
        _PrayerItem(
          name: 'العشاء',
          assetKey: 'isha',
          time: _parseTime(day['isha'], baseDate),
        ),
      ]);
    }

    final validPrayerItems = prayerItems
        .where((item) => item.time != null)
        .map(
          (item) => _PrayerItem(
            name: item.name,
            assetKey: item.assetKey,
            time: item.time!,
          ),
        )
        .toList();

    validPrayerItems.sort((a, b) => a.time!.compareTo(b.time!));

    for (int index = 0; index < validPrayerItems.length; index++) {
      final item = validPrayerItems[index];
      final prayerTime = item.time!;

      if (prayerTime.isAfter(currentTime) ||
          prayerTime.isAtSameMomentAs(currentTime)) {
        final remaining = prayerTime.difference(currentTime);
        final nextItem = index + 1 < validPrayerItems.length
            ? validPrayerItems[index + 1]
            : null;

        return _NextPrayerInfo(
          name: item.name,
          assetKey: item.assetKey,
          time: prayerTime,
          timeText: _formatTime(prayerTime),
          remainingText: _formatDuration(remaining),
          followingPrayerName: nextItem?.name ?? '—',
          followingPrayerTime: nextItem?.time == null
              ? '—'
              : _formatTime(nextItem!.time!),
        );
      }
    }

    return null;
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    try {
      final parsed = DateTime.parse(value.trim());
      return DateTime(parsed.year, parsed.month, parsed.day);
    } catch (_) {
      return null;
    }
  }

  DateTime? _parseTime(String? time, DateTime baseDate) {
    if (time == null || !time.contains(':')) return null;

    final parts = time.split(':');
    if (parts.length < 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return null;

    return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
  }

  String _formatTime(DateTime dateTime) {
    int hour = dateTime.hour;
    final String minute = dateTime.minute.toString().padLeft(2, '0');

    hour = hour % 12;

    if (hour == 0) {
      hour = 12;
    }

    return '$hour:$minute';
  }

  String _formatDuration(Duration duration) {
    final safeDuration = duration.isNegative ? Duration.zero : duration;
    final hours = safeDuration.inHours.toString().padLeft(2, '0');
    final minutes = (safeDuration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (safeDuration.inSeconds % 60).toString().padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  String? _cleanLabel(String? value) {
    final clean = value?.trim();
    if (clean == null || clean.isEmpty) return null;
    return clean;
  }
}

class _PrayerItem {
  const _PrayerItem({
    required this.name,
    required this.assetKey,
    required this.time,
  });

  final String name;
  final String assetKey;
  final DateTime? time;
}

class _NextPrayerInfo {
  const _NextPrayerInfo({
    required this.name,
    required this.assetKey,
    required this.time,
    required this.timeText,
    required this.remainingText,
    required this.followingPrayerName,
    required this.followingPrayerTime,
  });

  final String name;
  final String assetKey;
  final DateTime time;
  final String timeText;
  final String remainingText;
  final String followingPrayerName;
  final String followingPrayerTime;
}
