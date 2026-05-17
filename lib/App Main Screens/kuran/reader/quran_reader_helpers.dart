import '../constant.dart';

class QuranAyahPosition {
  final int suraIndex;
  final int ayahIndex;
  final int globalAyahIndex;

  const QuranAyahPosition({
    required this.suraIndex,
    required this.ayahIndex,
    required this.globalAyahIndex,
  });
}

class QuranJuzStart {
  final int juzNumber;
  final int suraIndex;
  final int ayahIndex;

  const QuranJuzStart({
    required this.juzNumber,
    required this.suraIndex,
    required this.ayahIndex,
  });
}

class QuranReaderHelpers {
  static const List<QuranJuzStart> juzStarts = [
    QuranJuzStart(juzNumber: 1, suraIndex: 0, ayahIndex: 0),
    QuranJuzStart(juzNumber: 2, suraIndex: 1, ayahIndex: 141),
    QuranJuzStart(juzNumber: 3, suraIndex: 1, ayahIndex: 252),
    QuranJuzStart(juzNumber: 4, suraIndex: 2, ayahIndex: 92),
    QuranJuzStart(juzNumber: 5, suraIndex: 3, ayahIndex: 23),
    QuranJuzStart(juzNumber: 6, suraIndex: 3, ayahIndex: 147),
    QuranJuzStart(juzNumber: 7, suraIndex: 4, ayahIndex: 81),
    QuranJuzStart(juzNumber: 8, suraIndex: 5, ayahIndex: 110),
    QuranJuzStart(juzNumber: 9, suraIndex: 6, ayahIndex: 87),
    QuranJuzStart(juzNumber: 10, suraIndex: 7, ayahIndex: 40),
    QuranJuzStart(juzNumber: 11, suraIndex: 8, ayahIndex: 92),
    QuranJuzStart(juzNumber: 12, suraIndex: 10, ayahIndex: 5),
    QuranJuzStart(juzNumber: 13, suraIndex: 11, ayahIndex: 52),
    QuranJuzStart(juzNumber: 14, suraIndex: 14, ayahIndex: 0),
    QuranJuzStart(juzNumber: 15, suraIndex: 16, ayahIndex: 0),
    QuranJuzStart(juzNumber: 16, suraIndex: 17, ayahIndex: 74),
    QuranJuzStart(juzNumber: 17, suraIndex: 20, ayahIndex: 0),
    QuranJuzStart(juzNumber: 18, suraIndex: 22, ayahIndex: 0),
    QuranJuzStart(juzNumber: 19, suraIndex: 24, ayahIndex: 20),
    QuranJuzStart(juzNumber: 20, suraIndex: 26, ayahIndex: 55),
    QuranJuzStart(juzNumber: 21, suraIndex: 28, ayahIndex: 45),
    QuranJuzStart(juzNumber: 22, suraIndex: 32, ayahIndex: 30),
    QuranJuzStart(juzNumber: 23, suraIndex: 35, ayahIndex: 27),
    QuranJuzStart(juzNumber: 24, suraIndex: 38, ayahIndex: 31),
    QuranJuzStart(juzNumber: 25, suraIndex: 40, ayahIndex: 46),
    QuranJuzStart(juzNumber: 26, suraIndex: 45, ayahIndex: 0),
    QuranJuzStart(juzNumber: 27, suraIndex: 50, ayahIndex: 30),
    QuranJuzStart(juzNumber: 28, suraIndex: 57, ayahIndex: 0),
    QuranJuzStart(juzNumber: 29, suraIndex: 66, ayahIndex: 0),
    QuranJuzStart(juzNumber: 30, suraIndex: 77, ayahIndex: 0),
  ];

  static int get totalAyahs {
    return noOfVerses.fold(0, (sum, count) => sum + count);
  }

  static int getGlobalAyahIndex({
    required int suraIndex,
    required int ayahIndex,
  }) {
    int previousVerses = 0;

    for (int i = 0; i < suraIndex; i++) {
      previousVerses += noOfVerses[i];
    }

    return previousVerses + ayahIndex;
  }

  static QuranAyahPosition getPositionFromGlobalIndex(int globalAyahIndex) {
    int remaining = globalAyahIndex;

    for (int suraIndex = 0; suraIndex < noOfVerses.length; suraIndex++) {
      final suraAyahCount = noOfVerses[suraIndex];

      if (remaining < suraAyahCount) {
        return QuranAyahPosition(
          suraIndex: suraIndex,
          ayahIndex: remaining,
          globalAyahIndex: globalAyahIndex,
        );
      }

      remaining -= suraAyahCount;
    }

    return QuranAyahPosition(
      suraIndex: 113,
      ayahIndex: noOfVerses[113] - 1,
      globalAyahIndex: totalAyahs - 1,
    );
  }

  static int getJuzNumber({
    required int suraIndex,
    required int ayahIndex,
  }) {
    int currentJuz = 1;

    final currentGlobal = getGlobalAyahIndex(
      suraIndex: suraIndex,
      ayahIndex: ayahIndex,
    );

    for (final juzStart in juzStarts) {
      final juzGlobal = getGlobalAyahIndex(
        suraIndex: juzStart.suraIndex,
        ayahIndex: juzStart.ayahIndex,
      );

      if (currentGlobal >= juzGlobal) {
        currentJuz = juzStart.juzNumber;
      } else {
        break;
      }
    }

    return currentJuz;
  }

  static int getApproxPageNumber(int globalAyahIndex) {
    const int mushafPagesCount = 604;

    final page = ((globalAyahIndex / totalAyahs) * mushafPagesCount).floor() + 1;

    if (page < 1) return 1;
    if (page > mushafPagesCount) return mushafPagesCount;

    return page;
  }

  static bool shouldShowBasmala({
    required int suraIndex,
    required int ayahIndex,
  }) {
    return ayahIndex == 0 && suraIndex != 0 && suraIndex != 8;
  }

  static String getSuraName(int suraIndex) {
    return arabicName[suraIndex]['name'].toString();
  }
}