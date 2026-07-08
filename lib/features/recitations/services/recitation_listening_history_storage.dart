import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/reciter_model.dart';

class RecitationListeningHistoryItem {
  final String id;
  final int reciterId;
  final String reciterName;
  final RecitationSource reciterSource;
  final String mp3QuranServerUrl;
  final int surahNumber;
  final String surahName;
  final String audioUrl;
  final String? localFilePath;
  final int listenedSeconds;
  final int positionSeconds;
  final int durationSeconds;
  final int listenedAtMs;

  const RecitationListeningHistoryItem({
    required this.id,
    required this.reciterId,
    required this.reciterName,
    required this.reciterSource,
    required this.mp3QuranServerUrl,
    required this.surahNumber,
    required this.surahName,
    required this.audioUrl,
    this.localFilePath,
    required this.listenedSeconds,
    required this.positionSeconds,
    required this.durationSeconds,
    required this.listenedAtMs,
  });

  RecitationListeningHistoryItem copyWith({
    String? id,
    int? reciterId,
    String? reciterName,
    RecitationSource? reciterSource,
    String? mp3QuranServerUrl,
    int? surahNumber,
    String? surahName,
    String? audioUrl,
    String? localFilePath,
    int? listenedSeconds,
    int? positionSeconds,
    int? durationSeconds,
    int? listenedAtMs,
  }) {
    return RecitationListeningHistoryItem(
      id: id ?? this.id,
      reciterId: reciterId ?? this.reciterId,
      reciterName: reciterName ?? this.reciterName,
      reciterSource: reciterSource ?? this.reciterSource,
      mp3QuranServerUrl: mp3QuranServerUrl ?? this.mp3QuranServerUrl,
      surahNumber: surahNumber ?? this.surahNumber,
      surahName: surahName ?? this.surahName,
      audioUrl: audioUrl ?? this.audioUrl,
      localFilePath: localFilePath ?? this.localFilePath,
      listenedSeconds: listenedSeconds ?? this.listenedSeconds,
      positionSeconds: positionSeconds ?? this.positionSeconds,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      listenedAtMs: listenedAtMs ?? this.listenedAtMs,
    );
  }

  factory RecitationListeningHistoryItem.fromJson(Map<String, dynamic> json) {
    final sourceText =
        json['reciterSource']?.toString() ?? RecitationSource.quranCom.name;

    final source = RecitationSource.values.firstWhere(
          (item) => item.name == sourceText,
      orElse: () => RecitationSource.quranCom,
    );

    return RecitationListeningHistoryItem(
      id: json['id']?.toString() ?? '',
      reciterId: int.tryParse(json['reciterId'].toString()) ?? 0,
      reciterName: json['reciterName']?.toString() ?? 'قارئ',
      reciterSource: source,
      mp3QuranServerUrl: json['mp3QuranServerUrl']?.toString() ?? '',
      surahNumber: int.tryParse(json['surahNumber'].toString()) ?? 1,
      surahName: json['surahName']?.toString() ?? 'الفاتحة',
      audioUrl: json['audioUrl']?.toString() ?? '',
      localFilePath: json['localFilePath']?.toString(),
      listenedSeconds: int.tryParse(json['listenedSeconds'].toString()) ?? 0,
      positionSeconds: int.tryParse(json['positionSeconds'].toString()) ?? 0,
      durationSeconds: int.tryParse(json['durationSeconds'].toString()) ?? 0,
      listenedAtMs: int.tryParse(json['listenedAtMs'].toString()) ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reciterId': reciterId,
      'reciterName': reciterName,
      'reciterSource': reciterSource.name,
      'mp3QuranServerUrl': mp3QuranServerUrl,
      'surahNumber': surahNumber,
      'surahName': surahName,
      'audioUrl': audioUrl,
      'localFilePath': localFilePath,
      'listenedSeconds': listenedSeconds,
      'positionSeconds': positionSeconds,
      'durationSeconds': durationSeconds,
      'listenedAtMs': listenedAtMs,
    };
  }
}

