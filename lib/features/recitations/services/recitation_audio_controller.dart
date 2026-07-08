import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rxdart/rxdart.dart';

import '../models/reciter_model.dart';
import 'recitation_api_service.dart';
import 'recitation_listening_history_storage.dart';
import 'recitation_listening_stats_storage.dart';
import 'recitation_progress_storage.dart';

class RecitationAudioState {
  final Duration position;
  final Duration duration;
  final bool playing;
  final bool loading;
  final bool connectionWarning;
  final ProcessingState processingState;

  const RecitationAudioState({
    required this.position,
    required this.duration,
    required this.playing,
    required this.loading,
    required this.connectionWarning,
    required this.processingState,
  });
}

class CurrentRecitationInfo {
  final int reciterId;
  final String reciterName;
  final RecitationSource reciterSource;
  final String mp3QuranServerUrl;
  final int surahNumber;
  final String surahName;
  final String audioUrl;
  final String? localFilePath;

  const CurrentRecitationInfo({
    required this.reciterId,
    required this.reciterName,
    required this.reciterSource,
    required this.mp3QuranServerUrl,
    required this.surahNumber,
    required this.surahName,
    required this.audioUrl,
    this.localFilePath,
  });

  bool get isOffline {
    return localFilePath != null && localFilePath!.trim().isNotEmpty;
  }
}

class RecitationAudioController {
  RecitationAudioController._internal();

  static final RecitationAudioController instance =
  RecitationAudioController._internal();

  final AudioPlayer player = AudioPlayer();

  CurrentRecitationInfo? currentInfo;

  bool _sessionConfigured = false;
  Duration _lastStatsPosition = Duration.zero;

  int _historyUnsavedSeconds = 0;

  Stream<RecitationAudioState> get audioStateStream {
    return Rx.combineLatest3<Duration, Duration?, PlayerState,
        RecitationAudioState>(
      player.positionStream,
      player.durationStream,
      player.playerStateStream,
          (position, duration, playerState) {
        final processingState = playerState.processingState;

        final loading = processingState == ProcessingState.loading ||
            processingState == ProcessingState.buffering;

        final onlineMode = currentInfo?.isOffline != true;

        final connectionWarning = onlineMode &&
            processingState == ProcessingState.buffering &&
            position.inSeconds > 1 &&
            !playerState.playing;

        return RecitationAudioState(
          position: position,
          duration: duration ?? Duration.zero,
          playing: playerState.playing,
          loading: loading,
          connectionWarning: connectionWarning,
          processingState: processingState,
        );
      },
    );
  }

  Future<void> _configureSession() async {
    if (_sessionConfigured) return;

    final session = await AudioSession.instance;

    await session.configure(
      AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions:
        AVAudioSessionCategoryOptions.duckOthers,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        avAudioSessionRouteSharingPolicy:
        AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType:
        AndroidAudioFocusGainType.gainTransientMayDuck,
        androidWillPauseWhenDucked: false,
      ),
    );

