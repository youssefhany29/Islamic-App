import 'qpc_models.dart';
import '../quran_reader_helpers.dart';

enum QuranSelectionType {
  ayah,
  word,
}

class QuranSelection {
  const QuranSelection({
    required this.ayahKey,
    this.wordKey,
  });

  final QpcAyahKey ayahKey;
  final QpcWordKey? wordKey;

  QuranSelectionType get type {
    return wordKey == null ? QuranSelectionType.ayah : QuranSelectionType.word;
  }

  bool get isAyahSelection {
    return type == QuranSelectionType.ayah;
  }

  bool get isWordSelection {
    return type == QuranSelectionType.word;
  }

  int get surah {
    return ayahKey.surah;
  }

  int get ayah {
    return ayahKey.ayah;
  }

  int? get word {
    return wordKey?.word;
  }

  String get ayahReference {
    return '${ayahKey.surah}:${ayahKey.ayah}';
  }

  String get surahName {
    final int suraIndex = (ayahKey.surah - 1).clamp(0, 113).toInt();
    return QuranReaderHelpers.getSuraName(suraIndex);
  }

  String get ayahDisplayLabel {
    return 'سورة $surahName | آية ${ayahKey.ayah}';
  }

  String get tafsirDisplayLabel {
    return 'تفسير سورة $surahName | آية ${ayahKey.ayah}';
  }

  String get readableArabicLabel {
    if (wordKey == null) {
      return ayahDisplayLabel;
    }

    return 'كلمة ${wordKey!.word} | $ayahDisplayLabel';
  }

  bool matchesAyah(QpcAyahKey key) {
    return ayahKey == key;
  }

  bool matchesWord(QpcWordKey key) {
    return wordKey == key;
  }

  QuranSelection copyWith({
    QpcAyahKey? ayahKey,
    QpcWordKey? wordKey,
    bool clearWord = false,
  }) {
    return QuranSelection(
      ayahKey: ayahKey ?? this.ayahKey,
      wordKey: clearWord ? null : wordKey ?? this.wordKey,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is QuranSelection &&
            runtimeType == other.runtimeType &&
            ayahKey == other.ayahKey &&
            wordKey == other.wordKey;
  }

  @override
  int get hashCode {
    return Object.hash(ayahKey, wordKey);
  }

  @override
  String toString() {
    if (wordKey == null) {
      return 'QuranSelection(ayah: $ayahReference)';
    }

    return 'QuranSelection(word: $ayahReference:${wordKey!.word})';
  }
}
