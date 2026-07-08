import 'package:flutter/material.dart';
import 'package:islamic_app/features/prayer/data/notifications/prayer_tracking_notification_scheduler.dart';
import 'package:islamic_app/core/notifications/notification_service.dart';
import 'package:islamic_app/features/prayer/data/services/prayer_widget_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Services/prayer_time_service.dart';
import 'prayer_notification_scheduler.dart';

enum PrayerSoundMode { prayerVoice, azan }

class PrayerNotificationSettingsProvider extends ChangeNotifier {
  static const String _enabledKey = 'prayer_notifications_enabled';
  static const String _notifyAtPrayerTimeKey = 'notify_at_prayer_time';
  static const String _notifyBeforePrayerKey = 'notify_before_prayer';
  static const String _notifyBeforeMinutesKey = 'notify_before_minutes';
  static const String _selectedPrayersKey = 'selected_prayers';
  static const String _prayerSoundEnabledKey = 'prayer_sound_enabled';
  static const String _soundModeKey = 'prayer_sound_mode';
  static const String _selectedAzanSoundKey = 'selected_azan_sound';
  static const String _azanSoundEnabledKey = 'azan_sound_enabled';
  static const String _progressRemindersEnabledKey =
      'prayer_progress_reminders_enabled';
  static const String _dailySummaryEnabledKey = 'prayer_daily_summary_enabled';
  static const String _achievementNotificationsEnabledKey =
      'prayer_achievement_notifications_enabled';
  static const String _afterPrayerAzkarReminderEnabledKey =
      'after_prayer_azkar_reminder_enabled';
  static const String _nightPrayReminderEnabledKey =
      'night_pray_reminder_enabled';
  static const String _nightPrayReminderHourKey = 'night_pray_reminder_hour';
  static const String _nightPrayReminderMinuteKey =
      'night_pray_reminder_minute';
  static const String _liveStatusEnabledKey =
      PrayerWidgetSyncService.liveStatusEnabledKey;

  static const List<String> defaultPrayers = [
    'الفجر',
    'الظهر',
    'العصر',
    'المغرب',
    'العشاء',
  ];

  static const List<String> azanSounds = [
    'azan_1',
    'azan_2',
    'azan_3',
    'azan_4',
    'azan_5',
  ];

  final PrayerTimeService _prayerTimeService = PrayerTimeService();

  bool _isLoaded = false;
  bool _isChanging = false;

  bool _enabled = false;
  bool _notifyAtPrayerTime = true;
  bool _notifyBeforePrayer = false;
  bool _prayerSoundEnabled = true;
  bool _azanSoundEnabled = true;
  bool _progressRemindersEnabled = true;
  bool _dailySummaryEnabled = true;
  bool _achievementNotificationsEnabled = true;
  bool _afterPrayerAzkarReminderEnabled = true;
  bool _nightPrayReminderEnabled = false;
  bool _liveStatusEnabled = false;

  int _notifyBeforeMinutes = 10;
  int _nightPrayReminderHour = 2;
  int _nightPrayReminderMinute = 0;

  PrayerSoundMode _soundMode = PrayerSoundMode.prayerVoice;
  String _selectedAzanSound = 'azan_1';

  List<String> _selectedPrayers = List<String>.from(defaultPrayers);

  bool get isLoaded => _isLoaded;
  bool get isChanging => _isChanging;

  bool get enabled => _enabled;
  bool get notifyAtPrayerTime => _notifyAtPrayerTime;
  bool get notifyBeforePrayer => _notifyBeforePrayer;
  bool get prayerSoundEnabled => _prayerSoundEnabled;
  bool get azanSoundEnabled => _azanSoundEnabled;
  bool get progressRemindersEnabled => _progressRemindersEnabled;
  bool get dailySummaryEnabled => _dailySummaryEnabled;
  bool get achievementNotificationsEnabled => _achievementNotificationsEnabled;
  bool get afterPrayerAzkarReminderEnabled => _afterPrayerAzkarReminderEnabled;
  bool get nightPrayReminderEnabled => _nightPrayReminderEnabled;
  bool get liveStatusEnabled => _liveStatusEnabled;

  int get notifyBeforeMinutes => _notifyBeforeMinutes;
  int get nightPrayReminderHour => _nightPrayReminderHour;
  int get nightPrayReminderMinute => _nightPrayReminderMinute;

  TimeOfDay get nightPrayReminderTime =>
      TimeOfDay(hour: _nightPrayReminderHour, minute: _nightPrayReminderMinute);

