part of '../qpc_connected_mushaf_page.dart';

extension _QuranReaderAudioMethods on _QpcConnectedMushafPageState {
  void _handlePlayerState(PlayerState state) {
    if (!mounted) {
      return;
    }

    final bool isPlayingNow = state.playing;
    if (_isAudioPlaying != isPlayingNow) {
      setState(() {
        _isAudioPlaying = isPlayingNow;
      });
    }

    if (state.processingState != ProcessingState.completed ||
        !_canAutoAdvanceAudio) {
      return;
    }

    final QpcAyahKey? completedAyah = _playingAyah;
    if (completedAyah == null) {
      return;
    }

    _queueAutoAdvanceForCompletedAyah(completedAyah);
  }

  bool get _canAutoAdvanceAudio {
    return _autoContinueSurah && !_userStoppedAudio && !_isAutoAdvancingAudio;
  }

  void _queueAutoAdvanceForCompletedAyah(QpcAyahKey completedAyah) {
    final QuranAyahAudioInfo? completedInfo = _currentAudioInfo;
    if (completedInfo == null ||
        completedInfo.surahNumber != completedAyah.surah ||
        completedInfo.ayahNumber != completedAyah.ayah ||
        _lastCompletedAudioAyah == completedAyah) {
      return;
    }

    _lastCompletedAudioAyah = completedAyah;
    _autoNextTimer?.cancel();
    _autoNextTimer = Timer(const Duration(milliseconds: 120), () {
      if (!mounted ||
          _userStoppedAudio ||
          !_autoContinueSurah ||
          _playingAyah != completedAyah) {
        return;
      }

      unawaited(_playNextAyahInSameSurah(expectedCurrent: completedAyah));
    });
  }

  void _handleAudioPosition(Duration position) {
    final QpcAyahKey? playingAyah = _playingAyah;
    final QuranAyahAudioInfo? audioInfo = _currentAudioInfo;

    if (playingAyah == null || audioInfo == null) {
      if (_activeAudioWord != null && mounted) {
        setState(() {
          _activeAudioWord = null;
        });
      }
      return;
    }

    _queueAutoAdvanceNearTrackEnd(position, playingAyah);

    if (_currentPlayingAyahWords.isEmpty) {
      if (_activeAudioWord != null && mounted) {
        setState(() {
          _activeAudioWord = null;
        });
      }
      return;
    }

    final QuranWordSyncResult result = _wordSyncController.resolveActiveWord(
      position: position,
      ayahKey: playingAyah,
      visibleAyahWords: _currentPlayingAyahWords,
      segments: audioInfo.segments,
    );

    if (!mounted) {
      return;
    }

    if (_activeAudioWord != result.activeWordKey) {
      setState(() {
        _activeAudioWord = result.activeWordKey;
      });
    }
  }

  void _queueAutoAdvanceNearTrackEnd(
    Duration position,
    QpcAyahKey playingAyah,
  ) {
    if (!_canAutoAdvanceAudio || _lastCompletedAudioAyah == playingAyah) {
      return;
    }

    final Duration? duration = _audioService.player.duration;
    if (duration == null || duration.inMilliseconds <= 0) {
      return;
    }

    final int remainingMs = duration.inMilliseconds - position.inMilliseconds;
    if (remainingMs < -500 || remainingMs > 120) {
      return;
    }

    _queueAutoAdvanceForCompletedAyah(playingAyah);
  }

