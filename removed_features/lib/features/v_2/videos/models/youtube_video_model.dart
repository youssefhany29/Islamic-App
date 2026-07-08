class YoutubeVideoModel {
  final String id;
  final String title;
  final String channelTitle;
  final String channelId;
  final String thumbnailUrl;
  final String publishedAt;
  final String publishedText;
  final String viewsText;

  const YoutubeVideoModel({
    required this.id,
    required this.title,
    required this.channelTitle,
    required this.channelId,
    required this.thumbnailUrl,
    required this.publishedAt,
    required this.publishedText,
    required this.viewsText,
  });

  String get youtubeUrl {
    return 'https://www.youtube.com/watch?v=$id';
  }

  String get channelUrl {
    if (channelId.trim().isNotEmpty) {
      return 'https://www.youtube.com/channel/$channelId';
    }

    final query = Uri.encodeQueryComponent(channelTitle);
    return 'https://www.youtube.com/results?search_query=$query';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'channelTitle': channelTitle,
      'channelId': channelId,
      'thumbnailUrl': thumbnailUrl,
      'publishedAt': publishedAt,
      'publishedText': publishedText,
      'viewsText': viewsText,
    };
  }

  factory YoutubeVideoModel.fromMap(Map<String, dynamic> map) {
    final publishedAt = map['publishedAt']?.toString() ?? '';

    return YoutubeVideoModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'بدون عنوان',
      channelTitle: map['channelTitle']?.toString() ?? 'YouTube',
      channelId: map['channelId']?.toString() ?? '',
      thumbnailUrl: map['thumbnailUrl']?.toString() ?? '',
      publishedAt: publishedAt,
      publishedText: map['publishedText']?.toString().isNotEmpty == true
          ? map['publishedText'].toString()
          : formatPublishedText(publishedAt),
      viewsText: map['viewsText']?.toString() ?? '',
    );
  }

  factory YoutubeVideoModel.fromPlaylistItemJson(Map<String, dynamic> json) {
    final snippet = json['snippet'] as Map<String, dynamic>? ?? {};
    final resourceId = snippet['resourceId'] as Map<String, dynamic>? ?? {};
    final thumbnails = snippet['thumbnails'] as Map<String, dynamic>? ?? {};

    final maxThumbnail = thumbnails['maxres'] as Map<String, dynamic>?;
    final highThumbnail = thumbnails['high'] as Map<String, dynamic>?;
    final mediumThumbnail = thumbnails['medium'] as Map<String, dynamic>?;
    final defaultThumbnail = thumbnails['default'] as Map<String, dynamic>?;

    final thumbnailUrl = maxThumbnail?['url']?.toString() ??
        highThumbnail?['url']?.toString() ??
        mediumThumbnail?['url']?.toString() ??
        defaultThumbnail?['url']?.toString() ??
        '';

    final publishedAt = snippet['publishedAt']?.toString() ?? '';

    final ownerChannelTitle =
        snippet['videoOwnerChannelTitle']?.toString() ?? '';

    final channelTitle = ownerChannelTitle.trim().isNotEmpty
        ? ownerChannelTitle
        : snippet['channelTitle']?.toString() ?? 'YouTube';

    return YoutubeVideoModel(
      id: resourceId['videoId']?.toString() ?? '',
      title: snippet['title']?.toString() ?? 'بدون عنوان',
      channelTitle: channelTitle,
      channelId: snippet['videoOwnerChannelId']?.toString() ??
          snippet['channelId']?.toString() ??
          '',
      thumbnailUrl: thumbnailUrl,
      publishedAt: publishedAt,
      publishedText: formatPublishedText(publishedAt),
      viewsText: '',
    );
  }

  factory YoutubeVideoModel.fromBackendJson(Map<String, dynamic> json) {
    final publishedAt = json['published_at']?.toString() ?? '';
    final playlist = json['youtube_playlists'] as Map<String, dynamic>?;

    final sheikhName = json['sheikh_name']?.toString() ?? '';
    final channelTitle = json['channel_title']?.toString() ?? '';
    final playlistTitle = playlist?['title']?.toString() ?? '';

    final displayChannel = sheikhName.trim().isNotEmpty
        ? sheikhName
        : channelTitle.trim().isNotEmpty
        ? channelTitle
        : playlistTitle.trim().isNotEmpty
        ? playlistTitle
        : 'YouTube';

    return YoutubeVideoModel(
      id: json['youtube_video_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'بدون عنوان',
      channelTitle: displayChannel,
      channelId: json['channel_id']?.toString() ?? '',
      thumbnailUrl: json['thumbnail']?.toString() ?? '',
      publishedAt: publishedAt,
      publishedText: formatPublishedText(publishedAt),
      viewsText: '',
    );
  }

  static String formatPublishedText(String publishedAt) {
    final date = DateTime.tryParse(publishedAt);

    if (date == null) {
      return '';
    }

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays >= 365) {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? 'منذ سنة' : 'منذ $years سنوات';
    }

    if (difference.inDays >= 30) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? 'منذ شهر' : 'منذ $months أشهر';
    }

    if (difference.inDays >= 7) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? 'منذ أسبوع' : 'منذ $weeks أسابيع';
    }

    if (difference.inDays >= 1) {
      return difference.inDays == 1
          ? 'منذ يوم'
          : 'منذ ${difference.inDays} أيام';
    }

    if (difference.inHours >= 1) {
      return difference.inHours == 1
          ? 'منذ ساعة'
          : 'منذ ${difference.inHours} ساعات';
    }

    return 'منذ قليل';
  }
}