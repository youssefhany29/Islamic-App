import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/chapter_audio_file_model.dart';
import '../models/reciter_model.dart';

class RecitationApiService {
  RecitationApiService._();

  static const String _quranComBaseUrl = 'https://api.quran.com/api/v4';
  static const String _mp3QuranRecitersUrl =
      'https://mp3quran.net/api/v3/reciters?language=ar';

  static Future<List<ReciterModel>> getReciters() async {
    try {
      final quranComReciters = await _getQuranComReciters();

      if (quranComReciters.isNotEmpty) {
        debugPrint('✅ Using Quran.com reciters: ${quranComReciters.length}');
        return quranComReciters;
      }
    } catch (error) {
      debugPrint('⚠️ Quran.com reciters failed, fallback to MP3Quran: $error');
    }

    final mp3QuranReciters = await _getMp3QuranReciters();

    debugPrint('✅ Using MP3Quran reciters: ${mp3QuranReciters.length}');

    return mp3QuranReciters;
  }

  static Future<List<ReciterModel>> _getQuranComReciters() async {
    final uri = Uri.parse('$_quranComBaseUrl/resources/chapter_reciters')
        .replace(
      queryParameters: {
        'language': 'ar',
      },
    );

    debugPrint('📡 Quran.com reciters request: $uri');

    final response = await http.get(
      uri,
      headers: const {
        'Accept': 'application/json',
      },
    );

    debugPrint('📡 Quran.com reciters statusCode: ${response.statusCode}');

    if (response.statusCode != 200) {
      debugPrint('❌ Quran.com reciters body: ${response.body}');
      throw Exception('Quran.com failed: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final rawReciters = decoded['reciters'] as List<dynamic>? ?? [];

    final reciters = rawReciters
        .whereType<Map<String, dynamic>>()
        .map(ReciterModel.fromQuranComJson)
        .where((reciter) => reciter.id > 0)
        .toList();

    reciters.sort((a, b) => a.name.compareTo(b.name));

    return reciters;
  }

  static Future<List<ReciterModel>> _getMp3QuranReciters() async {
    final uri = Uri.parse(_mp3QuranRecitersUrl);

    debugPrint('📡 MP3Quran reciters request: $uri');

    final response = await http.get(
      uri,
      headers: const {
        'Accept': 'application/json',
      },
    );

    debugPrint('📡 MP3Quran reciters statusCode: ${response.statusCode}');

    if (response.statusCode != 200) {
      debugPrint('❌ MP3Quran reciters body: ${response.body}');
      throw Exception('MP3Quran failed: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final rawReciters = decoded['reciters'] as List<dynamic>? ?? [];

    final reciters = rawReciters
        .whereType<Map<String, dynamic>>()
        .map(ReciterModel.fromMp3QuranJson)
        .where((reciter) {
      return reciter.id > 0 &&
          reciter.serverUrl.trim().isNotEmpty &&
          reciter.availableSurahs.isNotEmpty;
    })
        .toList();

    reciters.sort((a, b) => a.name.compareTo(b.name));

    return reciters;
  }

  static Future<ChapterAudioFileModel> getChapterAudioFile({
    required int reciterId,
    required RecitationSource source,
    required int chapterNumber,
    String mp3QuranServerUrl = '',
  }) async {
    if (source == RecitationSource.mp3Quran) {
      final safeServer = mp3QuranServerUrl.endsWith('/')
          ? mp3QuranServerUrl
          : '$mp3QuranServerUrl/';

      final paddedNumber = chapterNumber.toString().padLeft(3, '0');
      final audioUrl = '$safeServer$paddedNumber.mp3';

      return ChapterAudioFileModel.fromMp3QuranUrl(
        chapterId: chapterNumber,
        audioUrl: audioUrl,
      );
    }

    try {
      return await _getQuranComChapterAudioFile(
        reciterId: reciterId,
        chapterNumber: chapterNumber,
      );
    } catch (error) {
      debugPrint('❌ Quran.com chapter audio failed: $error');
      rethrow;
    }
  }

  static Future<ChapterAudioFileModel> _getQuranComChapterAudioFile({
    required int reciterId,
    required int chapterNumber,
  }) async {
    final uri = Uri.parse(
      '$_quranComBaseUrl/chapter_recitations/$reciterId/$chapterNumber',
    );

    debugPrint('📡 Quran.com chapter audio request: $uri');

    final response = await http.get(
      uri,
      headers: const {
        'Accept': 'application/json',
      },
    );

    debugPrint('📡 Quran.com chapter audio statusCode: ${response.statusCode}');

    if (response.statusCode != 200) {
      debugPrint('❌ Quran.com chapter audio body: ${response.body}');
      throw Exception('Quran.com audio failed: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final audioFile = decoded['audio_file'] as Map<String, dynamic>?;

    if (audioFile == null) {
      throw Exception('Audio file not found.');
    }

    return ChapterAudioFileModel.fromJson(audioFile);
  }
}