import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

enum QuranIrabSourceType { json, database }

class QuranIrabSource {
  const QuranIrabSource({
    required this.id,
    required this.label,
    required this.assetPath,
    this.type = QuranIrabSourceType.json,
  });

  final String id;
  final String label;
  final String assetPath;
  final QuranIrabSourceType type;
}

class QuranIrabEntry {
  const QuranIrabEntry({required this.source, required this.text});

  final QuranIrabSource source;
  final String text;
}

class QuranIrabRepository {
  QuranIrabRepository._();

  static final QuranIrabRepository instance = QuranIrabRepository._();

  static const List<QuranIrabSource> sources = <QuranIrabSource>[
    QuranIrabSource(
      id: 'darwish',
      label: 'إعراب القرآن للدرويش',
      assetPath: 'assets/quran/irab/i-rab-al-quran-li-al-darwish.json',
    ),
    QuranIrabSource(
      id: 'da_as',
      label: 'إعراب القرآن - د. ع. س',
      assetPath: 'assets/quran/irab/alrab-al-quran-li-da-as.db',
      type: QuranIrabSourceType.database,
    ),
    QuranIrabSource(
      id: 'muyassar',
      label: 'الإعراب الميسر',
      assetPath: 'assets/quran/irab/al-i-rab-al-muyassar.json',
    ),
  ];

  static const String _databaseFolderName = 'quran_irab_databases_v1';

  final Map<String, Map<String, dynamic>> _jsonCache =
      <String, Map<String, dynamic>>{};
  final Map<String, Database> _databaseCache = <String, Database>{};

  Future<QuranIrabEntry?> getIrab({
    QuranIrabSource? source,
    required int surah,
    required int ayah,
  }) async {
    final QuranIrabSource selectedSource = source ?? sources.first;
    final String? text = switch (selectedSource.type) {
      QuranIrabSourceType.json => await _getJsonIrab(
        source: selectedSource,
        surah: surah,
        ayah: ayah,
      ),
      QuranIrabSourceType.database => await _getDatabaseIrab(
        source: selectedSource,
        surah: surah,
        ayah: ayah,
      ),
    };

    final String cleaned = _cleanHtml(text ?? '');
    if (cleaned.trim().isEmpty) {
      return null;
    }

    return QuranIrabEntry(source: selectedSource, text: cleaned);
  }

  Future<String?> _getJsonIrab({
    required QuranIrabSource source,
    required int surah,
    required int ayah,
  }) async {
    final Map<String, dynamic> data = await _loadJsonSource(source);
    final dynamic rawEntry = data['$surah:$ayah'];
    final dynamic resolvedEntry = _resolveEntry(data, rawEntry);

    if (resolvedEntry is! Map) {
      return null;
    }

    return resolvedEntry['text']?.toString();
  }

  Future<String?> _getDatabaseIrab({
    required QuranIrabSource source,
    required int surah,
    required int ayah,
  }) async {
    final Database db = await _openDatabase(source);
    final String key = '$surah:$ayah';

    final List<Map<String, Object?>> directRows = await db.query(
      'tafsir',
      columns: const <String>['ayah_key', 'ayah_keys', 'text'],
      where: 'ayah_key = ?',
      whereArgs: <Object?>[key],
      limit: 1,
    );

    if (directRows.isNotEmpty) {
      return directRows.first['text']?.toString();
    }

    final List<Map<String, Object?>> groupRows = await db.query(
      'tafsir',
      columns: const <String>['ayah_key', 'ayah_keys', 'text'],
      where: 'ayah_keys LIKE ?',
      whereArgs: <Object?>['%$key%'],
      limit: 12,
    );

    for (final Map<String, Object?> row in groupRows) {
      final String ayahKeys = row['ayah_keys']?.toString() ?? '';
      final bool containsKey = ayahKeys
          .split(',')
          .map((value) => value.trim())
          .contains(key);
      if (containsKey) {
        return row['text']?.toString();
      }
    }

    return null;
  }

  dynamic _resolveEntry(Map<String, dynamic> data, dynamic rawEntry) {
    if (rawEntry is String && rawEntry.contains(':')) {
      return data[rawEntry];
    }

    return rawEntry;
  }

  Future<Map<String, dynamic>> _loadJsonSource(QuranIrabSource source) async {
    final Map<String, dynamic>? cached = _jsonCache[source.id];
    if (cached != null) {
      return cached;
    }

    final String rawJson = await rootBundle.loadString(source.assetPath);
    final Map<String, dynamic> decoded =
        jsonDecode(rawJson) as Map<String, dynamic>;

    _jsonCache[source.id] = decoded;
    return decoded;
  }

  Future<Database> _openDatabase(QuranIrabSource source) async {
    final Database? cached = _databaseCache[source.id];
    if (cached != null) {
      return cached;
    }

    final String dbPath = await _copyDatabaseFromAssets(source);
    final Database db = await openDatabase(
      dbPath,
      readOnly: true,
      singleInstance: false,
    );

    _databaseCache[source.id] = db;
    return db;
  }

  Future<String> _copyDatabaseFromAssets(QuranIrabSource source) async {
    final Directory appSupportDir = await getApplicationSupportDirectory();
    final String dbFolderPath =
        '${appSupportDir.path}${Platform.pathSeparator}$_databaseFolderName';

    await Directory(dbFolderPath).create(recursive: true);

    final String fileName = source.assetPath.split('/').last;
    final String targetPath = '$dbFolderPath${Platform.pathSeparator}$fileName';
    final File targetFile = File(targetPath);

    final ByteData data = await rootBundle.load(source.assetPath);
    final Uint8List bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );

    final bool mustRewrite =
        !await targetFile.exists() || await targetFile.length() != bytes.length;

    if (mustRewrite) {
      await targetFile.writeAsBytes(bytes, flush: true);
    }

    return targetPath;
  }

  String _cleanHtml(String text) {
    return text
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</h[1-6]>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}
