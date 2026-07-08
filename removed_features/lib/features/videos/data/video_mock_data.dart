import '../models/video_content_type.dart';
import '../models/youtube_playlist_model.dart';

class VideoMockData {
  VideoMockData._();

  static const List<YoutubePlaylistModel> fallbackPlaylists = [
    YoutubePlaylistModel(
      id: 'riwaythom_podcast',
      title: 'بودكاست روايتهم',
      subtitle: 'قصص وحوارات فكرية وتاريخية',
      playlistId: 'PLHKygUMQQ5Gfsfb6vdjQZaZ0N3FJ9dyIL',
      imageAsset: 'assets/icons/porcaster.png',
      type: VideoContentType.podcasts,
    ),
    YoutubePlaylistModel(
      id: 'eh_el_moshkla_season_1',
      title: 'إيه المشكلة - الموسم الأول',
      subtitle: 'بودكاست ديني وفكري',
      playlistId: 'PLlXQj2VGUTmdUP1KDQ9pkmKJU-KDNOkwt',
      imageAsset: 'assets/icons/porcaster.png',
      type: VideoContentType.podcasts,
    ),
    YoutubePlaylistModel(
      id: 'eh_el_moshkla_season_3',
      title: 'إيه المشكلة - الموسم الثالث',
      subtitle: 'بودكاست ديني وفكري',
      playlistId: 'PLlXQj2VGUTmfi3ynjo8TmFhA7vbZE9xCP',
      imageAsset: 'assets/icons/porcaster.png',
      type: VideoContentType.podcasts,
    ),
    YoutubePlaylistModel(
      id: 'eh_el_moshkla_season_4',
      title: 'إيه المشكلة - الموسم الرابع',
      subtitle: 'بودكاست ديني وفكري',
      playlistId: 'PLlXQj2VGUTmdkcN88VsaeitPrQpRHMaOW',
      imageAsset: 'assets/icons/porcaster.png',
      type: VideoContentType.podcasts,
    ),
    YoutubePlaylistModel(
      id: 'ala_el_maghrib_1',
      title: 'عالمغرب 1',
      subtitle: 'برنامج ديني',
      playlistId: 'PLlXQj2VGUTmdN73dvFG17xdOCoM2E1K66',
      imageAsset: 'assets/icons/porcaster.png',
      type: VideoContentType.podcasts,
    ),
    YoutubePlaylistModel(
      id: 'ala_el_maghrib_2',
      title: 'عالمغرب 2',
      subtitle: 'برنامج ديني',
      playlistId: 'PLlXQj2VGUTmfOrpzgytlcIlu38pQWh4UJ',
      imageAsset: 'assets/icons/porcaster.png',
      type: VideoContentType.podcasts,
    ),
  ];

  static List<YoutubePlaylistModel> playlistsByType(VideoContentType type) {
    return fallbackPlaylists
        .where((playlist) => playlist.type == type)
        .toList();
  }
}