import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class QuranAyahAudioInfo {
  const QuranAyahAudioInfo({
    required this.surahNumber,
    required this.ayahNumber,
    required this.audioUrl,
    required this.duration,
    required this.segments,
    required this.reciter,
  });

  final int surahNumber;
  final int ayahNumber;
  final String audioUrl;
  final double? duration;
  final List<QuranWordAudioSegment> segments;
  final QuranAyahReciter reciter;
}

class QuranWordAudioSegment {
  const QuranWordAudioSegment({
    required this.fromWord,
    required this.toWord,
    required this.startMs,
    required this.endMs,
  });

  final int fromWord;
  final int toWord;
  final int startMs;
  final int endMs;

  factory QuranWordAudioSegment.fromList(List<dynamic> values) {
    if (values.length == 3) {
      final int word = _asInt(values[0]) ?? 0;
      return QuranWordAudioSegment(
        fromWord: word,
        toWord: word,
        startMs: _asInt(values[1]) ?? 0,
        endMs: _asInt(values[2]) ?? 0,
      );
    }

    return QuranWordAudioSegment(
      fromWord: _asInt(values.isNotEmpty ? values[0] : null) ?? 0,
      toWord: _asInt(values.length > 1 ? values[1] : null) ?? 0,
      startMs: _asInt(values.length > 2 ? values[2] : null) ?? 0,
      endMs: _asInt(values.length > 3 ? values[3] : null) ?? 0,
    );
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString());
  }
}

enum QuranAyahReciterAssetType { database, json }

class QuranAyahReciter {
  const QuranAyahReciter({
    required this.id,
    required this.name,
    required this.assetDbPath,
    required this.dbFileName,
    this.assetType = QuranAyahReciterAssetType.database,
  });

  final String id;
  final String name;
  final String assetDbPath;
  final String dbFileName;
  final QuranAyahReciterAssetType assetType;

  bool get usesDatabase => assetType == QuranAyahReciterAssetType.database;
  bool get usesJson => assetType == QuranAyahReciterAssetType.json;
}

class QuranAyahAudioService {
  QuranAyahAudioService._();

  static final QuranAyahAudioService instance = QuranAyahAudioService._();

  static const List<QuranAyahReciter> reciters = <QuranAyahReciter>[
    QuranAyahReciter(
      id: 'alnufais',
      name: 'أحمد النفيس',
      assetDbPath: 'assets/quran/audio/ayah-recitation-alnufais.db',
      dbFileName: 'ayah-recitation-alnufais.db',
    ),
    QuranAyahReciter(
      id: 'yasser_al_dosari',
      name: 'ياسر الدوسري',
      assetDbPath:
          'assets/quran/audio/ayah-recitation-yasser-al-dosari-murattal-hafs-961.db',
      dbFileName: 'ayah-recitation-yasser-al-dosari-murattal-hafs-961.db',
    ),
    QuranAyahReciter(
      id: 'minshawi',
      name: 'محمد صديق المنشاوي',
      assetDbPath:
          'assets/quran/audio/ayah-recitation-muhammad-siddiq-al-minshawi-murattal-hafs-959.db',
      dbFileName:
          'ayah-recitation-muhammad-siddiq-al-minshawi-murattal-hafs-959.db',
    ),
    QuranAyahReciter(
      id: 'sudais',
      name: 'عبد الرحمن السديس',
      assetDbPath:
          'assets/quran/audio/ayah-recitation-abdur-rahman-as-sudais-recitation.db',
      dbFileName: 'ayah-recitation-abdur-rahman-as-sudais-recitation.db',
    ),
    QuranAyahReciter(
      id: 'husary',
      name: 'محمود خليل الحصري',
      assetDbPath:
          'assets/quran/audio/ayah-recitation-mahmoud-khalil-al-husary-murattal-hafs-955.json',
      dbFileName:
          'ayah-recitation-mahmoud-khalil-al-husary-murattal-hafs-955.json',
      assetType: QuranAyahReciterAssetType.json,
    ),
    QuranAyahReciter(
      id: 'abdul_basit',
      name: 'عبد الباسط عبد الصمد',
      assetDbPath:
          'assets/quran/audio/ayah-recitation-abdul-basit-abdul-samad-murattal-hafs-950.json',
      dbFileName:
          'ayah-recitation-abdul-basit-abdul-samad-murattal-hafs-950.json',
      assetType: QuranAyahReciterAssetType.json,
    ),
    QuranAyahReciter(
      id: 'maher_al_muaiqly',
      name: 'ماهر المعيقلي',
      assetDbPath:
          'assets/quran/audio/ayah-recitation-maher-al-mu-aiqly-murattal-hafs-948.db',
      dbFileName: 'ayah-recitation-maher-al-mu-aiqly-murattal-hafs-948.db',
    ),
  ];

