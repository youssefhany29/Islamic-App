import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/youtube_video_model.dart';

class VideoCacheStorage {
  VideoCacheStorage._();

  static const String _videosPrefix = 'cached_videos_for_playlist_v3_';
  static const String _lastUpdatePrefix = 'cached_videos_updated_at_v3_';

  static const int _maxCachedVideosPerList = 1000;

  static String _videosKey(String playlistId) {
    return '$_videosPrefix$playlistId';
  }

  static String _lastUpdateKey(String playlistId) {
    return '$_lastUpdatePrefix$playlistId';
  }

  static Future<void> savePlaylistVideos({
    required String playlistId,
    required List<YoutubeVideoModel> videos,
  }) async {
    if (playlistId.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();

    final uniqueVideos = <String, YoutubeVideoModel>{};

    for (final video in videos) {
      if (video.id.trim().isNotEmpty && video.title.trim().isNotEmpty) {
        uniqueVideos[video.id] = video;
      }
    }

    final limitedVideos = uniqueVideos.values.take(_maxCachedVideosPerList);

    final encodedVideos = limitedVideos.map((video) {
      return jsonEncode(video.toMap());
    }).toList();

    await prefs.setStringList(_videosKey(playlistId), encodedVideos);

    await prefs.setString(
      _lastUpdateKey(playlistId),
      DateTime.now().toIso8601String(),
    );
  }

  static Future<List<YoutubeVideoModel>> getPlaylistVideos(
      String playlistId,
      ) async {
    if (playlistId.trim().isEmpty) {
      return [];
    }

    final prefs = await SharedPreferences.getInstance();
    final rawVideos = prefs.getStringList(_videosKey(playlistId)) ?? [];

    final videos = <YoutubeVideoModel>[];

    for (final rawVideo in rawVideos) {
      try {
        final decoded = jsonDecode(rawVideo) as Map<String, dynamic>;
        final video = YoutubeVideoModel.fromMap(decoded);

        if (video.id.trim().isNotEmpty && video.title.trim().isNotEmpty) {
          videos.add(video);
        }
      } catch (_) {
        // Ignore broken cached item.
      }
    }

    return videos;
  }

  static Future<DateTime?> getLastUpdatedAt(String playlistId) async {
    if (playlistId.trim().isEmpty) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final rawLastUpdate = prefs.getString(_lastUpdateKey(playlistId));

    if (rawLastUpdate == null || rawLastUpdate.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(rawLastUpdate);
  }

  static Future<bool> shouldRefreshAfter({
    required String playlistId,
    Duration maxAge = const Duration(hours: 12),
  }) async {
    final lastUpdate = await getLastUpdatedAt(playlistId);

    if (lastUpdate == null) {
      return true;
    }

    return DateTime.now().difference(lastUpdate) >= maxAge;
  }

  static Future<bool> shouldRefreshToday(String playlistId) async {
    final lastUpdate = await getLastUpdatedAt(playlistId);

    if (lastUpdate == null) {
      return true;
    }

    final now = DateTime.now();

    final todayMidnight = DateTime(
      now.year,
      now.month,
      now.day,
    );

    return lastUpdate.isBefore(todayMidnight);
  }

  static Future<void> clearPlaylistCache(String playlistId) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_videosKey(playlistId));
    await prefs.remove(_lastUpdateKey(playlistId));
  }
}