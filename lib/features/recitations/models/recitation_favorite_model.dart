import 'reciter_model.dart';

enum RecitationFavoriteType {
  reciter,
  surah,
}

class RecitationFavoriteModel {
  final String id;
  final RecitationFavoriteType type;

  final int reciterId;
  final String reciterName;
  final RecitationSource reciterSource;
  final String mp3QuranServerUrl;

  final int? surahNumber;
  final String? surahName;

  final int createdAtMs;

  const RecitationFavoriteModel({
    required this.id,
    required this.type,
    required this.reciterId,
    required this.reciterName,
    required this.reciterSource,
    required this.mp3QuranServerUrl,
    this.surahNumber,
    this.surahName,
    required this.createdAtMs,
  });

  bool get isReciterFavorite => type == RecitationFavoriteType.reciter;

  bool get isSurahFavorite => type == RecitationFavoriteType.surah;

  factory RecitationFavoriteModel.reciter({
    required int reciterId,
    required String reciterName,
    required RecitationSource reciterSource,
    required String mp3QuranServerUrl,
  }) {
    return RecitationFavoriteModel(
      id: reciterKey(
        reciterId: reciterId,
        reciterSource: reciterSource,
      ),
      type: RecitationFavoriteType.reciter,
      reciterId: reciterId,
      reciterName: reciterName,
      reciterSource: reciterSource,
      mp3QuranServerUrl: mp3QuranServerUrl,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  factory RecitationFavoriteModel.surah({
    required int reciterId,
    required String reciterName,
    required RecitationSource reciterSource,
    required String mp3QuranServerUrl,
    required int surahNumber,
    required String surahName,
  }) {
    return RecitationFavoriteModel(
      id: surahKey(
        reciterId: reciterId,
        reciterSource: reciterSource,
        surahNumber: surahNumber,
      ),
      type: RecitationFavoriteType.surah,
      reciterId: reciterId,
      reciterName: reciterName,
      reciterSource: reciterSource,
      mp3QuranServerUrl: mp3QuranServerUrl,
      surahNumber: surahNumber,
      surahName: surahName,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  static String reciterKey({
    required int reciterId,
    required RecitationSource reciterSource,
  }) {
    return 'reciter_${reciterSource.name}_$reciterId';
  }

  static String surahKey({
    required int reciterId,
    required RecitationSource reciterSource,
    required int surahNumber,
  }) {
    return 'surah_${reciterSource.name}_${reciterId}_$surahNumber';
  }

  factory RecitationFavoriteModel.fromJson(Map<String, dynamic> json) {
    final typeText = json['type']?.toString() ?? RecitationFavoriteType.reciter.name;

    final type = RecitationFavoriteType.values.firstWhere(
          (item) => item.name == typeText,
      orElse: () => RecitationFavoriteType.reciter,
    );

    final sourceText = json['reciterSource']?.toString() ?? RecitationSource.quranCom.name;

    final source = RecitationSource.values.firstWhere(
          (item) => item.name == sourceText,
      orElse: () => RecitationSource.quranCom,
    );

    return RecitationFavoriteModel(
      id: json['id']?.toString() ?? '',
      type: type,
      reciterId: int.tryParse(json['reciterId'].toString()) ?? 0,
      reciterName: json['reciterName']?.toString() ?? 'قارئ',
      reciterSource: source,
      mp3QuranServerUrl: json['mp3QuranServerUrl']?.toString() ?? '',
      surahNumber: json['surahNumber'] == null
          ? null
          : int.tryParse(json['surahNumber'].toString()),
      surahName: json['surahName']?.toString(),
      createdAtMs: int.tryParse(json['createdAtMs'].toString()) ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'reciterId': reciterId,
      'reciterName': reciterName,
      'reciterSource': reciterSource.name,
      'mp3QuranServerUrl': mp3QuranServerUrl,
      'surahNumber': surahNumber,
      'surahName': surahName,
      'createdAtMs': createdAtMs,
    };
  }
}