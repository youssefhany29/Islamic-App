import 'package:shared_preferences/shared_preferences.dart';

import '../models/reciter_model.dart';

class RecitationSavedProgress {
  final Duration position;
  final Duration duration;
  final int lastListenedAtMs;

  const RecitationSavedProgress({
    required this.position,
    required this.duration,
    required this.lastListenedAtMs,
  });

  bool get hasProgress => position.inSeconds > 5;

  double get progress {
    if (duration.inMilliseconds <= 0) return 0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }
}

class RecitationProgressStorage {
  RecitationProgressStorage._();

  static const String _lastReciterIdKey = 'last_recitation_reciter_id';
  static const String _lastReciterNameKey = 'last_recitation_reciter_name';
  static const String _lastReciterSourceKey = 'last_recitation_reciter_source';
  static const String _lastMp3ServerKey = 'last_recitation_mp3_server';
  static const String _lastSurahNumberKey = 'last_recitation_surah_number';
  static const String _lastSurahNameKey = 'last_recitation_surah_name';
  static const String _lastAudioUrlKey = 'last_recitation_audio_url';
  static const String _lastPositionSecondsKey =
      'last_recitation_position_seconds';
  static const String _lastDurationSecondsKey =
      'last_recitation_duration_seconds';

  static String _progressKey({
    required int reciterId,
    required RecitationSource reciterSource,
    required int surahNumber,
  }) {
    return 'recitation_progress_${reciterSource.name}_${reciterId}_$surahNumber';
  }

  static String _durationKey({
    required int reciterId,
    required RecitationSource reciterSource,
    required int surahNumber,
  }) {
    return 'recitation_duration_${reciterSource.name}_${reciterId}_$surahNumber';
  }

  static String _lastListenedAtKey({
    required int reciterId,
    required RecitationSource reciterSource,
    required int surahNumber,
  }) {
    return 'recitation_last_listened_at_${reciterSource.name}_${reciterId}_$surahNumber';
  }