  String get nightPrayReminderTimeText {
    final String hour = _nightPrayReminderHour.toString().padLeft(2, '0');
    final String minute = _nightPrayReminderMinute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  PrayerSoundMode get soundMode => _soundMode;
  String get selectedAzanSound => _selectedAzanSound;

  List<String> get selectedPrayers => List.unmodifiable(_selectedPrayers);

  String get selectedPrayersText {
    if (_selectedPrayers.length == defaultPrayers.length) {
      return 'كل الصلوات';
    }

    if (_selectedPrayers.isEmpty) {
      return 'لا توجد صلوات مختارة';
    }

    return _selectedPrayers.join('، ');
  }

  String get soundModeText {
    switch (_soundMode) {
      case PrayerSoundMode.prayerVoice:
        return 'حان الآن موعد الصلاة';
      case PrayerSoundMode.azan:
        return 'الأذان';
    }
  }

  String get selectedAzanSoundText {
    switch (_selectedAzanSound) {
      case 'azan_1':
        return 'المؤذن الأول';
      case 'azan_2':
        return 'المؤذن الثاني';
      case 'azan_3':
        return 'المؤذن الثالث';
      case 'azan_4':
        return 'المؤذن الرابع';
      case 'azan_5':
        return 'المؤذن الخامس';
      default:
        return 'المؤذن الأول';
    }
  }

  PrayerNotificationSettingsProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _enabled = prefs.getBool(_enabledKey) ?? false;
    _notifyAtPrayerTime = prefs.getBool(_notifyAtPrayerTimeKey) ?? true;
    _notifyBeforePrayer = prefs.getBool(_notifyBeforePrayerKey) ?? false;
    _notifyBeforeMinutes = prefs.getInt(_notifyBeforeMinutesKey) ?? 10;

    _azanSoundEnabled = prefs.getBool(_azanSoundEnabledKey) ?? true;
    _prayerSoundEnabled = prefs.getBool(_prayerSoundEnabledKey) ?? true;

    _progressRemindersEnabled =
        prefs.getBool(_progressRemindersEnabledKey) ?? true;
    _dailySummaryEnabled = prefs.getBool(_dailySummaryEnabledKey) ?? true;
    _achievementNotificationsEnabled =
        prefs.getBool(_achievementNotificationsEnabledKey) ?? true;
    _afterPrayerAzkarReminderEnabled =
        prefs.getBool(_afterPrayerAzkarReminderEnabledKey) ?? true;

    _nightPrayReminderEnabled =
        prefs.getBool(_nightPrayReminderEnabledKey) ?? false;
    _nightPrayReminderHour = prefs.getInt(_nightPrayReminderHourKey) ?? 2;
    _nightPrayReminderMinute = prefs.getInt(_nightPrayReminderMinuteKey) ?? 0;
    _liveStatusEnabled = prefs.getBool(_liveStatusEnabledKey) ?? false;

    final savedSoundMode = prefs.getString(_soundModeKey);

    _soundMode = PrayerSoundMode.values.firstWhere(
      (mode) => mode.name == savedSoundMode,
      orElse: () => PrayerSoundMode.prayerVoice,
    );

    final savedAzanSound = prefs.getString(_selectedAzanSoundKey);

    if (savedAzanSound != null && azanSounds.contains(savedAzanSound)) {
      _selectedAzanSound = savedAzanSound;
    } else {
      _selectedAzanSound = 'azan_1';
    }

    final savedPrayers = prefs.getStringList(_selectedPrayersKey);

    if (savedPrayers == null || savedPrayers.isEmpty) {
      _selectedPrayers = List<String>.from(defaultPrayers);
    } else {
      _selectedPrayers = savedPrayers
          .where((prayer) => defaultPrayers.contains(prayer))
          .toList();

      if (_selectedPrayers.isEmpty) {
        _selectedPrayers = List<String>.from(defaultPrayers);
      }
    }

    _isLoaded = true;
    notifyListeners();

    if (_enabled) {
      final bool scheduled = await _schedulePrayerNotificationsFromCache();

      if (!scheduled) {
        _enabled = false;
        await prefs.setBool(_enabledKey, false);
        notifyListeners();
      }
    }

    if (_nightPrayReminderEnabled) {
      await _scheduleNightPrayReminder();
    }

    if (_liveStatusEnabled) {
      await PrayerWidgetSyncService.instance.setLiveStatusEnabled(true);
    }
  }

  Future<void> setEnabled(bool value) async {
    if (_isChanging) return;

    _isChanging = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    if (value) {
      final bool isAllowed = await NotificationService()
          .requestNotificationPermission();

      if (!isAllowed) {
        _enabled = false;
        await prefs.setBool(_enabledKey, false);

        _isChanging = false;
        notifyListeners();
        return;
      }

      final bool scheduled = await _schedulePrayerNotificationsFromCache();

      if (!scheduled) {
        _enabled = false;
        await prefs.setBool(_enabledKey, false);

        _isChanging = false;
        notifyListeners();
        return;
      }

      _enabled = true;
      await prefs.setBool(_enabledKey, true);
    } else {
      _enabled = false;
      await prefs.setBool(_enabledKey, false);

      await PrayerNotificationScheduler().cancelPrayerNotifications();
      await PrayerTrackingNotificationScheduler().cancelAllTrackingReminders();
    }

    _isChanging = false;
    notifyListeners();
  }

