import 'package:shared_preferences/shared_preferences.dart';

class VideoProgressStorage {
  VideoProgressStorage._();

  static const String _lastVideoPrefix = 'last_video_for_playlist_';
  static const String _lastPositionPrefix = 'last_video_position_';
  static const String _lastDurationPrefix = 'last_video_duration_';

  static const String _globalLastVideoIdKey = 'global_last_video_id';
  static const String _globalLastPlaylistIdKey = 'global_last_playlist_id';

  static String _lastVideoKey(String playlistId) {
    return '$_lastVideoPrefix$playlistId';
  }

  static String _lastPositionKey(String videoId) {
    return '$_lastPositionPrefix$videoId';
  }

  static String _lastDurationKey(String videoId) {
    return '$_lastDurationPrefix$videoId';
  }

  static Future<void> saveLastVideo({
    required String playlistId,
    required String videoId,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_lastVideoKey(playlistId), videoId);
    await prefs.setString(_globalLastVideoIdKey, videoId);
    await prefs.setString(_globalLastPlaylistIdKey, playlistId);
  }

  static Future<void> saveVideoPosition({
    required String videoId,
    required int positionSeconds,
    required int durationSeconds,
  }) async {
    if (videoId.trim().isEmpty) return;
    if (durationSeconds <= 0) return;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_lastPositionKey(videoId), positionSeconds);
    await prefs.setInt(_lastDurationKey(videoId), durationSeconds);
  }

  static Future<String?> getLastVideoId(String playlistId) async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_lastVideoKey(playlistId));
  }

  static Future<String?> getGlobalLastVideoId() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_globalLastVideoIdKey);
  }

  static Future<String?> getGlobalLastPlaylistId() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_globalLastPlaylistIdKey);
  }

  static Future<int> getVideoPositionSeconds(String videoId) async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getInt(_lastPositionKey(videoId)) ?? 0;
  }

  static Future<int> getVideoDurationSeconds(String videoId) async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getInt(_lastDurationKey(videoId)) ?? 0;
  }

  static Future<double> getVideoProgressPercent(String videoId) async {
    final position = await getVideoPositionSeconds(videoId);
    final duration = await getVideoDurationSeconds(videoId);

    if (duration <= 0) return 0;

    final percent = position / duration;

    if (percent < 0) return 0;
    if (percent > 1) return 1;

    return percent;
  }
}