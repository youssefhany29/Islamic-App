import 'dart:convert';

import 'package:flutter/services.dart';

class SvgMushafPageMetadataRepository {
  SvgMushafPageMetadataRepository._();

  static final SvgMushafPageMetadataRepository instance =
      SvgMushafPageMetadataRepository._();

  static const String _metadataAsset =
      'assets/quran/svg_geometry_quran_only/page_metadata.json';

  Future<Map<int, SvgMushafPageMetadata>>? _metadataFuture;

  Future<Map<int, SvgMushafPageMetadata>> loadAll() {
    return _metadataFuture ??= _loadAllFromAssets();
  }

  Future<SvgMushafPageMetadata?> loadPage(int pageNumber) async {
    final Map<int, SvgMushafPageMetadata> metadata = await loadAll();
    return metadata[pageNumber.clamp(1, 604).toInt()];
  }

  Future<Map<int, SvgMushafPageMetadata>> _loadAllFromAssets() async {
    final String text = await rootBundle.loadString(_metadataAsset);
    final Map<String, Object?> raw = (jsonDecode(text) as Map)
        .cast<String, Object?>();
    return raw.map((key, value) {
      final int page = int.parse(key);
      return MapEntry(
        page,
        SvgMushafPageMetadata.fromJson((value as Map).cast<String, Object?>()),
      );
    });
  }
}

class SvgMushafPageMetadata {
  const SvgMushafPageMetadata({
    required this.page,
    required this.surahs,
    required this.juz,
    this.firstAyah,
    this.lastAyah,
  });

  final int page;
  final List<SvgMushafPageSurah> surahs;
  final int juz;
  final SvgMushafPageAyah? firstAyah;
  final SvgMushafPageAyah? lastAyah;

  String get surahSummary {
    if (surahs.isEmpty) {
      return '';
    }
    if (surahs.length <= 3) {
      return surahs.map((surah) => surah.name).join(' • ');
    }
    return '${surahs.first.name} • ${surahs.last.name}';
  }

  factory SvgMushafPageMetadata.fromJson(Map<String, Object?> json) {
    SvgMushafPageAyah? parseAyah(String key) {
      final Object? value = json[key];
      if (value is! Map) {
        return null;
      }
      return SvgMushafPageAyah.fromJson(value.cast<String, Object?>());
    }

    return SvgMushafPageMetadata(
      page: _jsonInt(json['page']),
      surahs: ((json['surahs'] as List?) ?? const <Object?>[])
          .map((raw) {
            return SvgMushafPageSurah.fromJson(
              (raw as Map).cast<String, Object?>(),
            );
          })
          .toList(growable: false),
      juz: _jsonInt(json['juz'], fallback: 1),
      firstAyah: parseAyah('firstAyah'),
      lastAyah: parseAyah('lastAyah'),
    );
  }
}

class SvgMushafPageSurah {
  const SvgMushafPageSurah({required this.id, required this.name});

  final int id;
  final String name;

  factory SvgMushafPageSurah.fromJson(Map<String, Object?> json) {
    return SvgMushafPageSurah(
      id: _jsonInt(json['id']),
      name: json['name']?.toString() ?? '',
    );
  }
}

class SvgMushafPageAyah {
  const SvgMushafPageAyah({required this.surah, required this.ayah});

  final int surah;
  final int ayah;

  factory SvgMushafPageAyah.fromJson(Map<String, Object?> json) {
    return SvgMushafPageAyah(
      surah: _jsonInt(json['surah']),
      ayah: _jsonInt(json['ayah']),
    );
  }
}

int _jsonInt(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}