  Future<void> _playAyah(
    QpcAyahKey ayahKey, {
    bool continueSurah = true,
  }) async {
    final int requestToken = ++_audioRequestToken;
    _autoNextTimer?.cancel();
    _lastCompletedAudioAyah = null;

    unawaited(
      _saveReadingPosition(
        ayahKey: ayahKey,
        mushafPageNumber: _selectedPageNumber,
      ),
    );

    setState(() {
      _isAudioLoading = true;
      _autoContinueSurah = continueSurah;
      _userStoppedAudio = false;
      _playingAyah = ayahKey;
      _anchorAyahKey = ayahKey;
      _selection = QuranSelection(ayahKey: ayahKey);
      _activeAudioWord = null;
      _currentAudioInfo = null;
      _currentPlayingAyahWords = <QpcWord>[];
    });

    try {
      final QpcPageData? pageData = _visiblePageData;
      final List<QpcWord> ayahWords =
          pageData != null && pageData.containsAyah(ayahKey)
          ? pageData.wordsForAyah(ayahKey)
          : await _repository.loadAyahWords(
              surahNumber: ayahKey.surah,
              ayahNumber: ayahKey.ayah,
            );

      if (!mounted || requestToken != _audioRequestToken) {
        return;
      }

      final QuranAyahAudioInfo? info = await _audioService.playAyah(
        surahNumber: ayahKey.surah,
        ayahNumber: ayahKey.ayah,
      );

      await _audioService.player.setVolume(_volume);

      if (!mounted || requestToken != _audioRequestToken) {
        return;
      }

      if (info == null) {
        setState(() {
          _playingAyah = null;
          _isAudioPlaying = false;
          _currentAudioInfo = null;
          _currentPlayingAyahWords = <QpcWord>[];
        });

        _showInfoSnackBar('لم يتم العثور على صوت الآية', isError: true);
        return;
      }

      setState(() {
        _audioPanelVisible = true;
        _currentAudioInfo = info;
        _reciterName = info.reciter.name;
        _currentPlayingAyahWords = ayahWords;
      });
    } catch (_) {
      if (!mounted || requestToken != _audioRequestToken) {
        return;
      }

      setState(() {
        _playingAyah = null;
        _isAudioPlaying = false;
        _currentAudioInfo = null;
        _currentPlayingAyahWords = <QpcWord>[];
      });

      _showInfoSnackBar('حصل خطأ أثناء تشغيل الصوت', isError: true);
    } finally {
      if (mounted && requestToken == _audioRequestToken) {
        setState(() {
          _isAudioLoading = false;
        });
      }
    }
  }

  QpcAyahKey? _currentAudioTargetAyah() {
    return _selection?.ayahKey ?? _playingAyah ?? _anchorAyahKey;
  }

  QpcAyahKey? _offsetAyah(QpcAyahKey ayahKey, int offset) {
    final int suraIndex = (ayahKey.surah - 1).clamp(0, 113).toInt();
    final int ayahIndex = (ayahKey.ayah - 1).clamp(0, 286).toInt();
    final int globalAyahIndex = QuranReaderHelpers.getGlobalAyahIndex(
      suraIndex: suraIndex,
      ayahIndex: ayahIndex,
    );

    if (globalAyahIndex < 0) {
      return null;
    }

    final int targetGlobalAyahIndex = globalAyahIndex + offset;
    if (targetGlobalAyahIndex < 0 ||
        targetGlobalAyahIndex >= QuranReaderHelpers.totalAyahs) {
      return null;
    }

    final QuranAyahPosition position =
        QuranReaderHelpers.getPositionFromGlobalIndex(targetGlobalAyahIndex);

    return QpcAyahKey(
      surah: position.suraIndex + 1,
      ayah: position.ayahIndex + 1,
    );
  }

  Future<void> _playCurrentAudioTarget() async {
    final QpcAyahKey? ayahKey = _currentAudioTargetAyah();
    if (ayahKey == null) {
      return;
    }

    if (_currentAudioInfo != null && _playingAyah == ayahKey) {
      if (_audioService.player.playing) {
        _autoNextTimer?.cancel();
        _autoContinueSurah = false;
        _userStoppedAudio = true;
        await _audioService.pause();
        if (mounted) {
          setState(() {
            _isAudioPlaying = false;
          });
        }
      } else {
        if (_audioService.player.processingState == ProcessingState.completed) {
          await _playAyah(ayahKey, continueSurah: true);
          return;
        }

        _autoContinueSurah = true;
        _userStoppedAudio = false;
        await _audioService.resume();
        if (mounted) {
          setState(() {
            _isAudioPlaying = true;
          });
        }
      }
      return;
    }

    await _playAyah(ayahKey, continueSurah: true);
  }

  Future<void> _replayCurrentAyah() async {
    final QpcAyahKey? ayahKey = _currentAudioTargetAyah();
    if (ayahKey == null) {
      return;
    }

    await _playAyah(ayahKey, continueSurah: true);
  }

