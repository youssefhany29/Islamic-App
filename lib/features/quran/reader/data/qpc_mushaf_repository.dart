import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/qpc_models.dart';
import 'qpc_reader_perf.dart';

class QpcMushafRepository {
  QpcMushafRepository._();

  static final QpcMushafRepository instance = QpcMushafRepository._();

  static const String _wordsDbAssetPath = 'assets/quran/qpc-v2.db';
  static const String _layoutDbAssetPath = 'assets/quran/qpc-v2-15-lines.db';

  static const String _wordsDbFileName = 'qpc-v2.db';
  static const String _layoutDbFileName = 'qpc-v2-15-lines.db';

  Database? _wordsDb;
  Database? _layoutDb;
  Future<Database>? _wordsDbOpenFuture;
  Future<Database>? _layoutDbOpenFuture;

  final Map<int, QpcPageData> _pageMemoryCache = <int, QpcPageData>{};
  final Map<int, Future<QpcPageData>> _pageFutureCache =
      <int, Future<QpcPageData>>{};
  final Map<String, List<QpcWord>> _ayahWordsMemoryCache =
      <String, List<QpcWord>>{};
  final Map<QpcAyahKey, int> _finalWordIndexMemoryCache = <QpcAyahKey, int>{};

  QpcPageData? getCachedPage(int pageNumber) {
    final int safePageNumber = pageNumber.clamp(1, 604);
    return _pageMemoryCache[safePageNumber];
  }

  Future<void> initialize() async {
    await QpcReaderPerf.timeAsync('repository initialize', () async {
      await Future.wait(<Future<Database>>[_openWordsDb(), _openLayoutDb()]);
    });
  }

  Future<QpcPageData> loadPage(int pageNumber) {
    final int safePageNumber = pageNumber.clamp(1, 604);

    final QpcPageData? cachedPage = _pageMemoryCache[safePageNumber];
    if (cachedPage != null) {
      QpcReaderPerf.mark('page data cache hit p$safePageNumber');
      return Future<QpcPageData>.value(cachedPage);
    }

    final Future<QpcPageData>? runningLoad = _pageFutureCache[safePageNumber];
    if (runningLoad != null) {
      QpcReaderPerf.mark('page data joined in-flight p$safePageNumber');
      return runningLoad;
    }

    final Future<QpcPageData> task = _loadPageFromDatabases(safePageNumber);
    _pageFutureCache[safePageNumber] = task;

    return task.whenComplete(() {
      _pageFutureCache.remove(safePageNumber);
    });
  }

  Future<QpcPageData> _loadPageFromDatabases(int safePageNumber) async {
    return QpcReaderPerf.timeAsync(
      'page data db load p$safePageNumber',
      () async {
        final Database wordsDb = await _openWordsDb();
        final Database layoutDb = await _openLayoutDb();

        final Stopwatch? layoutStopwatch = QpcReaderPerf.start();
        final List<Map<String, Object?>> lineRows = await layoutDb.query(
          'pages',
          where: 'page_number = ?',
          whereArgs: <Object?>[safePageNumber],
          orderBy: 'line_number ASC',
        );
        QpcReaderPerf.end('layout db query p$safePageNumber', layoutStopwatch);

        int? pageFirstWordId;
        int? pageLastWordId;

        for (final Map<String, Object?> row in lineRows) {
          final int? firstWordId = _asInt(row['first_word_id']);
          final int? lastWordId = _asInt(row['last_word_id']);

          if (firstWordId != null) {
            pageFirstWordId = pageFirstWordId == null
                ? firstWordId
                : (firstWordId < pageFirstWordId
                      ? firstWordId
                      : pageFirstWordId);
          }

          if (lastWordId != null) {
            pageLastWordId = pageLastWordId == null
                ? lastWordId
                : (lastWordId > pageLastWordId ? lastWordId : pageLastWordId);
          }
        }

        final Map<int, QpcWord> wordsById = <int, QpcWord>{};

        if (pageFirstWordId != null && pageLastWordId != null) {
          final Stopwatch? wordStopwatch = QpcReaderPerf.start();
          final List<Map<String, Object?>> wordRows = await wordsDb.query(
            'words',
            where: 'id >= ? AND id <= ?',
            whereArgs: <Object?>[pageFirstWordId, pageLastWordId],
            orderBy: 'id ASC',
          );
          QpcReaderPerf.end('words db query p$safePageNumber', wordStopwatch);

          for (final Map<String, Object?> wordRow in wordRows) {
            final QpcWord word = _wordFromRow(wordRow);
            wordsById[word.id] = word;
          }
        }

        final List<QpcMushafLine> lines = <QpcMushafLine>[];

        for (final Map<String, Object?> row in lineRows) {
          final int lineNumber = _asInt(row['line_number']) ?? 0;
          final String lineType = row['line_type']?.toString() ?? '';
          final bool isCentered = (_asInt(row['is_centered']) ?? 0) == 1;
          final int? firstWordId = _asInt(row['first_word_id']);
          final int? lastWordId = _asInt(row['last_word_id']);
          final int? surahNumber = _asInt(row['surah_number']);

          final List<QpcWord> words = <QpcWord>[];

          if (firstWordId != null && lastWordId != null) {
            for (int id = firstWordId; id <= lastWordId; id++) {
              final QpcWord? word = wordsById[id];
              if (word != null) {
                words.add(word);
              }
            }
          }

          lines.add(
            QpcMushafLine(
              pageNumber: safePageNumber,
              lineNumber: lineNumber,
              lineType: lineType,
              isCentered: isCentered,
              firstWordId: firstWordId,
              lastWordId: lastWordId,
              surahNumber: surahNumber,
              words: words,
            ),
          );
        }

        final QpcPageData pageData = QpcPageData(
          pageNumber: safePageNumber,
          lines: lines,
          finalWordByAyah: await _loadFinalWordIndexesForPageWords(
            wordsDb: wordsDb,
            pageWords: wordsById.values.toList(growable: false),
          ),
        );

        _pageMemoryCache[safePageNumber] = pageData;

        return pageData;
      },
    );
  }

