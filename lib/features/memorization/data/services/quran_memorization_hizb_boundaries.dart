import '../../../quran/reader/quran_reader_helpers.dart';

class QuranMemorizationHizbRange {
  final int startGlobalAyahIndex;
  final int endGlobalAyahIndex;

  const QuranMemorizationHizbRange({
    required this.startGlobalAyahIndex,
    required this.endGlobalAyahIndex,
  });

  bool get isValid {
    return startGlobalAyahIndex >= 0 &&
        endGlobalAyahIndex >= startGlobalAyahIndex;
  }
}

class QuranMemorizationHizbBoundaries {
  const QuranMemorizationHizbBoundaries._();

  static const List<_HizbStart> _starts = [
    _HizbStart(0, 0),
    _HizbStart(1, 74),
    _HizbStart(1, 141),
    _HizbStart(1, 202),
    _HizbStart(1, 252),
    _HizbStart(2, 14),
    _HizbStart(2, 92),
    _HizbStart(2, 170),
    _HizbStart(3, 23),
    _HizbStart(3, 87),
    _HizbStart(3, 147),
    _HizbStart(4, 26),
    _HizbStart(4, 81),
    _HizbStart(5, 35),
    _HizbStart(5, 110),
    _HizbStart(6, 0),
    _HizbStart(6, 87),
    _HizbStart(6, 170),
    _HizbStart(7, 40),
    _HizbStart(8, 33),
    _HizbStart(8, 92),
    _HizbStart(9, 25),
    _HizbStart(10, 5),
    _HizbStart(10, 83),
    _HizbStart(11, 52),
    _HizbStart(12, 18),
    _HizbStart(14, 0),
    _HizbStart(15, 50),
    _HizbStart(16, 0),
    _HizbStart(16, 98),
    _HizbStart(17, 74),
    _HizbStart(19, 0),
    _HizbStart(20, 0),
    _HizbStart(21, 0),
    _HizbStart(22, 0),
    _HizbStart(23, 20),
    _HizbStart(24, 20),
    _HizbStart(25, 110),
    _HizbStart(26, 55),
    _HizbStart(27, 50),
    _HizbStart(28, 45),
    _HizbStart(30, 21),
    _HizbStart(32, 30),
    _HizbStart(33, 23),
    _HizbStart(35, 27),
    _HizbStart(36, 144),
    _HizbStart(38, 31),
    _HizbStart(39, 40),
    _HizbStart(40, 46),
    _HizbStart(42, 23),
    _HizbStart(45, 0),
    _HizbStart(47, 17),
    _HizbStart(50, 30),
    _HizbStart(54, 0),
    _HizbStart(57, 0),
    _HizbStart(61, 0),
    _HizbStart(66, 0),
    _HizbStart(71, 0),
    _HizbStart(77, 0),
    _HizbStart(86, 0),
  ];

  static QuranMemorizationHizbRange rangeForHizb(int hizbNumber) {
    final safeHizb = hizbNumber.clamp(1, 60).toInt();
    final start = _globalStart(_starts[safeHizb - 1]);

    final int end;
    if (safeHizb >= 60) {
      end = QuranReaderHelpers.totalAyahs - 1;
    } else {
      end = _globalStart(_starts[safeHizb]) - 1;
    }

    return QuranMemorizationHizbRange(
      startGlobalAyahIndex: start,
      endGlobalAyahIndex: end.clamp(start, QuranReaderHelpers.totalAyahs - 1).toInt(),
    );
  }

  static int _globalStart(_HizbStart start) {
    return QuranReaderHelpers.getGlobalAyahIndex(
      suraIndex: start.suraIndex,
      ayahIndex: start.ayahIndex,
    );
  }
}

class _HizbStart {
  final int suraIndex;
  final int ayahIndex;

  const _HizbStart(this.suraIndex, this.ayahIndex);
}