class RecitationListeningHistoryStorage {
  RecitationListeningHistoryStorage._();

  static const String _historyKey = 'recitation_listening_history';
  static const int _maxItems = 60;

  static Future<List<RecitationListeningHistoryItem>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);

    if (raw == null || raw.trim().isEmpty) {
      return <RecitationListeningHistoryItem>[];
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) {
        return <RecitationListeningHistoryItem>[];
      }

      final items = decoded
          .whereType<Map>()
          .map(
            (item) => RecitationListeningHistoryItem.fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
          .where((item) => item.id.trim().isNotEmpty)
          .toList();

      items.sort((a, b) => b.listenedAtMs.compareTo(a.listenedAtMs));

      return items;
    } catch (_) {
      return <RecitationListeningHistoryItem>[];
    }
  }

  static Future<void> addHistoryItem({
    required int reciterId,
    required String reciterName,
    required RecitationSource reciterSource,
    required String mp3QuranServerUrl,
    required int surahNumber,
    required String surahName,
    required String audioUrl,
    String? localFilePath,
    required int listenedSeconds,
    required int positionSeconds,
    required int durationSeconds,
  }) async {
    if (listenedSeconds <= 0) return;

    final prefs = await SharedPreferences.getInstance();
    final history = await loadHistory();

    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final sameRecentIndex = history.indexWhere((item) {
      final sameRecitation = item.reciterId == reciterId &&
          item.reciterSource == reciterSource &&
          item.surahNumber == surahNumber;

      final closeEnough =
          nowMs - item.listenedAtMs <= const Duration(minutes: 30).inMilliseconds;

      return sameRecitation && closeEnough;
    });

    if (sameRecentIndex >= 0) {
      final oldItem = history.removeAt(sameRecentIndex);

      history.insert(
        0,
        oldItem.copyWith(
          reciterName: reciterName,
          mp3QuranServerUrl: mp3QuranServerUrl,
          surahName: surahName,
          audioUrl: audioUrl,
          localFilePath: localFilePath,
          listenedSeconds: oldItem.listenedSeconds + listenedSeconds,
          positionSeconds: positionSeconds,
          durationSeconds: durationSeconds,
          listenedAtMs: nowMs,
        ),
      );
    } else {
      final id = '${reciterSource.name}_${reciterId}_${surahNumber}_$nowMs';

      history.insert(
        0,
        RecitationListeningHistoryItem(
          id: id,
          reciterId: reciterId,
          reciterName: reciterName,
          reciterSource: reciterSource,
          mp3QuranServerUrl: mp3QuranServerUrl,
          surahNumber: surahNumber,
          surahName: surahName,
          audioUrl: audioUrl,
          localFilePath: localFilePath,
          listenedSeconds: listenedSeconds,
          positionSeconds: positionSeconds,
          durationSeconds: durationSeconds,
          listenedAtMs: nowMs,
        ),
      );
    }

    while (history.length > _maxItems) {
      history.removeLast();
    }

    await prefs.setString(
      _historyKey,
      jsonEncode(
        history.map((item) => item.toJson()).toList(),
      ),
    );
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  static String formatHistoryTime(int listenedAtMs) {
    if (listenedAtMs <= 0) return '';

    final date = DateTime.fromMillisecondsSinceEpoch(listenedAtMs);
    final now = DateTime.now();

    final sameDay =
        date.year == now.year && date.month == now.month && date.day == now.day;

    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    if (sameDay) return 'اليوم $hour:$minute';
    if (isYesterday) return 'أمس $hour:$minute';

    return '${date.day}/${date.month} $hour:$minute';
  }

  static String formatShortDuration(int seconds) {
    if (seconds <= 0) return '0د';

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0 && minutes > 0) return '${hours}س ${minutes}د';
    if (hours > 0) return '${hours}س';

    return '${minutes <= 0 ? 1 : minutes}د';
  }
}