  Future<List<QpcWord>> loadAyahWords({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    final String cacheKey = '$surahNumber:$ayahNumber';

    final List<QpcWord>? cachedWords = _ayahWordsMemoryCache[cacheKey];
    if (cachedWords != null) {
      return cachedWords;
    }

    final Database wordsDb = await _openWordsDb();

    final List<Map<String, Object?>> rows = await wordsDb.query(
      'words',
      where: 'surah = ? AND ayah = ?',
      whereArgs: <Object?>[surahNumber, ayahNumber],
      orderBy: 'word ASC',
    );

    final List<QpcWord> words = rows.map(_wordFromRow).toList();

    _ayahWordsMemoryCache[cacheKey] = words;

    return words;
  }

  Future<void> warmUpPagesAround(
    int pageNumber, {
    int radius = 2,
    bool trimCache = true,
  }) async {
    final int safePageNumber = pageNumber.clamp(1, 604);
    final int safeRadius = radius < 0 ? 0 : radius;

    await QpcReaderPerf.timeAsync(
      'repository warm-up p$safePageNumber r$safeRadius',
      () async {
        for (final int page in _priorityPages(
          safePageNumber,
          radius: safeRadius,
        )) {
          if (!_pageMemoryCache.containsKey(page)) {
            await loadPage(page);
          }
        }
      },
    );

    if (trimCache) {
      retainPagesAround(safePageNumber, radius: safeRadius + 2);
    }
  }

  void retainPagesAround(int pageNumber, {int radius = 4}) {
    final int safePageNumber = pageNumber.clamp(1, 604);
    final int safeRadius = radius < 0 ? 0 : radius;
    final int minPage = (safePageNumber - safeRadius).clamp(1, 604);
    final int maxPage = (safePageNumber + safeRadius).clamp(1, 604);

    _pageMemoryCache.removeWhere((page, _) => page < minPage || page > maxPage);
  }

  Future<void> clearMemoryCache() async {
    _pageMemoryCache.clear();
    _pageFutureCache.clear();
    _ayahWordsMemoryCache.clear();
    _finalWordIndexMemoryCache.clear();
  }

  Future<void> close() async {
    await _wordsDb?.close();
    await _layoutDb?.close();

    _wordsDb = null;
    _layoutDb = null;
    _wordsDbOpenFuture = null;
    _layoutDbOpenFuture = null;

    await clearMemoryCache();
  }

  Future<Database> _openWordsDb() async {
    if (_wordsDb != null) {
      return _wordsDb!;
    }

    final Future<Database>? runningOpen = _wordsDbOpenFuture;
    if (runningOpen != null) {
      return runningOpen;
    }

    final Future<Database> task = QpcReaderPerf.timeAsync(
      'open words db',
      () async {
        final String dbPath = await _copyAssetDatabaseIfNeeded(
          assetPath: _wordsDbAssetPath,
          fileName: _wordsDbFileName,
          folderName: 'qpc_reader_databases_v1',
        );

        final Database database = await openDatabase(
          dbPath,
          readOnly: true,
          singleInstance: true,
        );

        _wordsDb = database;
        return database;
      },
    );
    _wordsDbOpenFuture = task;

    return task.whenComplete(() {
      _wordsDbOpenFuture = null;
    });
  }

  Future<Database> _openLayoutDb() async {
    if (_layoutDb != null) {
      return _layoutDb!;
    }

    final Future<Database>? runningOpen = _layoutDbOpenFuture;
    if (runningOpen != null) {
      return runningOpen;
    }

    final Future<Database> task = QpcReaderPerf.timeAsync(
      'open layout db',
      () async {
        final String dbPath = await _copyAssetDatabaseIfNeeded(
          assetPath: _layoutDbAssetPath,
          fileName: _layoutDbFileName,
          folderName: 'qpc_reader_databases_v1',
        );

        final Database database = await openDatabase(
          dbPath,
          readOnly: true,
          singleInstance: true,
        );

        _layoutDb = database;
        return database;
      },
    );
    _layoutDbOpenFuture = task;

    return task.whenComplete(() {
      _layoutDbOpenFuture = null;
    });
  }

  Future<String> _copyAssetDatabaseIfNeeded({
    required String assetPath,
    required String fileName,
    required String folderName,
  }) async {
    final Directory appSupportDirectory =
        await getApplicationSupportDirectory();

    final String dbFolderPath = path.join(appSupportDirectory.path, folderName);

    await Directory(dbFolderPath).create(recursive: true);

    final String targetPath = path.join(dbFolderPath, fileName);
    final File targetFile = File(targetPath);

    if (await targetFile.exists()) {
      return targetPath;
    }

    final Stopwatch? stopwatch = QpcReaderPerf.start();
    final ByteData data = await rootBundle.load(assetPath);

    await targetFile.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
    QpcReaderPerf.end('copy database asset $fileName', stopwatch);

    return targetPath;
  }

  QpcWord _wordFromRow(Map<String, Object?> row) {
    return QpcWord(
      id: _asInt(row['id']) ?? 0,
      surah: _asInt(row['surah']) ?? 0,
      ayah: _asInt(row['ayah']) ?? 0,
      word: _asInt(row['word']) ?? 0,
      location: row['location']?.toString() ?? '',
      text: row['text']?.toString() ?? '',
    );
  }

  Future<Map<QpcAyahKey, int>> _loadFinalWordIndexesForPageWords({
    required Database wordsDb,
    required List<QpcWord> pageWords,
  }) async {
    if (pageWords.isEmpty) {
      return <QpcAyahKey, int>{};
    }

    final Set<String> keyTexts = <String>{};
    for (final QpcWord word in pageWords) {
      if (word.surah > 0 && word.ayah > 0) {
        keyTexts.add('${word.surah}:${word.ayah}');
      }
    }

    if (keyTexts.isEmpty) {
      return <QpcAyahKey, int>{};
    }

    final Map<QpcAyahKey, int> result = <QpcAyahKey, int>{};
    final Set<String> missingKeyTexts = <String>{};

    for (final String keyText in keyTexts) {
      final List<String> parts = keyText.split(':');
      final QpcAyahKey key = QpcAyahKey(
        surah: int.parse(parts[0]),
        ayah: int.parse(parts[1]),
      );
      final int? cachedFinalWord = _finalWordIndexMemoryCache[key];
      if (cachedFinalWord != null) {
        result[key] = cachedFinalWord;
      } else {
        missingKeyTexts.add(keyText);
      }
    }

    if (missingKeyTexts.isEmpty) {
      return result;
    }

    final String whereClause = missingKeyTexts
        .map((_) => '(surah = ? AND ayah = ?)')
        .join(' OR ');

    final List<Object?> args = <Object?>[];
    for (final String keyText in missingKeyTexts) {
      final List<String> parts = keyText.split(':');
      args.add(int.parse(parts[0]));
      args.add(int.parse(parts[1]));
    }

    final Stopwatch? stopwatch = QpcReaderPerf.start();
    final List<Map<String, Object?>> rows = await wordsDb.rawQuery(
      'SELECT surah, ayah, MAX(word) AS final_word '
      'FROM words WHERE $whereClause GROUP BY surah, ayah',
      args,
    );
    QpcReaderPerf.end(
      'final word db query ayahs=${missingKeyTexts.length}',
      stopwatch,
    );

    for (final Map<String, Object?> row in rows) {
      final int? surah = _asInt(row['surah']);
      final int? ayah = _asInt(row['ayah']);
      final int? finalWord = _asInt(row['final_word']);

      if (surah != null && ayah != null && finalWord != null) {
        final QpcAyahKey key = QpcAyahKey(surah: surah, ayah: ayah);
        _finalWordIndexMemoryCache[key] = finalWord;
        result[key] = finalWord;
      }
    }

    return result;
  }

  List<int> _priorityPages(int pageNumber, {required int radius}) {
    final int safePageNumber = pageNumber.clamp(1, 604);
    final List<int> pages = <int>[safePageNumber];

    for (int offset = 1; offset <= radius; offset++) {
      final int nextPage = safePageNumber + offset;
      final int previousPage = safePageNumber - offset;

      if (nextPage <= 604) {
        pages.add(nextPage);
      }

      if (previousPage >= 1) {
        pages.add(previousPage);
      }
    }

    return pages;
  }

  int? _asInt(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.round();
    }

    final String text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return int.tryParse(text);
  }
}
