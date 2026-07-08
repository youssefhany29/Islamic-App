import '../models/youtube_video_model.dart';

class YoutubeApiService {
  YoutubeApiService._();

  static Future<List<YoutubeVideoModel>> getPlaylistVideos({
    required String playlistId,
    int maxResults = 50,
    int maxPages = 10,
  }) async {
    throw UnsupportedError(
      'Direct YouTube API calls are disabled. Use the backend API instead.',
    );
  }
}