    _sessionConfigured = true;
  }

  bool _isSameRecitation({
    required int reciterId,
    required RecitationSource reciterSource,
    required int surahNumber,
    required String selectedAudioUrl,
    String? localFilePath,
  }) {
    final info = currentInfo;

    if (info == null) return false;

    final currentLocalPath = info.localFilePath?.trim() ?? '';
    final newLocalPath = localFilePath?.trim() ?? '';

    return info.reciterId == reciterId &&
        info.reciterSource == reciterSource &&
        info.surahNumber == surahNumber &&
        info.audioUrl == selectedAudioUrl &&
        currentLocalPath == newLocalPath;
  }

  Future<void> playRecitation({
    required int reciterId,
    required String reciterName,
    required RecitationSource reciterSource,
    required String mp3QuranServerUrl,
    required int surahNumber,
    required String surahName,
    Duration startPosition = Duration.zero,
    String? initialAudioUrl,
    String? localFilePath,
  }) async {
    await _configureSession();

    final String selectedAudioUrl;

    if (localFilePath != null && localFilePath.trim().isNotEmpty) {
      selectedAudioUrl = localFilePath;
    } else {
      selectedAudioUrl = initialAudioUrl ??
          (await RecitationApiService.getChapterAudioFile(
            reciterId: reciterId,
            source: reciterSource,
            chapterNumber: surahNumber,
            mp3QuranServerUrl: mp3QuranServerUrl,
          ))
              .audioUrl;
    }

    final sameRecitation = _isSameRecitation(
      reciterId: reciterId,
      reciterSource: reciterSource,
      surahNumber: surahNumber,
      selectedAudioUrl: selectedAudioUrl,
      localFilePath: localFilePath,
    );

    if (!sameRecitation && currentInfo != null) {
      await _saveCurrentProgress(forceHistorySave: true);
      _historyUnsavedSeconds = 0;
    }

    currentInfo = CurrentRecitationInfo(
      reciterId: reciterId,
      reciterName: reciterName,
      reciterSource: reciterSource,
      mp3QuranServerUrl: mp3QuranServerUrl,
      surahNumber: surahNumber,
      surahName: surahName,
      audioUrl: selectedAudioUrl,
      localFilePath: localFilePath,
    );

    if (sameRecitation && player.processingState != ProcessingState.idle) {
      if (startPosition.inSeconds > 5) {
        final difference =
        (player.position.inSeconds - startPosition.inSeconds).abs();

        if (difference > 3) {
          await player.seek(startPosition);
          _lastStatsPosition = startPosition;
        }
      }

      if (!player.playing) {
        _lastStatsPosition = player.position;
        await player.play();
      }

      return;
    }

    final mediaItem = MediaItem(
      id: '${reciterSource.name}_${reciterId}_$surahNumber',
      album: 'تلاوة القرآن الكريم',
      title: 'سورة $surahName',
      artist: reciterName,
    );

    if (localFilePath != null && localFilePath.trim().isNotEmpty) {
      final file = File(localFilePath);

      if (!await file.exists()) {
        throw Exception('Local audio file does not exist.');
      }

      await player.setAudioSource(
        AudioSource.file(
          localFilePath,
          tag: mediaItem,
        ),
      );
    } else {
      await player.setAudioSource(
        AudioSource.uri(
          Uri.parse(selectedAudioUrl),
          tag: mediaItem,
        ),
      );
    }

    final savedPosition =
    await RecitationProgressStorage.getSavedPositionForRecitation(
      reciterId: reciterId,
      reciterSource: reciterSource,
      surahNumber: surahNumber,
    );

    final targetPosition =
    startPosition.inSeconds > 5 ? startPosition : savedPosition;

    if (targetPosition.inSeconds > 5) {
      await player.seek(targetPosition);
    }

    _lastStatsPosition = targetPosition;

    await player.play();
  }

  Future<void> togglePlayPause() async {
    if (player.playing) {
      await _saveCurrentProgress(forceHistorySave: true);
      await player.pause();
    } else {
      _lastStatsPosition = player.position;
      await player.play();
    }
  }

  Future<void> seekBackward() async {
    final target = player.position - const Duration(seconds: 10);
    final safeTarget = target.isNegative ? Duration.zero : target;

    await player.seek(safeTarget);
    _lastStatsPosition = safeTarget;

    await _saveCurrentProgress(countListeningTime: false);
  }

  Future<void> seekForward() async {
    final duration = player.duration;
    final target = player.position + const Duration(seconds: 10);

    if (duration != null && target > duration) {
      await player.seek(duration);
      _lastStatsPosition = duration;
    } else {
      await player.seek(target);
      _lastStatsPosition = target;
    }

    await _saveCurrentProgress(countListeningTime: false);
  }

  Future<void> seekTo(Duration position) async {
    await player.seek(position);
    _lastStatsPosition = position;
    await _saveCurrentProgress(countListeningTime: false);
  }

  Future<void> stop() async {
    await _saveCurrentProgress(forceHistorySave: true);
    await player.stop();
    currentInfo = null;
    _lastStatsPosition = Duration.zero;
    _historyUnsavedSeconds = 0;
  }

  Future<void> saveCurrentProgress() async {
    await _saveCurrentProgress();
  }

  Future<void> _saveHistorySnapshot({
    required CurrentRecitationInfo info,
    required Duration position,
    required Duration duration,
    required int listenedSeconds,
  }) async {
    if (listenedSeconds <= 0) return;

    await RecitationListeningHistoryStorage.addHistoryItem(
      reciterId: info.reciterId,
      reciterName: info.reciterName,
      reciterSource: info.reciterSource,
      mp3QuranServerUrl: info.mp3QuranServerUrl,
      surahNumber: info.surahNumber,
      surahName: info.surahName,
      audioUrl: info.audioUrl,
      localFilePath: info.localFilePath,
      listenedSeconds: listenedSeconds,
      positionSeconds: position.inSeconds,
      durationSeconds: duration.inSeconds,
    );
  }

  Future<void> _saveCurrentProgress({
    bool countListeningTime = true,
    bool forceHistorySave = false,
  }) async {
    final info = currentInfo;

    if (info == null) return;

    final duration = player.duration ?? Duration.zero;
    final position = player.position;

    if (countListeningTime && player.playing && duration.inSeconds > 0) {
      final deltaSeconds = position.inSeconds - _lastStatsPosition.inSeconds;

      if (deltaSeconds > 0 && deltaSeconds <= 30) {
        await RecitationListeningStatsStorage.addListeningSeconds(
          seconds: deltaSeconds,
          reciterId: info.reciterId,
          reciterName: info.reciterName,
          surahNumber: info.surahNumber,
          surahName: info.surahName,
        );

        _historyUnsavedSeconds += deltaSeconds;
      }

      _lastStatsPosition = position;
    }

    if (_historyUnsavedSeconds >= 60 ||
        (forceHistorySave && _historyUnsavedSeconds > 0)) {
      final secondsToSave = _historyUnsavedSeconds;
      _historyUnsavedSeconds = 0;

      await _saveHistorySnapshot(
        info: info,
        position: position,
        duration: duration,
        listenedSeconds: secondsToSave,
      );
    }

    await RecitationProgressStorage.saveLastRecitation(
      reciterId: info.reciterId,
      reciterName: info.reciterName,
      reciterSource: info.reciterSource,
      mp3QuranServerUrl: info.mp3QuranServerUrl,
      surahNumber: info.surahNumber,
      surahName: info.surahName,
      audioUrl: info.audioUrl,
      positionSeconds: position.inSeconds,
      durationSeconds: duration.inSeconds,
    );
  }
}