class ChapterAudioFileModel {
  final int id;
  final int chapterId;
  final int fileSize;
  final String format;
  final String audioUrl;

  const ChapterAudioFileModel({
    required this.id,
    required this.chapterId,
    required this.fileSize,
    required this.format,
    required this.audioUrl,
  });

  factory ChapterAudioFileModel.fromJson(Map<String, dynamic> json) {
    return ChapterAudioFileModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      chapterId: int.tryParse(json['chapter_id'].toString()) ?? 0,
      fileSize: int.tryParse(json['file_size'].toString()) ?? 0,
      format: json['format']?.toString() ?? 'mp3',
      audioUrl: json['audio_url']?.toString() ?? '',
    );
  }

  factory ChapterAudioFileModel.fromMp3QuranUrl({
    required int chapterId,
    required String audioUrl,
  }) {
    return ChapterAudioFileModel(
      id: chapterId,
      chapterId: chapterId,
      fileSize: 0,
      format: 'mp3',
      audioUrl: audioUrl,
    );
  }
}