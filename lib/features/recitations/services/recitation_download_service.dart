import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/quran_surahs_data.dart';
import '../models/downloaded_recitation_model.dart';
import '../models/reciter_model.dart';
import 'recitation_api_service.dart';

class RecitationDownloadService {
  RecitationDownloadService._();

  static final Dio _dio = Dio();

  static const String _downloadsKey = 'downloaded_recitations';

  static String _downloadKey({
    required int reciterId,
    required RecitationSource source,
    required int surahNumber,
  }) {
    return '${source.name}_${reciterId}_$surahNumber';
  }

  static Future<Directory> _getDownloadsDirectory() async {
    final baseDirectory = await getApplicationDocumentsDirectory();
    final downloadsDirectory = Directory(
      '${baseDirectory.path}/recitation_downloads',
    );

    if (!await downloadsDirectory.exists()) {
      await downloadsDirectory.create(recursive: true);
    }

    return downloadsDirectory;
  }

  static String _fileName({
    required int reciterId,
    required RecitationSource source,
    required int surahNumber,
  }) {
    final paddedSurah = surahNumber.toString().padLeft(3, '0');
    return '${source.name}_${reciterId}_$paddedSurah.mp3';
  }

  static Future<List<DownloadedRecitationModel>> getAllDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    final rawDownloads = prefs.getStringList(_downloadsKey) ?? [];

    final downloads = <DownloadedRecitationModel>[];

    for (final rawDownload in rawDownloads) {
      try {
        final decoded = jsonDecode(rawDownload) as Map<String, dynamic>;
        final download = DownloadedRecitationModel.fromMap(decoded);

        if (download.localFilePath.trim().isEmpty) continue;

        final file = File(download.localFilePath);

        if (await file.exists()) {
          downloads.add(download);
        }
      } catch (_) {}
    }

    downloads.sort((a, b) {
      final reciterCompare = a.reciterName.compareTo(b.reciterName);
      if (reciterCompare != 0) return reciterCompare;
      return a.surahNumber.compareTo(b.surahNumber);
    });