  Future<bool> refreshPrayerNotificationsAfterPrayerTimesUpdated() async {
    if (!_enabled) {
      return true;
    }

    final bool scheduled = await _schedulePrayerNotificationsFromCache();

    if (!scheduled) {
      final prefs = await SharedPreferences.getInstance();

      _enabled = false;
      await prefs.setBool(_enabledKey, false);

      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  Future<void> setNotifyAtPrayerTime(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    _notifyAtPrayerTime = value;
    await prefs.setBool(_notifyAtPrayerTimeKey, value);

    notifyListeners();

    if (_enabled) {
      await _schedulePrayerNotificationsFromCache();
    }
  }

  Future<void> setNotifyBeforePrayer(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    _notifyBeforePrayer = value;
    await prefs.setBool(_notifyBeforePrayerKey, value);

    notifyListeners();

    if (_enabled) {
      await _schedulePrayerNotificationsFromCache();
    }
  }

  Future<void> setNotifyBeforeMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();

    _notifyBeforeMinutes = minutes;
    await prefs.setInt(_notifyBeforeMinutesKey, minutes);

    notifyListeners();

    if (_enabled) {
      await _schedulePrayerNotificationsFromCache();
    }
  }

  Future<void> setSoundMode(PrayerSoundMode mode) async {
    final prefs = await SharedPreferences.getInstance();

    _soundMode = mode;
    await prefs.setString(_soundModeKey, mode.name);

    notifyListeners();

    if (_enabled) {
      await _schedulePrayerNotificationsFromCache();
    }
  }

  Future<void> setSelectedAzanSound(String soundName) async {
    if (!azanSounds.contains(soundName)) return;

    final prefs = await SharedPreferences.getInstance();

    _selectedAzanSound = soundName;
    await prefs.setString(_selectedAzanSoundKey, soundName);

    notifyListeners();

    if (_enabled && _soundMode == PrayerSoundMode.azan) {
      await _schedulePrayerNotificationsFromCache();
    }
  }

  Future<void> setAzanSoundEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    _azanSoundEnabled = value;
    await prefs.setBool(_azanSoundEnabledKey, value);

    notifyListeners();

    if (_enabled && _soundMode == PrayerSoundMode.azan) {
      await _schedulePrayerNotificationsFromCache();
    }
  }

  Future<void> setPrayerSoundEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    _prayerSoundEnabled = value;
    await prefs.setBool(_prayerSoundEnabledKey, value);

    notifyListeners();

