import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path/path.dart' as path;
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

class QuranAyahReciter {
  const QuranAyahReciter({
    required this.id,
    required this.name,
    required this.assetDbPath,
    required this.dbFileName,
  });

  final String id;
  final String name;
  final String assetDbPath;
  final String dbFileName;
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
  ];

  static const String _databaseFolderName = 'quran_audio_databases_v7';

  final AudioPlayer _player = AudioPlayer();
  final Map<String, Database> _openedDatabases = <String, Database>{};

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
    await _player.play();

    return info;
  }

  Future<void> pause() async => _player.pause();
  Future<void> resume() async => _player.play();
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
    try {
      final Database db = await _openDatabase(reciter);

      final List<Map<String, Object?>> rows = await db.query(
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

      if (rows.isEmpty) return null;

      final Map<String, Object?> row = rows.first;
      final String audioUrl = row['audio_url']?.toString().trim() ?? '';
      if (audioUrl.isEmpty) return null;

      return QuranAyahAudioInfo(
        surahNumber: _asInt(row['surah_number']) ?? surahNumber,
        ayahNumber: _asInt(row['ayah_number']) ?? ayahNumber,
        audioUrl: audioUrl,
        duration: _asDouble(row['duration']),
        segments: _parseSegments(row['segments']?.toString()),
        reciter: reciter,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Database> _openDatabase(QuranAyahReciter reciter) async {
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
    final String dbFolderPath = path.join(
      appSupportDir.path,
      _databaseFolderName,
    );

    await Directory(dbFolderPath).create(recursive: true);

    final String targetPath = path.join(dbFolderPath, reciter.dbFileName);
    final File targetFile = File(targetPath);

    final ByteData data = await rootBundle.load(reciter.assetDbPath);
    final Uint8List bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );

    final bool mustRewrite = !await targetFile.exists() ||
        await targetFile.length() != bytes.length;

    if (mustRewrite) {
      await targetFile.writeAsBytes(bytes, flush: true);
    }

    return targetPath;
  }

  static int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString());
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
