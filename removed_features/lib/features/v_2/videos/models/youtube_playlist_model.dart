import 'video_content_type.dart';

class YoutubePlaylistModel {
  final String id;
  final String title;
  final String subtitle;
  final String playlistId;
  final String imageAsset;
  final VideoContentType type;

  const YoutubePlaylistModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.playlistId,
    required this.imageAsset,
    required this.type,
  });

  factory YoutubePlaylistModel.fromBackendJson(Map<String, dynamic> json) {
    final contentType = json['content_type']?.toString() ?? 'videos';
    final category = json['video_categories'] as Map<String, dynamic>?;

    final sheikhName = json['sheikh_name']?.toString() ?? '';
    final categoryName = category?['name_ar']?.toString() ?? '';

    String subtitle = json['subtitle']?.toString() ?? '';

    if (subtitle.trim().isEmpty && sheikhName.trim().isNotEmpty) {
      subtitle = sheikhName;
    }

    if (subtitle.trim().isEmpty && categoryName.trim().isNotEmpty) {
      subtitle = categoryName;
    }

    return YoutubePlaylistModel(
      id: json['id']?.toString() ?? json['playlist_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'بدون عنوان',
      subtitle: subtitle,
      playlistId: json['playlist_id']?.toString() ?? '',
      imageAsset: json['image_asset']?.toString().trim().isNotEmpty == true
          ? json['image_asset'].toString()
          : 'assets/icons/porcaster.png',
      type: _typeFromString(contentType),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'playlistId': playlistId,
      'imageAsset': imageAsset,
      'type': type.name,
    };
  }

  factory YoutubePlaylistModel.fromMap(Map<String, dynamic> map) {
    return YoutubePlaylistModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'بدون عنوان',
      subtitle: map['subtitle']?.toString() ?? '',
      playlistId: map['playlistId']?.toString() ?? '',
      imageAsset: map['imageAsset']?.toString().trim().isNotEmpty == true
          ? map['imageAsset'].toString()
          : 'assets/icons/porcaster.png',
      type: _typeFromString(map['type']?.toString() ?? 'videos'),
    );
  }

  static VideoContentType _typeFromString(String value) {
    switch (value) {
      case 'podcasts':
        return VideoContentType.podcasts;
      case 'videos':
      default:
        return VideoContentType.videos;
    }
  }
}