    if (_enabled) {
      await _schedulePrayerNotificationsFromCache();
    }
  }

  Future<void> showTestNotification() async {
    final bool isAllowed = await NotificationService()
        .requestNotificationPermission();

    if (!isAllowed) {
      return;
    }

    await PrayerNotificationScheduler().showPrayerSoundTestNotification(
      soundMode: _soundMode,
      selectedAzanSound: _selectedAzanSound,
      azanSoundEnabled: _azanSoundEnabled,
      prayerSoundEnabled: _prayerSoundEnabled,
    );
  }

  Future<void> togglePrayerSelection(String prayer) async {
    if (!defaultPrayers.contains(prayer)) return;

    final prefs = await SharedPreferences.getInstance();

    if (_selectedPrayers.contains(prayer)) {
      _selectedPrayers.remove(prayer);
    } else {
      _selectedPrayers.add(prayer);
    }

    _selectedPrayers.sort((a, b) {
      return defaultPrayers.indexOf(a).compareTo(defaultPrayers.indexOf(b));
    });

    await prefs.setStringList(_selectedPrayersKey, _selectedPrayers);

    notifyListeners();

    if (_enabled) {
      await _schedulePrayerNotificationsFromCache();
    }
  }

  Future<void> selectAllPrayers() async {
    final prefs = await SharedPreferences.getInstance();

    _selectedPrayers = List<String>.from(defaultPrayers);
    await prefs.setStringList(_selectedPrayersKey, _selectedPrayers);

    notifyListeners();

    if (_enabled) {
      await _schedulePrayerNotificationsFromCache();
    }
  }

  Future<void> clearSelectedPrayers() async {
    final prefs = await SharedPreferences.getInstance();

    _selectedPrayers = [];
    await prefs.setStringList(_selectedPrayersKey, _selectedPrayers);

    notifyListeners();

    if (_enabled) {
      await _schedulePrayerNotificationsFromCache();
    }
  }

  Future<void> setProgressRemindersEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    _progressRemindersEnabled = value;
    await prefs.setBool(_progressRemindersEnabledKey, value);

    notifyListeners();

    if (_enabled) {
      await _schedulePrayerNotificationsFromCache();
    } else if (!value) {
      await PrayerTrackingNotificationScheduler().cancelAllTrackingReminders();
    }
  }

  Future<void> setDailySummaryEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    _dailySummaryEnabled = value;
    await prefs.setBool(_dailySummaryEnabledKey, value);

    notifyListeners();

    if (!_enabled || !value) {
      await PrayerTrackingNotificationScheduler().cancelDailySummaryReminder();
    }
  }

  Future<void> setAchievementNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    _achievementNotificationsEnabled = value;
    await prefs.setBool(_achievementNotificationsEnabledKey, value);

    notifyListeners();
  }

  Future<void> setAfterPrayerAzkarReminderEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    _afterPrayerAzkarReminderEnabled = value;
    await prefs.setBool(_afterPrayerAzkarReminderEnabledKey, value);

    notifyListeners();

    if (!value) {
      await PrayerTrackingNotificationScheduler()
          .cancelAfterPrayerAzkarReminder();
    }
  }

  Future<void> setNightPrayReminderEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    if (value) {
      final bool isAllowed = await NotificationService()
          .requestNotificationPermission();

      if (!isAllowed) {
        _nightPrayReminderEnabled = false;
        await prefs.setBool(_nightPrayReminderEnabledKey, false);
        await PrayerNotificationScheduler().cancelNightPrayReminder();

        notifyListeners();
        return;
      }
    }

    _nightPrayReminderEnabled = value;
    await prefs.setBool(_nightPrayReminderEnabledKey, value);

    notifyListeners();

    if (value) {
      await _scheduleNightPrayReminder();
    } else {
      await PrayerNotificationScheduler().cancelNightPrayReminder();
    }
  }

  Future<void> setNightPrayReminderTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();

    _nightPrayReminderHour = time.hour;
    _nightPrayReminderMinute = time.minute;

    await prefs.setInt(_nightPrayReminderHourKey, _nightPrayReminderHour);
    await prefs.setInt(_nightPrayReminderMinuteKey, _nightPrayReminderMinute);

    notifyListeners();

    if (_nightPrayReminderEnabled) {
      await _scheduleNightPrayReminder();
    }
  }

  Future<void> setLiveStatusEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    if (value) {
      final bool isAllowed = await NotificationService()
          .requestNotificationPermission();

      if (!isAllowed) {
        _liveStatusEnabled = false;
        await prefs.setBool(_liveStatusEnabledKey, false);
        notifyListeners();
        return;
      }
    }

    _liveStatusEnabled = value;
    await prefs.setBool(_liveStatusEnabledKey, value);
    notifyListeners();

    await PrayerWidgetSyncService.instance.setLiveStatusEnabled(value);
  }

  Future<void> _scheduleNightPrayReminder() async {
    await PrayerNotificationScheduler().scheduleNightPrayReminder(
      enabled: _nightPrayReminderEnabled,
      hour: _nightPrayReminderHour,
      minute: _nightPrayReminderMinute,
    );
  }

  Future<bool> _schedulePrayerNotificationsFromCache() async {
    final cachedPrayerWeek = await _prayerTimeService.getCachedPrayerWeek();

    if (cachedPrayerWeek.isEmpty) {
      debugPrint(
        '⚠️ Prayer notifications were not scheduled because cached prayer times are empty.',
      );
      return false;
    }

    await PrayerNotificationScheduler().cancelPrayerNotifications();

    await PrayerNotificationScheduler().schedulePrayerNotifications(
      prayerWeek: cachedPrayerWeek,
      selectedPrayers: _selectedPrayers,
      notifyAtPrayerTime: _notifyAtPrayerTime,
      notifyBeforePrayer: _notifyBeforePrayer,
      notifyBeforeMinutes: _notifyBeforeMinutes,
      soundMode: _soundMode,
      selectedAzanSound: _selectedAzanSound,
      azanSoundEnabled: _azanSoundEnabled,
      prayerSoundEnabled: _prayerSoundEnabled,
    );

    if (_progressRemindersEnabled) {
      await PrayerTrackingNotificationScheduler().scheduleTrackingReminders(
        prayerWeek: cachedPrayerWeek,
        selectedPrayers: _selectedPrayers,
        onTimeGraceMinutes: 60,
        lastChanceBeforeNextPrayerMinutes: 30,
        lockWarningBeforeMinutes: 5,
      );
    } else {
      await PrayerTrackingNotificationScheduler().cancelAllTrackingReminders();
    }

    return true;
  }
}
