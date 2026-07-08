import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

enum QuranTafsirSourceType { json, database }

class QuranTafsirSource {
  const QuranTafsirSource({
    required this.id,
    required this.label,
    required this.assetPath,
    this.type = QuranTafsirSourceType.json,
  });

  final String id;
  final String label;
  final String assetPath;
  final QuranTafsirSourceType type;
}

class QuranTafsirEntry {
  const QuranTafsirEntry({required this.source, required this.text});

  final QuranTafsirSource source;
  final String text;
}

class QuranTafsirRepository {
  QuranTafsirRepository._();

  static final QuranTafsirRepository instance = QuranTafsirRepository._();

  static const List<QuranTafsirSource> sources = <QuranTafsirSource>[
    QuranTafsirSource(
      id: 'wasit',
      label: 'التفسير الوسيط',
      assetPath: 'assets/quran/tafsir/ar-tafsir-al-wasit.json',
    ),
    QuranTafsirSource(
      id: 'qurtubi',
      label: 'تفسير القرطبي',
      assetPath: 'assets/quran/tafsir/ar-tafseer-al-qurtubi.json',
    ),
    QuranTafsirSource(
      id: 'ibn_kathir',
      label: 'تفسير ابن كثير',
      assetPath: 'assets/quran/tafsir/ar-tafsir-ibn-kathir.json',
    ),
    QuranTafsirSource(
      id: 'tabari',
      label: 'تفسير الطبري',
      assetPath: 'assets/quran/tafsir/ar-tafsir-al-tabari.json',
    ),
    QuranTafsirSource(
      id: 'ibn_al_jawzi',
      label: 'تفسير ابن الجوزي',
      assetPath: 'assets/quran/tafsir/tafsir-ibn-al-jawzi.db',
      type: QuranTafsirSourceType.database,
    ),
    QuranTafsirSource(
      id: 'jamia_al_bayan_aliji',
      label: 'جامع البيان للإيجي',
      assetPath: 'assets/quran/tafsir/jamia-al-bayan-aliji.db',
      type: QuranTafsirSourceType.database,
    ),
    QuranTafsirSource(
      id: 'ibn_al_qayyim',
      label: 'تفسير ابن القيم',
      assetPath: 'assets/quran/tafsir/tafsir-ibn-al-qayyim.json',
    ),
  ];

  static const String _databaseFolderName = 'quran_tafsir_databases_v1';

  final Map<String, Map<String, dynamic>> _jsonCache =
      <String, Map<String, dynamic>>{};
  final Map<String, Database> _databaseCache = <String, Database>{};

  Future<QuranTafsirEntry?> getTafsir({
    required QuranTafsirSource source,
    required int surah,
    required int ayah,
  }) async {
    final String? text = switch (source.type) {
      QuranTafsirSourceType.json => await _getJsonTafsir(
        source: source,
        surah: surah,
        ayah: ayah,
      ),
      QuranTafsirSourceType.database => await _getDatabaseTafsir(
        source: source,
        surah: surah,
        ayah: ayah,
      ),
    };

    final String cleaned = _cleanHtml(text ?? '');
    if (cleaned.trim().isEmpty) {
      return null;
    }

    return QuranTafsirEntry(source: source, text: cleaned);
  }

  Future<String?> _getJsonTafsir({
    required QuranTafsirSource source,
    required int surah,
    required int ayah,
  }) async {
    final Map<String, dynamic> data = await _loadJsonSource(source);
    final dynamic rawEntry = data['$surah:$ayah'];
    if (rawEntry is! Map) {
      return null;
    }

    return rawEntry['text']?.toString();
  }

  Future<String?> _getDatabaseTafsir({
    required QuranTafsirSource source,
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

  Future<Map<String, dynamic>> _loadJsonSource(QuranTafsirSource source) async {
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

  Future<Database> _openDatabase(QuranTafsirSource source) async {
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

  Future<String> _copyDatabaseFromAssets(QuranTafsirSource source) async {
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