  Future<void> _playPreviousAyah() async {
    final QpcAyahKey? ayahKey = _currentAudioTargetAyah();
    if (ayahKey == null) {
      return;
    }

    final QpcAyahKey? previousAyah = _offsetAyah(ayahKey, -1);
    if (previousAyah == null) {
      return;
    }

    final int pageNumber = _pageNumberForAyah(previousAyah);
    if (!_connectedMode) {
      _lastMushafPageNumber = pageNumber;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_mushafPageIndex(pageNumber));
      }
    }

    setState(() {
      _anchorAyahKey = previousAyah;
      _selectedPageNumber = pageNumber;
      _selection = QuranSelection(ayahKey: previousAyah);
    });
    _setBottomBarSnapshotForPage(pageNumber, ayahKey: previousAyah);
    if (!_connectedMode) {
      _warmUpReaderAssets(pageNumber, reason: 'audio previous');
    }

    await _playAyah(previousAyah, continueSurah: true);
  }

  Future<void> _playNextAyah() async {
    final QpcAyahKey? ayahKey = _currentAudioTargetAyah();
    if (ayahKey == null) {
      return;
    }

    final QpcAyahKey? nextAyah = _offsetAyah(ayahKey, 1);
    if (nextAyah == null) {
      return;
    }

    final int pageNumber = _pageNumberForAyah(nextAyah);
    if (!_connectedMode) {
      _lastMushafPageNumber = pageNumber;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_mushafPageIndex(pageNumber));
      }
    }

    setState(() {
      _anchorAyahKey = nextAyah;
      _selectedPageNumber = pageNumber;
      _selection = QuranSelection(ayahKey: nextAyah);
    });
    _setBottomBarSnapshotForPage(pageNumber, ayahKey: nextAyah);
    if (!_connectedMode) {
      _warmUpReaderAssets(pageNumber, reason: 'audio next');
    }

    await _playAyah(nextAyah, continueSurah: true);
  }

  Future<void> _playNextAyahInSameSurah({QpcAyahKey? expectedCurrent}) async {
    if (_isAutoAdvancingAudio) {
      return;
    }

    final QpcAyahKey? current = _playingAyah;
    if (current == null) {
      return;
    }

    if (expectedCurrent != null && current != expectedCurrent) {
      return;
    }

    _isAutoAdvancingAudio = true;

    try {
      final QpcAyahKey? next = _offsetAyah(current, 1);
      if (next == null) {
        await _stopAudio();
        return;
      }

      final int pageNumber = _pageNumberForAyah(next);
      if (!_connectedMode) {
        _lastMushafPageNumber = pageNumber;
        if (_pageController.hasClients && pageNumber != _selectedPageNumber) {
          _pageController.jumpToPage(_mushafPageIndex(pageNumber));
        }
      }

      if (mounted) {
        setState(() {
          _anchorAyahKey = next;
          _selectedPageNumber = pageNumber;
          _selection = QuranSelection(ayahKey: next);
        });
        _setBottomBarSnapshotForPage(pageNumber, ayahKey: next);
        if (!_connectedMode) {
          _warmUpReaderAssets(pageNumber, reason: 'audio auto next');
        }
      }

      await _playAyah(next, continueSurah: true);
    } finally {
      _isAutoAdvancingAudio = false;
    }
  }

  Future<void> _stopAudio({bool hidePanel = true}) async {
    _audioRequestToken++;
    _autoNextTimer?.cancel();
    _lastCompletedAudioAyah = null;
    _userStoppedAudio = true;
    _autoContinueSurah = false;
    await _audioService.stop();

    if (!mounted) {
      return;
    }

    setState(() {
      _playingAyah = null;
      _activeAudioWord = null;
      _currentAudioInfo = null;
      _currentPlayingAyahWords = <QpcWord>[];
      _isAudioLoading = false;
      _isAudioPlaying = false;
      if (hidePanel) {
        _audioPanelVisible = false;
      }
    });
  }

  Future<void> _changeVolume(double value) async {
    final double safeValue = value.clamp(0.0, 1.0).toDouble();

    setState(() {
      _volume = safeValue;
    });

    await _audioService.player.setVolume(safeValue);
    _showControls();
  }

  Future<void> _selectReciter(QuranAyahReciter reciter) async {
    await _audioService.setReciter(reciter);

    if (!mounted) {
      return;
    }

    setState(() {
      _reciterName = reciter.name;
      _playingAyah = null;
      _activeAudioWord = null;
      _currentAudioInfo = null;
      _currentPlayingAyahWords = <QpcWord>[];
      _audioPanelVisible = false;
    });

    _showControls();
  }
}
