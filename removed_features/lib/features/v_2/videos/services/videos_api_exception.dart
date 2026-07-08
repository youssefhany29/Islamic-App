class VideosApiException implements Exception {
  final String message;
  final int? statusCode;
  final Object? originalError;

  const VideosApiException(
      this.message, {
        this.statusCode,
        this.originalError,
      });

  @override
  String toString() {
    if (statusCode == null) {
      return message;
    }

    return '$message ($statusCode)';
  }
}