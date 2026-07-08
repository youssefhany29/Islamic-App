class QpcAyahKey {
  const QpcAyahKey({
    required this.surah,
    required this.ayah,
  });

  final int surah;
  final int ayah;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is QpcAyahKey &&
            runtimeType == other.runtimeType &&
            surah == other.surah &&
            ayah == other.ayah;
  }

  @override
  int get hashCode => Object.hash(surah, ayah);

  @override
  String toString() {
    return '$surah:$ayah';
  }
}

class QpcWordKey {
  const QpcWordKey({
    required this.surah,
    required this.ayah,
    required this.word,
  });

  final int surah;
  final int ayah;
  final int word;

  QpcAyahKey get ayahKey {
    return QpcAyahKey(
      surah: surah,
      ayah: ayah,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is QpcWordKey &&
            runtimeType == other.runtimeType &&
            surah == other.surah &&
            ayah == other.ayah &&
            word == other.word;
  }

  @override
  int get hashCode => Object.hash(surah, ayah, word);

  @override
  String toString() {
    return '$surah:$ayah:$word';
  }
}

class QpcWord {
  const QpcWord({
    required this.id,
    required this.surah,
    required this.ayah,
    required this.word,
    required this.location,
    required this.text,
  });

  final int id;
  final int surah;
  final int ayah;
  final int word;
  final String location;
  final String text;

  QpcAyahKey get ayahKey {
    return QpcAyahKey(
      surah: surah,
      ayah: ayah,
    );
  }

  QpcWordKey get wordKey {
    return QpcWordKey(
      surah: surah,
      ayah: ayah,
      word: word,
    );
  }

  bool belongsToAyah(QpcAyahKey key) {
    return surah == key.surah && ayah == key.ayah;
  }
}

class QpcMushafLine {
  const QpcMushafLine({
    required this.pageNumber,
    required this.lineNumber,
    required this.lineType,
    required this.isCentered,
    required this.firstWordId,
    required this.lastWordId,
    required this.surahNumber,
    required this.words,
  });

  final int pageNumber;
  final int lineNumber;
  final String lineType;
  final bool isCentered;
  final int? firstWordId;
  final int? lastWordId;
  final int? surahNumber;
  final List<QpcWord> words;

  bool get isSurahNameLine => lineType == 'surah_name';

  bool get isBasmallahLine => lineType == 'basmallah';

  bool get isAyahLine => words.isNotEmpty;

  List<QpcWord> wordsForAyah(QpcAyahKey key) {
    return words.where((word) => word.belongsToAyah(key)).toList();
  }
}

class QpcPageData {
  const QpcPageData({
    required this.pageNumber,
    required this.lines,
    this.finalWordByAyah = const <QpcAyahKey, int>{},
  });

  final int pageNumber;
  final List<QpcMushafLine> lines;
  final Map<QpcAyahKey, int> finalWordByAyah;

  QpcMushafLine? lineByNumber(int number) {
    for (final QpcMushafLine line in lines) {
      if (line.lineNumber == number) {
        return line;
      }
    }

    return null;
  }

  List<QpcWord> get allWords {
    final List<QpcWord> result = <QpcWord>[];

    for (final QpcMushafLine line in lines) {
      result.addAll(line.words);
    }

    return result;
  }

  List<QpcWord> wordsForAyah(QpcAyahKey key) {
    return allWords.where((word) => word.belongsToAyah(key)).toList();
  }

  bool containsAyah(QpcAyahKey key) {
    return wordsForAyah(key).isNotEmpty;
  }
}
