enum VideoContentType {
  videos,
  podcasts,
}

extension VideoContentTypeExtension on VideoContentType {
  String get arabicTitle {
    switch (this) {
      case VideoContentType.videos:
        return 'فيديوهات';
      case VideoContentType.podcasts:
        return 'بودكاست';
    }
  }
}