  static const String _databaseFolderName = 'quran_audio_databases_v7';

  final AudioPlayer _player = AudioPlayer();
  final Map<String, Database> _openedDatabases = <String, Database>{};
  final Map<String, Map<String, dynamic>> _jsonReciterCache =
      <String, Map<String, dynamic>>{};

  QuranAyahAudioInfo? _currentAyah;
  QuranAyahReciter _currentReciter = reciters.first;

  AudioPlayer get player => _player;
  QuranAyahAudioInfo? get currentAyah => _currentAyah;
  QuranAyahReciter get currentReciter => _currentReciter;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  Future<void> setReciter(QuranAyahReciter reciter) async {
    if (reciter.id == _currentReciter.id) return;

    await _player.stop();
    _currentAyah = null;
    _currentReciter = reciter;
  }

  Future<QuranAyahAudioInfo?> getAyahAudio({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    if (surahNumber < 1 || surahNumber > 114 || ayahNumber < 1) {
      return null;
    }

    final QuranAyahAudioInfo? selected = await _findInReciter(
      reciter: _currentReciter,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
    );

    if (selected != null) return selected;

    for (final QuranAyahReciter reciter in reciters) {
      if (reciter.id == _currentReciter.id) continue;

      final QuranAyahAudioInfo? fallback = await _findInReciter(
        reciter: reciter,
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
      );

      if (fallback != null) return fallback;
    }

    return null;
  }

  Future<QuranAyahAudioInfo?> playAyah({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    final QuranAyahAudioInfo? info = await getAyahAudio(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
    );

    if (info == null || info.audioUrl.trim().isEmpty) return null;

    _currentAyah = info;

    final AudioSource source = AudioSource.uri(
      Uri.parse(info.audioUrl),
      tag: MediaItem(
        id: '${info.surahNumber}:${info.ayahNumber}',
        album: 'القرآن الكريم',
        title: 'سورة ${info.surahNumber} - آية ${info.ayahNumber}',
        artist: info.reciter.name,
      ),
    );

    await _player.stop();
    await _player.setAudioSource(source);
    unawaited(_player.play());

    return info;
  }

  Future<void> pause() async => _player.pause();
  Future<void> resume() async {
    unawaited(_player.play());
  }

  Future<void> stop() async => _player.stop();

  Future<void> dispose() async {
    await _player.dispose();
    for (final Database db in _openedDatabases.values) {
      await db.close();
    }
    _openedDatabases.clear();
  }

  Future<QuranAyahAudioInfo?> _findInReciter({
    required QuranAyahReciter reciter,
    required int surahNumber,
    required int ayahNumber,
  }) async {
    if (reciter.usesJson) {
      return _findInJsonReciter(
        reciter: reciter,
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
      );
    }

    try {
      final Database db = await _openDatabase(reciter);

      Map<String, Object?>? row;

      final List<Map<String, Object?>> directRows = await db.query(
        'verses',
        columns: <String>[
          'surah_number',
          'ayah_number',
          'audio_url',
          'duration',
          'segments',
        ],
        where: 'surah_number = ? AND ayah_number = ?',
        whereArgs: <Object?>[surahNumber, ayahNumber],
        limit: 1,
      );

      if (directRows.isNotEmpty) {
        final Map<String, Object?> directRow = directRows.first;
        final String directUrl =
            directRow['audio_url']?.toString().trim() ?? '';

        if (_audioUrlMatchesAyah(
          directUrl,
          surahNumber: surahNumber,
          ayahNumber: ayahNumber,
        )) {
          row = directRow;
        }
      }

      row ??= await _findByAudioFileName(
        db: db,
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
      );

      if (row == null) return null;

      final String audioUrl = row['audio_url']?.toString().trim() ?? '';
      if (audioUrl.isEmpty) return null;

      return QuranAyahAudioInfo(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        audioUrl: audioUrl,
        duration: _asDouble(row['duration']),
        segments: _parseSegments(row['segments']?.toString()),
        reciter: reciter,
      );
    } catch (_) {
      return null;
    }
  }

  Future<QuranAyahAudioInfo?> _findInJsonReciter({
    required QuranAyahReciter reciter,
    required int surahNumber,
    required int ayahNumber,
  }) async {
    try {
      final Map<String, dynamic> data = await _loadJsonReciter(reciter);
      final dynamic rawEntry = data['$surahNumber:$ayahNumber'];
      if (rawEntry is! Map) {
        return null;
      }

      final String audioUrl = rawEntry['audio_url']?.toString().trim() ?? '';
      if (audioUrl.isEmpty) {
        return null;
      }

      return QuranAyahAudioInfo(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        audioUrl: audioUrl,
        duration: _asDouble(rawEntry['duration']),
        segments: _parseSegments(jsonEncode(rawEntry['segments'])),
        reciter: reciter,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _loadJsonReciter(
    QuranAyahReciter reciter,
  ) async {
    final Map<String, dynamic>? cached = _jsonReciterCache[reciter.id];
    if (cached != null) {
      return cached;
    }

    final String rawJson = await rootBundle.loadString(reciter.assetDbPath);
    final Map<String, dynamic> decoded =
        jsonDecode(rawJson) as Map<String, dynamic>;

    _jsonReciterCache[reciter.id] = decoded;
    return decoded;
  }

  Future<Map<String, Object?>?> _findByAudioFileName({
    required Database db,
    required int surahNumber,
    required int ayahNumber,
  }) async {
    final String fileName = _audioFileName(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
    );
    final List<Map<String, Object?>> rows = await db.query(
      'verses',
      columns: <String>[
        'surah_number',
        'ayah_number',
        'audio_url',
        'duration',
        'segments',
      ],
      where: 'audio_url LIKE ?',
      whereArgs: <Object?>['%$fileName'],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return rows.first;
  }

  static bool _audioUrlMatchesAyah(
    String audioUrl, {
    required int surahNumber,
    required int ayahNumber,
  }) {
    return audioUrl.endsWith(
      _audioFileName(surahNumber: surahNumber, ayahNumber: ayahNumber),
    );
  }

  static String _audioFileName({
    required int surahNumber,
    required int ayahNumber,
  }) {
    return '${surahNumber.toString().padLeft(3, '0')}'
        '${ayahNumber.toString().padLeft(3, '0')}.mp3';
  }

  Future<Database> _openDatabase(QuranAyahReciter reciter) async {
    if (!reciter.usesDatabase) {
      throw StateError('${reciter.id} is not a database reciter');
    }

    final Database? cached = _openedDatabases[reciter.id];
    if (cached != null) return cached;

    final String dbPath = await _copyDatabaseFromAssets(reciter);
    final Database db = await openDatabase(
      dbPath,
      readOnly: true,
      singleInstance: false,
    );

    _openedDatabases[reciter.id] = db;
    return db;
  }

  Future<String> _copyDatabaseFromAssets(QuranAyahReciter reciter) async {
    final Directory appSupportDir = await getApplicationSupportDirectory();
    final String dbFolderPath =
        '${appSupportDir.path}${Platform.pathSeparator}$_databaseFolderName';

    await Directory(dbFolderPath).create(recursive: true);

    final String targetPath =
        '$dbFolderPath${Platform.pathSeparator}${reciter.dbFileName}';
    final File targetFile = File(targetPath);

    final ByteData data = await rootBundle.load(reciter.assetDbPath);
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

  static double? _asDouble(Object? value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static List<QuranWordAudioSegment> _parseSegments(String? rawSegments) {
    if (rawSegments == null || rawSegments.trim().isEmpty) {
      return const <QuranWordAudioSegment>[];
    }

    try {
      final dynamic decoded = jsonDecode(rawSegments);
      if (decoded is! List) return const <QuranWordAudioSegment>[];

      return decoded
          .whereType<List<dynamic>>()
          .map(QuranWordAudioSegment.fromList)
          .toList(growable: false);
    } catch (_) {
      return const <QuranWordAudioSegment>[];
    }
  }
}
