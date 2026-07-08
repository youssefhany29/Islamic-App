import 'package:flutter/foundation.dart';

import '../models/youtube_playlist_model.dart';
import '../models/youtube_video_model.dart';
import 'cached_videos_api_service.dart';
import 'video_cache_storage.dart';

class VideosRepository {
  VideosRepository._();

  static const String _mergedVideosCacheKey = 'merged_videos_from_backend';

  static bool lastPlaylistVideosUsedCacheFallback = false;
  static bool lastMergedVideosUsedCacheFallback = false;

  static Future<List<YoutubeVideoModel>> getPlaylistVideos({
    required YoutubePlaylistModel playlist,
    int maxResults = 0,
    bool forceRefresh = false,
  }) async {
    lastPlaylistVideosUsedCacheFallback = false;

    final cachedVideos = await VideoCacheStorage.getPlaylistVideos(
      playlist.playlistId,
    );

    debugPrint('🎬 Playlist: ${playlist.title}');
    debugPrint('🎬 Cached videos: ${cachedVideos.length}');
    debugPrint('🌐 Backend request playlistId: ${playlist.playlistId}');

    try {
      final backendVideos = await CachedVideosApiService.getAllVideos(
        playlistId: playlist.playlistId,
        maxItems: maxResults,
        pageSize: 50,
      );

      final videosToReturn = maxResults > 0
          ? backendVideos.take(maxResults).toList()
          : backendVideos;

      debugPrint('✅ Backend playlist videos loaded: ${videosToReturn.length}');

      if (videosToReturn.isNotEmpty) {
        await VideoCacheStorage.savePlaylistVideos(
          playlistId: playlist.playlistId,
          videos: videosToReturn,
        );

        return videosToReturn;
      }

      debugPrint('⚠️ Backend returned empty playlist videos, fallback cache');

      if (cachedVideos.isNotEmpty) {
        lastPlaylistVideosUsedCacheFallback = true;
      }

      return maxResults > 0
          ? cachedVideos.take(maxResults).toList()
          : cachedVideos;
    } catch (error) {
      debugPrint('❌ Failed to load playlist from backend: $error');
      debugPrint('⚠️ Returning cached videos: ${cachedVideos.length}');

      if (cachedVideos.isNotEmpty) {
        lastPlaylistVideosUsedCacheFallback = true;
      }

      return maxResults > 0
          ? cachedVideos.take(maxResults).toList()
          : cachedVideos;
    }
  }

  static Future<List<YoutubeVideoModel>> getMergedVideos({
    required List<YoutubePlaylistModel> playlists,
    int maxResultsPerPlaylist = 0,
    bool forceRefresh = false,
  }) async {
    lastMergedVideosUsedCacheFallback = false;

    final cachedVideos = await VideoCacheStorage.getPlaylistVideos(
      _mergedVideosCacheKey,
    );

    debugPrint('🌐 Backend request merged videos');
    debugPrint('🎬 Cached merged videos: ${cachedVideos.length}');

    try {
      final maxItems = maxResultsPerPlaylist > 0 && playlists.isNotEmpty
          ? playlists.length * maxResultsPerPlaylist
          : 0;

      final backendVideos = await CachedVideosApiService.getAllVideos(
        maxItems: maxItems,
        pageSize: 50,
      );

      final uniqueVideos = <String, YoutubeVideoModel>{};

      for (final video in backendVideos) {
        uniqueVideos[video.id] = video;
      }

      final allVideos = uniqueVideos.values.toList();

      allVideos.sort((a, b) {
        final aDate = DateTime.tryParse(a.publishedAt);
        final bDate = DateTime.tryParse(b.publishedAt);

        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;

        return bDate.compareTo(aDate);
      });

      debugPrint('✅ Backend merged videos loaded: ${allVideos.length}');

      if (allVideos.isNotEmpty) {
        await VideoCacheStorage.savePlaylistVideos(
          playlistId: _mergedVideosCacheKey,
          videos: allVideos,
        );

        return allVideos;
      }

      debugPrint('⚠️ Backend returned empty merged videos, fallback cache');

      if (cachedVideos.isNotEmpty) {
        lastMergedVideosUsedCacheFallback = true;
      }

      return cachedVideos;
    } catch (error) {
      debugPrint('❌ Failed to load merged videos from backend: $error');
      debugPrint('⚠️ Returning cached merged videos: ${cachedVideos.length}');

      if (cachedVideos.isNotEmpty) {
        lastMergedVideosUsedCacheFallback = true;
      }

      return cachedVideos;
    }
  }
}