    return downloads;
  }

  static Future<void> _saveDownloads(
      List<DownloadedRecitationModel> downloads,
      ) async {
    final prefs = await SharedPreferences.getInstance();

    final encodedDownloads = downloads.map((download) {
      return jsonEncode(download.toMap());
    }).toList();

    await prefs.setStringList(_downloadsKey, encodedDownloads);
  }

  static Future<bool> hasAnyDownloads() async {
    final downloads = await getAllDownloads();
    return downloads.isNotEmpty;
  }

  static Future<DownloadedRecitationModel?> getDownload({
    required int reciterId,
    required RecitationSource source,
    required int surahNumber,
  }) async {
    final downloads = await getAllDownloads();
    final key = _downloadKey(
      reciterId: reciterId,
      source: source,
      surahNumber: surahNumber,
    );

    for (final download in downloads) {
      if (download.uniqueKey == key) {
        return download;
      }
    }

    return null;
  }

  static Future<bool> isDownloaded({
    required int reciterId,
    required RecitationSource source,
    required int surahNumber,
  }) async {
    final download = await getDownload(
      reciterId: reciterId,
      source: source,
      surahNumber: surahNumber,
    );

    return download != null;
  }

  static Future<DownloadedRecitationModel> downloadSurah({
    required int reciterId,
    required String reciterName,
    required RecitationSource reciterSource,
    required String mp3QuranServerUrl,
    required int surahNumber,
    required String surahName,
    required String audioUrl,
    CancelToken? cancelToken,
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    final existingDownload = await getDownload(
      reciterId: reciterId,
      source: reciterSource,
      surahNumber: surahNumber,
    );

    if (existingDownload != null) {
      return existingDownload;
    }

    final downloadsDirectory = await _getDownloadsDirectory();
    final filePath =
        '${downloadsDirectory.path}/${_fileName(
      reciterId: reciterId,
      source: reciterSource,
      surahNumber: surahNumber,
    )}';

    final tempFilePath = '$filePath.part';

    try {
      await _dio.download(
        audioUrl,
        tempFilePath,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          receiveTimeout: const Duration(minutes: 5),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      final tempFile = File(tempFilePath);
      final finalFile = File(filePath);

      if (await finalFile.exists()) {
        await finalFile.delete();
      }

      await tempFile.rename(filePath);

      final fileSize = await finalFile.length();

      final download = DownloadedRecitationModel(
        reciterId: reciterId,
        reciterName: reciterName,
        reciterSource: reciterSource,
        mp3QuranServerUrl: mp3QuranServerUrl,
        surahNumber: surahNumber,
        surahName: surahName,
        audioUrl: audioUrl,
        localFilePath: filePath,
        fileSizeBytes: fileSize,
        downloadedAt: DateTime.now().toIso8601String(),
      );

      final downloads = await getAllDownloads();
      downloads.removeWhere((item) => item.uniqueKey == download.uniqueKey);
      downloads.add(download);

      await _saveDownloads(downloads);

      return download;
    } catch (_) {
      final tempFile = File(tempFilePath);

      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      rethrow;
    }
  }

  static Future<void> deleteDownload(DownloadedRecitationModel download) async {
    final file = File(download.localFilePath);

    if (await file.exists()) {
      await file.delete();
    }

    final downloads = await getAllDownloads();
    downloads.removeWhere((item) => item.uniqueKey == download.uniqueKey);

    await _saveDownloads(downloads);
  }

  static Future<void> deleteSurah({
    required int reciterId,
    required RecitationSource source,
    required int surahNumber,
  }) async {
    final download = await getDownload(
      reciterId: reciterId,
      source: source,
      surahNumber: surahNumber,
    );

    if (download == null) return;

    await deleteDownload(download);
  }

  static Future<void> deleteAllDownloads() async {
    final downloads = await getAllDownloads();

    for (final download in downloads) {
      final file = File(download.localFilePath);

      if (await file.exists()) {
        await file.delete();
      }
    }

    await _saveDownloads([]);
  }

  static Future<void> downloadAllReciterSurahs({
    required ReciterModel reciter,
    CancelToken? cancelToken,
    required void Function(int current, int total, String surahName) onProgress,
  }) async {
    final surahs = QuranSurahsData.surahs.where((surah) {
      return reciter.hasSurah(surah.number);
    }).toList();

    for (int index = 0; index < surahs.length; index++) {
      if (cancelToken?.isCancelled ?? false) {
        throw DioException.requestCancelled(
          requestOptions: RequestOptions(path: ''),
          reason: 'تم إيقاف التحميل',
        );
      }

      final surah = surahs[index];

      onProgress(index + 1, surahs.length, surah.name);

      final alreadyDownloaded = await isDownloaded(
        reciterId: reciter.id,
        source: reciter.source,
        surahNumber: surah.number,
      );

      if (alreadyDownloaded) {
        continue;
      }

      final audioFile = await RecitationApiService.getChapterAudioFile(
        reciterId: reciter.id,
        source: reciter.source,
        chapterNumber: surah.number,
        mp3QuranServerUrl: reciter.serverUrl,
      );

      await downloadSurah(
        reciterId: reciter.id,
        reciterName: reciter.name,
        reciterSource: reciter.source,
        mp3QuranServerUrl: reciter.serverUrl,
        surahNumber: surah.number,
        surahName: surah.name,
        audioUrl: audioFile.audioUrl,
        cancelToken: cancelToken,
      );
    }
  }

  static String formatSize(int bytes) {
    if (bytes <= 0) return '';

    final kb = bytes / 1024;
    final mb = kb / 1024;

    if (mb >= 1) {
      return '${mb.toStringAsFixed(1)} MB';
    }

    return '${kb.toStringAsFixed(0)} KB';
  }
}