  static Future<void> saveLastRecitation({
    required int reciterId,
    required String reciterName,
    required RecitationSource reciterSource,
    required String mp3QuranServerUrl,
    required int surahNumber,
    required String surahName,
    required String audioUrl,
    required int positionSeconds,
    required int durationSeconds,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final safePositionSeconds = positionSeconds < 0 ? 0 : positionSeconds;
    final safeDurationSeconds = durationSeconds < 0 ? 0 : durationSeconds;

    await prefs.setInt(_lastReciterIdKey, reciterId);
    await prefs.setString(_lastReciterNameKey, reciterName);
    await prefs.setString(_lastReciterSourceKey, reciterSource.name);
    await prefs.setString(_lastMp3ServerKey, mp3QuranServerUrl);
    await prefs.setInt(_lastSurahNumberKey, surahNumber);
    await prefs.setString(_lastSurahNameKey, surahName);
    await prefs.setString(_lastAudioUrlKey, audioUrl);
    await prefs.setInt(_lastPositionSecondsKey, safePositionSeconds);
    await prefs.setInt(_lastDurationSecondsKey, safeDurationSeconds);

    await saveRecitationProgress(
      reciterId: reciterId,
      reciterSource: reciterSource,
      surahNumber: surahNumber,
      positionSeconds: safePositionSeconds,
      durationSeconds: safeDurationSeconds,
    );
  }

  static Future<void> saveRecitationProgress({
    required int reciterId,
    required RecitationSource reciterSource,
    required int surahNumber,
    required int positionSeconds,
    required int durationSeconds,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final safePositionSeconds = positionSeconds < 0 ? 0 : positionSeconds;
    final safeDurationSeconds = durationSeconds < 0 ? 0 : durationSeconds;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await prefs.setInt(
      _progressKey(
        reciterId: reciterId,
        reciterSource: reciterSource,
        surahNumber: surahNumber,
      ),
      safePositionSeconds,
    );

    await prefs.setInt(
      _durationKey(
        reciterId: reciterId,
        reciterSource: reciterSource,
        surahNumber: surahNumber,
      ),
      safeDurationSeconds,
    );

    await prefs.setInt(
      _lastListenedAtKey(
        reciterId: reciterId,
        reciterSource: reciterSource,
        surahNumber: surahNumber,
      ),
      nowMs,
    );
  }

  static Future<RecitationSavedProgress> getSavedProgressInfo({
    required int reciterId,
    required RecitationSource reciterSource,
    required int surahNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final positionSeconds = prefs.getInt(
          _progressKey(
            reciterId: reciterId,
            reciterSource: reciterSource,
            surahNumber: surahNumber,
          ),
        ) ??
        0;

    final durationSeconds = prefs.getInt(
          _durationKey(
            reciterId: reciterId,
            reciterSource: reciterSource,
            surahNumber: surahNumber,
          ),
        ) ??
        0;

    final lastListenedAtMs = prefs.getInt(
          _lastListenedAtKey(
            reciterId: reciterId,
            reciterSource: reciterSource,
            surahNumber: surahNumber,
          ),
        ) ??
        0;

    return RecitationSavedProgress(
      position: Duration(seconds: positionSeconds < 0 ? 0 : positionSeconds),
      duration: Duration(seconds: durationSeconds < 0 ? 0 : durationSeconds),
      lastListenedAtMs: lastListenedAtMs,
    );
  }

  static Future<Duration> getSavedPositionForRecitation({
    required int reciterId,
    required RecitationSource reciterSource,
    required int surahNumber,
  }) async {
    final progress = await getSavedProgressInfo(
      reciterId: reciterId,
      reciterSource: reciterSource,
      surahNumber: surahNumber,
    );

    return progress.position;
  }

  static Future<Duration> getSavedDurationForRecitation({
    required int reciterId,
    required RecitationSource reciterSource,
    required int surahNumber,
  }) async {
    final progress = await getSavedProgressInfo(
      reciterId: reciterId,
      reciterSource: reciterSource,
      surahNumber: surahNumber,
    );

    return progress.duration;
  }

  static Future<void> clearRecitationProgress({
    required int reciterId,
    required RecitationSource reciterSource,
    required int surahNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(
      _progressKey(
        reciterId: reciterId,
        reciterSource: reciterSource,
        surahNumber: surahNumber,
      ),
    );

    await prefs.remove(
      _durationKey(
        reciterId: reciterId,
        reciterSource: reciterSource,
        surahNumber: surahNumber,
      ),
    );

    await prefs.remove(
      _lastListenedAtKey(
        reciterId: reciterId,
        reciterSource: reciterSource,
        surahNumber: surahNumber,
      ),
    );
  }

  static Future<Map<String, dynamic>?> getLastRecitation() async {
    final prefs = await SharedPreferences.getInstance();

    final reciterId = prefs.getInt(_lastReciterIdKey);
    final reciterName = prefs.getString(_lastReciterNameKey);
    final sourceText = prefs.getString(_lastReciterSourceKey);
    final mp3Server = prefs.getString(_lastMp3ServerKey) ?? '';
    final surahNumber = prefs.getInt(_lastSurahNumberKey);
    final surahName = prefs.getString(_lastSurahNameKey);
    final audioUrl = prefs.getString(_lastAudioUrlKey);
    final positionSeconds = prefs.getInt(_lastPositionSecondsKey) ?? 0;
    final durationSeconds = prefs.getInt(_lastDurationSecondsKey) ?? 0;

    if (reciterId == null ||
        reciterName == null ||
        sourceText == null ||
        surahNumber == null ||
        surahName == null ||
        audioUrl == null) {
      return null;
    }

    final source = RecitationSource.values.firstWhere(
      (item) => item.name == sourceText,
      orElse: () => RecitationSource.quranCom,
    );

    return {
      'reciterId': reciterId,
      'reciterName': reciterName,
      'reciterSource': source,
      'mp3QuranServerUrl': mp3Server,
      'surahNumber': surahNumber,
      'surahName': surahName,
      'audioUrl': audioUrl,
      'positionSeconds': positionSeconds,
      'durationSeconds': durationSeconds,
    };
  }
}
