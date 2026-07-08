import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/youtube_video_model.dart';
import 'videos_api_exception.dart';

class CachedVideosApiService {
  CachedVideosApiService._();

  static const String baseUrl = 'https://islamic-videos-api.onrender.com';

  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  static const Duration _timeout = Duration(seconds: 12);

  static Future<List<YoutubeVideoModel>> getVideos({
    String? category,
    String? playlistId,
    String? sheikhName,
    int page = 1,
    int limit = defaultPageSize,
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safeLimit = _safeLimit(limit);

    final uri = Uri.parse('$baseUrl/api/videos').replace(
      queryParameters: {
        if (category != null && category.trim().isNotEmpty)
          'category': category.trim(),
        if (playlistId != null && playlistId.trim().isNotEmpty)
          'playlistId': playlistId.trim(),
        if (sheikhName != null && sheikhName.trim().isNotEmpty)
          'sheikhName': sheikhName.trim(),
        'page': safePage.toString(),
        'limit': safeLimit.toString(),
      },
    );

    final data = await _getDataMap(uri);
    final videos = data['videos'] as List<dynamic>? ?? [];

    return _parseVideos(videos);
  }

  static Future<List<YoutubeVideoModel>> getAllVideos({
    String? category,
    String? playlistId,
    String? sheikhName,
    int maxItems = 0,
    int pageSize = defaultPageSize,
  }) async {
    final hasLimit = maxItems > 0;
    final safePageSize = _safeLimit(pageSize);

    final allVideos = <YoutubeVideoModel>[];
    var page = 1;
    var hasMore = true;

    while (hasMore) {
      if (hasLimit && allVideos.length >= maxItems) {
        break;
      }

      final uri = Uri.parse('$baseUrl/api/videos').replace(
        queryParameters: {
          if (category != null && category.trim().isNotEmpty)
            'category': category.trim(),
          if (playlistId != null && playlistId.trim().isNotEmpty)
            'playlistId': playlistId.trim(),
          if (sheikhName != null && sheikhName.trim().isNotEmpty)
            'sheikhName': sheikhName.trim(),
          'page': page.toString(),
          'limit': safePageSize.toString(),
        },
      );

      final data = await _getDataMap(uri);
      final rawVideos = data['videos'] as List<dynamic>? ?? [];
      final pagination = data['pagination'] as Map<String, dynamic>? ?? {};

      final pageVideos = _parseVideos(rawVideos);

      allVideos.addAll(pageVideos);

      hasMore = pagination['hasMore'] == true;

      if (pageVideos.isEmpty) {
        hasMore = false;
      }

      page++;
    }

    final uniqueVideos = <String, YoutubeVideoModel>{};

    for (final video in allVideos) {
      uniqueVideos[video.id] = video;
    }

    final result = uniqueVideos.values.toList();

    if (hasLimit) {
      return result.take(maxItems).toList();
    }

    return result;
  }

  static int _safeLimit(int limit) {
    if (limit < 1) {
      return defaultPageSize;
    }

    if (limit > maxPageSize) {
      return maxPageSize;
    }

    return limit;
  }

  static Future<Map<String, dynamic>> _getDataMap(Uri uri) async {
    try {
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode != 200) {
        throw VideosApiException(
          'تعذر تحميل الفيديوهات من السيرفر',
          statusCode: response.statusCode,
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw const VideosApiException('استجابة السيرفر غير صحيحة');
      }

      if (decoded['success'] != true) {
        throw VideosApiException(
          decoded['message']?.toString() ?? 'فشل تحميل الفيديوهات',
        );
      }

      final data = decoded['data'];

      if (data is! Map<String, dynamic>) {
        throw const VideosApiException('بيانات الفيديوهات غير صحيحة');
      }

      return data;
    } on TimeoutException catch (error) {
      throw VideosApiException(
        'انتهت مهلة الاتصال بالسيرفر',
        originalError: error,
      );
    } on SocketException catch (error) {
      throw VideosApiException(
        'لا يوجد اتصال إنترنت مستقر',
        originalError: error,
      );
    } on FormatException catch (error) {
      throw VideosApiException(
        'صيغة البيانات القادمة من السيرفر غير صحيحة',
        originalError: error,
      );
    } on http.ClientException catch (error) {
      throw VideosApiException(
        'حدثت مشكلة أثناء الاتصال بالسيرفر',
        originalError: error,
      );
    }
  }

  static List<YoutubeVideoModel> _parseVideos(List<dynamic> rawVideos) {
    return rawVideos
        .whereType<Map<String, dynamic>>()
        .map(YoutubeVideoModel.fromBackendJson)
        .where((video) => video.id.trim().isNotEmpty)
        .where((video) => video.title.trim().isNotEmpty)
        .where((video) => video.title.toLowerCase() != 'private video')
        .where((video) => video.title.toLowerCase() != 'deleted video')
        .toList();
  }
}