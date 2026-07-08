enum RecitationSource {
  quranCom,
  mp3Quran,
}

class ReciterModel {
  final int id;
  final String name;
  final String translatedName;
  final String qiratName;
  final String styleName;
  final RecitationSource source;

  // خاص بـ MP3Quran
  final String serverUrl;
  final List<int> availableSurahs;

  const ReciterModel({
    required this.id,
    required this.name,
    required this.translatedName,
    required this.qiratName,
    required this.styleName,
    required this.source,
    this.serverUrl = '',
    this.availableSurahs = const [],
  });

  bool hasSurah(int surahNumber) {
    if (source == RecitationSource.quranCom) return true;
    return availableSurahs.contains(surahNumber);
  }

  String audioUrlForSurah(int surahNumber) {
    final paddedNumber = surahNumber.toString().padLeft(3, '0');

    final safeServer = serverUrl.endsWith('/')
        ? serverUrl
        : '$serverUrl/';

    return '$safeServer$paddedNumber.mp3';
  }

  factory ReciterModel.fromQuranComJson(Map<String, dynamic> json) {
    final translatedNameMap =
        json['translated_name'] as Map<String, dynamic>? ?? {};
    final qiratMap = json['qirat'] as Map<String, dynamic>? ?? {};
    final styleMap = json['style'] as Map<String, dynamic>? ?? {};

    return ReciterModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? 'قارئ',
      translatedName: translatedNameMap['name']?.toString() ?? '',
      qiratName: qiratMap['name']?.toString() ?? '',
      styleName: styleMap['name']?.toString() ?? '',
      source: RecitationSource.quranCom,
    );
  }

  factory ReciterModel.fromMp3QuranJson(Map<String, dynamic> json) {
    final moshafList = json['moshaf'] as List<dynamic>? ?? [];

    Map<String, dynamic>? selectedMoshaf;

    for (final item in moshafList) {
      if (item is! Map<String, dynamic>) continue;

      final surahTotal = int.tryParse(item['surah_total'].toString()) ?? 0;
      final server = item['server']?.toString() ?? '';

      if (surahTotal >= 114 && server.trim().isNotEmpty) {
        selectedMoshaf = item;
        break;
      }
    }

    selectedMoshaf ??= moshafList.whereType<Map<String, dynamic>>().isNotEmpty
        ? moshafList.whereType<Map<String, dynamic>>().first
        : null;

    final surahListText = selectedMoshaf?['surah_list']?.toString() ?? '';

    final availableSurahs = surahListText
        .split(',')
        .map((item) => int.tryParse(item.trim()))
        .whereType<int>()
        .toList();

    return ReciterModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? 'قارئ',
      translatedName: '',
      qiratName: selectedMoshaf?['name']?.toString() ?? '',
      styleName: 'MP3Quran',
      source: RecitationSource.mp3Quran,
      serverUrl: selectedMoshaf?['server']?.toString() ?? '',
      availableSurahs: availableSurahs,
    );
  }
}