import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/video_content_type.dart';
import '../models/youtube_playlist_model.dart';

class PlaylistCacheStorage {
  PlaylistCacheStorage._();

  static const String _playlistsPrefix = 'cached_playlists_v1_';
  static const String _updatedAtPrefix = 'cached_playlists_updated_at_v1_';

  static String _typeKey(VideoContentType? type, String? category) {
    final typePart = type?.name ?? 'all';
    final categoryPart = category?.trim().isNotEmpty == true
        ? category!.trim()
        : 'all';

    return '${typePart}_$categoryPart';
  }

  static String _playlistsKey(VideoContentType? type, String? category) {
    return '$_playlistsPrefix${_typeKey(type, category)}';
  }

  static String _updatedAtKey(VideoContentType? type, String? category) {
    return '$_updatedAtPrefix${_typeKey(type, category)}';
  }

  static Future<void> savePlaylists({
    required List<YoutubePlaylistModel> playlists,
    VideoContentType? type,
    String? category,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final encodedPlaylists = playlists.map((playlist) {
      return jsonEncode(playlist.toMap());
    }).toList();

    await prefs.setStringList(
      _playlistsKey(type, category),
      encodedPlaylists,
    );

    await prefs.setString(
      _updatedAtKey(type, category),
      DateTime.now().toIso8601String(),
    );
  }

  static Future<List<YoutubePlaylistModel>> getPlaylists({
    VideoContentType? type,
    String? category,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final rawPlaylists = prefs.getStringList(
      _playlistsKey(type, category),
    ) ??
        [];

    final playlists = <YoutubePlaylistModel>[];

    for (final rawPlaylist in rawPlaylists) {
      try {
        final decoded = jsonDecode(rawPlaylist) as Map<String, dynamic>;
        final playlist = YoutubePlaylistModel.fromMap(decoded);

        if (playlist.playlistId.trim().isNotEmpty &&
            playlist.title.trim().isNotEmpty) {
          playlists.add(playlist);
        }
      } catch (_) {
        // Ignore broken cached playlist.
      }
    }

    return playlists;
  }

  static Future<DateTime?> getLastUpdatedAt({
    VideoContentType? type,
    String? category,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final rawDate = prefs.getString(_updatedAtKey(type, category));

    if (rawDate == null || rawDate.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(rawDate);
  }

  static Future<void> clearPlaylists({
    VideoContentType? type,
    String? category,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_playlistsKey(type, category));
    await prefs.remove(_updatedAtKey(type, category));
  }
}