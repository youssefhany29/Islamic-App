import 'dart:ui';

import '../models/qpc_models.dart';

class SvgPageGeometry {
  const SvgPageGeometry({
    required this.page,
    required this.originalWidth,
    required this.originalHeight,
    required this.cropWidth,
    required this.cropHeight,
    required this.imageWidth,
    required this.imageHeight,
    required this.ayahs,
  });

  final int page;
  final double originalWidth;
  final double originalHeight;
  final double cropWidth;
  final double cropHeight;
  final double imageWidth;
  final double imageHeight;
  final List<SvgAyahGeometry> ayahs;

  factory SvgPageGeometry.fromJson(Map<String, Object?> json) {
    final Map<String, Object?> viewBox = (json['originalViewBox'] as Map)
        .cast<String, Object?>();
    final Map<String, Object?> crop = (json['cropRect'] as Map)
        .cast<String, Object?>();
    final Map<String, Object?> imageSize =
        ((json['outputImageSize'] as Map?)?.cast<String, Object?>() ??
        <String, Object?>{});

    return SvgPageGeometry(
      page: _jsonInt(json['page']),
      originalWidth: _jsonDouble(viewBox['width']),
      originalHeight: _jsonDouble(viewBox['height']),
      cropWidth: _jsonDouble(crop['width']),
      cropHeight: _jsonDouble(crop['height']),
      imageWidth: _jsonDouble(
        imageSize['width'],
        fallback: _jsonDouble(crop['width']),
      ),
      imageHeight: _jsonDouble(
        imageSize['height'],
        fallback: _jsonDouble(viewBox['height']),
      ),
      ayahs: (json['ayahs'] as List<Object?>)
          .map((raw) {
            return SvgAyahGeometry.fromJson(
              (raw as Map).cast<String, Object?>(),
            );
          })
          .toList(growable: false),
    );
  }

  SvgAyahGeometry? ayahForKey(QpcAyahKey key) {
    for (final SvgAyahGeometry ayah in ayahs) {
      if (ayah.ayahKey == key) {
        return ayah;
      }
    }
    return null;
  }

  SvgGeometryHit? hitTest(
    Offset localPosition,
    Size size, {
    QpcPageData? pageData,
  }) {
    if (size.width <= 0 || size.height <= 0) {
      return null;
    }

    final Offset normalized = Offset(
      (localPosition.dx / size.width).clamp(0.0, 1.0),
      (localPosition.dy / size.height).clamp(0.0, 1.0),
    );

    for (final SvgAyahGeometry ayah in ayahs) {
      for (final SvgBoxGeometry word in ayah.textWords) {
        if (word.contains(normalized)) {
          return SvgGeometryHit(ayah: ayah, word: word, pageData: pageData);
        }
      }
    }

    for (final SvgAyahGeometry ayah in ayahs) {
      for (final SvgBoxGeometry segment in ayah.segments) {
        if (segment.contains(normalized)) {
          return SvgGeometryHit(
            ayah: ayah,
            word: ayah.firstTextWord,
            pageData: pageData,
          );
        }
      }
    }

    return null;
  }
}

class SvgAyahGeometry {
  const SvgAyahGeometry({
    required this.surah,
    required this.ayah,
    required this.segments,
    required this.textWords,
    required this.ayahNumberBoxes,
  });

  final int surah;
  final int ayah;
  final List<SvgBoxGeometry> segments;
  final List<SvgBoxGeometry> textWords;
  final List<SvgBoxGeometry> ayahNumberBoxes;

  QpcAyahKey get ayahKey => QpcAyahKey(surah: surah, ayah: ayah);

  SvgBoxGeometry? get firstTextWord {
    return textWords.isEmpty ? null : textWords.first;
  }

  factory SvgAyahGeometry.fromJson(Map<String, Object?> json) {
    final int surah = _jsonInt(json['surah']);
    final int ayah = _jsonInt(json['ayah']);

    List<SvgBoxGeometry> parseBoxes(String key, {required bool words}) {
      return ((json[key] as List?) ?? const <Object?>[])
          .map((raw) {
            return SvgBoxGeometry.fromJson(
              (raw as Map).cast<String, Object?>(),
              surah: surah,
              ayah: ayah,
              wordBox: words,
            );
          })
          .toList(growable: false);
    }

    return SvgAyahGeometry(
      surah: surah,
      ayah: ayah,
      segments: parseBoxes('segments', words: false),
      textWords: parseBoxes('textWords', words: true),
      ayahNumberBoxes: parseBoxes('ayahNumberBoxes', words: false),
    );
  }
}

class SvgBoxGeometry {
  const SvgBoxGeometry({
    required this.line,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    this.surah,
    this.ayah,
    this.wordIndex,
    this.hafs = '',
  });

  static const Set<int> _waqfMarkRunes = <int>{
    0x06D6,
    0x06D7,
    0x06D8,
    0x06D9,
    0x06DA,
    0x06DB,
    0x06DC,
  };

  final int line;
  final double x;
  final double y;
  final double w;
  final double h;
  final int? surah;
  final int? ayah;
  final int? wordIndex;
  final String hafs;

  factory SvgBoxGeometry.fromJson(
    Map<String, Object?> json, {
    required int surah,
    required int ayah,
    required bool wordBox,
  }) {
    return SvgBoxGeometry(
      line: _jsonInt(json['line']),
      x: _jsonDouble(json['x']),
      y: _jsonDouble(json['y']),
      w: _jsonDouble(json['w']),
      h: _jsonDouble(json['h']),
      surah: wordBox ? surah : null,
      ayah: wordBox ? ayah : null,
      wordIndex: wordBox ? _jsonInt(json['wordIndex']) : null,
      hafs: wordBox ? json['hafs']?.toString() ?? '' : '',
    );
  }

  Rect toRect(Size size) {
    return Rect.fromLTWH(
      x * size.width,
      y * size.height,
      w * size.width,
      h * size.height,
    );
  }

  bool contains(Offset normalized) {
    return normalized.dx >= x &&
        normalized.dx <= x + w &&
        normalized.dy >= y &&
        normalized.dy <= y + h;
  }

  bool get isWaqfMark {
    final String text = hafs.trim();
    if (text.isEmpty) {
      return false;
    }

    final Iterator<int> runes = text.runes.iterator;
    if (!runes.moveNext()) {
      return false;
    }

    final int mark = runes.current;
    if (runes.moveNext()) {
      return false;
    }

    return _waqfMarkRunes.contains(mark);
  }
}

class SvgGeometryHit {
  const SvgGeometryHit({
    required this.ayah,
    required this.word,
    required this.pageData,
  });

  final SvgAyahGeometry ayah;
  final SvgBoxGeometry? word;
  final QpcPageData? pageData;

  QpcAyahKey get ayahKey => ayah.ayahKey;

  QpcWordKey get wordKey {
    final List<QpcWord> ayahWords = pageData?.wordsForAyah(ayahKey) ?? const [];
    final int? wordIndex = word?.wordIndex;
    if (wordIndex != null && wordIndex > 0 && wordIndex <= ayahWords.length) {
      return ayahWords[wordIndex - 1].wordKey;
    }

    if (ayahWords.isNotEmpty) {
      return ayahWords.first.wordKey;
    }

    return QpcWordKey(surah: ayah.surah, ayah: ayah.ayah, word: wordIndex ?? 1);
  }
}

int _jsonInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.parse(value.toString());
}

double _jsonDouble(Object? value, {double fallback = 0}) {
  if (value == null) {
    return fallback;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.parse(value.toString());
}
