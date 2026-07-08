import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:islamic_app/features/azkar/data/datasources/zekr_local_data.dart';
import 'package:islamic_app/features/prayer/data/services/prayer_time_service.dart';

class ZekrProgressService {
  const ZekrProgressService();

  static const String _completedItemsPrefix = 'zekr_completed_items_';
  static const String _totalCompletedCountKey = 'zekr_total_completed_count';

  static const PrayerTimeService _prayerTimeService = PrayerTimeService();

  static const List<String> _afterPrayerKeys = [
    'fajr',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
  ];

  static final ValueNotifier<int> progressVersion = ValueNotifier<int>(0);

  static void _notifyProgressChanged() {
    progressVersion.value = progressVersion.value + 1;
  }

  String _todayKey() {
    return _dateKey(DateTime.now());
  }

  String _regularStorageKey() {
    return '$_completedItemsPrefix${_todayKey()}';
  }

  Future<String> _storageKeyForCategory(String categoryId) async {
    if (categoryId == ZekrLocalData.afterPrayerId) {
      return _afterPrayerStorageKey();
    }

    return _regularStorageKey();
  }

  Future<String> _afterPrayerStorageKey() async {
    final String sessionKey = await _currentAfterPrayerSessionKey();
    return '${_completedItemsPrefix}${ZekrLocalData.afterPrayerId}_$sessionKey';
  }

  String _itemKey({required String categoryId, required String itemId}) {
    return '$categoryId::$itemId';
  }

