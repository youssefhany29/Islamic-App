import 'reciter_model.dart';

class DownloadedRecitationModel {
  final int reciterId;
  final String reciterName;
  final RecitationSource reciterSource;
  final String mp3QuranServerUrl;
  final int surahNumber;
  final String surahName;
  final String audioUrl;
  final String localFilePath;
  final int fileSizeBytes;
  final String downloadedAt;

  const DownloadedRecitationModel({
    required this.reciterId,
    required this.reciterName,
    required this.reciterSource,
    required this.mp3QuranServerUrl,
    required this.surahNumber,
    required this.surahName,
    required this.audioUrl,
    required this.localFilePath,
    required this.fileSizeBytes,
    required this.downloadedAt,
  });

  String get uniqueKey {
    return '${reciterSource.name}_${reciterId}_$surahNumber';
  }

  Map<String, dynamic> toMap() {
    return {
      'reciterId': reciterId,
      'reciterName': reciterName,
      'reciterSource': reciterSource.name,
      'mp3QuranServerUrl': mp3QuranServerUrl,
      'surahNumber': surahNumber,
      'surahName': surahName,
      'audioUrl': audioUrl,
      'localFilePath': localFilePath,
      'fileSizeBytes': fileSizeBytes,
      'downloadedAt': downloadedAt,
    };
  }

  factory DownloadedRecitationModel.fromMap(Map<String, dynamic> map) {
    final sourceText = map['reciterSource']?.toString() ?? '';

    final source = RecitationSource.values.firstWhere(
          (item) => item.name == sourceText,
      orElse: () => RecitationSource.quranCom,
    );

    return DownloadedRecitationModel(
      reciterId: int.tryParse(map['reciterId'].toString()) ?? 0,
      reciterName: map['reciterName']?.toString() ?? 'قارئ',
      reciterSource: source,
      mp3QuranServerUrl: map['mp3QuranServerUrl']?.toString() ?? '',
      surahNumber: int.tryParse(map['surahNumber'].toString()) ?? 1,
      surahName: map['surahName']?.toString() ?? 'الفاتحة',
      audioUrl: map['audioUrl']?.toString() ?? '',
      localFilePath: map['localFilePath']?.toString() ?? '',
      fileSizeBytes: int.tryParse(map['fileSizeBytes'].toString()) ?? 0,
      downloadedAt: map['downloadedAt']?.toString() ?? '',
    );
  }
}