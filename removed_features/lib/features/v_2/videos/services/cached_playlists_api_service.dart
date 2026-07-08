import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/video_content_type.dart';
import '../models/youtube_playlist_model.dart';
import 'cached_videos_api_service.dart';
import 'playlist_cache_storage.dart';
import 'videos_api_exception.dart';

class CachedPlaylistsApiService {
  CachedPlaylistsApiService._();

  static const Duration _timeout = Duration(seconds: 12);

  static bool lastLoadUsedCacheFallback = false;

  static Future<List<YoutubePlaylistModel>> getPlaylists({
    VideoContentType? type,
    String? category,
    bool allowCacheFallback = true,
  }) async {
    lastLoadUsedCacheFallback = false;

    try {
      final playlists = await _fetchPlaylists(
        type: type,
        category: category,
      );

      if (playlists.isNotEmpty) {
        await PlaylistCacheStorage.savePlaylists(
          playlists: playlists,
          type: type,
          category: category,
        );
      }

      return playlists;
    } catch (_) {
      if (!allowCacheFallback) {
        rethrow;
      }

      final cachedPlaylists = await PlaylistCacheStorage.getPlaylists(
        type: type,
        category: category,
      );

      if (cachedPlaylists.isNotEmpty) {
        lastLoadUsedCacheFallback = true;
        return cachedPlaylists;
      }

      rethrow;
    }
  }

  static Future<List<YoutubePlaylistModel>> _fetchPlaylists({
    VideoContentType? type,
    String? category,
  }) async {
    final uri = Uri.parse('${CachedVideosApiService.baseUrl}/api/playlists')
        .replace(
      queryParameters: {
        if (type != null) 'type': type.name,
        if (category != null && category.trim().isNotEmpty)
          'category': category.trim(),
      },
    );

    try {
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode != 200) {
        throw VideosApiException(
          'تعذر تحميل قوائم الفيديوهات',
          statusCode: response.statusCode,
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw const VideosApiException('استجابة قوائم الفيديوهات غير صحيحة');
      }

      if (decoded['success'] != true) {
        throw VideosApiException(
          decoded['message']?.toString() ?? 'فشل تحميل قوائم الفيديوهات',
        );
      }

      final data = decoded['data'];

      if (data is! Map<String, dynamic>) {
        throw const VideosApiException('بيانات قوائم الفيديوهات غير صحيحة');
      }

      final playlists = data['playlists'] as List<dynamic>? ?? [];

      return playlists
          .whereType<Map<String, dynamic>>()
          .map(YoutubePlaylistModel.fromBackendJson)
          .where((playlist) => playlist.playlistId.trim().isNotEmpty)
          .where((playlist) => playlist.title.trim().isNotEmpty)
          .toList();
    } on TimeoutException catch (error) {
      throw VideosApiException(
        'انتهت مهلة تحميل قوائم الفيديوهات',
        originalError: error,
      );
    } on SocketException catch (error) {
      throw VideosApiException(
        'لا يوجد اتصال إنترنت مستقر',
        originalError: error,
      );
    } on FormatException catch (error) {
      throw VideosApiException(
        'صيغة قوائم الفيديوهات غير صحيحة',
        originalError: error,
      );
    } on http.ClientException catch (error) {
      throw VideosApiException(
        'حدثت مشكلة أثناء الاتصال بالسيرفر',
        originalError: error,
      );
    }
  }
}