  Future<Set<String>> _readCompletedItemsFromStorage(String storageKey) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> savedItems = prefs.getStringList(storageKey) ?? [];
    return savedItems.toSet();
  }

  Future<void> _writeCompletedItemsToStorage({
    required String storageKey,
    required Set<String> completedItems,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(storageKey, completedItems.toList());
  }

  Future<int> getTotalCompletedCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalCompletedCountKey) ?? 0;
  }

  Future<void> _incrementTotalCompletedCount() async {
    final prefs = await SharedPreferences.getInstance();
    final oldValue = prefs.getInt(_totalCompletedCountKey) ?? 0;
    await prefs.setInt(_totalCompletedCountKey, oldValue + 1);
  }

  Future<Set<String>> getCompletedItemsToday() async {
    final Set<String> regularCompletedItems =
        await _readCompletedItemsFromStorage(_regularStorageKey());

    // مهم:
    // الإصدارات القديمة كانت تحفظ أذكار بعد الصلاة داخل مفتاح اليوم العام،
    // وده كان بيخليها تفضل مقروءة طول اليوم. بنشيلها من المفتاح العام هنا
    // ونقرأها من مفتاح جلسة الصلاة الحالية فقط.
    regularCompletedItems.removeWhere(
      (key) => key.startsWith('${ZekrLocalData.afterPrayerId}::'),
    );

    final Set<String> afterPrayerCompletedItems =
        await _readCompletedItemsFromStorage(await _afterPrayerStorageKey());

    return {...regularCompletedItems, ...afterPrayerCompletedItems};
  }

  Future<bool> isItemCompletedToday({
    required String categoryId,
    required String itemId,
  }) async {
    final String storageKey = await _storageKeyForCategory(categoryId);
    final Set<String> completedItems = await _readCompletedItemsFromStorage(
      storageKey,
    );

    return completedItems.contains(
      _itemKey(categoryId: categoryId, itemId: itemId),
    );
  }

  Future<void> markItemCompleted({
    required String categoryId,
    required String itemId,
  }) async {
    final String storageKey = await _storageKeyForCategory(categoryId);
    final Set<String> completedItems = await _readCompletedItemsFromStorage(
      storageKey,
    );
    final String key = _itemKey(categoryId: categoryId, itemId: itemId);
    final bool wasAlreadyCompleted = completedItems.contains(key);

    completedItems.add(key);

    await _writeCompletedItemsToStorage(
      storageKey: storageKey,
      completedItems: completedItems,
    );

    if (!wasAlreadyCompleted) {
      await _incrementTotalCompletedCount();
    }

    _notifyProgressChanged();
  }

  Future<void> unmarkItemCompleted({
    required String categoryId,
    required String itemId,
  }) async {
    final String storageKey = await _storageKeyForCategory(categoryId);
    final Set<String> completedItems = await _readCompletedItemsFromStorage(
      storageKey,
    );

    completedItems.remove(_itemKey(categoryId: categoryId, itemId: itemId));

    await _writeCompletedItemsToStorage(
      storageKey: storageKey,
      completedItems: completedItems,
    );

    _notifyProgressChanged();
  }

  Future<int> getCompletedCountForCategory(String categoryId) async {
    if (categoryId == ZekrLocalData.afterPrayerId) {
      final Set<String> completedItems = await _readCompletedItemsFromStorage(
        await _afterPrayerStorageKey(),
      );

      return completedItems
          .where((key) => key.startsWith('$categoryId::'))
          .length;
    }

    final Set<String> completedItems = await getCompletedItemsToday();

    return completedItems
        .where((key) => key.startsWith('$categoryId::'))
        .length;
  }

  Future<String> _currentAfterPrayerSessionKey() async {
    final DateTime now = DateTime.now();

    try {
      final List<Map<String, String>> prayerWeek = await _prayerTimeService
          .getCachedPrayerWeek();

      final List<_AfterPrayerSessionCandidate> candidates = [];

      for (final Map<String, String> day in prayerWeek) {
        final DateTime? date = _parseDateKey(day['date']);
        if (date == null) continue;

        for (final String prayerKey in _afterPrayerKeys) {
          final DateTime? prayerTime = _parsePrayerDateTime(
            day: day,
            prayerKey: prayerKey,
            fallbackDate: date,
          );

          if (prayerTime == null) continue;
          if (prayerTime.isAfter(now)) continue;

          candidates.add(
            _AfterPrayerSessionCandidate(
              prayerKey: prayerKey,
              time: prayerTime,
            ),
          );
        }
      }

      if (candidates.isNotEmpty) {
        candidates.sort((a, b) => b.time.compareTo(a.time));
        final _AfterPrayerSessionCandidate current = candidates.first;
        return '${_dateKey(current.time)}_${current.prayerKey}';
      }
    } catch (error) {
      debugPrint('⚠️ Failed to resolve after-prayer zekr session: $error');
    }

    return _fallbackAfterPrayerSessionKey(now);
  }

  DateTime? _parsePrayerDateTime({
    required Map<String, String> day,
    required String prayerKey,
    required DateTime fallbackDate,
  }) {
    final String? timeValue = day[prayerKey];
    if (timeValue == null || timeValue.trim().isEmpty) return null;

    final List<String> parts = timeValue.trim().split(':');
    if (parts.length < 2) return null;

    final int? hour = int.tryParse(parts[0]);
    final int? minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

    final DateTime date = _parseDateKey(day['date']) ?? fallbackDate;

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  String _fallbackAfterPrayerSessionKey(DateTime now) {
    DateTime sessionDate = DateTime(now.year, now.month, now.day);
    String prayerKey;

    if (now.hour < 5) {
      sessionDate = sessionDate.subtract(const Duration(days: 1));
      prayerKey = 'isha';
    } else if (now.hour < 12) {
      prayerKey = 'fajr';
    } else if (now.hour < 15) {
      prayerKey = 'dhuhr';
    } else if (now.hour < 18) {
      prayerKey = 'asr';
    } else if (now.hour < 21) {
      prayerKey = 'maghrib';
    } else {
      prayerKey = 'isha';
    }

    return '${_dateKey(sessionDate)}_$prayerKey';
  }

  String _dateKey(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  DateTime? _parseDateKey(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    try {
      final DateTime parsed = DateTime.parse(value.trim());
      return DateTime(parsed.year, parsed.month, parsed.day);
    } catch (_) {
      return null;
    }
  }
}

class _AfterPrayerSessionCandidate {
  const _AfterPrayerSessionCandidate({
    required this.prayerKey,
    required this.time,
  });

  final String prayerKey;
  final DateTime time;
}
